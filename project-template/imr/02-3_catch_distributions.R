## ---------------------------
##
## Script name: Catch distributions
##
## Purpose of script: Turn the ldist, aldist and matp tables into gadget3 catch-distribution data,
## binned to the likelihood length and age groups, and plot them for checking.
##
## Age convention: fleets sample the stock at the predation step, BEFORE renewal, so recruits of
## year Y first appear in the catches in year Y + 1, one model age older than at renewal. Decide
## and document whether observed ages are used as recorded or offset (MODEL$LIKELIHOOD$age_offset).
##
## Creates: <Fleet>_ldist, <Fleet>_aldist, <Fleet>_matp
##
## ---------------------------

lik <- model_params$likelihood

## Likelihood length groups (can be coarser than the model's) and age groups
ldist_breaks <- seq(stock_params$minlength, stock_params$maxlength, by = lik$ldist_bin %||% stock_params$dl)
aldist_length_breaks <- seq(stock_params$minlength, stock_params$maxlength, by = lik$aldist_length_bin %||% 5)
age_breaks <- unlist(lik$age_groups %||% seq(stock_params$minage, stock_params$maxage))
matp_breaks <- seq(stock_params$minlength, stock_params$maxlength, by = lik$matp_bin %||% 2)

drop_area <- length(areas) == 1 # One-area models compare all areas together

finish <- function(x) if (drop_area) dplyr::select(x, -area) else x

for (fl in lik$ldist %||% character(0)) {
  x <- read_model_input("ldist", fl) |> to_g3_distribution(ldist_breaks) |> finish()
  assign(paste0(fl, "_ldist"), x)
}

for (fl in lik$aldist %||% character(0)) {
  x <- read_model_input("aldist", fl)
  if (isTRUE(lik$age_offset)) x <- mutate(x, age = age + 1) # Biological age -> model age at sampling
  x <- x |> to_g3_distribution(aldist_length_breaks, age_breaks = age_breaks) |> finish()
  assign(paste0(fl, "_aldist"), x)
}

if (model_params$two_stocks) {
  for (fl in lik$matp %||% character(0)) {
    x <- read_model_input("matp", fl) |> to_g3_distribution(matp_breaks) |> finish()
    assign(paste0(fl, "_matp"), x)
  }
}

dist_names <- ls(pattern = "_(ldist|aldist|matp)$")

## Check: sample size per year-step
for (nm in dist_names) {
  small <- get(nm) |>
    group_by(year, step) |>
    summarise(n = sum(number), .groups = "drop") |>
    filter(n < (lik$min_sample %||% 30))
  if (nrow(small) > 0) warning(nm, ": year-steps with few fish: ", paste(small$year, small$step, sep = "-", collapse = ", "))
}

## Figures
for (nm in grep("_ldist$", dist_names, value = TRUE)) {
  ggsave(file.path(base_dir, "figures", paste0(nm, ".png")),
    plot = plot_g3_distribution(get(nm), nm), # R/data_contract.R
    width = pagewidth, height = pagewidth * 1.4, units = "mm", dpi = 200, bg = "white"
  )
}

save(list = dist_names, file = file.path(base_dir, "data/Catch distributions to Gadget.rda"))
rm(x, fl, nm, small, finish)
