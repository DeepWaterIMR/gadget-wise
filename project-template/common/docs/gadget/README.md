# gadget3 report sections

Quarto partials for the model chapters of a benchmark or assessment report. Include them from the
wise-writing document (`docs/benchmark-report/` or `docs/assessment-report/`):

```markdown
{{< include ../gadget/_model-description.qmd >}}
```

Each partial loads the fitted model from `params$model_dir` (the `YYYYMMDD_model_*` folder) and
reads numbers from it with inline R; nothing is hard-coded. See the `gadget-report` skill.
