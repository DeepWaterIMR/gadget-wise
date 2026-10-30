## ---------------------------
##
## Script name: Data
##
## Purpose of script: Orchestrate the data. The data-loop (02-0) writes the model-input tables of
## the data contract (R/data_contract.R); the 02-1 to 02-4 scripts turn them into gadget3 inputs.
##
## Creates: life-history objects (02-1), survey indices (02-2), *_ldist / *_aldist / *_matp (02-3),
## *_catches (02-4)
##
## ---------------------------

## Data-loop: pull fresh data from the sources (BAIT, mfdb or custom) ####

if (reload_data) {
  message("Running the ", model_params$data_loop, " data-loop...")
  source("02-0_data_loop.R")
}

## Life history ####

source("02-1_life_history.R")

## Survey indices ####

if (reset_model) {
  source("02-2_survey_indices.R")
} else {
  load(file.path(base_dir, "data/Survey indices to Gadget.rda"))
}

## Length, age and maturity distributions ####

if (reset_model) {
  source("02-3_catch_distributions.R")
} else {
  load(file.path(base_dir, "data/Catch distributions to Gadget.rda"))
}

## Catches ####

if (reset_model) {
  source("02-4_catches.R")
} else {
  load(file.path(base_dir, "data/Catches to Gadget.rda"))
}
