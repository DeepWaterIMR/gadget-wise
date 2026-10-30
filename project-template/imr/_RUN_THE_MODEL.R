## ---------------------------
##
## Script name: Run the gadget3 model for {{STOCK_NAME}}
##
## Purpose of script: Master script. Set the options below, then source the whole script, or run it
## from the top to a chosen line (Ctrl+Alt+B in RStudio). The model structure (stocks, fleets,
## likelihood) is in the MODEL section of config.yaml; this script holds the options of one run.
##
## IMR format of gadget-wise (https://github.com/DeepWaterIMR/gadget-wise).
##
## ---------------------------

## Running on a server: use a screen session and write a log to logs/ (gadget-run skill), e.g.
# screen -dmS <stock>_run -L -Logfile logs/<base_dir>.log bash -lc 'cd <project> && Rscript -e "source(\"_RUN_THE_MODEL.R\", echo = TRUE)"'
## Variants without editing this script: run_scripts/_RUN_WITH.R.

if (!exists("keep_settings")) rm(list = ls()) # _RUN_WITH.R sets keep_settings to keep its overrides

source("00_run_first.R")

# 1. Model run ####

## Name the output folder YYYYMMDD_model_<description>, with the date of the run
set_default <- function(name, value) if (!exists(name, envir = globalenv())) assign(name, value, envir = globalenv())

set_default("base_dir", paste0(format(Sys.Date(), "%Y%m%d"), "_model")) # All files and output of this run
set_default("reset_model", TRUE) # TRUE: build and fit from scratch. FALSE: load the model in base_dir (extra analyses, projections)
set_default("overwrite", TRUE) # If base_dir exists: TRUE overwrites it, FALSE moves it to base_dir_<creation time>
set_default("reload_data", FALSE) # Run the data-loop (02-0_data_loop.R). FALSE uses data/output/model-input/
set_default("ncores", max(1, parallel::detectCores() - 1)) # Cores for parallel runs. Memory is the limit. Windows: 1 (fork-based parallelism)
set_default("maxit", 3000) # Maximum iterations per optimisation

# 2. What to run ####

set_default("run_reweighting", FALSE) # Iterative reweighting (hours). FALSE uses the weights in 06_parameters.R
set_default("run_optim", TRUE) # Optimise the model
set_default("run_jitter", FALSE) # Re-optimise from jittered starting values (09_jitter.R)
set_default("run_retro", FALSE) # Retrospective analysis (10_retro.R)
set_default("run_leaveout", FALSE) # Leave-out analysis (11_leaveout.R)
set_default("run_profile", FALSE) # Likelihood profile over one parameter (12_likelihood_profile.R)
set_default("run_proj_long_term", FALSE) # Long-term projections for reference points (13_long_term_projections.R)
set_default("run_proj_short_term", FALSE) # Short-term projections and catch scenarios (14_short_term_projections.R)
set_default("plot_html", TRUE) # HTML model summary (gadgetplots::make_html, needs pandoc)

# 3. Fitting options ####

set_default("set_weights", TRUE) # Use the likelihood weights in 06_parameters.R
set_default("force_bound_params", TRUE) # Penalise parameters outside their bounds (g3l_bounds_penalty)
set_default("previous_model_params_as_initial", FALSE) # Start from the previous run's optimum
set_default("cv_floor", 4e-4) # Reweighting: maximum survey index weight 1 / cv_floor
set_default("rec_scalar", 1000) # Scale of recruitment and initial numbers: recruits = rec.# x rec_scalar x 10 000 fish. Raise it if the start is understocked
# zero_weights <- "Surv_aldist" # Drop likelihood components (regex on the *_weight names) for the whole run
# scale_weights <- c(Surv_SI = 2) # Multiply likelihood weights (regex names) for the whole run

# 4. Diagnostics options ####

set_default("njits", 20) # Jitter runs
set_default("jitter_fraction", 0.5) # Jitter as a fraction of each parameter (optimiser scale)
set_default("jitter_fraction_rec", 0.1) # Smaller jitter for log recruitment
set_default("retro_peels", 5) # Retro peels
# leaveout_re <- c("^Comm_", "Surv_SI") # Leave-out groups (regex on the component names); default one per fleet and index
set_default("profile_parameter", "*.M") # Profiled parameter (glob on the parameter names)
set_default("profile_values", seq(0.1, 0.4, by = 0.05))

# 5. Projection options ####

set_default("num_project_years", 100) # Long-term projection years
set_default("harvest_rates", seq(0, 0.5, by = 0.01)) # Long-term target harvest rates
set_default("hr_trials", 100) # Trials per harvest rate (trial = RNG seed: same recruitment series across rates)
set_default("advice_cv", 0.212) # Assessment/advice error CV (ICES default)
set_default("advice_rho", 0.423) # Assessment/advice error autocorrelation (ICES default)
set_default("eval_years", 50) # Final projection years the reference points are computed over
set_default("bloss_from_year", NULL) # First year for Bloss (Blim). NULL: first model year
set_default("catch_prop_years", 3) # Fleet catch shares from the last n years
set_default("max_project_years", 5) # Short-term projection years built into the model
set_default("ncores_projections", ncores)

# Build the model ####

source("01_settings.R") # Folder, model structure from config.yaml
source("02_data.R") # Data
source("03_stocks.R") # Stocks
source("04_fleets.R") # Fleets
source("05_likelihood.R") # Likelihood
source("06_parameters.R") # R and TMB model, initial parameters and weights

if (reset_model) file.copy(c(dir(pattern = "\\.R$"), "config.yaml"), file.path(base_dir, "scripts"))

# Fit the model ####

if (run_reweighting && reset_model) {
  dir.create(file.path(base_dir, "reweighting"), showWarnings = FALSE)
  source("07_reweighting.R")
} else if (!reset_model && file.exists(file.path(base_dir, "reweighting/Iterated TMB parameters.rda"))) {
  load(file.path(base_dir, "reweighting/Iterated TMB parameters.rda"))
}

if (run_optim && reset_model) {
  source("08_optimise.R")
} else if (!reset_model && file.exists(file.path(base_dir, "optim/Optimized TMB parameters.rda"))) {
  load(file.path(base_dir, "optim/Optimized TMB parameters.rda"))
  load(file.path(base_dir, "optim/Optimized TMB model fit.rda"))
}

# Diagnostics ####

if (run_jitter) source("09_jitter.R")
if (run_retro) source("10_retro.R")
if (run_leaveout) source("11_leaveout.R")
if (run_profile) source("12_likelihood_profile.R")

save.image(file = file.path(base_dir, "session/gadget_workspace.RData"), compress = "xz")

if (exists("optim_param")) {
  s <- attributes(optim_param)$summary
  message("Optimisation ", if (isTRUE(s$convergence)) "converged" else "did NOT converge", " (score ", round(s$score, 2), ").")
}

# Projections ####
## The projection scripts rebuild the model in their own environment with projection years.

if (run_proj_long_term) source("13_long_term_projections.R")
if (run_proj_short_term) source("14_short_term_projections.R")

message("Finished ", Sys.time(), ". Output in ", base_dir)
