---
name: gadget-model
description: Explain and apply how gadget3 models work — stocks, sub-stocks, actions and their order within a time step, growth, maturation, recruitment, fleets and selectivity, likelihood components and their data, parameters and the parameter template, compilation to R/TMB, reports, and common pitfalls. Use for any question about gadget3 model structure or code, before writing or reviewing gadget3 code, and for uses beyond stock assessment (multispecies, spatial, tagging, MSE).
---

<!-- pack-resources:start -->
**Pack resources:** the `gadget-wise` root is `~/.gadget-wise/config.json` → `gadget_wise_path`, else `~/.fiskwise/config.json` →
`components.gadget-wise.path`, else the checkout containing this skill. Paths such as `knowledge/`
and `project-template/` are relative to that root, never `../../` from a skills folder; resolve
links that leave this skill's folder against the source skill there. Use absolute paths.
<!-- pack-resources:end -->

# How gadget3 works

The universal gadget-wise skill: what an agent must know to read, write, review or explain any
gadget3 model, in any folder layout. Read `knowledge/gadget3.md` and `knowledge/action-order.md`
first. For exact signatures, defaults, auto-generated parameter names and source references, use
[references/gadget3-reference.md](references/gadget3-reference.md); for gadgetutils, gadgetplots,
g3experiments and mfdb, [references/helper-packages.md](references/helper-packages.md).

**Authority order:** the installed gadget3 source (`args(gadget3::fn)`, `gadget3:::fn`, `?fn`) >
gadget3 GitHub (`gadget-framework/gadget3`, NEWS.md) > the references here > vignettes and the
gadget3 site > gadget2 documentation (concepts only). State the gadget3 version you checked.

## 1. The mental model

- A model is a flat list of **actions**; each action is a set of R formulas (steps) with their own
  environment. `g3_to_r()` / `g3_to_tmb()` sort the steps by name (`g3_action_order`), wrap them in one
  time loop and emit an R function or a TMB C++ template. List order does not matter.
- **Stocks** have length groups (always) and optionally age (`g3s_age`), area (`g3s_livesonareas`)
  and tag dimensions. Sub-stocks (immature/mature, male/female) are separate stocks linked by
  maturation (`g3a_growmature(..., maturity_f = g3a_mature_continuous(), output_stocks = )`) or
  ageing transitions (`g3a_age(output_stocks = )`).
- **Fleets** (`g3_fleet`) predate on stocks with a **suitability** (selectivity:
  `g3_suitability_exponentiall50`, `_andersen`, `_constant`, custom `g3_formula`) and a
  **catchability**: `g3a_predate_catchability_totalfleet` (remove the reported catch),
  `_numberfleet`, `_linearfleet` and `_effortfleet` (effort), `_quotafleet`, `_project` (catch data in the hindcast, quota in projections).
- **Likelihood**: `g3l_catchdistribution()` compares fleet catches (length, age-length, maturity, sex
  composition; or biomass), `g3l_abundancedistribution()` compares the stock (survey indices, stock
  composition). The comparison is `function_f`: `g3l_distribution_sumofsquares()`, `_multinomial()`,
  `_multivariate()`, `_surveyindices_log(alpha, beta)`, `_surveyindices_linear()`. Penalties:
  `g3l_understocking()` (catch > stock), `g3l_bounds_penalty()`, `g3l_random_dnorm/walk()`.
- **Parameters** are created by `g3_parameterized(name, by_stock, by_year, by_age, by_predator,
  exponentiate, scale, offset, ...)` inside the actions. The compiled model carries
  `attr(model, "parameter_template")`; fill it with `g3_init_val(template, "pattern", value, lower,
  upper, optimise)`. Patterns: `*` matches any characters (also across dots), `#` a number.
- Weights of likelihood components are parameters named `<type>_<function>_<nll_name>_weight`
  (e.g. `cdist_sumofsquares_Surv_ldist_weight`, `adist_surveyindices_log_Surv_SI_weight`).

## 2. Timing (read before touching data)

Within a step: predate (3) → natural mortality (4) → grow (5) → spawn (6) → mature (7) → renewal (8)
→ likelihood (10) → report (11) → age (12). Therefore:

