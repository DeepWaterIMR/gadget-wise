## ---------------------------
##
## Script name: Optimise
##
## Purpose of script: Optimise the model (gadgetutils::g3_optim, BFGS with parscale), extract the
## fit (gadgetutils::g3_fit) and write the HTML summary (gadgetplots::make_html).
##
## Creates: optim_param, optim_fit
##
## ---------------------------

dir.create(file.path(base_dir, "optim"), showWarnings = FALSE)

init_optim_param <- if (exists("iter_param")) iter_param[tmb_param$switch, ] else tmb_param

if (nrow(filter(init_optim_param, optimise, lower >= upper)) > 0) {
  warning("Some lower bounds are not below the upper bounds. Expect trouble in the optimisation.")
}

time_optim_start <- Sys.time()
optim_param <- g3_optim(
  model = tmb_model,
  params = init_optim_param,
  use_parscale = TRUE,
  method = "BFGS",
  control = list(maxit = maxit),
  print_status = TRUE
)
time_optim <- round(as.numeric(Sys.time() - time_optim_start, units = "mins"), 1)

opt_summary <- attributes(optim_param)$summary
cat(
  "Optimisation\n",
  "  time: ", time_optim, " min\n",
  "  convergence: ", opt_summary$convergence, "\n",
  "  gradient calls: ", opt_summary$gd_calls, "\n",
  "  score: ", round(opt_summary$score, 2), "\n\n",
  file = file.path(base_dir, "session/run_times.txt"), sep = "", append = TRUE
)

write.csv(optim_param, file.path(base_dir, "optim/Optimized TMB parameters.csv"), row.names = FALSE)
save(optim_param, file = file.path(base_dir, "optim/Optimized TMB parameters.rda"), compress = "xz")

optim_fit <- g3_fit(tmb_model, optim_param)
save(optim_fit, file = file.path(base_dir, "optim/Optimized TMB model fit.rda"), compress = "xz")

## Parameters at their bounds are a warning sign (non-identified or mis-specified)
at_bounds <- optim_param |>
  filter(optimise) |>
  mutate(value = unlist(value)) |>
  filter(abs(value - lower) < 1e-3 * abs(upper - lower) | abs(value - upper) < 1e-3 * abs(upper - lower))
if (nrow(at_bounds) > 0) warning("Parameters at their bounds: ", paste(at_bounds$switch, collapse = ", "))

if (plot_html) make_html(optim_fit, path = file.path(getwd(), base_dir, "figures"))
