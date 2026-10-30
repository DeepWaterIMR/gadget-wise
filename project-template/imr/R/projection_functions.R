## -----------------------------------------------------------------------------
##
## Projection and reference point helpers
##
## -----------------------------------------------------------------------------

## ICES MSY advice rule with a Blim cut ####

#' @title Hockey-stick quota with zero catch below Blim
#' @description The ICES MSY advice rule: the target (TAC or harvest rate) is reduced linearly with SSB below MSY
#'   Btrigger, target x min(1, SSB / Btrigger) (gadget3::g3_quota_hockeystick()), and is zero when SSB is below Blim.
#'   With blim = 0 (the default value of the hs.blim parameter) it is the plain hockey stick
#' @param predstocks,preystocks,... Passed to gadget3::g3_quota_hockeystick()
#' @param blim Blim in the unit of the prey biomass (kg), as a formula or parameter
#' @return A quota formula for gadget3::g3_quota()

g3_quota_hockeystick_blim <- function(predstocks, preystocks, ...,
                                      blim = g3_parameterized("hs.blim", by_stock = predstocks, value = 0)) {
  hs <- gadget3::g3_quota_hockeystick(predstocks, preystocks, ...)
  # The SSB expression is the first argument of the dif_pmin(SSB / trigger, 1, 1000) call in the quota formula
  find_ssb <- function(x) {
    if (is.call(x)) {
      if (identical(x[[1]], as.symbol("dif_pmin"))) return(x[[2]][[2]])
      for (el in as.list(x)[-1]) {
        r <- find_ssb(el)
        if (!is.null(r)) return(r)
      }
    }
    NULL
  }
  ssb <- find_ssb(hs[[2]])
  if (is.null(ssb)) stop("g3_quota_hockeystick() has changed: no dif_pmin(SSB / trigger, ...) call found")
  out <- gadget3:::f_substitute(~ if (ssb < blim) 0 else hs_quota, list(ssb = ssb, blim = blim, hs_quota = hs))
  attr(out, "quota_name") <- attr(hs, "quota_name")
  attr(out, "catchability_unit") <- attr(hs, "catchability_unit")
  out
}

## Fit summaries ####

#' @title Spawning-stock biomass by year
#' @param fit A gadget.fit object (gadgetutils::g3_fit())
#' @param mat_stock Name of the mature stock (e.g. "cod_mat"). NULL: all stocks
#' @return Tibble with year and ssb (kg) at the start of the year
ssb_by_year <- function(fit, mat_stock = NULL) {
  fit$res.by.year |>
    filter(is.null(mat_stock) | .data$stock %in% mat_stock) |>
    group_by(year) |>
    summarise(ssb = sum(total.biomass), .groups = "drop")
}

#' @title Fishing mortality of the plus group
#' @description F of fish aged \code{min_age} and older, from the numbers caught and the numbers at the time of
#'   fishing. Fleets predate before natural mortality within a step (g3_action_order), so F = -log(1 - catch / number)
#' @param fit A gadget.fit object
#' @param min_age Youngest age of the plus group
#' @return Tibble with year and f_plus
f_plus_group <- function(fit, min_age) {
  fit$stock.prey |>
    filter(.data$age >= .env$min_age) |>
    group_by(year) |>
    summarise(catch_n = sum(number_consumed, na.rm = TRUE), n = sum(number, na.rm = TRUE), .groups = "drop") |>
    mutate(f_plus = -log(1 - catch_n / n)) |>
    dplyr::select(year, f_plus)
}

## Reference points ####

#' @title Biomass reference points on the model's scale (ICES stock type 5)
#' @description Blim = Bloss, the lowest SSB in the hindcast (no clear stock-recruitment signal),
#'   Bpa = Blim x exp(1.645 sigma) and MSY Btrigger = Bpa. Choose the stock type with the ICES
#'   reference point guidelines; this helper covers only the Bloss case.
#' @param fit A gadget.fit object of the hindcast
#' @param end_year Last hindcast year. Later (projection) years are ignored
#' @param from_year First year considered for Bloss, e.g. the first year with survey data
#' @param sigma Standard deviation of log(SSB) in the terminal year. ICES default 0.2
#' @param mat_stock Name of the mature stock
#' @return List with blim, bpa, btrigger (kg), bloss_year, sigma and basis (text for tables)
model_bio_refpoints <- function(fit, end_year, from_year, sigma = 0.2, mat_stock = NULL) {
  ssb <- ssb_by_year(fit, mat_stock) |> filter(year >= from_year, year <= end_year)
  lo <- ssb |> slice_min(ssb, n = 1, with_ties = FALSE)
  blim <- lo$ssb
  bpa <- blim * exp(1.645 * sigma)
  list(
    blim = blim, bpa = bpa, btrigger = bpa, bloss_year = lo$year, sigma = sigma,
    basis = c(
      blim = paste0("Bloss: lowest SSB in ", from_year, "-", end_year, " (", lo$year, ")"),
      bpa = paste0("Blim x exp(1.645 x ", sigma, ")"),
      btrigger = "Bpa"
    )
  )
}
