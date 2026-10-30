## ---------------------------
##
## Script name: Long-term projections
##
## Purpose of script: Stochastic long-term projections over a grid of target harvest rates for the
## reference points (ICES WKREF / WKGMSE style): recruitment is a block bootstrap of the estimated
## recruitment, SSB-dependent below Blim (hockey-stick); the advice has lognormal AR(1) error; the
## MSY advice rule cuts the harvest rate below Btrigger. Three scenarios:
##   pre        - no advice error, no Btrigger (Flim)
##   msy_notrig - advice error, no Btrigger (Fmsy, Fp0.5)
##   msy        - advice error and Btrigger (precautionary check of the advice rule)
## Many runs: use a server (gadget-run skill).
##
## Creates: long_term_projections/results_*.rda
##
## ---------------------------

outpath <- file.path(base_dir, "long_term_projections")
dir.create(outpath, recursive = TRUE, showWarnings = FALSE)

end_year <- max(model_params$year_range)
spawning_stock_name <- stocks[[if (model_params$two_stocks) "mat" else 1]]$name

## Reference points on the model's scale (kg). Bloss is a placeholder for Blim: choose the ICES
## stock type and method in the reference-point report (gadget-projections skill)
bio_rp <- model_bio_refpoints(optim_fit, end_year = end_year, from_year = bloss_from_year %||% min(model_params$year_range), mat_stock = spawning_stock_name)

proj_env <- projection_env(num_project_years, "bootstrap", "harvest-rate-year", outpath, optim_fit$params)
fn <- g3_tmb_fn(proj_env$tmb_model) # Lighter than the ADFun for many single runs

catch_props <- fleet_catch_props(optim_fit, end_year - catch_prop_years + 1, end_year)

base_proj_params <- proj_env$tmb_param |>
  g3_init_val("*.rec.proj.blim", bio_rp$blim)
for (fl in catch_props$fleet) {
  base_proj_params <- base_proj_params |>
    g3_init_val(paste0(fl, ".quota.interim.1"), catch_props$catch_last[catch_props$fleet == fl]) |> # Interim year: status-quo catch
    g3_init_val(paste0(fl, ".quota.prop"), catch_props$prop[catch_props$fleet == fl])
}

save(end_year, num_project_years, harvest_rates, hr_trials, advice_cv, advice_rho, bio_rp, catch_props, base_proj_params,
  file = file.path(outpath, "projection_definitions.rda"), compress = "xz"
)

ssb_report <- paste0("hist_", model_params$species_code, "_spawn_ssb")

run_trial <- function(hr_target, trial, cv, rho, trigger) {
  set.seed(trial + 1e6) # Same advice error series for a trial across harvest rates
  params <- base_proj_params |>
    g3_init_val("hs.target.#", hr_target * advice_error(num_project_years, cv, rho)) |>
    g3_init_val("*.hs.trigger", trigger)
  set.seed(trial) # Same recruitment series for a trial across harvest rates and scenarios
  res <- fn(params)

  num <- res[[paste0("dstart_", spawning_stock_name, "__num")]]
  wgt <- res[[paste0("dstart_", spawning_stock_name, "__wgt")]]
  ssb <- sum_by_year(num * wgt)
  catch <- Reduce(`+`, lapply(res[grep("^detail_.+__predby_.+_fishery$", names(res))], function(x) sum_by_year(x)$value))
  tibble(year = ssb$year, ssb = ssb$value, catch = catch, hr_target = hr_target, trial = trial) |>
    filter(year > end_year)
}

run_scenario <- function(cv, rho, trigger) {
  grid <- expand.grid(hr = harvest_rates, trial = seq_len(hr_trials))
  bind_rows(parallel::mclapply(seq_len(nrow(grid)), function(i) {
    run_trial(grid$hr[[i]], grid$trial[[i]], cv, rho, trigger)
  }, mc.cores = ncores_projections))
}

results_pre <- run_scenario(cv = 0, rho = 0, trigger = 1) # Trigger 1 kg: never bites
save(results_pre, file = file.path(outpath, "results_pre.rda"), compress = "xz")

results_msy_notrig <- run_scenario(cv = advice_cv, rho = advice_rho, trigger = 1)
save(results_msy_notrig, file = file.path(outpath, "results_msy_notrig.rda"), compress = "xz")

results_msy <- run_scenario(cv = advice_cv, rho = advice_rho, trigger = bio_rp$btrigger)
save(results_msy, file = file.path(outpath, "results_msy.rda"), compress = "xz")

## Reference point summary over the final eval_years
summarise_hr <- function(res) {
  res |>
    filter(year > max(year) - eval_years) |>
    group_by(hr_target) |>
    summarise(
      catch_median = median(catch),
      ssb_median = median(ssb),
      p_below_blim = mean(ssb < bio_rp$blim), # Annual probability, averaged over years and trials
      .groups = "drop"
    )
}

rp_table <- list(
  pre = summarise_hr(results_pre),
  msy_notrig = summarise_hr(results_msy_notrig),
  msy = summarise_hr(results_msy)
)
hr_lim <- rp_table$pre |> filter(ssb_median >= bio_rp$blim) |> pull(hr_target) |> max() # HR giving median SSB = Blim
hr_msy <- rp_table$msy_notrig |> slice_max(catch_median, n = 1, with_ties = FALSE) |> pull(hr_target)
hr_p05 <- rp_table$msy |> filter(p_below_blim <= 0.05) |> pull(hr_target) |> max()
ref_points <- tibble(
  name = c("Blim", "Bpa", "MSY Btrigger", "HRlim", "HRmsy (uncapped)", "HRp0.5", "HRmsy"),
  value = c(bio_rp$blim, bio_rp$bpa, bio_rp$btrigger, hr_lim, hr_msy, hr_p05, min(hr_msy, hr_p05))
)
write.csv(ref_points, file.path(outpath, "reference_points.csv"), row.names = FALSE)
save(rp_table, ref_points, file = file.path(outpath, "reference_points.rda"))
print(ref_points)
