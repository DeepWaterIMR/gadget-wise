## ---------------------------
##
## Custom data-loop
##
## Write your own code here to produce the model-input tables of the data contract (see
## R/data_contract.R) from your data sources. Keep raw extracts in data/source/ (gitignored).
##
## ---------------------------

run_data_loop <- function(model_params, stock_params, fleet_params, out_dir) {
  # Example: read your own files and write the contract tables
  # raw <- readr::read_csv("data/source/my_length_samples.csv")
  # raw |>
  #   transmute(year, step = 1, area = "1", length = length_cm, number = n) |>
  #   readr::write_csv(file.path(out_dir, "ldist_Surv.csv"))
  #
  # Also write life_history.yaml (see data/output/parameters/README.md)
  stop("R/data_loop_custom.R is a stub. Write the data-loop for your data sources first.")
}
