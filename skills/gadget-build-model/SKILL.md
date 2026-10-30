---
name: gadget-build-model
description: Build or modify the structure of a gadget3 model in either folder format — stocks and sub-stocks, growth, maturation, natural mortality, recruitment, initial conditions, fleets and selectivity, likelihood components, parameters, starting values and bounds — then compile and debug until the nll is finite. Use when adding or changing a fleet, survey, stock, likelihood component or parameterisation, or when a model fails to compile or gives NaN/Inf.
---

<!-- pack-resources:start -->
**Pack resources:** resolve `gadget-wise` from `~/.gadget-wise/config.json` → `gadget_wise_path` (or
`~/.fiskwise/config.json` → `components.gadget-wise.path`). If neither exists, use the checkout
containing this skill, or locate/obtain the pack through its install instructions. Paths such as
`knowledge/`, `config/`, `examples/` and `project-template/` belong to that repository, not the
current model directory. Keep bundled `references/` links relative to the skill. Never assume
`../../` from an agent's global skills folder reaches the repository. Use absolute resolved paths.
<!-- pack-resources:end -->

# Build or change the model

Read the `gadget-model` skill first. Detect the layout (`knowledge/layouts.md`); the same change
lands in different files:

| Change | IMR format | Icelandic format |
|---|---|---|
| Years, steps, areas, stocks, fleets, likelihood list | `config.yaml` `MODEL` | `00-setup/setup.R` options, `setup-stocks.R` |
| Stock actions (growth, M, recruitment, maturation) | `03_stocks.R` | `setup-model.R` / `setup-model-single-stock.R` |
| Fleets, selectivity, catchability, quota | `04_fleets.R` (+ `fleet_suitability()` in `R/g3_helpers.R`) | `setup-fleets.R` |
| Likelihood components | `05_likelihood.R` | `setup-likelihood.R` |
| Starting values, bounds, weights | `06_parameters.R` | parameter chain in `setup.R` |

## Procedure

1. **State the change and why** (biology, data, diagnostics). Record it in `ai/memory/` and, when it
   alters results, bump the model version and write `NEWS.md` (IMR: `bump_version()`).
2. **Check the API** of every function you use in the installed gadget3 (`args()`, source) — names
   and defaults change between versions.
3. **Make the change**, following the patterns in the existing scripts (parameter naming with
   `by_stock` / `prepend_extra`, `g3_parameterized()` rather than hand-written `g3_param()`).
4. **Starting values and bounds** for every new parameter, inside the bounds, on a sensible scale.
   `g3_init_val()` without `lower`/`upper` fixes a parameter (`optimise = FALSE`).
5. **Compile and evaluate** without fitting:
   ```r
   run_optim <- FALSE; source("_RUN_THE_MODEL.R")   # IMR (or run up to 06_parameters.R)
   r <- model(tmb_param$value); r[[1]]; attr(r, "nll_detail")  # finite? which components dominate?
   ```
   Icelandic: `source("00-setup/setup.R")` with the run flags off; it prints the initial nll.
6. **Compare** with the previous model at the same parameters where possible: a pure refactor must
   give the same nll.

## Debugging

- **Compile errors** usually name the R formula; read the generated code: `g3_to_r(actions)` prints R;
  `edit(model)` lets you step through. TMB C++ errors: rebuild with `g3_to_r` first.
- **NaN / Inf**: `g3experiments::g3a_trace_nan(actions)` (or gadget3 `g3a_trace_var`) appended to the
  actions reports the first step and variable that goes non-finite. Typical causes: zero catch
  denominators, negative growth, a parameter at 0 under `log()`, missing values in data.
- **Huge nll (1e15-1e25)**: understocking (stock too small for the catches) or bounds penalty
  (a fixed parameter at its bound). Check `nll_detail`.
- **Parameter missing from the template**: the action that creates it was not included, or its
  name differs (print `tmb_param$switch`).
- **Warnings "g3_init_val(...) didn't match any parameters"**: the pattern is stale; fix or remove it.
- **Slow compiles**: delete the cache folders only when needed (`gadget3_tmb_work_dir/`); keep one
  compile per structure and reuse it.

## Common structural choices

- Selectivity: logistic by length for most; dome (Andersen) when the largest fish are out of reach
  (check residuals by length first); logistic by age when composition by age and length disagree.
  Fleets can share a selectivity (`shares_selectivity_with` in the IMR config).
- Natural mortality: fixed (profile it later) or age-dependent; estimating M needs strong data.
- Recruitment: log-AR(1) by default; check `rec.scalar` is fixed (it is confounded with index
  catchabilities).
- Initial population: estimated numbers at age with init.F, or from equilibrium; a catch-only spin-up
  period lets the model build the stock dynamically.
- Survey indices: catchability estimated (`surveyindices_log(beta = 1)`); `beta` estimated only with
  good reason (hyperstability).
