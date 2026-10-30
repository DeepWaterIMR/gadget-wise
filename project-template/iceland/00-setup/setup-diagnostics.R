## Diagnostics on the reweighted model (params_final): retrospective, jitter, leave-out.
## Retro rebuilds the likelihood with the data truncated by `peel` (setup-likelihood.R).

if (!exists("params_final")) load(file.path(base_dir, vers, wgts_folder, "fit.Rdata"))

if (run_retro) {
  retro_model <- retro_params <- list()
  for (peel in seq_len(number_of_peels)) {
    source(file.path(base_dir, "00-setup", "setup-likelihood.R"))
    time_actions_peel <- list(g3a_time(min(defaults$year), max(defaults$year) - peel, step_lengths = defaults$timestep), list())
    ra <- c(stock_actions, fleet_actions, likelihood_actions, if (penalise_recruitment == 1) random_actions, time_actions_peel)
    retro_model[[peel]] <- g3_to_tmb(c(ra, list(g3a_report_detail(ra)), list(g3l_bounds_penalty(ra))))
    tpl <- attr(retro_model[[peel]], "parameter_template")
    retro_params[[peel]] <- params_final[params_final$switch %in% tpl$switch, ]
  }
  peel <- 0
  source(file.path(base_dir, "00-setup", "setup-likelihood.R"))
  retro <- parallel::mclapply(seq_len(number_of_peels), function(x) {
    g3_optim(retro_model[[x]], retro_params[[x]], control = optim_control)
  }, mc.cores = min(ncores, number_of_peels))
  retro_fit <- lapply(seq_len(number_of_peels), function(x) g3_fit(retro_model[[x]], retro[[x]]))
  names(retro_fit) <- paste0("r", seq_len(number_of_peels))
  fs::dir_create(file.path(base_dir, vers, retro_folder))
  save(retro_fit, file = file.path(base_dir, vers, retro_folder, "retro_fit.Rdata"))
  print(gadgetutils::mohnrho(fit, retro_fit))
}

if (run_jitter) {
  jitter_out <- gadgetutils::g3_jitter(file.path(base_dir, vers), outdir = jitter_folder, model = tmb_model, params = params_final,
    njits = number_of_jitters, jitter_fraction = jitter_fraction, control = optim_control, mc.cores = ncores)
  jitter_fit <- lapply(Filter(function(k) !inherits(k, "try-error"), jitter_out), function(p) g3_fit(tmb_model, p))
  save(jitter_fit, file = file.path(base_dir, vers, jitter_folder, "jitter_fit.Rdata"))
}

if (run_leaveout) {
  lo_out <- gadgetutils::g3_leaveout(file.path(base_dir, vers), outdir = "LEAVEOUT", model = tmb_model, params = params_final,
    grouping = grouping, control = optim_control, mc.cores = ncores)
  leaveout_fit <- lapply(Filter(function(k) !inherits(k, "try-error"), lo_out), function(p) g3_fit(tmb_model, p))
  save(leaveout_fit, file = file.path(base_dir, vers, "LEAVEOUT", "leaveout_fit.Rdata"))
}
