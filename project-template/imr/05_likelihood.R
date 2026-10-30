## ---------------------------
##
## Script name: Likelihood
##
## Purpose of script: Define the likelihood components (MODEL$LIKELIHOOD in config.yaml): length
## distributions (ldist), age-length distributions (aldist), maturity proportions (matp) and survey
## indices. Component names become the weight parameter names, e.g. cdist_sumofsquares_Surv_ldist_weight.
##
## Creates: likelihood_actions
##
## ---------------------------

nll_breakdown <- TRUE # Per-step nll in the report
lik_report <- TRUE # Model and observed values in the report (needed by g3_fit)

lik <- model_params$likelihood

catchdist <- function(fl, kind, function_f = g3l_distribution_sumofsquares()) {
  obs_name <- paste0(fl, "_", kind)
  g3l_catchdistribution(
    obs_name,
    get(obs_name),
    function_f = function_f,
    fleets = list(fleets[[fl]]),
    stocks = stocks,
    area_group = areas,
    nll_breakdown = nll_breakdown,
    report = lik_report
  )
}

## Length and age-length distributions: sum of squares of proportions within each year-step
likelihood_ldist_actions <- lapply(lik$ldist %||% character(0), catchdist, kind = "ldist")
likelihood_aldist_actions <- lapply(lik$aldist %||% character(0), catchdist, kind = "aldist")

## Maturity proportions: proportions within each length group (stock column = imm/mat; partial stock
## names match the sub-stocks). sumofsquares() avoids the avoid_zero() floor (R/g3_helpers.R)
likelihood_matp_actions <- if (model_params$two_stocks) {
  lapply(lik$matp %||% character(0), catchdist, kind = "matp", function_f = sumofsquares(over = c("area", "length")))
} else {
  list()
}

## Survey indices: log-linear with estimated catchability (alpha) and fixed beta = 1 by default
likelihood_si_actions <- lapply(model_params$likelihood$indices %||% list(), function(si) {
  g3l_abundancedistribution(
    si$name,
    survey_indices[[si$name]],
    function_f = g3l_distribution_surveyindices_log(beta = si$beta %||% 1),
    stocks = stocks,
    area_group = areas,
    nll_breakdown = nll_breakdown,
    report = lik_report
  )
})

## Understocking: penalises predation of more fish than there are (keep the weight high)
likelihood_actions <- c(
  list(g3l_understocking(stocks, nll_breakdown = nll_breakdown, weight = 1e6)),
  likelihood_ldist_actions,
  likelihood_aldist_actions,
  likelihood_matp_actions,
  likelihood_si_actions
)
