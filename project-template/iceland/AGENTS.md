# AGENTS.md — {{PROJECT_TITLE}}

A gadget3 model of {{STOCK_NAME}} (*{{STOCK_LATIN}}*) in ICES {{ICES_AREAS}}, in the **Icelandic
format** of [gadget-wise](https://github.com/DeepWaterIMR/gadget-wise) (after the MFRI models in
[gadget-models](https://github.com/gadget-framework/gadget-models)). Documents follow
[wise-writing](https://github.com/DeepWaterIMR/wise-writing).

## Read first

- `ai/memory/MEMORY.md`: decisions, known issues and the scaffold interview.
- The gadget-wise skills: `gadget-model`, `gadget-docs`, `gadget-build-model`, `gadget-fit-model`,
  `gadget-diagnostics`, `gadget-projections`, `gadget-report`, `gadget-run`. Use `r-code-style` for R code.

## How the project is organised

| What | Where |
|---|---|
| Options (plain variables) and the run order | `00-setup/setup.R` |
| Stocks and stock actions | `00-setup/setup-stocks.R`, `setup-model.R` (or `setup-model-single-stock.R`) |
| Fleets, likelihood, recruitment penalty | `00-setup/setup-fleets.R`, `setup-likelihood.R`, `setup-randomeffects.R` |
| Data (mfdb queries, `read_data <- TRUE`) | `00-setup/setup-fleet-data.R`, `setup-catchdistribution.R`, `setup-indices.R`, `setup-initial_parameters.R` |
| Data snapshots | `data/*.Rdata` (gitignored) |
| Diagnostics and advice | `00-setup/setup-diagnostics.R`, `setup-advice.R` |
| Model versions | `model/<vers>/` (gitignored): `WGTS/`, `RETRO/`, `JITTER/`, `figs/` |
| Documents | `docs/` (Quarto; wise-writing) |

Sub-scripts share globals and are re-sourced in loops (`peel` for retro, `boot_repl` for
bootstrap): keep data subsetting in `setup-likelihood.R`.

## Rules

- Never commit data, snapshots or model output.
- Name each model version `model/<NN>-<label>_<setting codes>` (or `model/<wg>_<year>` for an assessment) and keep its `fit.Rdata`.
- Reweight (`g3_iterative`) after data or structure changes; run diagnostics on `params_final`.
- Long runs go to a server in a screen session with a log in `logs/` (`gadget-run`).
- Check gadget3 behaviour in the installed source, not in gadget2 documentation.
