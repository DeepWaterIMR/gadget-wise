# gadget3 in one page

gadget3 (Globally applicable Area-Disaggregated General Ecosystem Toolbox, version 3) is an R
package that builds a fisheries or ecosystem model from **actions** and compiles it to an R function
(`g3_to_r()`) or a C++ TMB template (`g3_to_tmb()`). There is no input-file format: the model is an R
script. It re-implements gadget2 (C++ with input files, Begley & Howell 2004) so that gadget2 models
can be reproduced with automatic differentiation, random effects and fast gradient-based fitting.

## Building blocks

| Block | Functions | What it is |
|---|---|---|
| Stock | `g3_stock()` + `g3s_age()`, `g3s_livesonareas()`, `g3s_tag()` | A population with length groups and optionally ages, areas, tags. Sub-stocks (immature/mature, sex) are separate stocks |
| Fleet | `g3_fleet()` | A predator without population: a fishery or a survey |
| Stock action | `g3a_initialconditions_*`, `g3a_naturalmortality()`, `g3a_age()`, `g3a_growmature()`, `g3a_renewal_*()`, `g3a_spawn()`, `g3a_migrate()` | What happens to a stock in each time step |
| Predation | `g3a_predate_fleet()`, `g3a_predate()` with `g3_suitability_*()` and `g3a_predate_catchability_*()` | Fishing (and predation by modelled predators) |
| Likelihood | `g3l_catchdistribution()`, `g3l_abundancedistribution()`, `g3l_understocking()`, `g3l_bounds_penalty()`, `g3l_random_*()` | Compares model output with data, or penalises |
| Parameters | `g3_parameterized()`, `g3_param_project()`, `g3_init_val()` | Every unknown is a named parameter in a template (value, bounds, optimise, parscale, random) |
| Time | `g3a_time()`, `g3_action_order` | Years and steps; the fixed order of actions within a step |

A model is `c(time_actions, stock_actions, fleet_actions, likelihood_actions)`. The order of the list
does not matter: steps are sorted by `g3_action_order` (see `action-order.md`).

## The ecosystem

| Package | Role | Source |
|---|---|---|
| gadget3 | The model | CRAN; development on GitHub `gadget-framework/gadget3` |
| gadgetutils | Data aggregation (`g3_data`), optimisation (`g3_optim`), reweighting (`g3_iterative`), jitter, retro, leave-out, sensitivity, `g3_fit`, `mohnrho` | GitHub |
| gadgetplots | ggplot2 plots of a `g3_fit()` object, `make_html()` summaries | GitHub |
| g3experiments | Experimental: projections (`g3p_*`), harvest control rules, NaN tracing | GitHub (undocumented) |
| mfdb | Fisheries database that aggregates data the way gadget needs (Icelandic models) | CRAN / GitHub; only on request |
| TMB | Compiles and differentiates the C++ | CRAN |

## Uses beyond single-stock assessment

Multispecies and predator-prey models, spatial models with migration, tagging, sex-structured models,
management strategy evaluation and harvest control rules, reference points, climate scenarios and
ecosystem studies (see `publications.md`). gadget3 additionally supports random effects (Laplace),
close-kin mark-recapture likelihoods (`g3l_ckmr_po`) and sparse-sample likelihoods.

## Where the details are

- Function signatures, parameter names, timing, pitfalls: `skills/gadget-model/references/gadget3-reference.md`
- gadgetutils / gadgetplots / g3experiments / mfdb: `skills/gadget-model/references/helper-packages.md`
- Documentation map and gadget2 → gadget3 glossary: `skills/gadget-docs/references/docs-map.md`
- The final authority is the gadget3 source: installed (`gadget3:::fn`, `?fn`) or GitHub.
