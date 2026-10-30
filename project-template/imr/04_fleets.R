## ---------------------------
##
## Script name: Fleets
##
## Purpose of script: Define the commercial fleets and surveys (MODEL$FLEETS in config.yaml) and
## their predation on the stocks: selectivity (suitability) and catchability. Commercial fleets
## remove their reported catches (g3a_predate_catchability_project, which also takes a quota in
## projection years); surveys remove a nominal catch (g3a_predate_catchability_totalfleet).
##
## Creates: fleets, fleet_actions, quota
##
## ---------------------------

## Fleets ####

fleets <- setNames(lapply(fleet_params$name, function(fl) {
  type <- fleet_params$type[fleet_params$name == fl]
  g3_fleet(c(name = fl, type)) |> g3s_livesonareas(areas)
}), fleet_params$name)

fishery_names <- fleet_params$name[fleet_params$type == "fishery"]
survey_names <- fleet_params$name[fleet_params$type == "survey"]

## Projection quota ####
## Only when projection years are built in (model_params$max_project_years > 0, set by the projection
## scripts): ICES MSY advice rule, target x min(1, SSB / Btrigger), zero below Blim (hs.blim; 0 = no cut).
## The target is a harvest rate by year (hs.target.<year>), filled by the projection scripts.

mature_stocks <- if (model_params$two_stocks) list(stocks$mat) else stocks

quota <- if (model_params$max_project_years == 0) {
  NULL
} else {
  g3_quota(
    g3_quota_hockeystick_blim(
      fleets[fishery_names],
      mature_stocks,
      target = substitute(
        g3_param_table("hs.target", expand.grid(cur_year = end_year + 1:mpy), ifmissing = 0),
        list(mpy = model_params$max_project_years)
      ),
      unit = model_params$quota_unit %||% "biomass-year"
    ),
    start_step = 1L,
    run_revstep = -1L
  )
}

## Fleet actions ####

fleet_actions <- lapply(fleet_params$name, function(fl) {
  fp <- fleet_params[fleet_params$name == fl, ]
  prefix <- if (is.na(fp$shares_selectivity_with)) fl else fp$shares_selectivity_with
  type <- if (is.na(fp$shares_selectivity_with)) fp$selectivity else fleet_params$selectivity[fleet_params$name == prefix]
  catch_data_var <- paste0(fl, "_catches")

  g3a_predate_fleet(
    fleets[[fl]],
    stocks,
    suitabilities = fleet_suitability(type, prefix, stocks), # R/g3_helpers.R
    catchability_f = if (fp$type == "fishery") {
      g3a_predate_catchability_project(
        landings_f = g3_timeareadata(catch_data_var, get(catch_data_var), areas = areas),
        unit = fp$catch_unit,
        quota_f = quota,
        # Share of the yearly quota taken in each step. One step: all of it. Several steps: the
        # <fleet>.cons.step.# parameters (set them, e.g. to the historical shares)
        cons_step = if (length(model_params$step_lengths) == 1) 1.0 else g3_parameterized("cons.step", by_predator = TRUE, by_step = TRUE)
      )
    } else {
      g3a_predate_catchability_totalfleet(g3_timeareadata(catch_data_var, get(catch_data_var), areas = areas))
    }
  )
})
names(fleet_actions) <- fleet_params$name
