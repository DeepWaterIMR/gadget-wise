# {{PROJECT_TITLE}}

A [gadget3](https://gadget-framework.github.io/gadget3/) model of {{STOCK_NAME}} (*{{STOCK_LATIN}}*)
in ICES {{ICES_AREAS}} for {{WORKING_GROUP}}. Scaffolded with
[gadget-wise](https://github.com/DeepWaterIMR/gadget-wise) (IMR format).

## Quick start

1. Install the packages: gadget3 (CRAN or `remotes::install_github("gadget-framework/gadget3")`),
   gadgetutils, gadgetplots and g3experiments (GitHub, gadget-framework), TMB, tidyverse, yaml.
2. Put the model-input tables in `data/output/model-input/` (run the data-loop with
   `reload_data <- TRUE`, see `02-0_data_loop.R`).
3. Set the options in `_RUN_THE_MODEL.R` and source it:

```r
source("_RUN_THE_MODEL.R")
```

Variants without editing the script:

```bash
Rscript run_scripts/_RUN_WITH.R 'base_dir <- "20261030_model_M03"' 'run_retro <- TRUE'
Rscript run_scripts/_RUN_PROJECTIONS.R 20261030_model both
```

## Pipeline

```
00_run_first.R            packages, gadget3 caches, helpers, ggplot theme
01_settings.R             output folder; model structure from config.yaml
02_data.R                 data:
  02-0_data_loop.R          data-loop -> data/output/model-input/ (reload_data = TRUE)
  02-1_life_history.R       growth, length-weight, maturity, initial length at age
  02-2_survey_indices.R     survey indices
  02-3_catch_distributions.R  ldist, aldist, matp
  02-4_catches.R            catches by fleet
03_stocks.R               stocks and stock actions
04_fleets.R               fleets, selectivity, catchability, projection quota
05_likelihood.R           likelihood components
06_parameters.R           R and TMB model, initial values, bounds, weights
07_reweighting.R          iterative reweighting (optional, slow)
08_optimise.R             optimisation and fit
09_jitter.R … 12_likelihood_profile.R   diagnostics (optional)
13_long_term_projections.R   reference points
14_short_term_projections.R  catch scenarios
```

## Output (`YYYYMMDD_model_<description>/`, gitignored)

| Folder | Contents |
|---|---|
| `data/` | Model inputs and the initial parameters |
| `optim/` | Optimised parameters and the fit (`g3_fit`) |
| `reweighting/`, `jitter/`, `retro/`, `leaveout/`, `profile_*` | Diagnostics |
| `long_term_projections/`, `short_term_projections/` | Projections and reference points |
| `figures/` | Figures and the HTML model summary |
| `scripts/` | The scripts and config of the run |
| `session/` | Session info, run times, workspace |
| `model_code.cpp` | The TMB C++ code |

Compiled code is cached in `gadget3_tmb_work_dir/` and `gadget3_r_work_dir/`; delete them to force recompilation.
