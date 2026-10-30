## ---------------------------
##
## Run _RUN_THE_MODEL.R with settings given as arguments, without editing it
##
## Usage (from the project folder):
##   Rscript run_scripts/_RUN_WITH.R 'base_dir <- "20261030_model_M03"' 'run_retro <- TRUE'
##   Rscript run_scripts/_RUN_WITH.R 'base_dir <- "20261030_model"' 'reset_model <- FALSE' 'run_jitter <- TRUE'
##
## Each argument is R code evaluated before _RUN_THE_MODEL.R; its set_default() calls keep these
## values. Model-structure changes go into config.yaml (copy it per variant if needed:
## 'config_file <- "config_M03.yaml"').
##
## ---------------------------

args <- commandArgs(trailingOnly = TRUE)
for (a in args) eval(parse(text = a), envir = globalenv())
keep_settings <- TRUE
source("_RUN_THE_MODEL.R", echo = TRUE)
