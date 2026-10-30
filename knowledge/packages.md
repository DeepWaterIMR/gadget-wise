# Packages

| Package | Install | Needed for |
|---|---|---|
| gadget3 | `install.packages("gadget3")` or `remotes::install_github("gadget-framework/gadget3")` | Everything. Projections with `g3_param_project_bootstrap()` need ≥ 0.15-1-999 (GitHub) |
| TMB | CRAN (needs a C++ compiler: Xcode CLT on macOS, Rtools on Windows) | Compiling models |
| gadgetutils | `remotes::install_github("gadget-framework/gadgetutils")` | Optimisation, reweighting, diagnostics, `g3_fit` |
| gadgetplots | `remotes::install_github("gadget-framework/gadgetplots")` | Plots and HTML summaries |
| g3experiments | `remotes::install_github("gadget-framework/g3experiments")` | Projections (Icelandic layout), NaN tracing |
| tidyverse, yaml, cowplot, pbapply | CRAN | Templates |
| ggFishPlots | CRAN | Life-history starting values |
| mfdb | CRAN | Only for mfdb data-loops |
| duckdb, DBI | CRAN | BAIT data-loop |

Parallel diagnostics fork (`parallel::mclapply`): on Windows set `ncores <- 1`. Memory is usually the
limit on servers, not cores.
