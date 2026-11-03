## ---------------------------
##
## gadget3 model helpers for the IMR-format pipeline
##
## Sourced by 00_run_first.R. Generic helpers only; stock-specific code belongs in the numbered
## scripts.
##
## ---------------------------

`%||%` <- function(a, b) if (is.null(a)) b else a

#' @title Read a YAML file as UTF-8, independent of the R locale
read_yaml_utf8 <- function(path) {
  txt <- readChar(path, file.info(path)$size, useBytes = TRUE)
  Encoding(txt) <- "UTF-8"
  yaml::yaml.load(txt, eval.expr = FALSE)
}

#' @title Time step lengths from the config
#' @param x "yearly", "quarterly", "monthly" or a numeric vector of months per step summing to 12
#' @return Numeric vector of months per step, for g3a_time(step_lengths = )
step_lengths <- function(x) {
  if (is.numeric(x) || is.list(x)) {
    out <- as.numeric(unlist(x))
  } else {
    out <- switch(x,
      yearly = 12,
      quarterly = c(3, 3, 3, 3),
      monthly = rep(1, 12),
      stop("Unknown TIMESTEP: ", x)
    )
  }
  stopifnot("Time steps must sum to 12 months" = sum(out) == 12)
  out
}

#' @title Fleet definitions as a table
#' @param fleets List of fleet definitions from config.yaml MODEL$FLEETS
#' @return A tibble with one row per fleet: name, type ("fishery" or "survey"), selectivity
#'   ("s", "dome", "age_s", "full"), catch_unit ("biomass" or "number", fisheries) and
#'   shares_selectivity_with (another fleet name, or NA)
fleet_table <- function(fleets) {
  out <- bind_rows(lapply(fleets, function(k) as_tibble(lapply(k, function(v) if (is.null(v)) NA else v))))
  for (col in c("selectivity", "catch_unit", "shares_selectivity_with")) {
    if (!col %in% names(out)) out[[col]] <- NA_character_
  }
  out <- out |>
    mutate(
      selectivity = coalesce(selectivity, "s"),
      catch_unit = coalesce(catch_unit, "biomass")
    )
  stopifnot(
    "Fleet type must be 'fishery' or 'survey'" = all(out$type %in% c("fishery", "survey")),
    "Fleet names must be unique" = !anyDuplicated(out$name),
    "Fleet selectivity must be s, dome, age_s or full" = all(out$selectivity %in% c("s", "dome", "age_s", "full")),
    "shares_selectivity_with must name another fleet" = all(is.na(out$shares_selectivity_with) | out$shares_selectivity_with %in% out$name)
  )
  out
}

#' @title Fleet suitability (selectivity) function
#' @description Builds the gadget3 suitability for a fleet. Parameter names are
#'   `<prefix>.<stock species>.<parameter>`, e.g. `Comm.cod.l50`, so fleets sharing a selectivity
#'   share a prefix.
#' @param type "s" (exponential-l50 logistic by length), "dome" (Andersen), "age_s" (logistic by age)
#'   or "full" (constant 1)
#' @param prefix Parameter name prefix, normally the fleet name
#' @param stocks List of g3 stocks the fleet predates on (used for the Andersen p5)
fleet_suitability <- function(type, prefix, stocks) {
  switch(type,
    full = g3_suitability_constant(suit = 1),
    s = g3_suitability_exponentiall50(
      g3_parameterized("alpha", by_stock = "species", prepend_extra = prefix),
      g3_parameterized("l50", by_stock = "species", prepend_extra = prefix)
    ),
    dome = g3_suitability_andersen(
      g3_parameterized("andersen.p0", value = 0, optimise = FALSE, by_stock = "species"),
      p1 = g3_parameterized("andersen.p1", value = log(2), by_stock = "species", prepend_extra = prefix),
      p2 = g3_parameterized("andersen.p2", value = 1, optimise = FALSE, by_stock = "species"),
      p3 = g3_parameterized("andersen.p3", value = 0.1, exponentiate = TRUE, by_stock = "species", prepend_extra = prefix),
      p4 = g3_parameterized("andersen.p4", value = 0.1, exponentiate = TRUE, by_stock = "species", prepend_extra = prefix),
      p5 = max(vapply(stocks, function(x) g3_stock_def(x, "maxmidlen"), numeric(1)))
    ),
    # NB: + 0 * stock__midlen gives the suitability report a length dimension, which gadgetutils::g3_fit() needs
    age_s = g3_formula(
      quote(1 / (1 + exp(-age_alpha * (age - a50))) + 0 * stock__midlen),
      age_alpha = g3_parameterized("age.alpha", by_stock = "species", prepend_extra = prefix),
      a50 = g3_parameterized("a50", by_stock = "species", prepend_extra = prefix)
    ),
    stop("Selectivity '", type, "' is not implemented")
  )
}

#' @title Initial proportion mature by age
#' @description Ogive splitting the initial numbers at age between an immature and a mature
#'   sub-stock. NB: gadget3's bounded(x, a, b) = a + (b - a) / (1 + exp(x)) DECREASES with x, so the
#'   argument is negated to make the mature proportion rise with age.
#' @param mature TRUE for the mature stock, FALSE (1 - ogive) for the immature stock
g3a_initial_ageprop <- function(alpha = g3_parameterized("mat_initial_alpha", by_stock = by_stock),
                                a50 = g3_parameterized("mat_initial_a50", by_stock = by_stock),
                                mature = FALSE,
                                by_stock = "species") {
  out <- gadget3:::f_substitute(
    ~ bounded(-1 * alpha * (age - a50), 0, 1),
    list(alpha = alpha, a50 = a50)
  )
  if (!mature) out <- gadget3:::f_substitute(quote(1 - out), list(out = out))
  out
}

#' @title Sum of squares without the avoid_zero() floor
#' @description g3l_distribution_sumofsquares() divides each group by avoid_zero(group total), which
#'   floors totals at ~7e-4. Survey catches can be tiny in model units, which then pushes model
#'   proportions towards 0 in low-catch groups. This replaces the floor with dif_pmax() at a large
#'   scale. Named sumofsquares so component names stay cdist_sumofsquares_*.
sumofsquares <- function(over = c("area", "length"), scale = 1e12) {
  out <- g3l_distribution_sumofsquares(over = over)
  env <- environment(out)
  for (n in c("modelstock__sstotal", "obsstock__sstotal")) {
    stopifnot(identical(env[[n]][[1]], as.symbol("avoid_zero")))
    env[[n]] <- substitute(dif_pmax(x, 0, scale), list(x = env[[n]][[2]], scale = scale))
  }
  out
}

#' @title Likelihood weights matching a pattern
#' @param params gadget3 parameter template
#' @param pattern Regular expression on the *_weight parameter names
weight_switches <- function(params, pattern = ".") {
  grep(pattern, grep("_weight$", params$switch, value = TRUE), value = TRUE)
}
