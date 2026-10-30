## Length, age-length and maturity distributions from mfdb (read_data = TRUE). Edit the sampling
## types (and data sources) for your database. Lengths and ages are grouped as in the model stocks.

minage <- min(sapply(stocks, g3_stock_def, "minage"))
maxage <- max(sapply(stocks, g3_stock_def, "maxage"))
minlen <- min(sapply(stocks, g3_stock_def, "minlen"))
maxlen <- max(sapply(stocks, function(s) max(head(g3_stock_def(s, "maxlen"), -1))))
dl <- min(sapply(stocks, g3_stock_def, "dl"))

sampling_types <- list() # e.g. list(<survey> = "AUT", <comm fleet> = "SEA")

for (fl in names(sampling_types)) {
  assign(paste0("ldist.", fl), mfdb::mfdb_sample_count(mdb, c("age", "length"), c(list(
    sampling_type = sampling_types[[fl]],
    age = mfdb::mfdb_interval("all", c(minage, maxage), open_ended = c("upper", "lower")),
    length = mfdb::mfdb_interval("len", seq(minlen, maxlen, by = dl), open_ended = c("upper", "lower"))
  ), defaults)))
  assign(paste0("aldist.", fl), mfdb::mfdb_sample_count(mdb, c("age", "length"), c(list(
    sampling_type = sampling_types[[fl]],
    age = mfdb::mfdb_interval("age", minage:maxage, open_ended = c("upper")),
    length = mfdb::mfdb_interval("len", seq(minlen, maxlen, by = 4 * dl), open_ended = c("upper", "lower"))
  ), defaults)))
  if (!single_stock_model && fl %in% survey_fleets) {
    assign(paste0("matp.", fl), mfdb::mfdb_sample_count(mdb, c("maturity_stage", "length"), c(list(
      sampling_type = sampling_types[[fl]],
      length = mfdb::mfdb_interval("len", seq(minlen, maxlen, by = 2 * dl), open_ended = c("lower", "upper")),
      maturity_stage = mfdb::mfdb_group(imm = 1, mat = 2:5) # Partial stock names: imm / mat
    ), defaults)))
  }
}

save(list = ls(pattern = "^(ldist|aldist|matp)\\."), file = file.path(base_dir, "data", "catchdistribution_data.Rdata"))
