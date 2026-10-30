## ---------------------------
##
## Script name: Leave-out analysis
##
## Purpose of script: Re-optimise with each group of likelihood components left out (weight 0) to
## see which data drive the estimates (gadgetutils::g3_leaveout).
##
## Creates: leaveout_fit, figures/Leaveout_*.png
##
## ---------------------------

## Groups of likelihood components (nll names, e.g. "Comm_ldist", "Surv_SI") left out together
component_names <- sub("^[ac]dist_[a-z_]+?_(.+)_weight$", "\\1", weight_switches(tmb_param))
component_names <- component_names[unlist(tmb_param[weight_switches(tmb_param), "value"]) != 0]

leaveout_grouping <- if (exists("leaveout_re")) {
  # Regular expressions on the component names, one group per expression
  lapply(setNames(leaveout_re, leaveout_re), function(re) grep(re, component_names, value = TRUE))
} else {
  # One group per fleet (its distributions) and one per survey index
  si_names <- vapply(model_params$likelihood$indices %||% list(), function(si) si$name, character(1))
  c(
    lapply(setNames(fleet_params$name, fleet_params$name), function(fl) grep(paste0("^", fl, "_(ldist|aldist|matp)$"), component_names, value = TRUE)),
    lapply(setNames(si_names, si_names), function(si) intersect(si, component_names))
  )
}
leaveout_grouping <- leaveout_grouping[lengths(leaveout_grouping) > 0]

lo_start <- if (exists("optim_param")) optim_param else init_retro_param
invisible(g3_tmb_adfun(tmb_model, lo_start))

lo_out <- gadgetutils::g3_leaveout(
  gd = base_dir,
  outdir = "leaveout",
  model = tmb_model,
  params = lo_start,
  grouping = leaveout_grouping,
  control = list(maxit = maxit),
  mc.cores = ncores
)

leaveout_fit <- lapply(Filter(function(k) !inherits(k, "try-error"), lo_out), function(p) try(g3_fit(tmb_model, p)))
leaveout_fit <- Filter(function(k) !inherits(k, "try-error"), leaveout_fit)
save(leaveout_fit, file = file.path(base_dir, "leaveout", "leaveout_fit.rda"), compress = "xz")

ggsave(file.path(base_dir, "figures/Leaveout_model_biomass.png"),
  plot = gadgetplots::plot_leaveout(leaveout_fit),
  width = pagewidth, height = pagewidth * 0.7, units = "mm", dpi = 300, bg = "white"
)
