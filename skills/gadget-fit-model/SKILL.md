---
name: gadget-fit-model
description: Fit a gadget3 model — optimise with gadgetutils::g3_optim (BFGS with parscale), run iterative reweighting of likelihood components with g3_iterative (grouping, cv_floor), check convergence, gradients and parameters at bounds, extract the fit with g3_fit and make the HTML summary. Use when the user asks to fit, refit, reweight or re-optimise a gadget3 model, or when a fit fails to converge.
---

<!-- pack-resources:start -->
**Pack resources:** resolve `gadget-wise` from `~/.gadget-wise/config.json` → `gadget_wise_path` (or
`~/.fiskwise/config.json` → `components.gadget-wise.path`). If neither exists, use the checkout
containing this skill, or locate/obtain the pack through its install instructions. Paths such as
`knowledge/`, `config/`, `examples/` and `project-template/` belong to that repository, not the
current model directory. Keep bundled `references/` links relative to the skill. Never assume
`../../` from an agent's global skills folder reaches the repository. Use absolute resolved paths.
<!-- pack-resources:end -->

# Fit and reweight

Read the gadget-model skill (sections 4-5) and `gadget-model/references/helper-packages.md`
(g3_optim, g3_iterative, g3_fit). Long runs go through `gadget-run`.

## 1. Before fitting

- The nll at the starting values is finite and not dominated by understocking or bounds penalties.
- Every optimised parameter has bounds and starts inside them.
- The likelihood weights are either the snapshot for this data set and structure, or the run
  includes reweighting.

## 2. Optimise

IMR: `run_optim <- TRUE` in `_RUN_THE_MODEL.R` (`08_optimise.R`). Directly:

```r
optim_param <- gadgetutils::g3_optim(tmb_model, tmb_param, use_parscale = TRUE, method = "BFGS",
                                     control = list(maxit = 3000), print_status = TRUE)
attributes(optim_param)$summary   # convergence, score, gd_calls
optim_fit <- gadgetutils::g3_fit(tmb_model, optim_param)
gadgetplots::make_html(optim_fit, path = "<model folder>/figures")
```

Check: convergence TRUE; `g3_optim` warning about non-finite gradients; parameters at their bounds
(`08_optimise.R` warns); the maximum gradient component (`TMB` obj `$gr()`) small. Not converged at
maxit: restart from the result (`previous_model_params_as_initial`) or look for a flat direction.

## 3. Iterative reweighting

Weights are set so each component's weighted residual variance is about 1 (Taylor et al. 2007).
`g3_iterative()`:

1. sets the weight of each group to 1 / its residual variance from a fit where only that group is
   upweighted (stage 1), then
2. refits with all weights to give the final parameters (`params_final`, stage 2).

Grouping: components that inform the same thing are reweighted together, so a single component
cannot be fitted perfectly at the expense of the rest. Defaults: one group per fleet (its ldist,
aldist, matp), and the survey indices either one group each or all together (several length-group
indices from one survey usually as one group). `cv_floor` caps the index weights at 1 / cv_floor
(e.g. 4e-4 → 2500); without it an index the model can fit almost exactly gets an enormous weight.

IMR: `run_reweighting <- TRUE` (`07_reweighting.R`), then paste the printed weights into
`06_parameters.R` (`model_weights`) so later runs (retro, projections, variants) reuse them.
Icelandic: `run_iterative <- TRUE`; `params_final` is saved in `model/<vers>/WGTS/`.

Reweight again when the data, the likelihood components or the structure change. Report the final
weights and any manual adjustments (e.g. downweighting an early index segment), with the reason.

## 4. Read the fit

Look at, in this order: survey index fits (`plot_si`), composition fits and residuals (`plot_ldist`,
`plot_agecomp`, `plot_resid`), likelihood by component (`plot_likelihood`), selectivity
(`plot_suitability`), growth (`plot_growth`), biomass/SSB/F/recruitment (`plot_biomass`, `plot_f`,
`plot_rec`). Systematic residual patterns are structural problems, not weighting problems.

Then `gadget-diagnostics`.
