## ---------------------------
##
## {{PROJECT_TITLE}}
##
## Icelandic format of gadget-wise (after gadget-framework/gadget-models): one runner (this file)
## with the options as plain variables, sub-scripts 00-setup/setup-*.R sourced in dependency order,
## data snapshots in data/*.Rdata, and each model version in model/<vers>/.
##
## Run from the project root: source("00-setup/setup.R")
##
## ---------------------------

library(gadget3)
library(gadgetutils)
library(gadgetplots)
library(tidyverse)

`%||%` <- function(a, b) if (is.null(a)) b else a

## --- options ---------------------------------------------------------------------

base_dir <- "."
vers <- file.path("model", "{{RUN_NAME}}") # e.g. model/nwwg_2026 or model/01-baseline_<setting codes>
year_range <- {{YEAR_START}}:{{YEAR_END}}
species_name <- "{{STOCK_PREFIX}}" # Stock and parameter prefix: <sp>_imm, <sp>.Linf

read_data <- FALSE # TRUE: query mfdb and write data/*.Rdata. FALSE: load the snapshots
run_iterative <- TRUE
run_retro <- FALSE
run_jitter <- FALSE
run_leaveout <- FALSE
run_advice <- FALSE # Projections and catch options (setup-advice.R)

wgts_folder <- "WGTS"
retro_folder <- "RETRO"
jitter_folder <- "JITTER"
number_of_peels <- 5
number_of_jitters <- 20
jitter_fraction <- 0.1
ncores <- max(1, parallel::detectCores() - 1) # Windows: 1
optim_control <- list(maxit = 2000, reltol = 1e-10)
cv_floor <- 4e-4

## model switches
single_stock_model <- {{SINGLE_STOCK}} # TRUE: one stock; FALSE: immature and mature sub-stocks
estimate_linf <- FALSE
estimate_k <- TRUE
maxlengthgroupgrowth <- {{MAX_LENGTH_GROUP_GROWTH}}
naturalmortality <- {{M_VALUE}}
penalise_recruitment <- 1 # 1: free yearly recruitment with a random-walk penalty (setup-randomeffects.R); 0: no penalty
recruitment_sigma <- 0.4
project_years <- 10
rec_scalar <- 1000 # Scale of recruitment and initial numbers (see the parameters below)

comm_fleets <- c({{COMM_FLEETS}}) # Commercial fleets (landings remove fish)
survey_fleets <- c({{SURVEY_FLEETS}}) # Surveys (nominal catch)
dome_fleets <- character(0) # Fleets with dome-shaped (Andersen) selectivity

boot_repl <- 1 # Bootstrap replicate, read by setup-likelihood.R
peel <- 0 # Retro peel, read by setup-likelihood.R

## --- spatial / temporal defaults -----------------------------------------------------

defaults <- list(
  area = list("1" = 1), # With mfdb: mfdb::mfdb_group("1" = <divisions>)
  timestep = {{TIMESTEP}}, # Months per step; with mfdb: mfdb::mfdb_timestep_quarterly etc.
  year = year_range,
  project_years = project_years,
  species = toupper(species_name)
)
areas <- structure(seq_along(defaults$area), names = names(defaults$area))
time_actions <- list(g3a_time(start_year = min(defaults$year), end_year = max(defaults$year), step_lengths = defaults$timestep), list())

fs::dir_create(file.path(base_dir, c("data", vers)))
save(defaults, areas, file = file.path(base_dir, vers, "defaults.Rdata"))

## --- sub-scripts ---------------------------------------------------------------

source(file.path(base_dir, "00-setup", "setup-stocks.R")) # imm_stock, mat_stock (or single_stock), stocks
source(file.path(base_dir, "00-setup", if (single_stock_model) "setup-model-single-stock.R" else "setup-model.R")) # stock_actions

if (read_data) {
  mdb <- mfdb::mfdb("{{MFDB_NAME}}") # Connection details: see the mfdb documentation
  source(file.path(base_dir, "00-setup", "setup-fleet-data.R"))
  source(file.path(base_dir, "00-setup", "setup-catchdistribution.R"))
  source(file.path(base_dir, "00-setup", "setup-indices.R"))
  source(file.path(base_dir, "00-setup", "setup-initial_parameters.R"))
  mfdb::mfdb_disconnect(mdb)
} else {
  for (f in fs::dir_ls(file.path(base_dir, "data"), glob = "*.Rdata")) {
    if (!grepl("bootstrap", f)) load(f, envir = .GlobalEnv)
  }
}

source(file.path(base_dir, "00-setup", "setup-fleets.R")) # fleets, fleet_actions
source(file.path(base_dir, "00-setup", "setup-likelihood.R")) # likelihood_actions
source(file.path(base_dir, "00-setup", "setup-randomeffects.R")) # random_actions

## --- compile ---------------------------------------------------------------------

actions <- c(stock_actions, fleet_actions, likelihood_actions, if (penalise_recruitment == 1) random_actions, time_actions)
tmb_model <- g3_to_tmb(c(actions, list(g3a_report_detail(actions)), list(g3l_bounds_penalty(actions))))
model <- g3_to_r(attr(tmb_model, "actions"))

