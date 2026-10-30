## ---------------------------
##
## Script name: Stocks
##
## Purpose of script: Define the stocks (one stock, or immature and mature sub-stocks) and their
## actions: initial conditions, natural mortality, ageing, growth (and maturation), and recruitment.
##
## Creates: stocks, stock_actions
##
## Parameter names follow gadget3: <species>_<stock>.<parameter> with by_stock = TRUE, and
## <species>.<parameter> with by_stock = "species" (shared by the sub-stocks).
##
## ---------------------------

## Stocks ####

make_stock <- function(k) {
  g3_stock(
    c(species = model_params$species_code, k),
    lengthgroups = seq(stock_params[[k]]$minlength, stock_params[[k]]$maxlength, stock_params$dl)
  ) |>
    g3s_age(minage = stock_params[[k]]$minage, maxage = stock_params[[k]]$maxage) |>
    g3s_livesonareas(areas)
}

stocks <- setNames(lapply(model_params$stock_names, make_stock), model_params$stock_names)
recruit_stock <- if (model_params$two_stocks) stocks$imm else stocks[[1]]
recage <- g3_stock_def(recruit_stock, "minage")

## Natural mortality ####
## MODEL$M: type "constant" (one M) or "age" (M declines from M.young to M around M.break_age)

common_M <- if (identical(model_params$M$type, "age")) {
  g3_formula(
    quote(M_old + (M_young - M_old) / (1 + exp(age - break_age))),
    M_old = g3_parameterized("M", by_stock = stocks),
    M_young = g3_parameterized("M.young", by_stock = stocks),
    break_age = g3_parameterized("M.break_age", by_stock = stocks, optimise = FALSE)
  )
} else {
  g3_parameterized("M", by_stock = stocks)
}

## Recruitment ####
## Recruits (in 10 000 fish, scaled by rec.scalar) enter the youngest age at renewal. For fitting,
## yearly recruitment follows a log-AR(1) process ("logar1", with a likelihood) or is free ("free").
## Projections replace it by a block bootstrap ("bootstrap") or the mean ("constant") of the
## estimated recruitment over the pool years.

rec_pool_from <- g3_parameterized("rec.proj.from_year", value = min(model_params$year_range), optimise = FALSE, by_stock = stocks)
rec_pool_to <- g3_parameterized("rec.proj.to_year", value = max(model_params$year_range) - 2L, optimise = FALSE, by_stock = stocks)

rec_factor <- if (identical(model_params$rec_projection, "free")) {
  g3_parameterized("rec", by_year = TRUE, by_stock = stocks, scale = "rec.scalar")
} else {
  do.call(g3_param_project, c(
    list(
      "rec",
      switch(model_params$rec_projection,
        logar1 = g3_param_project_logar1(),
        bootstrap = g3_param_project_bootstrap(
          from_year_f = rec_pool_from,
          to_year_f = rec_pool_to,
          block_size_f = g3_parameterized("rec.proj.block_size", value = 5L, optimise = FALSE, by_stock = stocks)
        ),
        constant = g3_param_project_dlnorm(
          lstddev_f = g3_parameterized("rec.proj.dlnorm.stddev", value = 0, optimise = FALSE, type = "LOG", by_stock = stocks),
          from_year_f = rec_pool_from,
          to_year_f = rec_pool_to
        ),
        stop("Unknown rec_projection: ", model_params$rec_projection)
      ),
      scale = "scalar",
      random = FALSE,
      by_stock = stocks,
      by_step = FALSE
    ),
    # A constant projection has an infinite nll; it is only used where the nll is not
    if (identical(model_params$rec_projection, "constant")) list(weight = 0)
  ))
}

## Stock actions ####

initial_conditions <- function(stock, proportion_f = 1) {
  g3a_initialconditions_normalparam(
    stock,
    factor_f = g3a_renewal_initabund(
      proportion_f = proportion_f,
      M = common_M,
      recage = recage,
      by_stock = stocks,
      by_stock_f = stocks
    ),
    mean_f = g3_parameterized("init.meanlen", by_stock = TRUE, by_age = TRUE),
    stddev_f = g3_parameterized("init.sd", by_stock = TRUE, by_age = TRUE),
    by_stock = stocks,
    wgt_by_stock = stocks
  )
}

growth_impl <- g3a_grow_impl_bbinom(maxlengthgroupgrowth = stock_params$maxlengthgroupgrowth, by_stock = stocks)

renewal <- g3a_renewal_normalparam(
  recruit_stock,
  factor_f = rec_factor,
  mean_f = g3_parameterized("init.meanlen", by_stock = TRUE, by_age = TRUE),
  by_stock = stocks,
  wgt_by_stock = stocks
)

