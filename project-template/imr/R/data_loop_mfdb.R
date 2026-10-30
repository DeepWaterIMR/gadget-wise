## ---------------------------
##
## mfdb data-loop
##
## Pulls the data from an mfdb database (https://github.com/gadget-framework/mfdb), the data system
## of the Icelandic gadget models. mfdb_sample_*() queries return data already aggregated to the
## requested groups; this loop writes them to the contract tables. Edit the queries for your
## database: sampling types, areas and species codes are database-specific.
##
## ---------------------------

run_data_loop <- function(model_params, stock_params, fleet_params, out_dir) {
  if (!requireNamespace("mfdb", quietly = TRUE)) stop("Install mfdb first: install.packages('mfdb')")
  cfg <- read_yaml_utf8("config.yaml")$MODEL$MFDB
  if (is.null(cfg)) stop("Set MODEL$MFDB in config.yaml: db (connection), species, areas, and per fleet sampling_type")

  mdb <- mfdb::mfdb(cfg$db)
  on.exit(mfdb::mfdb_disconnect(mdb))

  defaults <- list(
    area = mfdb::mfdb_group(`1` = cfg$areas),
    timestep = if (length(model_params$step_lengths) == 1) mfdb::mfdb_timestep_yearly else mfdb::mfdb_timestep_quarterly,
    year = model_params$year_range,
    species = cfg$species
  )
  len <- mfdb::mfdb_interval("len", seq(stock_params$minlength, stock_params$maxlength, by = stock_params$dl))

  to_contract <- function(x, kind) {
    x |>
      dplyr::rename_with(~"length", dplyr::any_of("length")) |>
      dplyr::mutate(
        step = as.integer(.data$step), area = as.character(.data$area),
        length = as.numeric(sub("^len", "", .data$length))
      )
  }

  for (fl in names(cfg$fleets)) {
    st <- cfg$fleets[[fl]]$sampling_type
    ld <- mfdb::mfdb_sample_count(mdb, c("length"), c(list(sampling_type = st, length = len), defaults))[[1]]
    to_contract(ld) |> readr::write_csv(file.path(out_dir, paste0("ldist_", fl, ".csv")))

    al <- mfdb::mfdb_sample_count(mdb, c("age", "length"), c(list(
      sampling_type = st, age = mfdb::mfdb_interval("age", seq(stock_params$minage, stock_params$maxage)),
      length = len
    ), defaults))[[1]]
    to_contract(al) |>
      dplyr::mutate(age = as.numeric(sub("^age", "", .data$age))) |>
      readr::write_csv(file.path(out_dir, paste0("aldist_", fl, ".csv")))

    if (!is.null(cfg$fleets[[fl]]$landings_type)) {
      mfdb::mfdb_sample_totalweight(mdb, NULL, c(list(sampling_type = cfg$fleets[[fl]]$landings_type), defaults))[[1]] |>
        dplyr::mutate(step = as.integer(.data$step), area = as.character(.data$area)) |>
        readr::write_csv(file.path(out_dir, paste0("catches_", fl, ".csv")))
    }
  }
  message("Survey indices and life_history.yaml: write them from your sources (see R/data_contract.R)")
}
