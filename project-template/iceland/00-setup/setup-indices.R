## Survey indices by length group from mfdb (read_data = TRUE), or from an external stratified index
## (e.g. the index-wise assessment index). <survey>.SI is a list (bootstrap replicate) of lists
## (length group) of data frames with year, step, area, length, number.

si_len_breaks <- c({{SI_LENGTH_BREAKS}}) # Length-group bounds of the indices

si_sampling_types <- list() # e.g. list(<survey> = "AUT")

for (fl in names(si_sampling_types)) {
  si <- mfdb::mfdb_sample_count(mdb, c("length"), c(list(
    sampling_type = si_sampling_types[[fl]], # Survey sampling type in your database
    length = mfdb::mfdb_interval("len", si_len_breaks, open_ended = c("lower", "upper"))
  ), defaults))[[1]]
  assign(paste0(fl, ".SI"), list(split(si, si$length)))
}

save(list = paste0(survey_fleets, ".SI"), file = file.path(base_dir, "data", "indices.Rdata"))
