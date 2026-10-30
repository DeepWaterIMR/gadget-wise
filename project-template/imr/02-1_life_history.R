## ---------------------------
##
## Script name: Life history
##
## Purpose of script: Read the life-history parameters that give the starting values of growth,
## length-weight, maturity and initial length-at-age (data/output/model-input/life_history.yaml).
## Estimate them in a data report first (e.g. ggFishPlots::plot_growth(), plot_maturity(),
## plot_lw()), then record the estimates in the yaml.
##
## Creates: life_history, init_lengths
##
## ---------------------------

life_history <- read_yaml_utf8(file.path(model_input_dir, "life_history.yaml"))

required_lh <- c("Linf", "K", "walpha", "wbeta")
if (model_params$two_stocks) required_lh <- c(required_lh, "mat_l50", "mat_alpha", "mat_a50", "mat_a_alpha")
miss <- setdiff(required_lh, names(life_history))
if (length(miss)) stop("life_history.yaml is missing: ", paste(miss, collapse = ", "))
rm(miss, required_lh)

## Initial mean length and sd at age: from the yaml table if given, otherwise from the von
## Bertalanffy curve with a CV of init_length_cv (default 0.1)
init_lengths <- if (!is.null(life_history$init_length_at_age)) {
  bind_rows(lapply(life_history$init_length_at_age, as_tibble))
} else {
  tibble(age = stock_params$minage:stock_params$maxage) |>
    mutate(
      ml = life_history$Linf * (1 - exp(-life_history$K * (age - (life_history$t0 %||% 0)))),
      ml = pmax(ml, stock_params$minlength + stock_params$dl),
      ms = ml * (life_history$init_length_cv %||% 0.1)
    )
}
init_lengths <- init_lengths |>
  filter(age >= stock_params$minage, age <= stock_params$maxage) |>
  mutate(ms = if_else(is.na(ms) | ms < 1, 1, ms)) |>
  arrange(age)

if (reset_model) save(life_history, init_lengths, file = file.path(base_dir, "data/Life history parameters.rda"))
