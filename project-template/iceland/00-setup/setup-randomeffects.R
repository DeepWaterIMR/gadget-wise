## Recruitment penalty: a random walk on log recruitment with fixed sigma (penalise_recruitment = 1).
## For true random effects (random = TRUE, integrated with the Laplace approximation) see the gadget3
## article "Random effects & projections"; they need nlminb and TMB::sdreport, not g3_optim.

rec_stock <- if (single_stock_model) single_stock else imm_stock

random_actions <- list(
  g3l_random_walk(
    nll_name = "recruitment",
    param_f = g3_parameterized("rec", by_stock = list(rec_stock), by_year = TRUE, ifmissing = NaN),
    log_f = TRUE, # The walk is on log(rec)
    period = "year",
    sigma_f = g3_parameterized(paste0(species_name, "_recruitment_sigma"))
  )
)
