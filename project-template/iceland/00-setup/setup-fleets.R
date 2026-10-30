## Fleets: commercial fleets remove their landings (<fleet>_landings), surveys a nominal catch
## (<fleet>_landings with total_weight = 1). Logistic selectivity by length unless in dome_fleets.

fleet_suitability <- function(fl) {
  if (fl %in% dome_fleets) {
    g3_suitability_andersen(
      g3_parameterized("andersen.p0", value = 0, optimise = FALSE, by_stock = "species"),
      p1 = g3_parameterized("andersen.p1", by_stock = "species", prepend_extra = fl),
      p2 = g3_parameterized("andersen.p2", value = 1, optimise = FALSE, by_stock = "species"),
      p3 = g3_parameterized("andersen.p3", exponentiate = TRUE, by_stock = "species", prepend_extra = fl),
      p4 = g3_parameterized("andersen.p4", exponentiate = TRUE, by_stock = "species", prepend_extra = fl),
      p5 = max(sapply(stocks, g3_stock_def, "maxmidlen"))
    )
  } else {
    g3_suitability_exponentiall50(
      g3_parameterized("alpha", by_stock = "species", prepend_extra = fl),
      g3_parameterized("l50", by_stock = "species", prepend_extra = fl)
    )
  }
}

fleets <- lapply(setNames(c(comm_fleets, survey_fleets), c(comm_fleets, survey_fleets)), function(fl) {
  g3_fleet(fl) |> g3s_livesonareas(areas[c("1")])
})

landings_data <- function(fl) {
  get(paste0(fl, "_landings"))[[1]] |>
    mutate(area = as.numeric(area), step = as.numeric(step), year = as.numeric(year))
}

fleet_actions <- c(
  lapply(comm_fleets, function(fl) {
    fleets[[fl]] |> g3a_predate_fleet(
      stocks,
      suitabilities = fleet_suitability(fl),
      catchability_f = g3a_predate_catchability_totalfleet(g3_timeareadata(paste0(fl, "_landings"), landings_data(fl)))
    )
  }),
  lapply(survey_fleets, function(fl) {
    fleets[[fl]] |> g3a_predate_fleet(
      stocks,
      suitabilities = fleet_suitability(fl),
      catchability_f = g3a_predate_catchability_totalfleet(g3_timeareadata(paste0(fl, "_landings"), landings_data(fl)))
    )
  })
)
