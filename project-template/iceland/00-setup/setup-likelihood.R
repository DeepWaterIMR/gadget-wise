## Likelihood: ldist.<fleet>, aldist.<fleet>, matp.<fleet> and <fleet>.SI (lists by bootstrap
## replicate; [[boot_repl]]). Data hygiene (dropped years etc.) goes here as filter() calls.
## Retro: data are truncated to max(year) - peel.

nll_breakdown <- TRUE
lik_report <- TRUE

keep_years <- function(x) x |> filter(year <= max(defaults$year) - peel)

catchdist <- function(prefix, fl, function_f = g3l_distribution_sumofsquares()) {
  obj <- paste0(prefix, ".", fl)
  if (!exists(obj)) return(NULL)
  dat <- get(obj)[[boot_repl]] |> keep_years()
  if (prefix == "matp" && "maturity_stage" %in% names(dat)) dat <- dat |> rename(stock = maturity_stage)
  g3l_catchdistribution(
    nll_name = paste0(prefix, "_", fl),
    obs_data = dat,
    fleets = list(fleets[[fl]]),
    stocks = stocks,
    function_f = function_f,
    nll_breakdown = nll_breakdown,
    report = lik_report
  )
}

likelihood_actions <- c(
  list(g3l_understocking(stocks, nll_breakdown = nll_breakdown, weight = 1e6)),
  Filter(Negate(is.null), lapply(c(comm_fleets, survey_fleets), catchdist, prefix = "ldist")),
  Filter(Negate(is.null), lapply(c(comm_fleets, survey_fleets), catchdist, prefix = "aldist")),
  if (!single_stock_model) Filter(Negate(is.null), lapply(survey_fleets, catchdist, prefix = "matp"))
)

## Survey indices: one component per length group (stock-based, fleets = list())
for (fl in survey_fleets) {
  obj <- paste0(fl, ".SI")
  if (!exists(obj)) next
  for (i in names(get(obj)[[boot_repl]])) {
    likelihood_actions <- c(likelihood_actions, list(g3l_abundancedistribution(
      nll_name = paste0("si_", fl, "_", gsub("[^0-9]+", "_", i)),
      obs_data = get(obj)[[boot_repl]][[i]] |> keep_years(),
      fleets = list(),
      stocks = stocks,
      function_f = g3l_distribution_surveyindices_log(beta = 1),
      nll_breakdown = nll_breakdown,
      report = lik_report
    )))
  }
}
