## ---------------------------
##
## The model-input data contract
##
## Every data-loop (BAIT, mfdb or custom) writes the same tables to data/output/model-input/. The
## numbered data scripts (02-*) read only these tables, so a data-loop can be swapped without
## touching the model. One file per data set, named <kind>_<fleet or index>.csv:
##
##   catches_<Fleet>.csv   year, step, area, total_weight (kg) or number
##   ldist_<Fleet>.csv     year, step, area, length (cm), number
##   aldist_<Fleet>.csv    year, step, area, age, length (cm), number
##   matp_<Fleet>.csv      year, step, area, length (cm), maturity_stage ("imm"/"mat"), number
##   index_<Name>.csv      year, step, area, [length (cm, lower bound)], weight or number, [lwr, upr]
##   life_history.yaml     growth, length-weight, maturity and initial length-at-age (see data/output/parameters/README.md)
##
## Lengths and ages are raw observations (or already-binned lower bounds); the scripts bin them to
## the model groups here. Numbers are counts or raised numbers, as the data-loop documents.
##
## ---------------------------

model_input_dir <- file.path("data", "output", "model-input")

CONTRACT_COLUMNS <- list(
  catches = c("year", "step", "area"),
  ldist = c("year", "step", "area", "length", "number"),
  aldist = c("year", "step", "area", "age", "length", "number"),
  matp = c("year", "step", "area", "length", "maturity_stage", "number"),
  index = c("year", "step", "area")
)

#' @title Read and validate a model-input table
#' @param kind One of names(CONTRACT_COLUMNS)
#' @param name Fleet or index name, e.g. "Comm"
#' @param years Model years; rows outside are dropped
read_model_input <- function(kind, name, years = model_params$year_range) {
  f <- file.path(model_input_dir, paste0(kind, "_", name, ".csv"))
  if (!file.exists(f)) stop("Missing model input ", f, ". Run the data-loop (02-0_data_loop.R) first.")
  x <- readr::read_csv(f, show_col_types = FALSE, col_types = readr::cols(area = "c", .default = readr::col_guess()))
  miss <- setdiff(CONTRACT_COLUMNS[[kind]], names(x))
  if (length(miss)) stop(f, " is missing columns: ", paste(miss, collapse = ", "))
  if (kind == "catches" && !any(c("total_weight", "number") %in% names(x))) {
    stop(f, " needs a total_weight (kg) or number column")
  }
  if (kind == "index" && !any(c("weight", "number") %in% names(x))) {
    stop(f, " needs a weight or number column")
  }
  if (kind == "matp" && !all(x$maturity_stage %in% c("imm", "mat"))) {
    stop(f, ": maturity_stage must be 'imm' or 'mat'")
  }
  x |> filter(year %in% years)
}

#' @title Bin lengths to gadget3 length groups
#' @description Clamps lengths to the model range and labels them "[lower,upper)", the cut() form
#'   gadget3 parses for likelihood data (gadget3:::parse_levels). The last group is open-ended.
#' @param length Numeric lengths (cm)
#' @param breaks Lower bounds of the groups
bin_length <- function(length, breaks) {
  labs <- paste0("[", head(breaks, -1), ",", tail(breaks, -1), ")")
  labs <- c(labs, paste0("[", tail(breaks, 1), ",Inf)"))
  idx <- findInterval(pmax(length, min(breaks)), breaks)
  factor(labs[idx], levels = labs)
}

#' @title Bin ages to gadget3 age groups
#' @param age Numeric ages
#' @param breaks Lower bounds of the age groups, e.g. c(2:20, 23, 26) for annual ages to 20, then 3-year groups
bin_age <- function(age, breaks) {
  labs <- paste0("[", head(breaks, -1), ",", tail(breaks, -1), ")")
  labs <- c(labs, paste0("[", tail(breaks, 1), ",Inf)"))
  idx <- findInterval(age, breaks)
  keep <- idx > 0
  out <- rep(NA_character_, length(age))
  out[keep] <- labs[idx[keep]]
  factor(out, levels = labs)
}

#' @title Aggregate a contract table to gadget3 likelihood data
#' @param x Contract table (ldist, aldist or matp)
#' @param length_breaks Lower bounds of the likelihood length groups
#' @param age_breaks Lower bounds of the age groups (aldist only)
#' @param areas Named area vector (model area names); area "all" keeps one aggregated area
#' @return A data.frame with year, step, area, [age], length, [stock], number. Missing year-step-
#'   group combinations are completed with 0 within sampled year-steps.
to_g3_distribution <- function(x, length_breaks, age_breaks = NULL) {
  x <- x |>
    mutate(length = bin_length(length, length_breaks))
  if (!is.null(age_breaks) && "age" %in% names(x)) {
    x <- x |>
      mutate(age = bin_age(age, age_breaks)) |>
      filter(!is.na(age))
  }
  if ("maturity_stage" %in% names(x)) x <- rename(x, stock = maturity_stage)
  grp <- intersect(c("year", "step", "area", "stock", "age", "length"), names(x))
  out <- x |>
    group_by(across(all_of(grp))) |>
    summarise(number = sum(number), .groups = "drop") |>
    tidyr::complete(tidyr::nesting(year, step, area), !!!rlang::syms(setdiff(grp, c("year", "step", "area"))), fill = list(number = 0)) |>
    arrange(across(all_of(grp)))
  as.data.frame(out)
}

#' @title Plot a binned distribution for checking
#' @param x Output of to_g3_distribution()
#' @param title Plot title
plot_g3_distribution <- function(x, title = NULL) {
  x |>
    mutate(lower = as.numeric(sub("^\\[([^,]+),.*", "\\1", as.character(length)))) |>
    group_by(year, lower) |>
    summarise(number = sum(number), .groups = "drop") |>
    group_by(year) |>
    mutate(prop = number / sum(number)) |>
    ggplot(aes(lower, prop)) +
    geom_col(width = 0.9 * min(diff(sort(unique(as.numeric(sub("^\\[([^,]+),.*", "\\1", levels(x$length)))))))) +
    facet_wrap(~year, ncol = 4) +
    labs(x = "Length (cm, lower bound)", y = "Proportion", title = title)
}
