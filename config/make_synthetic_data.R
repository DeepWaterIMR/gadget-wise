# make_synthetic_data.R — write synthetic model-input tables for the gadget-wise data contract.
#
# Simulates a simple age-structured stock (von Bertalanffy growth, logistic selectivity and
# maturity, lognormal recruitment) and samples catches, length, age-length and maturity data and a
# survey biomass index from it. For testing the templates only: the numbers mean nothing.
#
# Usage:
#   source("config/make_synthetic_data.R")
#   make_synthetic_data("examples/synthetic/config.yaml", "<project>/data/output/model-input")

make_synthetic_data <- function(config, out_dir, seed = 1) {
  set.seed(seed)
  txt <- readChar(config, file.info(config)$size, useBytes = TRUE)
  Encoding(txt) <- "UTF-8"
  cfg <- yaml::yaml.load(txt)$MODEL
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  years <- seq(cfg$YEARS[[1]], cfg$YEARS[[2]])
  ages <- 1:max(vapply(cfg$STOCKS, function(s) s$maxage, numeric(1)))
  ny <- length(years)
  na <- length(ages)

  linf <- 110; k <- 0.15; t0 <- -0.5; cv_len <- 0.1
  walpha <- 1e-5; wbeta <- 3
  mat_l50 <- 55; mat_alpha <- 0.2
  M <- 0.2

  ml <- linf * (1 - exp(-k * (ages - t0)))
  wt <- walpha * ml^wbeta # kg
  sel_comm <- 1 / (1 + exp(-0.2 * (ml - 50)))
  sel_surv <- 1 / (1 + exp(-0.3 * (ml - 20)))

  rec <- exp(rnorm(ny, log(5e7), 0.5))
  f <- 0.1 + 0.3 * sin(seq(0, pi, length.out = ny))

  N <- matrix(0, ny, na)
  N[1, ] <- rec[1] * exp(-(M + 0.2) * (ages - 1))
  for (y in seq_len(ny)) {
    if (y > 1) {
      N[y, 1] <- rec[y]
      N[y, -1] <- N[y - 1, -na] * exp(-(M + f[y - 1] * sel_comm[-na]))
      N[y, na] <- N[y, na] + N[y - 1, na] * exp(-(M + f[y - 1] * sel_comm[na]))
    }
  }

  catch_n <- N * (1 - exp(-(M + outer(f, sel_comm)))) * outer(f, sel_comm) / (M + outer(f, sel_comm))
  catches <- tibble::tibble(year = years, step = 1, area = cfg$AREAS[[1]], total_weight = round(as.vector(catch_n %*% wt)))
  readr::write_csv(catches, file.path(out_dir, "catches_Comm.csv"))

  # Individual samples: draw ages from the selected numbers, lengths from the age-length key
  sample_fish <- function(numbers, n) {
    do.call(rbind, lapply(seq_len(ny), function(y) {
      a <- sample(ages, n, replace = TRUE, prob = numbers[y, ])
      len <- round(rnorm(n, ml[a], cv_len * ml[a]))
      data.frame(year = years[y], step = 1, area = cfg$AREAS[[1]], age = a, length = pmax(len, 1))
    }))
  }

  comm <- sample_fish(catch_n, 500)
  surv <- sample_fish(N * rep(sel_surv, each = ny), 800)
  surv$maturity_stage <- ifelse(runif(nrow(surv)) < 1 / (1 + exp(-mat_alpha * (surv$length - mat_l50))), "mat", "imm")

  count <- function(x, ...) dplyr::count(x, ..., name = "number")
  readr::write_csv(count(comm, year, step, area, length), file.path(out_dir, "ldist_Comm.csv"))
  readr::write_csv(count(surv, year, step, area, length), file.path(out_dir, "ldist_Surv.csv"))
  readr::write_csv(count(surv[surv$year %% 2 == 0, ], year, step, area, age, length), file.path(out_dir, "aldist_Surv.csv"))
  readr::write_csv(count(surv, year, step, area, length, maturity_stage), file.path(out_dir, "matp_Surv.csv"))

  index <- tibble::tibble(
    year = years, step = 1, area = cfg$AREAS[[1]],
    weight = as.vector((N * rep(sel_surv, each = ny)) %*% wt) * 1e-4 * exp(rnorm(ny, 0, 0.2))
  )
  readr::write_csv(index, file.path(out_dir, "index_Surv_SI.csv"))

  a50 <- t0 - log(1 - mat_l50 / linf) / k # Age at mat_l50
  yaml::write_yaml(
    list(
      Linf = linf, K = k, t0 = t0, walpha = walpha, wbeta = wbeta,
      mat_l50 = mat_l50, mat_alpha = mat_alpha, mat_a50 = round(a50, 2), mat_a_alpha = 1,
      init_length_cv = cv_len,
      source = "Synthetic values from gadget-wise config/make_synthetic_data.R"
    ),
    file.path(out_dir, "life_history.yaml")
  )
  invisible(out_dir)
}
