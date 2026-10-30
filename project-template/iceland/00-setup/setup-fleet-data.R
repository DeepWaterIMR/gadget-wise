## Landings by fleet from mfdb (read_data = TRUE). Edit gear and sampling types for your database.
## Surveys get a nominal catch (total_weight = 1) in the survey step.

fleet_gears <- list() # e.g. list(<fleet> = c("BMT"))
stopifnot("Set fleet_gears" = all(comm_fleets %in% names(fleet_gears)))

for (fl in comm_fleets) {
  assign(paste0(fl, "_landings"), mfdb::mfdb_sample_totalweight(mdb, NULL, c(list(
    gear = fleet_gears[[fl]], # Gear codes of the fleet in your database
    sampling_type = "LND",
    species = defaults$species
  ), defaults)))
}
for (fl in survey_fleets) {
  assign(paste0(fl, "_landings"), list(data.frame(year = defaults$year, step = 1, area = 1, total_weight = 1)))
}

save(list = paste0(c(comm_fleets, survey_fleets), "_landings"), file = file.path(base_dir, "data", "fleet_data.Rdata"))
