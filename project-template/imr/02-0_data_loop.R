## ---------------------------
##
## Script name: Data-loop
##
## Purpose of script: Pull the data from their sources and write the model-input tables of the data
## contract (R/data_contract.R) to data/output/model-input/. Only this script knows where the data
## come from. Run with reload_data = TRUE in _RUN_THE_MODEL.R.
##
## The loop is chosen by MODEL$DATA_LOOP in config.yaml:
##   bait   - IMR Biotic data through the BAIT DuckDB database (R/data_loop_bait.R)
##   mfdb   - an mfdb database (R/data_loop_mfdb.R)
##   custom - your own code (R/data_loop_custom.R)
##
## Raw extracts go to data/source/ (gitignored). Never commit data.
##
## ---------------------------

dir.create(model_input_dir, recursive = TRUE, showWarnings = FALSE)

loop_file <- file.path("R", paste0("data_loop_", model_params$data_loop, ".R"))
if (!file.exists(loop_file)) stop("No data-loop ", loop_file, ". Set MODEL$DATA_LOOP to bait, mfdb or custom.")

source(loop_file)
run_data_loop(model_params, stock_params, fleet_params, out_dir = model_input_dir)

message("Model-input tables written to ", model_input_dir, ": ",
        paste(list.files(model_input_dir), collapse = ", "))