## --- parameters ('*' matches any name parts, '#' any number) --------------------------

tmb_param <- attr(tmb_model, "parameter_template") |>
  g3_init_val("*.rec.#", 10, lower = 0.001, upper = 1000) |>
  g3_init_val("*.init.#", 10, lower = 0.001, upper = 1000) |>
  # Recruits and initial numbers are rec.# x rec.scalar x 10 000 fish: scale the scalars so the
  # starting stock can take the catches (an understocking nll of ~1e20 means it cannot)
  g3_init_val("*.rec.scalar", rec_scalar, optimise = FALSE) |>
  g3_init_val("*.init.scalar", rec_scalar, optimise = FALSE) |>
  g3_init_val("*.Linf", growth_vals$Linf, lower = 0.75 * growth_vals$Linf, upper = 1.5 * growth_vals$Linf, optimise = estimate_linf) |>
  g3_init_val("*.K", growth_vals$K, lower = 0.25 * growth_vals$K, upper = 4 * growth_vals$K, optimise = estimate_k) |>
  g3_init_val("*.t0", growth_vals$t0 %||% 0, optimise = FALSE) |>
  g3_init_val("*.bbin", 10, lower = 1e-3, upper = 1000) |>
  g3_init_val("*.M.#", naturalmortality) |>
  g3_init_val("*.init.F", 0.2, lower = 0.001, upper = 1) |>
  g3_init_val("*.*.alpha", 0.5, lower = 0.01, upper = 3) |>
  g3_init_val("*.*.l50", mean(range(sapply(stocks, g3_stock_def, "midlen"))), spread = 0.5) |>
  g3_init_val("*.walpha", lw.constants$a, optimise = FALSE) |>
  g3_init_val("*.wbeta", lw.constants$b, optimise = FALSE) |>
  g3_init_val("*.recl.cv", 0.1, lower = 0.01, upper = 0.5) |>
  g3_init_val("*.lencv.#", init.cv, lower = 0.01, upper = 0.5, optimise = FALSE) |>
  g3_init_val(paste0(species_name, "_recruitment_sigma"), recruitment_sigma, optimise = FALSE)

if (!single_stock_model) {
  tmb_param <- tmb_param |>
    g3_init_val("*.mat.alpha", 0.2, lower = 0.01, upper = 2) |>
    g3_init_val("*.mat.l50", mat.l50, spread = 0.5) |>
    g3_init_val("*.mat_initial_alpha", 1, optimise = FALSE) |>
    g3_init_val("*.mat_initial_a50", mat.a50, optimise = FALSE)
}
if (length(dome_fleets) > 0) {
  tmb_param <- tmb_param |>
    g3_init_val("*.*.andersen.p1", 0.35, lower = 0, upper = 3) |>
    g3_init_val("*.*.andersen.p3", 0.1, lower = 1e-4, upper = 10) |>
    g3_init_val("*.*.andersen.p4", 0.1, lower = 1e-4, upper = 10)
}

## --- test run and persistence -----------------------------------------------------

result <- model(tmb_param$value)
message("nll at the initial values: ", result[[1]])
save(tmb_param, file = file.path(base_dir, vers, "tmb_param.Rdata"))
save(tmb_model, file = file.path(base_dir, vers, "tmb_model.Rdata"))

## --- iterative reweighting -------------------------------------------------------

## One group per fleet (its ldist, aldist, matp); all survey indices as one group
lik_names <- sub("^[ac]dist_[a-z]+_(.*)_weight$", "\\1", grep("_weight$", tmb_param$switch, value = TRUE))
grouping <- c(
  lapply(setNames(c(comm_fleets, survey_fleets), c(comm_fleets, survey_fleets)), function(fl) {
    intersect(paste0(c("ldist_", "aldist_", "matp_"), fl), lik_names)
  }),
  list(sind = grep("^si_", lik_names, value = TRUE))
)
grouping <- grouping[lengths(grouping) > 0]

if (run_iterative) {
  params_final <- g3_iterative(
    file.path(base_dir, vers),
    wgts = wgts_folder,
    model = tmb_model,
    params.in = tmb_param,
    grouping = grouping,
    method = "BFGS",
    control = optim_control,
    use_parscale = TRUE,
    shortcut = FALSE,
    cv_floor = cv_floor,
    resume_final = FALSE,
    mc.cores = ncores
  )
  fit <- g3_fit(tmb_model, params_final)
  save(params_final, fit, file = file.path(base_dir, vers, wgts_folder, "fit.Rdata"))
  gadgetplots::gadget_plots(fit, file.path(base_dir, vers, "figs"), file_type = "html")
}

## --- diagnostics and advice ---------------------------------------------------------

if (run_retro || run_jitter || run_leaveout) source(file.path(base_dir, "00-setup", "setup-diagnostics.R"))
if (run_advice) source(file.path(base_dir, "00-setup", "setup-advice.R"))
