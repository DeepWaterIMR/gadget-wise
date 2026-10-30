## ---------------------------
##
## Script name: Survey indices
##
## Purpose of script: Turn the index tables (index_<Name>.csv) into gadget3 abundance-distribution
## data. A biomass index has a weight column, an abundance index a number column; a length-group
## index has a length column (one group per index, or several groups fitted as one component).
##
## Index-wise users: copy the versioned assessment index (assessment-index.rds) from the index-wise
## project and convert it to index_<Name>.csv in the data-loop, keeping the index-wise metadata.
##
## Timing: stock-based indices (g3l_abundancedistribution without fleets) are compared with the
## model at the likelihood step, AFTER renewal and BEFORE ageing (g3_action_order). A year-Y index
## therefore includes the recruits added in year Y. See knowledge/action-order.md in gadget-wise.
##
## Creates: survey_indices (named list of g3 data frames)
##
## ---------------------------

survey_indices <- lapply(model_params$likelihood$indices, function(si) {
  x <- read_model_input("index", si$name)
  value_col <- if ("weight" %in% names(x)) "weight" else "number"

  if (!is.null(si$year_shift) && si$year_shift != 0) x <- mutate(x, year = year + si$year_shift)
  if (!is.null(si$start_year)) x <- filter(x, year >= si$start_year)

  out <- x |> dplyr::select(year, step, any_of("length"), all_of(value_col))
  if ("length" %in% names(out)) {
    # Length-group index: one or more groups, bounds from MODEL$LIKELIHOOD$indices[[i]]$lengths
    stopifnot("A length index needs lengths: [lower, upper, ...]" = !is.null(si$lengths))
    out <- out |>
      mutate(length = bin_length(length, unlist(si$lengths))) |>
      group_by(year, step, length) |>
      summarise(!!value_col := sum(.data[[value_col]]), .groups = "drop")
  }
  as.data.frame(out)
})
names(survey_indices) <- vapply(model_params$likelihood$indices, function(si) si$name, character(1))

save(survey_indices, file = file.path(base_dir, "data/Survey indices to Gadget.rda"))
