# AGENTS.md — {{PROJECT_TITLE}}

A gadget3 model of {{STOCK_NAME}} (*{{STOCK_LATIN}}*) in ICES {{ICES_AREAS}}, in the **IMR format**
of [gadget-wise](https://github.com/DeepWaterIMR/gadget-wise). Built on
[wise-writing](https://github.com/DeepWaterIMR/wise-writing) for the documents.

## Read first

- `ai/memory/MEMORY.md`: decisions, known issues and the scaffold interview. Load the relevant notes before any task.
- The gadget-wise skills: `gadget-model` (how gadget3 works), `gadget-docs` (where to look things up),
  `gadget-build-model`, `gadget-fit-model`, `gadget-diagnostics`, `gadget-projections`, `gadget-report`, `gadget-run`.
- Use `r-code-style` for all R code.

## How the project is organised

| What | Where |
|---|---|
| Model structure (stocks, fleets, likelihood, years) | `config.yaml`, section `MODEL` |
| Options of one run | `_RUN_THE_MODEL.R`, sections 1-5 |
| Pipeline | `00_run_first.R` … `14_short_term_projections.R`, sourced in order by `_RUN_THE_MODEL.R` |
| Data-loop (where data come from) | `02-0_data_loop.R` + `R/data_loop_<bait|mfdb|custom>.R` |
| Model-input tables (the data contract) | `data/output/model-input/` (`R/data_contract.R`) |
| Helpers | `R/` |
| Model runs | `YYYYMMDD_model_<description>/` (gitignored) |
| Documents | `docs/` (Quarto; wise-writing) |

Each numbered script depends on the objects of the scripts before it; the header of each script
lists what it creates.

## Rules

- **Never commit data or model output.** Raw data in `data/source/`, model inputs in
  `data/output/`, runs in `YYYYMMDD_model_*` are gitignored.
- Change the model **structure** in `config.yaml` and the scripts, the **run** in `_RUN_THE_MODEL.R`
  or with `run_scripts/_RUN_WITH.R`. One run per `base_dir` at a time.
- After a change that alters results, bump the model version (`bump_version()`, `R/version.R`) and
  describe it in `NEWS.md`.
- Long runs (reweighting, jitter, retro, projections) go to a server in a screen session with a
  log in `logs/` (`gadget-run`).
- Reweight again when the data or the structure change; paste the weights into `06_parameters.R`.
- Check gadget3 behaviour in the installed source (`gadget3:::` / GitHub), not in gadget2 documentation.
