## ---------------------------
##
## Script name: Model settings
##
## Purpose of script: Set up the output folder and read the model structure (stocks, years, time
## steps, areas, fleets, likelihood components) from the MODEL section of config.yaml into
## model_params and stock_params.
##
## Creates: model_params, stock_params, fleet_params, areas, time_actions
##
## ---------------------------

## Switches ####

if (!reset_model & reload_data) {
  message("Cannot reload the data when reset_model = FALSE. Switching reload_data to FALSE")
  reload_data <- FALSE
}

if (run_reweighting) previous_model_params_as_initial <- FALSE

## Output folder ####

if (reset_model & dir.exists(base_dir)) {
  prev_param_file <- file.path(base_dir, "optim/Optimized TMB parameters.csv")
  if (previous_model_params_as_initial & file.exists(prev_param_file)) {
    prev_param <- read.csv(prev_param_file) |>
      dplyr::select(switch, value) |>
      filter(!grepl("weight$", switch))
    prev_param <- setNames(prev_param$value, prev_param$switch)
  }

  if (!overwrite) {
    backup_base_dir <- paste0(base_dir, "_", format(file.info(base_dir)[, "ctime"], "%Y-%m-%d-%H-%M-%S"))
    file.rename(base_dir, backup_base_dir)
    message("The old base_dir was moved to ", backup_base_dir)
  }
  unlink(base_dir, recursive = TRUE)
  message(base_dir, " deleted and recreated.")
}

if (!dir.exists(base_dir)) {
  for (d in c("data", "figures", "scripts", "session")) dir.create(file.path(base_dir, d), recursive = TRUE)
  writeLines(
    c(
      "Model version:", model_version(),
      "\nGit commit:", model_git_commit(),
      "\nStart time:", capture.output(Sys.time()),
      "\nSession info:", capture.output(sessionInfo())
    ),
    file.path(base_dir, "session", "sessionInfo.txt")
  )
}

## Model settings ####

if (reset_model) {
  cfg_model <- read_yaml_utf8("config.yaml")$MODEL
  if (is.null(cfg_model)) stop("config.yaml has no MODEL section. See the gadget-new-model skill.")

  model_params <- list()
  model_params$version <- model_version() # See VERSION, NEWS.md and R/version.R
  model_params$git_commit <- model_git_commit()
  model_params$species_code <- cfg_model$STOCK_PREFIX # Prefix of stock and parameter names, e.g. "cod" -> cod_imm, cod_imm.Linf
  model_params$year_range <- seq(cfg_model$YEARS[[1]], cfg_model$YEARS[[2]])
  model_params$step_lengths <- step_lengths(cfg_model$TIMESTEP) # Months per time step, e.g. 12 (yearly) or c(3, 3, 3, 3)
  model_params$max_project_years <- 0 # Projection years built into the model (sizes the parameter arrays). Set by the projection scripts
  model_params$rec_projection <- cfg_model$RECRUITMENT %||% "logar1" # "logar1" for fitting; "bootstrap" or "constant" for projections
  model_params$M <- cfg_model$M
  model_params$fleets <- cfg_model$FLEETS
  model_params$likelihood <- cfg_model$LIKELIHOOD
  model_params$data_loop <- cfg_model$DATA_LOOP %||% "custom"
  model_params$peel <- 0 # Retro peel. Set by 10_retro.R

  ## Stocks: one stock, or an immature and a mature sub-stock (names imm and mat)
  stock_params <- cfg_model$STOCKS
  model_params$stock_names <- names(stock_params)
  model_params$two_stocks <- setequal(model_params$stock_names, c("imm", "mat"))
  if (!model_params$two_stocks && length(stock_params) != 1) {
    stop("MODEL$STOCKS must be one stock, or two sub-stocks named imm and mat")
  }

  stock_params$dl <- cfg_model$LENGTH_BIN %||% 1 # Width of the model length groups (cm)
  stock_params$maxlengthgroupgrowth <- cfg_model$MAX_LENGTH_GROUP_GROWTH %||% 15 # Max length groups a fish can grow in one step
  stock_params$minage <- min(vapply(model_params$stock_names, function(k) stock_params[[k]]$minage, numeric(1)))
  stock_params$maxage <- max(vapply(model_params$stock_names, function(k) stock_params[[k]]$maxage, numeric(1)))
  stock_params$minlength <- min(vapply(model_params$stock_names, function(k) stock_params[[k]]$minlength, numeric(1)))
  stock_params$maxlength <- max(vapply(model_params$stock_names, function(k) stock_params[[k]]$maxlength, numeric(1)))

  ## Fleets as a table
  fleet_params <- fleet_table(model_params$fleets) # R/g3_helpers.R

  ## Areas: names map to the integer area numbers gadget3 uses
  areas <- structure(seq_along(cfg_model$AREAS), names = as.character(cfg_model$AREAS))

  ## Time keeping
  time_actions <- list(
    g3a_time(
      start_year = min(model_params$year_range),
      end_year = max(model_params$year_range),
      step_lengths = model_params$step_lengths
    ),
    list()
  )

  save(model_params, stock_params, fleet_params, areas, time_actions,
    file = file.path(base_dir, "data/Model and stock parameters.rda"), compress = "xz"
  )
} else {
  load(file.path(base_dir, "data/Model and stock parameters.rda"))
}
