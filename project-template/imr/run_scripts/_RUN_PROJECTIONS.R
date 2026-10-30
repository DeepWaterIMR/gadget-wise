## ---------------------------
##
## Projections only, on an existing fitted model
##
## Usage (from the project folder):
##   Rscript run_scripts/_RUN_PROJECTIONS.R 20261030_model [long|short|both]
##
## ---------------------------

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("Give the model folder (base_dir)")
what <- if (length(args) > 1) args[[2]] else "both"

base_dir <- args[[1]]
reset_model <- FALSE
run_optim <- TRUE # Loads the optimised parameters and fit from base_dir
plot_html <- FALSE
run_proj_long_term <- what %in% c("long", "both")
run_proj_short_term <- what %in% c("short", "both")
keep_settings <- TRUE
source("_RUN_THE_MODEL.R", echo = TRUE)
