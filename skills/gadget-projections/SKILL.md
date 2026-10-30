---
name: gadget-projections
description: Project a fitted gadget3 model — long-term stochastic projections over harvest rates for reference points (Blim, Bpa, MSY Btrigger, Flim/HRlim, HRmsy, HRp0.5) with bootstrapped SSB-dependent recruitment and advice error, and short-term projections with interim-year catch and catch scenarios for the advice; harvest control rules (ICES MSY advice rule) with g3_quota. Use when the user asks for reference points, catch options, advice projections, or an HCR/MSE evaluation.
---

<!-- pack-resources:start -->
**Pack resources:** resolve `gadget-wise` from `~/.gadget-wise/config.json` → `gadget_wise_path` (or
`~/.fiskwise/config.json` → `components.gadget-wise.path`). If neither exists, use the checkout
containing this skill, or locate/obtain the pack through its install instructions. Paths such as
`knowledge/`, `config/`, `examples/` and `project-template/` belong to that repository, not the
current model directory. Keep bundled `references/` links relative to the skill. Never assume
`../../` from an agent's global skills folder reaches the repository. Use absolute resolved paths.
<!-- pack-resources:end -->

# Projections and reference points

Projections rebuild the fitted model with projection years and run it with the **optimised
parameters**, never a refit. Follow the ICES technical guidelines for reference points
(WKREF/WKGMSE) and the stock's working-group practice; the user decides the stock type and the basis
of Blim.

## IMR format

- `13_long_term_projections.R` (`run_proj_long_term`): rebuilds the model in its own environment
  (`projection_env()`, `R/projection_setup.R`) with `rec_projection = "bootstrap"`: block bootstrap of
  the estimated recruitment (pool `rec.proj.from_year`–`to_year`, `rec.proj.block_size`), made
  SSB-dependent below Blim by spawning into a dummy stock (`03_stocks.R`); harvest-rate quota
  (`g3_quota_hockeystick_blim()`, `R/projection_functions.R`) with lognormal AR(1) advice error
  (`advice_cv`, `advice_rho`); fleet shares from the last `catch_prop_years`; `hr_trials` trials per
  harvest rate with the trial number as seed, so trials share recruitment across rates. Three
  scenarios: no error/no trigger (HRlim), error/no trigger (HRmsy), error/trigger (HRp0.5 check).
  Writes `long_term_projections/reference_points.csv`.
- `14_short_term_projections.R` (`run_proj_short_term`): constant recruitment (mean of the pool),
  interim-year catch (status quo or `interim_catch`), scenarios `st_scenarios` (named harvest rates;
  the MSY advice rule added when reference points exist). Writes `scenario_summary.csv` and a figure.
- Projections only, on an existing model: `Rscript run_scripts/_RUN_PROJECTIONS.R <model folder> both`.

Blim default in the template is **Bloss** (`model_bio_refpoints()`, ICES stock type 5) — a placeholder
until the user decides. Bpa = Blim × exp(1.645 σ), σ = 0.2 by default; MSY Btrigger = Bpa.

## Icelandic format

`setup-advice.R` with g3experiments: `g3p_setup_pars(model, params, blim, btrigger, harvest_rates,
...)` produces one parameter set per harvest rate and trial; run them with `g3_fit()` or the TMB
function. The MFRI advice scripts add interim-year fleets and evaluate catch options over a grid.

## Checks

- Realised harvest rate vs target: the quota applies to fleet-selected biomass, not total biomass —
  report which one HR refers to.
- Recruitment pool: exclude poorly estimated terminal years and a data-free spin-up period.
- Burn-in: compute statistics over the final `eval_years` only.
- Enough trials for stable P(SSB < Blim) at HRp0.5 (≥ 100; more near the threshold).
- Short-term: SSB at the start of the advice year and the year after, catch in the advice year,
  % change vs previous TAC; table in the advice sheet layout.
- Write the settings (pool, block size, CV, rho, trials, years) into the report.
