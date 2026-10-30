## ---------------------------
##
## Script name: Iterative reweighting
##
## Purpose of script: Weight the likelihood components by the inverse of their residual variance
## (Taylor et al. 2007) with gadgetutils::g3_iterative(). Components of one fleet are reweighted as a
## group; each survey index on its own. Slow (hours): run on a server (gadget-run skill).
##
## Creates: iter_param. Paste the weights into 06_parameters.R (set_weights) afterwards.
##
## ---------------------------

## Start from weight 1, except components intentionally set to 0
if (set_weights) {
  tmb_param[grepl("weight$", tmb_param$switch) & tmb_param$value != 0, c("value", "lower", "upper", "optimise")] <-
    data.frame(value = 1, lower = NA, upper = NA, optimise = FALSE)
}

## Component grouping: the distributions of a fleet together, each survey index alone
lik <- model_params$likelihood
component_grouping <- lapply(fleet_params$name, function(fl) {
  c(
    if (fl %in% lik$ldist) paste0(fl, "_ldist"),
    if (fl %in% lik$aldist) paste0(fl, "_aldist"),
    if (fl %in% lik$matp && model_params$two_stocks) paste0(fl, "_matp")
  )
})
names(component_grouping) <- fleet_params$name
component_grouping <- component_grouping[lengths(component_grouping) > 0]
si_names <- vapply(lik$indices %||% list(), function(si) si$name, character(1))
component_grouping <- c(component_grouping, setNames(as.list(si_names), si_names))

## Drop names that match no non-zero weight (typos or removed components)
active <- weight_switches(tmb_param)[unlist(tmb_param[weight_switches(tmb_param), "value"]) != 0]
component_grouping <- lapply(component_grouping, function(k) k[vapply(k, function(x) any(grepl(x, active, fixed = TRUE)), logical(1))])
component_grouping <- component_grouping[lengths(component_grouping) > 0]

time_iter_start <- Sys.time()
message("Reweighting started ", time_iter_start)

iter_param <- g3_iterative(
  gd = base_dir,
  wgts = "reweighting",
  model = tmb_model,
  params.in = tmb_param,
  grouping = component_grouping,
  use_parscale = TRUE,
  control = list(maxit = maxit),
  cv_floor = cv_floor, # Maximum weight 1 / cv_floor for the survey indices
  shortcut = FALSE,
  mc.cores = ncores
)

message("Reweighting finished after ", round(as.numeric(Sys.time() - time_iter_start, units = "hours"), 1), " h")

save(iter_param, file = file.path(base_dir, "reweighting/Iterated TMB parameters.rda"))
write.csv(iter_param, file.path(base_dir, "reweighting/Iterated TMB parameters.csv"), row.names = FALSE)
message("Weights for 06_parameters.R:")
dput(unlist(iter_param[grepl("_weight$", iter_param$switch), "value"]))
