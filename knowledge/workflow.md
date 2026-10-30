# Workflow

| Step | Skill | Produces |
|---|---|---|
| 0. Understand gadget3 / find docs | `gadget-model`, `gadget-docs` | — |
| 1. Start a model (questionnaire, plan, scaffold) | `gadget-new-model` | Project folder, `config.yaml`, memory |
| 2. Compile the data (data-loop, data report) | `gadget-compile-data` | Model-input tables, data report |
| 3. Build or change the model | `gadget-build-model` | Stocks, fleets, likelihood, parameters that compile and give a finite nll |
| 4. Fit and reweight | `gadget-fit-model` | Optimised parameters, weights, fit |
| 5. Diagnose | `gadget-diagnostics` | Jitter, retro, leave-out, profiles, residual checks |
| 6. Project | `gadget-projections` | Reference points, catch scenarios |
| 7. Report | `gadget-report` | Benchmark/assessment chapters, advice, slides |
| Long runs | `gadget-run` | Detached runs with logs |
| Install / update | `gadget-install`, `gadget-update` | — |

Steps 3-5 loop: a structural change means rebuild → refit → reweight → diagnose. Every run goes to a
new dated model folder; record what changed in `NEWS.md` and why in `ai/memory/`.
