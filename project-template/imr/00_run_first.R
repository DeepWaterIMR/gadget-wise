## ---------------------------
##
## Script name: Run first
##
## Purpose of script: Load packages, set gadget3 options, source the project helpers and set the
## ggplot theme. Sourced by _RUN_THE_MODEL.R before anything else.
##
## ---------------------------

## Packages ####

## Package installation needs the user's consent (see the r-package-setup skill). This script only
## checks and loads; install missing packages with renv::restore() or explicitly.

pkgs <- c(
  "tidyverse", "TMB", "gadget3", "gadgetutils", "gadgetplots", "g3experiments",
  "yaml", "cowplot", "pbapply"
)

missing_pkgs <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  stop(
    "Missing packages: ", paste(missing_pkgs, collapse = ", "), ".\n",
    "gadget3 is on CRAN; gadgetutils, gadgetplots and g3experiments install from GitHub, e.g.\n",
    "  remotes::install_github('gadget-framework/gadgetutils')",
    call. = FALSE
  )
}

invisible(lapply(pkgs, function(pkg) {
  suppressPackageStartupMessages(library(pkg, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE))
}))

options(dplyr.summarise.inform = FALSE)

## gadget3 caches ####
## Compiled TMB objects and R model code are cached here (gitignored). Delete the folders to force
## recompilation.

options(
  gadget3.tmb.work_dir = file.path("gadget3_tmb_work_dir"),
  gadget3.r.work_dir = file.path("gadget3_r_work_dir")
)

## Project helpers ####

for (f in list.files("R", pattern = "^(g3_|data_contract|projection_|version)", full.names = TRUE)) {
  source(f)
}
rm(f)

## Figures ####

colwidth <- 85 # mm, single-column figure width
pagewidth <- 170 # mm, double-column figure width

theme_set(
  theme_classic(base_size = 11) %+replace%
    theme(
      strip.background = element_blank(),
      legend.background = element_blank(),
      plot.margin = margin(5.5, 10, 5.5, 5.5)
    )
)