stock_actions <- if (model_params$two_stocks) {
  list(
    # Immature: grows and matures into the mature stock (length-based ogive, g3a_mature_continuous)
    initial_conditions(stocks$imm, g3a_initial_ageprop(mature = FALSE)),
    g3a_naturalmortality(stocks$imm, g3a_naturalmortality_exp(param_f = common_M, by_stock = stocks)),
    g3a_age(stocks$imm, output_stocks = list(stocks$mat)),
    g3a_growmature(
      stocks$imm,
      impl_f = growth_impl,
      maturity_f = g3a_mature_continuous(),
      transition_f = TRUE,
      output_stocks = list(stocks$mat)
    ),
    renewal,
    # Mature
    initial_conditions(stocks$mat, g3a_initial_ageprop(mature = TRUE)),
    g3a_naturalmortality(stocks$mat, g3a_naturalmortality_exp(param_f = common_M, by_stock = stocks)),
    g3a_age(stocks$mat),
    g3a_growmature(stocks$mat, impl_f = growth_impl)
  )
} else {
  list(
    initial_conditions(stocks[[1]]),
    g3a_naturalmortality(stocks[[1]], g3a_naturalmortality_exp(param_f = common_M, by_stock = stocks)),
    g3a_age(stocks[[1]]),
    g3a_growmature(stocks[[1]], impl_f = growth_impl),
    renewal
  )
}

## SSB-dependent recruitment for long-term projections ####
## With rec_projection = "bootstrap" (13_long_term_projections.R) the spawning stock spawns into a
## dummy stock (ages 0 to recage - 1) in projection years, which ages into the recruit stock at
## renewal time recage years later. Spawned recruitment = bootstrapped rec x min(1, SSB / rec.proj.blim),
## SSB being the spawning-stock biomass at spawning. rec.proj.blim defaults to 1 kg (no SSB effect);
## the projection script sets it to Blim. Renewal stops once spawned recruits arrive.
## NB: rec_factor is looked up for the year the recruits arrive (cur_year + recage), capped at the
##     final model year.

rec_ssb_dependent <- identical(model_params$rec_projection, "bootstrap")
spawning_stock <- if (model_params$two_stocks) stocks$mat else stocks[[1]]

if (rec_ssb_dependent) {
  dummy <- g3_stock(
    c(species = model_params$species_code, "dummy"),
    lengthgroups = seq(stock_params[[model_params$stock_names[1]]]$minlength, stock_params[[model_params$stock_names[1]]]$maxlength, stock_params$dl)
  ) |>
    g3s_age(minage = 0, maxage = recage - 1) |>
    g3s_livesonareas(areas)

  # Renewal only until the spawned recruits arrive
  stock_actions[[which(vapply(stock_actions, function(a) identical(a, renewal), logical(1)))]] <- g3a_renewal_normalparam(
    recruit_stock,
    factor_f = rec_factor,
    mean_f = g3_parameterized("init.meanlen", by_stock = TRUE, by_age = TRUE),
    by_stock = stocks,
    wgt_by_stock = stocks,
    run_f = gadget3:::f_substitute(~ age == recage && cur_step == 1 && cur_year <= end_year + recage, list(recage = recage))
  )

  ssb_name <- paste0(model_params$species_code, "_spawn_ssb")
  spawn_ssb_step <- g3_step(do.call(g3_formula, c(
    list(
      substitute(stock_with(sp, ssb_var[] <- sum(sp__wgt * sp__spawningnum)), list(ssb_var = as.symbol(ssb_name))),
      sp = spawning_stock,
      sp__wgt = g3_stock_instance(spawning_stock, 1),
      sp__spawningnum = g3_stock_instance(spawning_stock)
    ),
    setNames(list(array(0, dim = c(vec = 1))), ssb_name) # NB: Array, history can't be recorded for a scalar
  )))

  dummy_actions <- list(
    g3a_spawn(
      spawning_stock,
      recruitment_f = g3a_spawn_recruitment_hockeystick(
        r0 = g3_formula(
          quote(10000 * rec_factor), # NB: As g3a_renewal_len_dnorm()
          rec_factor = gadget3:::f_substitute(rec_factor, list(
            cur_year = bquote(min(cur_year + .(as.integer(recage)), start_year + total_years - 1L))
          ))
        ),
        blim = g3_parameterized("rec.proj.blim", value = 1, optimise = FALSE, by_stock = stocks)
      ),
      proportion_f = 1,
      output_stocks = list(dummy),
      mean_f = g3_parameterized(paste0("init.meanlen.", recage), by_stock = recruit_stock),
      stddev_f = g3_parameterized("rec.sd", by_stock = stocks),
      by_stock = stocks,
      wgt_by_stock = stocks,
      run_step = 1,
      run_f = ~cur_year_projection
    ),
    # Spawning-stock biomass at spawning, reported as hist_<species>_spawn_ssb. Named to sort straight after g3a_spawn
    setNames(list(spawn_ssb_step), gadget3:::step_id(g3_action_order$spawn, "g3a_spawn_ssb", spawning_stock)),
    g3a_age(
      dummy,
      output_stocks = list(recruit_stock),
      run_f = ~ cur_step == 1,
      run_at = g3_action_order$time,
      transition_at = g3_action_order$renewal
    )
  )
  dummy_actions <- c(dummy_actions, list(g3a_report_history(dummy_actions, var_re = paste0("^", ssb_name, "$"))))
  stock_actions <- c(stock_actions, dummy_actions)
}

if (reset_model) save(stocks, stock_actions, file = file.path(base_dir, "data/Model stock actions.rda"), compress = "xz")
