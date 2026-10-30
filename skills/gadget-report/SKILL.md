---
name: gadget-report
description: Write the gadget-specific parts of stock assessment, benchmark and advice documents and presentations — model description, data and likelihood, weighting, diagnostics, reference points and projections — as Quarto sections that read the fitted model folder, within wise-writing's report templates and wise-presentations slides. Use when documenting a gadget3 model, writing a benchmark or working-group chapter, or making slides from a gadget model run.
---

<!-- pack-resources:start -->
**Pack resources:** the `gadget-wise` root is `~/.gadget-wise/config.json` → `gadget_wise_path`, else `~/.fiskwise/config.json` →
`components.gadget-wise.path`, else the checkout containing this skill. Paths such as `knowledge/`
and `project-template/` are relative to that root, never `../../` from a skills folder; resolve
links that leave this skill's folder against the source skill there. Use absolute paths.
<!-- pack-resources:end -->

# Report a gadget3 model

wise-writing owns the documents; this skill supplies the gadget content. Read
`knowledge/wise-writing.md`, then the wise-writing skills `academic-style`,
`academic-conventions` and the document type: `academic-benchmark-report`,
`academic-assessment-report`, `academic-advice-sheet`, `academic-data-report`. Slides:
`make-presentation` / `review-presentation` (wise-presentations).

## The partials

`docs/gadget/` holds Quarto partials that read the fitted model folder (`params$model_dir`):

| Partial | Content |
|---|---|
| `_model-description.qmd` | Structure: years, steps, areas, stocks, fleets and selectivity, likelihood components with weights and contributions |
| `_diagnostics.qmd` | Convergence, index fits, residuals, retro (when run) |
| `_reference-points.qmd` | Reference points table (when run) |

Include them from the document (`{{< include ../gadget/_model-description.qmd >}}`) and set
`params: model_dir:` in its YAML to the reported model folder. Extend them; keep every number from
the model by inline R.

## What a gadget model chapter must state

1. **Model type and software**: gadget3 version, TMB, gadgetutils/gadgetplots versions; cite gadget3
   and Begley & Howell (2004) for the framework (`knowledge/publications.md`).
2. **Population structure**: stocks, ages, lengths, length bin, plus groups, areas, time steps, the
   action order within a step and its consequences for index and age timing.
3. **Processes**: growth (von Bertalanffy mean, beta-binomial spread, `maxlengthgroupgrowth`),
   length-weight, maturation, natural mortality, recruitment (process and penalty), initial population.
4. **Fleets**: definitions, catch data, selectivity forms, shared selectivities.
5. **Data and likelihood**: each component (data, years, function), the understocking and bounds
   penalties, weighting (iterative reweighting with grouping and cv_floor), final weights.
6. **Parameters**: estimated vs fixed with values and sources; bounds; number of estimated parameters.
7. **Diagnostics**: convergence, jitter, retro (Mohn's rho), leave-out, profiles, residuals.
8. **Results**: SSB, total biomass, F/harvest rate, recruitment with uncertainty where available.
9. **Reference points and projections** with their settings (see `gadget-projections`).
10. **Alternatives considered** and why rejected (benchmarks).

## Model versioning in documents

Report the model folder name and the model version (`VERSION`, `NEWS.md`; IMR `model_version_label()`)
in figure captions or the document's metadata, so every figure traces to one run.
