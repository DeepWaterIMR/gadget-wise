## ---------------------------
##
## Script name: Retrospective analysis
##
## Purpose of script: Peel years off the end of the model and refit (retro_peels peels), then plot
## the retro and compute Mohn's rho (gadgetutils::mohnrho).
##
## NB: Do not peel only with the g3a_time retro_years parameter. surveyindices_log computes its nll
## at the final observation, so the likelihood data must be truncated to the peeled terminal year
## and each peel compiled with them. This script rebuilds the likelihood for each peel.
##
## Creates: retro_fit, retro/ tables, figures/Retro_*.png
##
## ---------------------------

dir.create(file.path(base_dir, "retro"), showWarnings = FALSE)

## Each peel starts from the initial parameters, with the reweighted weights if available
if (exists("iter_param")) {
  sw <- intersect(weight_switches(iter_param), init_retro_param$switch)
  init_retro_param$value[sw] <- iter_param$value[sw]
}

base_objects <- list(model_params = model_params, time_actions = time_actions, survey_indices = survey_indices)
data_names <- ls(pattern = "_(ldist|aldist|matp)$")
base_data <- mget(data_names)

truncate_years <- function(x, terminal_year) {
  if (is.data.frame(x) && "year" %in% names(x)) filter(x, year <= terminal_year) else x
}

retro_models <- lapply(0:retro_peels, function(peel) {
  terminal_year <- max(base_objects$model_params$year_range) - peel
  model_params <<- base_objects$model_params
  model_params$peel <<- peel
  model_params$year_range <<- model_params$year_range[model_params$year_range <= terminal_year]
  time_actions <<- list(g3a_time(min(model_params$year_range), terminal_year, step_lengths = model_params$step_lengths), list())
  list2env(lapply(base_data, truncate_years, terminal_year = terminal_year), envir = globalenv())
  survey_indices <<- lapply(base_objects$survey_indices, truncate_years, terminal_year = terminal_year)

  source("05_likelihood.R", local = FALSE)
  retro_actions <- c(time_actions, stock_actions, fleet_actions, likelihood_actions)
  m <- g3_to_tmb(c(retro_actions, list(
    if (force_bound_params) g3l_bounds_penalty(retro_actions, weight = 1e6) else NULL,
    g3a_report_detail(retro_actions)
  )))
  tpl <- attr(m, "parameter_template")
  p <- init_retro_param[match(tpl$switch, init_retro_param$switch), ]
  if (anyNA(p$switch)) stop("Retro peel ", peel, " has parameters missing from init_retro_param")
  list(peel = peel, model = m, param = p)
})

## Restore the full-data objects
model_params <- base_objects$model_params
time_actions <- base_objects$time_actions
survey_indices <- base_objects$survey_indices
list2env(base_data, envir = globalenv())
source("05_likelihood.R")

retro_list <- parallel::mclapply(retro_models, function(r) {
  p <- g3_optim(r$model, r$param, use_parscale = TRUE, method = "BFGS", control = list(maxit = maxit))
  list(peel = r$peel, param = p, fit = g3_fit(r$model, p))
}, mc.cores = min(ncores, length(retro_models)))

save(retro_list, file = file.path(base_dir, "retro/Retro parameters and fit.rda"), compress = "xz")

retro_fit <- lapply(retro_list, function(k) k$fit)
rho <- gadgetutils::mohnrho(retro_fit[[1]], retro_fit[-1])
write.csv(rho, file.path(base_dir, "retro/Mohns rho.csv"), row.names = FALSE)

ggsave(file.path(base_dir, "figures/Retro_model_biomass.png"),
  plot = gadgetplots::plot_retro(retro_fit),
  width = pagewidth, height = pagewidth * 0.7, units = "mm", dpi = 300, bg = "white"
)