- catches and their compositions are taken before this step's recruitment;
- stock-based indices (no fleets) are compared after renewal and before ageing;
- with an annual step, recruits first appear in fleet data the next year, one age older.

Work out what the model's year-Y index and age-a catch correspond to biologically, and whether index
years or observed ages need a shift. Write the decision down (project memory and report).

## 3. Writing gadget3 code

- Build stocks with the pipe: `g3_stock(c(species = "cod", "imm"), seq(5, 100, 1)) |> g3s_age(1, 10) |> g3s_livesonareas(areas)`.
- Use `by_stock = stocks` (a list) for parameters shared by sub-stocks (named `<species>.<par>`),
  `by_stock = TRUE` for per-stock parameters (`<species>_<stock>.<par>`), `prepend_extra =` for fleet prefixes.
- Recruitment: `g3a_renewal_normalparam()` / `_normalcv()` with `factor_f` either free by year
  (`g3_parameterized("rec", by_year = TRUE, scale = ...)`) or a projected process
  (`g3_param_project("rec", g3_param_project_logar1(), scale = "scalar")`). Penalise free recruitment
  with `g3l_random_walk()` or use the log-AR(1) process; true random effects (`random = TRUE`) need
  `nlminb` + Laplace and are not fork-safe.
- Initial population: `g3a_initialconditions_normalparam()` / `_normalcv()` with
  `g3a_renewal_initabund()` (numbers from recruitment, M and init.F) and a proportion by age to split
  between sub-stocks.
- Custom formulas: `g3_formula(quote(...), name = value)`; inside, `stock__num`, `stock__wgt`,
  `stock__midlen`, `age`, `cur_year`, `cur_step` are available; `bounded()`, `avoid_zero()`,
  `dif_pmax()` are model-safe functions (see the formula-language appendix of the reference).
- Never edit generated C++. Change actions and recompile.

## 4. Running a model

```r
actions <- c(time_actions, stock_actions, fleet_actions, likelihood_actions)
tmb_model <- g3_to_tmb(c(actions, list(g3l_bounds_penalty(actions), g3a_report_detail(actions))))
params <- attr(tmb_model, "parameter_template") |> g3_init_val(...)
model <- g3_to_r(actions)                      # R version for debugging
nll <- model(params$value)                    # check finite before fitting
fit_params <- gadgetutils::g3_optim(tmb_model, params, use_parscale = TRUE)
fit <- gadgetutils::g3_fit(tmb_model, fit_params)   # tables for plotting/reporting
```

`g3_fit()` returns `stockdist`, `catchdist.fleets`, `sidat`, `suitability`, `likelihood`,
`stock.std`, `stock.prey`, `fleet.info`, `res.by.year`, `params`, `score` (see helper-packages.md).

## 5. Pitfalls checklist

- Understocking nll of ~1e20 at the start: the initial stock cannot take the catches. Scale
  `rec.scalar`, `init.scalar`, `rec.#`, `init.#` before fitting.
- Parameters at their bounds after fitting: non-identified (e.g. `rec.scalar` vs index catchability),
  mis-specified, or bounds too tight.
- `g3l_distribution_sumofsquares()` divides by `avoid_zero(total)` (floor ≈ 7e-4): tiny model
  catches in some groups get distorted proportions; use a `dif_pmax()` variant (IMR template
  `sumofsquares()`).
- Yearly data without `step` are aggregated over steps; give indices a step.
- Retro by `retro_years` alone is not enough for `surveyindices_log`: truncate the data per peel.
- `__renewalnum` reports are not reset on non-renewal steps.
- Fork-based parallel runs (`mclapply`) do not work on Windows and duplicate memory.
- More in the reference, section 8 (pitfalls, NEWS breaking changes by version).

## 6. Beyond single-stock assessment

Multispecies predation (`g3a_predate()` with stock predators and `g3_suitability_*` by predator
length), migration (`g3a_migrate` with matrices by area), tagging (`g3s_tag`, `g3a_predate_tagrelease`, `g3a_tag_shedding`), sex-split
stocks, MSE with harvest control rules (`g3_quota_*`, g3experiments `g3a_hcr_*`), other food
(`g3a_otherfood`), CKMR (`g3l_ckmr_po`). Published examples: `knowledge/publications.md`.
