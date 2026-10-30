# make_synthetic_iceland.R — turn the synthetic contract tables into the data/*.Rdata snapshots of
# the Icelandic layout (as its mfdb data scripts would write them). For testing only.
#
# Usage: make_synthetic_iceland("examples/synthetic/config.yaml", "<project>")

make_synthetic_iceland <- function(config, project, seed = 1) {
  source(file.path("config", "make_synthetic_data.R"))
  source(file.path("project-template", "imr", "R", "data_contract.R"))
  tmp <- tempfile("contract")
  make_synthetic_data(config, tmp, seed = seed)
  txt <- readChar(config, file.info(config)$size, useBytes = TRUE)
  Encoding(txt) <- "UTF-8"
  m <- yaml::yaml.load(txt)$MODEL
  rd <- function(f) readr::read_csv(file.path(tmp, f), show_col_types = FALSE)
  minl <- min(unlist(lapply(m$STOCKS, `[[`, "minlength")))
  maxl <- max(unlist(lapply(m$STOCKS, `[[`, "maxlength")))
  num <- function(x) dplyr::mutate(x, area = 1)

  Comm_landings <- list(rd("catches_Comm.csv") |> num())
  Surv_landings <- list(data.frame(year = unique(rd("ldist_Surv.csv")$year), step = 1, area = 1, total_weight = 1))
  ldist.Comm <- list(to_g3_distribution(rd("ldist_Comm.csv") |> num(), seq(minl, maxl, by = 2)))
  ldist.Surv <- list(to_g3_distribution(rd("ldist_Surv.csv") |> num(), seq(minl, maxl, by = 2)))
  aldist.Surv <- list(to_g3_distribution(rd("aldist_Surv.csv") |> num(), seq(minl, maxl, by = 10), age_breaks = 1:10))
  matp.Surv <- list(to_g3_distribution(rd("matp_Surv.csv") |> num(), seq(minl, maxl, by = 4)))
  si <- rd("index_Surv_SI.csv")
  Surv.SI <- list(list(all = data.frame(year = si$year, step = 1, area = 1, weight = si$weight)))

  lh <- yaml::read_yaml(file.path(tmp, "life_history.yaml"))
  lw.constants <- list(a = lh$walpha, b = lh$wbeta)
  init.cv <- rep(0.1, max(unlist(lapply(m$STOCKS, `[[`, "maxage"))))
  mat.l50 <- lh$mat_l50
  mat.a50 <- lh$mat_a50
  growth_vals <- list(Linf = lh$Linf, K = lh$K, t0 = lh$t0)

  d <- file.path(project, "data")
  dir.create(d, showWarnings = FALSE, recursive = TRUE)
  save(Comm_landings, Surv_landings, file = file.path(d, "fleet_data.Rdata"))
  save(ldist.Comm, ldist.Surv, aldist.Surv, matp.Surv, file = file.path(d, "catchdistribution_data.Rdata"))
  save(Surv.SI, file = file.path(d, "indices.Rdata"))
  save(lw.constants, init.cv, mat.l50, mat.a50, growth_vals, file = file.path(d, "init_param.Rdata"))
  invisible(project)
}
`%||%` <- function(a, b) if (is.null(a)) b else a
