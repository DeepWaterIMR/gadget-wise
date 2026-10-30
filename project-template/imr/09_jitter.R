## ---------------------------
##
## Script name: Jitter
##
## Purpose of script: Re-optimise from jittered starting values (gadgetutils::g3_jitter) to check
## that the optimum is global. Jitter wide enough to test it (jitter_fraction 0.1 only probes the
## neighbourhood), but less for parameters where large moves make the start infeasible (e.g. log
## recruitment: a few weak year classes leave too few fish for the catches).
##
## Creates: jitter_fit; figures/Jitter_*.png; jitter/ tables
##
## ---------------------------

init_jitter_param <- if (exists("optim_param")) optim_param else tmb_param

jitter_fraction_vec <- local({
  par_names <- names(gadget3::g3_tmb_par(init_jitter_param, include_random = FALSE))
  # Optimiser names use "__" for "."
  ifelse(grepl("__rec__([0-9]+|proj__logar1__level)$", par_names), jitter_fraction_rec, jitter_fraction)
})

## Compile before forking, otherwise the parallel runs all compile at once
invisible(g3_tmb_adfun(tmb_model, init_jitter_param))

jitpar_out <- gadgetutils::g3_jitter(
  gd = base_dir,
  outdir = "jitter",
  model = tmb_model,
  params = init_jitter_param,
  njits = njits,
  jitter_fraction = jitter_fraction_vec,
  control = list(maxit = maxit),
  mc.cores = ncores
)

jitter_fit <- pbapply::pblapply(Filter(function(k) !is.null(k) && !inherits(k, "try-error"), jitpar_out), function(p) {
  try(g3_fit(model = tmb_model, params = p))
})
jitter_fit <- Filter(function(k) !inherits(k, "try-error"), jitter_fit)
save(jitter_fit, file = file.path(base_dir, "jitter", "jitter_fit.rda"), compress = "xz")

## Objective function across the jitters: a spread larger than ~1 nll unit means local optima
gadgetutils:::bind_fit_components(jitter_fit, "score") |>
  summarise(n = n(), min = min(nll), max = max(nll), sd = sd(nll)) |>
  write.csv(file.path(base_dir, "jitter", "jitter_nll_summary.csv"), row.names = FALSE)

ggsave(file.path(base_dir, "figures/Jitter_model_biomass.png"),
  plot = gadgetplots::plot_jitter(jitter_fit),
  width = pagewidth, height = pagewidth * 0.7, units = "mm", dpi = 300, bg = "white"
)
