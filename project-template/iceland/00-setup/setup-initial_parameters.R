## Starting values from data (read_data = TRUE): length-weight, length CV by age, maturity, growth.
## Saved to data/init_param.Rdata: lw.constants (a, b), init.cv, mat.l50, mat.a50, growth_vals (Linf, K)

ind <- mfdb::mfdb_dplyr_sample(mdb) |>
  filter(species == local(defaults$species), !is.na(length)) |>
  select(year, age, length, weight, maturity_stage) |>
  collect()

lw <- lm(log(weight) ~ log(length), data = filter(ind, weight > 0))
lw.constants <- list(a = exp(coef(lw)[[1]]), b = coef(lw)[[2]]) # Check the weight unit (kg in the model)

init.cv <- ind |>
  filter(!is.na(age)) |>
  group_by(age) |>
  summarise(cv = sd(length) / mean(length)) |>
  pull(cv)

mat <- ind |> filter(!is.na(maturity_stage)) |> mutate(mature = maturity_stage > 1)
mat.l50 <- unname(-coef(glm(mature ~ length, binomial, mat))[[1]] / coef(glm(mature ~ length, binomial, mat))[[2]])
mat.a50 <- unname(-coef(glm(mature ~ age, binomial, mat))[[1]] / coef(glm(mature ~ age, binomial, mat))[[2]])

vb <- nls(length ~ Linf * (1 - exp(-K * (age - t0))), data = filter(ind, !is.na(age)), start = list(Linf = max(ind$length), K = 0.2, t0 = 0))
growth_vals <- as.list(coef(vb))

save(lw.constants, init.cv, mat.l50, mat.a50, growth_vals, file = file.path(base_dir, "data", "init_param.Rdata"))
