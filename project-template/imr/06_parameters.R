## ---------------------------
##
## Script name: Parameters
##
## Purpose of script: Compile the model (R and TMB) and set the initial values, bounds and
## likelihood weights in the parameter template.
##
## Creates: actions, tmb_model, model, tmb_param, init_retro_param
##
## g3_init_val() patterns: "*" matches one name part, "#" a number (year, age), e.g. "*.rec.#".
## Every estimated parameter needs bounds; g3l_bounds_penalty() penalises values outside them.
##
## ---------------------------

## Collate actions ####

actions <- c(time_actions, stock_actions, fleet_actions, likelihood_actions)

tmb_model <- g3_to_tmb(c(
  actions,
  list(
    if (force_bound_params) g3l_bounds_penalty(actions, weight = 1e6) else NULL,
    g3a_report_detail(actions)
  )
))
writeLines(tmb_model, file.path(base_dir, "model_code.cpp"))

tmb_param <- attr(tmb_model, "parameter_template")

## Initial values and bounds ####
## Starting values come from the life-history data report (life_history.yaml). The bounds are
## generic defaults: check them against the stock's biology before the first fit.

lh <- life_history

tmb_param <- tmb_param |>
  # Initial conditions and recruitment (recruitment in 10 000 fish x rec.scalar)
  g3_init_val("*.init.#", 10, lower = 0.001, upper = 1000) |>
  g3_init_val("*.init.scalar", rec_scalar, optimise = FALSE) |>
  g3_init_val("*.init.F", 0.2, lower = 0.001, upper = 1) |>
  g3_init_val("*.rec.#", 10, lower = 0.001, upper = 1000) |>
  g3_init_val("*.rec.scalar", rec_scalar, optimise = FALSE) |> # Redundant with rec.# and the index catchability: keep fixed
  g3_init_val("*.rec.sd", lh$rec_sd %||% 2, lower = 0.5, upper = 10) |>
  # Growth (von Bertalanffy) and the beta-binomial growth spread
  g3_init_val("*.Linf", lh$Linf, lower = 0.75 * lh$Linf, upper = 1.5 * lh$Linf, optimise = isTRUE(lh$estimate_Linf)) |>
  g3_init_val("*.K", lh$K, lower = 0.25 * lh$K, upper = 4 * lh$K) |>
  g3_init_val("*.bbin", 10, lower = 1e-3, upper = 1000) |>
  # Length-weight
  g3_init_val("*.walpha", lh$walpha, optimise = FALSE) |>
  g3_init_val("*.wbeta", lh$wbeta, optimise = FALSE) |>
  # Selectivity
  g3_init_val("*.*.alpha", 0.5, lower = 0.01, upper = 3) |>
  g3_init_val("*.*.l50", (stock_params$minlength + stock_params$maxlength) / 3, lower = stock_params$minlength, upper = stock_params$maxlength)

## Initial length at age
for (k in model_params$stock_names) {
  il <- init_lengths |> filter(age >= stock_params[[k]]$minage, age <= stock_params[[k]]$maxage)
  tmb_param <- tmb_param |>
    g3_init_val(paste0("*_", k, ".init.meanlen.#"), il$ml) |>
    g3_init_val(paste0("*_", k, ".init.sd.#"), il$ms)
}
rm(k, il)

## Recruitment log-AR(1) (fitting only)
if (identical(model_params$rec_projection, "logar1")) {
  tmb_param <- tmb_param |>
    g3_init_val("*.rec.proj.logar1.phi", 0.5, lower = 0, upper = 0.99) |>
    g3_init_val("*.rec.proj.logar1.stddev", 0.5, lower = 0.05, upper = 2) |>
    g3_init_val("*.rec.proj.logar1.level", 10, lower = 0.1, upper = 1000)
}

## Natural mortality: fixed unless MODEL$M$estimate
tmb_param <- tmb_param |>
  g3_init_val("*.M", model_params$M$value, lower = 0.01, upper = 1, optimise = isTRUE(model_params$M$estimate))
if (identical(model_params$M$type, "age")) {
  tmb_param <- tmb_param |>
    g3_init_val("*.M.young", model_params$M$young %||% (2 * model_params$M$value), lower = 0.01, upper = 2) |>
    g3_init_val("*.M.break_age", model_params$M$break_age %||% 5, optimise = FALSE)
}

