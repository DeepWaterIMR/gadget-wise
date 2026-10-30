## -----------------------------------------------------------------------------
##
## Rebuild the model for projections
##
## -----------------------------------------------------------------------------

#' @title Rebuild the model with projection years
#' @description Sources 03_stocks.R, 04_fleets.R, 05_likelihood.R and 06_parameters.R into a new
#'   environment, with projection years, the recruitment projection and the quota unit changed, so
#'   the fitted model's objects are untouched. The optimised parameters are copied in.
#' @param project_years Projection years built into the model
#' @param rec_projection "constant" (short-term) or "bootstrap" (long-term, SSB-dependent)
#' @param quota_unit "biomass-year" (TAC) or "harvest-rate-year"
#' @param out_dir Folder for the rebuilt model's files
#' @param fit_params Parameter table of the fitted model (optim_fit$params)
#' @return The environment; its tmb_model and tmb_param hold the projection model and parameters
projection_env <- function(project_years, rec_projection, quota_unit, out_dir, fit_params) {
  env <- new.env(parent = globalenv())
  env$base_dir <- out_dir
  dir.create(file.path(out_dir, "data"), recursive = TRUE, showWarnings = FALSE)
  env$reset_model <- FALSE # Don't overwrite the fitted model's files
  env$model_params <- model_params
  env$model_params$max_project_years <- project_years
  env$model_params$rec_projection <- rec_projection
  env$model_params$quota_unit <- quota_unit
  for (f in c("03_stocks.R", "04_fleets.R", "05_likelihood.R", "06_parameters.R")) source(f, local = env)

  # NB: Only parameters still in the model (e.g. the log-AR(1) parameters are gone with "bootstrap")
  fp <- fit_params[fit_params$switch %in% env$tmb_param$switch, ]
  env$tmb_param[fp$switch, "value"] <- list(fp$value)
  env$tmb_param <- env$tmb_param |> g3_init_val("project_years", project_years)
  env
}

#' @title Fleet catch shares
#' @param fit A gadget.fit object
#' @param from_year,to_year Years averaged
#' @return Tibble with fleet, prop (share of the catch) and catch_last (the to_year catch, kg)
fleet_catch_props <- function(fit, from_year, to_year) {
  fit$fleet.info |>
    filter(year >= from_year, year <= to_year, !grepl("survey$", fleet)) |>
    group_by(fleet) |>
    summarise(catch = sum(amount), catch_last = sum(amount[year == to_year]), .groups = "drop") |>
    mutate(prop = catch / sum(catch))
}

#' @title Lognormal AR(1) advice error multipliers (as g3experiments::g3p_project_advice_error())
advice_error <- function(n, cv, rho) {
  if (cv == 0) return(rep(1, n))
  eps <- numeric(n)
  eps[[1]] <- rnorm(1, 0, cv)
  for (i in seq_len(n)[-1]) eps[[i]] <- rho * eps[[i - 1]] + sqrt(1 - rho^2) * rnorm(1, 0, cv)
  exp(eps)
}

#' @title Sum a gadget3 report array to one value per year
sum_by_year <- function(ar) {
  out <- apply(ar, "time", sum)
  tibble(year = as.integer(sub("-.*", "", names(out))), value = unname(out)) |>
    group_by(year) |>
    summarise(value = sum(value), .groups = "drop")
}
