## ---------------------------
##
## Script name: Short-term projections
##
## Purpose of script: Catch scenarios for the advice: the model is rebuilt with max_project_years
## projection years and constant recruitment (the mean of the estimated recruitment pool). The
## interim year (end_year + 1) takes the status-quo catch (or the TAC: set interim_catch); the
## advice year and later follow each scenario's harvest rate through the MSY advice rule.
##
## Creates: short_term_projections/scenario_fits.rda, scenario_summary.csv
##
## ---------------------------

outpath <- file.path(base_dir, "short_term_projections")
dir.create(outpath, recursive = TRUE, showWarnings = FALSE)

end_year <- max(model_params$year_range)
spawning_stock_name <- stocks[[if (model_params$two_stocks) "mat" else 1]]$name

proj_env <- projection_env(max_project_years, "constant", "harvest-rate-year", outpath, optim_fit$params)

catch_props <- fleet_catch_props(optim_fit, end_year - catch_prop_years + 1, end_year)
interim_total <- if (exists("interim_catch")) interim_catch else sum(catch_props$catch_last) # kg

## Scenarios: named harvest rates. Add the reference-point rates (13_long_term_projections.R) when available
if (!exists("st_scenarios")) {
  st_scenarios <- c(zero_catch = 0, setNames(c(0.05, 0.1, 0.15, 0.2), paste0("hr_", c(0.05, 0.1, 0.15, 0.2))))
  rp_file <- file.path(base_dir, "long_term_projections/reference_points.rda")
  if (file.exists(rp_file)) {
    load(rp_file)
    st_scenarios <- c(st_scenarios, MSY_advice_rule = ref_points$value[ref_points$name == "HRmsy"])
  }
}
btrigger <- if (exists("ref_points")) ref_points$value[ref_points$name == "MSY Btrigger"] else 1

scenario_fits <- lapply(st_scenarios, function(hr) {
  params <- proj_env$tmb_param |>
    g3_init_val("hs.target.#", hr) |>
    g3_init_val("*.hs.trigger", btrigger)
  for (fl in catch_props$fleet) {
    params <- params |>
      g3_init_val(paste0(fl, ".quota.interim.1"), interim_total * catch_props$prop[catch_props$fleet == fl]) |>
      g3_init_val(paste0(fl, ".quota.prop"), catch_props$prop[catch_props$fleet == fl])
  }
  g3_fit(proj_env$tmb_model, params)
})
save(scenario_fits, st_scenarios, catch_props, file = file.path(outpath, "scenario_fits.rda"), compress = "xz")

scenario_summary <- lapply(names(scenario_fits), function(sc) {
  f <- scenario_fits[[sc]]
  ssb_by_year(f, spawning_stock_name) |>
    left_join(
      f$fleet.info |> filter(!grepl("survey$", fleet)) |> group_by(year) |> summarise(catch = sum(amount), .groups = "drop"),
      by = "year"
    ) |>
    filter(year >= end_year) |>
    mutate(scenario = sc, hr_target = st_scenarios[[sc]], .before = 1)
}) |> bind_rows()

write.csv(scenario_summary, file.path(outpath, "scenario_summary.csv"), row.names = FALSE)

ggsave(file.path(base_dir, "figures/Short_term_projections.png"),
  plot = scenario_summary |>
    tidyr::pivot_longer(c(ssb, catch)) |>
    ggplot(aes(year, value / 1e3, colour = scenario)) +
    geom_line() +
    facet_wrap(~name, scales = "free_y", labeller = as_labeller(c(ssb = "SSB (t)", catch = "Catch (t)"))) +
    labs(x = "Year", y = NULL, colour = "Scenario"),
  width = pagewidth, height = pagewidth * 0.5, units = "mm", dpi = 300, bg = "white"
)