## Maturity (two sub-stocks): the maturation ogive by length and the initial split by age
if (model_params$two_stocks) {
  tmb_param <- tmb_param |>
    g3_init_val("*.mat.l50", lh$mat_l50, lower = 0.5 * lh$mat_l50, upper = 1.5 * lh$mat_l50, optimise = isTRUE(lh$estimate_maturity)) |>
    g3_init_val("*.mat.alpha", lh$mat_alpha, lower = 0.01, upper = 5, optimise = isTRUE(lh$estimate_maturity)) |>
    g3_init_val("*.mat_initial_a50", lh$mat_a50, optimise = FALSE) |>
    g3_init_val("*.mat_initial_alpha", lh$mat_a_alpha, optimise = FALSE)
}

## Dome-shaped selectivity (only when a fleet uses it). Peak at p5 * exp(-p1)
if ("dome" %in% fleet_params$selectivity) {
  tmb_param <- tmb_param |>
    g3_init_val("*.*.andersen.p1", 0.35, lower = 0, upper = 3) |>
    g3_init_val("*.*.andersen.p3", 0.1, lower = 1e-4, upper = 10) |>
    g3_init_val("*.*.andersen.p4", 0.1, lower = 1e-4, upper = 10)
}
if ("age_s" %in% fleet_params$selectivity) {
  tmb_param <- tmb_param |>
    g3_init_val("*.*.age.alpha", 0.5, lower = 0.01, upper = 5) |>
    g3_init_val("*.*.a50", (stock_params$minage + stock_params$maxage) / 3, lower = stock_params$minage, upper = stock_params$maxage)
}

## Likelihood weights ####
## Default 1. After iterative reweighting (07_reweighting.R), paste the weights here as a named vector
## (snapshot with dput(unlist(iter_param[grepl("_weight$", rownames(iter_param)), "value"]))), so
## runs without reweighting use them. Reweight again whenever the data or the structure change.

if (set_weights) {
  model_weights <- c(
    # cdist_sumofsquares_Surv_ldist_weight = 1,
  )
  model_weights <- model_weights[names(model_weights) %in% rownames(tmb_param)]
  tmb_param[names(model_weights), "value"] <- model_weights
}

## Scale (scale_weights) or drop (zero_weights) components for the whole run, incl. retro and jitter
if (exists("scale_weights") && length(scale_weights) > 0) {
  for (re in names(scale_weights)) {
    sw <- weight_switches(tmb_param, re)
    if (length(sw) == 0) stop("scale_weights matches no likelihood weight: ", re)
    tmb_param$value[sw] <- lapply(tmb_param$value[sw], function(x) x * scale_weights[[re]])
  }
}
if (exists("zero_weights") && length(zero_weights) > 0) {
  sw <- weight_switches(tmb_param, paste(zero_weights, collapse = "|"))
  if (length(sw) == 0) stop("zero_weights matches no likelihood weight")
  tmb_param[sw, "value"] <- 0
  message("Weights set to 0: ", paste(sw, collapse = ", "))
}

## Initial parameters for the retro and leave-out (re-optimised from the same start)
init_retro_param <- tmb_param

## Start from the previous run's optimum (faster, but ties the fit to that surface)
if (exists("prev_param") && previous_model_params_as_initial && !run_reweighting) {
  idx <- intersect(names(prev_param), tmb_param$switch)
  tmb_param[idx, "value"] <- prev_param[idx]
}

## R model, for debugging (model <- edit(model); see the gadget-build-model skill)
model <- g3_to_r(actions)

## The starting stock must be able to take the catches: an nll of ~1e20 is understocking
init_nll <- model(tmb_param$value)[[1]]
message("nll at the starting values: ", signif(init_nll, 4))
if (!is.finite(init_nll) || init_nll > 1e10) {
  warning("The nll at the starting values is ", signif(init_nll, 3), ": probably understocking. ",
          "Increase rec_scalar in _RUN_THE_MODEL.R (recruits = rec.# x rec.scalar x 10 000 fish).")
}

if (reset_model) {
  write.csv(tmb_param, file = file.path(base_dir, "data/Initial model parameters.csv"), row.names = FALSE)
  save(tmb_param, file = file.path(base_dir, "data/Initial model parameters.rda"))
  save(model, tmb_model, file = file.path(base_dir, "data/R and TMB model.rda"), compress = "xz") |> suppressWarnings()
}
