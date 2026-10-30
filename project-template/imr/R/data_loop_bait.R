## ---------------------------
##
## BAIT data-loop: IMR Biotic data through the local BioticExplorer DuckDB database
##
## Requires BAIT (https://github.com/DeepWaterIMR/BAIT) and its database. Connect with the
## biotic-connect skill, query with biotic-query, and qualify survey samples with
## biotic-survey-analysis. Raw data stay on this machine (BAIT privacy rules, biotic-privacy).
##
## This loop writes length, age-length and maturity data for the fleets in fleet_params from Biotic
## individual data. Commercial catches (landings) and survey indices do not come from Biotic:
##   - catches_<Fleet>.csv: official landings (e.g. ICES or national statistics), converted in
##     prepare_catches() below
##   - index_<Name>.csv: the assessment index from index-wise (assessment-index.rds), converted in
##     prepare_index() below
##
## Fill BIOTIC_FILTERS with the selection of each fleet (gear, platform, mission type, area, time).
## These are stock-specific decisions: record them in the data report.
##
## ---------------------------

BIOTIC_FILTERS <- list(
  # Surv = list(cruiseseriescode = <code>, gear = NULL, area = NULL, months = 1:12),
  # Comm = list(missiontype = c(1, 2, 3), gear = NULL, area = NULL, months = 1:12)
)

run_data_loop <- function(model_params, stock_params, fleet_params, out_dir) {
  if (length(BIOTIC_FILTERS) == 0) stop("Set BIOTIC_FILTERS in R/data_loop_bait.R first (one entry per fleet).")
  if (!requireNamespace("duckdb", quietly = TRUE)) stop("BAIT needs the duckdb package")

  db_path <- Sys.getenv("BIOTIC_DUCKDB", file.path("~", "IMR_biotic_BES_database", "bioticexplorer.duckdb"))
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path.expand(db_path), read_only = TRUE)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))

  species <- read_yaml_utf8("config.yaml")$MODEL$BIOTIC_SPECIES # Common name or aphia code in the Biotic database
  if (is.null(species)) stop("Set MODEL$BIOTIC_SPECIES in config.yaml")

  # Individual data with station metadata (indall; see the biotic-query skill). NB: commonname is
  # Norwegian free text: verify the filter against aphia
  ind <- dplyr::tbl(con, "indall") |>
    dplyr::filter(.data$commonname == !!species, .data$startyear %in% !!model_params$year_range) |>
    dplyr::select(startyear, stationstartdate, missiontype, cruiseseriescode, gear, area, platform, serialnumber, catchsampleid, length, age, maturationstage, sex) |>
    dplyr::collect() |>
    dplyr::mutate(
      year = .data$startyear,
      month = as.integer(format(as.Date(.data$stationstartdate), "%m")),
      length = .data$length * 100 # m -> cm
    )

  steps <- cumsum(c(0, model_params$step_lengths))

  for (fl in names(BIOTIC_FILTERS)) {
    f <- BIOTIC_FILTERS[[fl]]
    x <- ind |>
      dplyr::filter(
        is.null(f$cruiseseriescode) | .data$cruiseseriescode %in% f$cruiseseriescode,
        is.null(f$missiontype) | .data$missiontype %in% f$missiontype,
        is.null(f$gear) | .data$gear %in% f$gear,
        is.null(f$area) | .data$area %in% f$area,
        .data$month %in% (f$months %||% 1:12),
        !is.na(.data$length)
      ) |>
      dplyr::mutate(step = findInterval(.data$month - 1, steps), area = names(areas)[1])

    # NB: Raw counts. Raise by catch sample (number caught / number measured) for survey or fishery
    # compositions, as decided in the data report (biotic-survey-analysis)
    x |> dplyr::count(year, step, area, length, name = "number") |>
      readr::write_csv(file.path(out_dir, paste0("ldist_", fl, ".csv")))
    x |> dplyr::filter(!is.na(.data$age)) |> dplyr::count(year, step, area, age, length, name = "number") |>
      readr::write_csv(file.path(out_dir, paste0("aldist_", fl, ".csv")))
    if (model_params$two_stocks) {
      # NB: Check the maturity scale of the species. Here stages 1-2 are immature, 3+ mature
      x |> dplyr::filter(!is.na(.data$maturationstage)) |>
        dplyr::mutate(maturity_stage = ifelse(.data$maturationstage %in% 1:2, "imm", "mat")) |>
        dplyr::count(year, step, area, length, maturity_stage, name = "number") |>
        readr::write_csv(file.path(out_dir, paste0("matp_", fl, ".csv")))
    }
  }

  prepare_catches(model_params, fleet_params, out_dir)
  prepare_index(model_params, out_dir)
  message("Life history: estimate growth, length-weight and maturity (ggFishPlots) in the data report, then write ",
          file.path(out_dir, "life_history.yaml"))
}

#' Landings to catches_<Fleet>.csv. BAIT's catch-data skill or official statistics supply landings.csv.
prepare_catches <- function(model_params, fleet_params, out_dir) {
  src <- file.path("data", "source", "landings.csv") # year, fleet, tonnes
  if (!file.exists(src)) {
    warning("No ", src, ": write catches_<Fleet>.csv yourself")
    return(invisible())
  }
  readr::read_csv(src, show_col_types = FALSE) |>
    dplyr::filter(.data$year %in% model_params$year_range) |>
    dplyr::group_split(.data$fleet) |>
    lapply(function(x) {
      x |> dplyr::transmute(year, step = 1, area = names(areas)[1], total_weight = tonnes * 1e3) |>
        readr::write_csv(file.path(out_dir, paste0("catches_", x$fleet[1], ".csv")))
    })
  invisible()
}

#' index-wise assessment index to index_<Name>.csv
prepare_index <- function(model_params, out_dir) {
  for (si in model_params$likelihood$indices %||% list()) {
    src <- file.path("data", "source", si$file %||% "assessment-index.rds")
    if (!file.exists(src)) {
      warning("No ", src, ": copy the index-wise assessment index there, or write index_", si$name, ".csv yourself")
      next
    }
    idx <- readRDS(src)
    # index-wise handoff (schema 1): observations plus metadata; keep the provenance in the data report
    if (is.data.frame(idx)) {
      tab <- idx
      value_col <- "weight"
    } else if (identical(idx$schema_version, 1L)) {
      tab <- idx$observations
      value_col <- if (grepl("abundance", idx$metadata$index_type %||% "")) "number" else "weight"
    } else {
      stop(src, " is neither a data frame nor an index-wise schema 1 handoff")
    }
    tab |>
      dplyr::transmute(year, step = si$step %||% 1, area = names(areas)[1], !!value_col := .data$est,
                       lwr = .data$lwr, upr = .data$upr) |>
      readr::write_csv(file.path(out_dir, paste0("index_", si$name, ".csv")))
  }
  invisible()
}
