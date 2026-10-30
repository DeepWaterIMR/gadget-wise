## Stock actions, two sub-stocks: initial conditions, natural mortality, ageing, growth and
## maturation (immature -> mature), recruitment into the immature stock.
## Growth: von Bertalanffy mean length increase, beta-binomial spread (g3a_grow_impl_bbinom).
## Initial and recruit lengths: von Bertalanffy mean length at age (with t0), CV lencv / recl.cv.

## Initial proportion mature by age (logistic). NB: gadget3's bounded(x, a, b) decreases with x
initial_ageprop <- function(mature) {
  out <- gadget3:::f_substitute(
    ~ bounded(-1 * alpha * (age - a50), 0, 1),
    list(alpha = g3_parameterized("mat_initial_alpha", by_stock = stocks), a50 = g3_parameterized("mat_initial_a50", by_stock = stocks))
  )
  if (!mature) out <- gadget3:::f_substitute(quote(1 - out), list(out = out))
  out
}

initabun <- function(mature) {
  g3a_renewal_initabund(
    M = g3_parameterized("M", by_stock = stocks, by_age = TRUE),
    proportion_f = initial_ageprop(mature),
    recage = g3_stock_def(imm_stock, "minage"),
    by_stock = stocks,
    by_stock_f = stocks
  )
}

common_pars <- list(
  mean_len = g3a_renewal_vonb_t0(by_stock = stocks),
  cv_len = g3_parameterized("lencv", by_stock = stocks, by_age = TRUE)
)

growth_impl <- g3a_grow_impl_bbinom(
  delta_len_f = g3a_grow_lengthvbsimple(by_stock = stocks),
  beta_f = g3_parameterized("bbin", by_stock = stocks),
  maxlengthgroupgrowth = maxlengthgroupgrowth
)

imm_actions <- list(
  g3a_initialconditions_normalcv(imm_stock, factor_f = initabun(FALSE), mean_f = common_pars$mean_len, cv_f = common_pars$cv_len, by_stock = stocks, wgt_by_stock = stocks),
  g3a_naturalmortality(imm_stock, g3a_naturalmortality_exp(by_stock = stocks)),
  g3a_age(imm_stock, output_stocks = list(mat_stock)),
  g3a_growmature(imm_stock, impl_f = growth_impl, maturity_f = g3a_mature_continuous(), output_stocks = list(mat_stock), transition_f = ~TRUE),
  g3a_renewal_normalcv(
    imm_stock,
    factor_f = g3_parameterized("rec", by_stock = TRUE, by_year = TRUE, scale = g3_parameterized("rec.scalar", value = 1, by_stock = TRUE, optimise = FALSE), ifmissing = NaN),
    mean_f = common_pars$mean_len,
    cv_f = g3_parameterized("recl.cv", by_stock = stocks),
    by_stock = stocks,
    wgt_by_stock = stocks
  )
)

mat_actions <- list(
  g3a_initialconditions_normalcv(mat_stock, factor_f = initabun(TRUE), mean_f = common_pars$mean_len, cv_f = common_pars$cv_len, by_stock = stocks, wgt_by_stock = stocks),
  g3a_naturalmortality(mat_stock, g3a_naturalmortality_exp(by_stock = stocks)),
  g3a_age(mat_stock),
  g3a_growmature(mat_stock, impl_f = growth_impl)
)

stock_actions <- c(imm_actions, mat_actions)
