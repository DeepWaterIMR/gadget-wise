## ---------------------------
##
## Script name: Catches
##
## Purpose of script: Read the catch tables (catches_<Fleet>.csv) for each fleet. Commercial
## catches are in kg (total_weight); survey "catches" are nominal (a small number of fish per
## year-step), so surveys do not deplete the stock.
##
## Creates: <Fleet>_catches
##
## ---------------------------

for (i in seq_len(nrow(fleet_params))) {
  fl <- fleet_params$name[i]
  x <- if (fleet_params$type[i] == "survey" && !file.exists(file.path(model_input_dir, paste0("catches_", fl, ".csv")))) {
    # Nominal survey catch in the survey years (any fleet data the survey has)
    survey_years <- unique(unlist(lapply(ls(pattern = paste0("^", fl, "_(ldist|aldist|matp)$")), function(k) get(k)$year)))
    tidyr::expand_grid(year = sort(survey_years), step = 1, area = names(areas)[1]) |>
      mutate(number = 1)
  } else {
    read_model_input("catches", fl)
  }
  if (!"total_weight" %in% names(x)) x <- rename(x, total_weight = number)
  x <- x |>
    mutate(area = areas[as.character(area)]) |>
    group_by(year, step, area) |>
    summarise(total_weight = sum(total_weight), .groups = "drop") |>
    as.data.frame()
  assign(paste0(fl, "_catches"), x)
}

save(list = ls(pattern = "_catches$"), file = file.path(base_dir, "data/Catches to Gadget.rda"))
rm(i, fl, x)
