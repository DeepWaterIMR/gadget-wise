## Stock actions, single stock: initial conditions, natural mortality, ageing, growth, recruitment

common_pars <- list(
  mean_len = g3a_renewal_vonb_t0(by_stock = stocks),
  cv_len = g3_parameterized("lencv", by_stock = stocks, by_age = TRUE)
)

stock_actions <- list(
  g3a_initialconditions_normalcv(
    single_stock,
    factor_f = g3a_renewal_initabund(M = g3_parameterized("M", by_stock = stocks, by_age = TRUE), recage = g3_stock_def(single_stock, "minage"), by_stock = stocks, by_stock_f = stocks),
    mean_f = common_pars$mean_len, cv_f = common_pars$cv_len, by_stock = stocks, wgt_by_stock = stocks
  ),
  g3a_naturalmortality(single_stock, g3a_naturalmortality_exp(by_stock = stocks)),
  g3a_age(single_stock),
  g3a_growmature(single_stock, impl_f = g3a_grow_impl_bbinom(
    delta_len_f = g3a_grow_lengthvbsimple(by_stock = stocks),
    beta_f = g3_parameterized("bbin", by_stock = stocks),
    maxlengthgroupgrowth = maxlengthgroupgrowth
  )),
  g3a_renewal_normalcv(
    single_stock,
    factor_f = g3_parameterized("rec", by_stock = TRUE, by_year = TRUE, scale = g3_parameterized("rec.scalar", value = 1, by_stock = TRUE, optimise = FALSE), ifmissing = NaN),
    mean_f = common_pars$mean_len,
    cv_f = g3_parameterized("recl.cv", by_stock = stocks),
    by_stock = stocks, wgt_by_stock = stocks
  )
)
