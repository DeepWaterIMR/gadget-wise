---
name: gadget-diagnostics
description: Diagnose a fitted gadget3 model — jitter (global optimum), retrospective analysis and Mohn's rho, leave-out of data components, likelihood profiles (natural mortality, catchability, any parameter), residual patterns, parameter uncertainty (sdreport), and comparison of model variants. Use after a fit, when choosing between candidate models in a benchmark, or when the user asks whether a model is stable or which data drive it.
---

<!-- pack-resources:start -->
**Pack resources:** the `gadget-wise` root is `~/.gadget-wise/config.json` → `gadget_wise_path`, else `~/.fiskwise/config.json` →
`components.gadget-wise.path`, else the checkout containing this skill. Paths such as `knowledge/`
and `project-template/` are relative to that root, never `../../` from a skills folder; resolve
links that leave this skill's folder against the source skill there. Use absolute paths.
<!-- pack-resources:end -->

# Diagnose the model

Run diagnostics on the reweighted fit (IMR: `optim_param` after reweighting; Icelandic:
`params_final`). They are slow: `gadget-run`. Functions: `gadgetutils::g3_jitter`, `g3_retro`,
`g3_leaveout`, `g3_sensitivity`, `mohnrho`; plots `gadgetplots::plot_jitter`, `plot_retro`,
`plot_leaveout` (see `gadget-model/references/helper-packages.md`).

| Diagnostic | IMR | Icelandic | Question | Accept when |
|---|---|---|---|---|
| Jitter | `09_jitter.R` (`run_jitter`) | `setup-diagnostics.R` | Is the optimum global? | nll spread across jitters ≤ ~1 unit; same trajectories |
| Retro | `10_retro.R` (`run_retro`, `retro_peels`) | `run_retro` | Are estimates stable when years are removed? | Mohn's rho of SSB and F within −0.15–0.20 (long-lived) or −0.22–0.30 (short-lived) (ICES rule of thumb) |
| Leave-out | `11_leaveout.R` | `run_leaveout` | Which data drive the estimates; are data sources in conflict? | No single source flips the conclusions without explanation |
| Profile | `12_likelihood_profile.R` (`profile_parameter`, `profile_values`) | loop in `setup-diagnostics.R` | Is a fixed value (M, catchability) supported; which data pull which way? | The chosen value is near the total minimum or the choice is justified |
| Residuals | `plot_resid`, `plot_ldist` | same | Structural misfit? | No trends by year, length, age or fleet |
| Uncertainty | `TMB::sdreport(g3_tmb_adfun(tmb_model, p), g3_tmb_par(p))` | same | CIs of SSB, recruitment | Hessian positive definite |

## Notes

- **Jitter** perturbs each parameter by ±`jitter_fraction` on the optimiser's scale. 0.1 only probes
  the neighbourhood; use wider jitters to test globality, but less for log-recruitment (a few weak
  year classes make the start infeasible). Compile once before forking (`g3_tmb_adfun`).
- **Retro**: rebuild the likelihood with data truncated per peel (the template does); re-optimise
  each peel from the same start with the final weights. Report rho with lag (F and recruitment lag 1).
- **Leave-out**: by fleet or data type, re-optimised (not reweighted unless stated).
- **Profiles**: fix the parameter at each value and re-optimise; plot total nll and each component
  relative to its minimum. Components with opposite slopes are in conflict.
- **Comparing variants**: same data and likelihood → compare nll; different data or weights → compare
  diagnostics, retro, residuals and plausibility, never raw nll. Keep a comparison table
  (variant, change, nll by component, rho, key estimates) in the report.
- A failed diagnostic means changing the model (`gadget-build-model`) or the data, not hiding the
  result. Record outcomes in `ai/memory/`.
