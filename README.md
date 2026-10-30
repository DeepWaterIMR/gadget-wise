[![Part of Fiskwise](https://deepwaterimr.github.io/fiskwise/assets/part-of-fiskwise.svg)](https://deepwaterimr.github.io/fiskwise/)

# 🐟 gadget-wise — Build gadget3 models with AI agents

<!-- version -->
**Version 0.1.1** (2026-10-30)
<!-- /version -->

This repository is part of [Fiskwise](https://github.com/DeepWaterIMR/fiskwise), with its [project hub](https://deepwaterimr.github.io/fiskwise/).

**Teach your AI coding agent to build, fit, diagnose and report [gadget3](https://gadget-framework.github.io/gadget3/) models — for any stock, in a standard folder structure, on your own machine.**

gadget-wise is a knowledge pack that turns a general coding agent (Claude Code, Codex, Cursor, Gemini CLI, …) into a competent assistant for **gadget3**, the TMB-based Globally applicable Area-Disaggregated General Ecosystem Toolbox of the [gadget-framework](https://github.com/gadget-framework). It covers the whole model: stocks, growth, maturation, recruitment, fleets, likelihood, parameters, fitting and reweighting, diagnostics, projections and reference points, and the report. It works for any gadget user, not only at the Institute of Marine Research: the skills are independent of the folder structure, and two structures are supported.

Tell your agent which stock you want modelled, and it will:

1. **Ask you a structured questionnaire** (stock, years, steps, stocks, fleets, data, data source, folder format) and confirm a plan.
2. **Scaffold a project** in the **IMR format** or the **Icelandic format**, on top of wise-writing's document structure.
3. **Compile the data** through a data-loop: IMR Biotic data via [BAIT](https://github.com/DeepWaterIMR/BAIT) by default, [mfdb](https://github.com/gadget-framework/mfdb), or your own files.
4. **Build, fit, reweight and diagnose** the model, **project** it for reference points and catch options, and **write** the benchmark or assessment chapter.

> **It is not a trained model.** Your data never leave your machine and never enter any model's weights. The agent reads this repository while it helps you. See [Confidentiality](#-confidentiality).

## 🚀 Quickstart

1. **Install gadget-wise:**
   ```
   install https://github.com/DeepWaterIMR/gadget-wise
   ```
   The agent runs [`gadget-install`](skills/gadget-install/SKILL.md): clone → install the skills globally → check the gadget3/TMB toolchain. With Fiskwise: `install Fiskwise` and choose gadget-wise.
2. **Start a model:**
   ```
   Let's set up a gadget3 model for tusk in ICES 5a and 14 using gadget-wise.
   ```
   The agent runs [`gadget-new-model`](skills/gadget-new-model/SKILL.md).
3. **Or ask anything about gadget3** in an existing model ("why does my index include this year's recruits?", "add a dome-shaped survey", "where is this documented?"): [`gadget-model`](skills/gadget-model/SKILL.md) and [`gadget-docs`](skills/gadget-docs/SKILL.md) work in any gadget3 project.

## 🧰 The skills

| Skill | Use |
|---|---|
| [`gadget-model`](skills/gadget-model/SKILL.md) | **Universal**: how gadget3 works — stocks, actions and their order, growth, maturation, recruitment, fleets, likelihood, parameters, compilation, pitfalls, uses beyond assessment |
| [`gadget-docs`](skills/gadget-docs/SKILL.md) | Find the right documentation; tell gadget2 from gadget3; gadget2 → gadget3 glossary |
| [`gadget-new-model`](skills/gadget-new-model/SKILL.md) | Questionnaire, plan, scaffold (IMR or Icelandic format) |
| [`gadget-compile-data`](skills/gadget-compile-data/SKILL.md) | Data-loop (BAIT, mfdb, custom), model inputs, data report |
| [`gadget-build-model`](skills/gadget-build-model/SKILL.md) | Add or change stocks, fleets, likelihood, parameters; compile and debug |
| [`gadget-fit-model`](skills/gadget-fit-model/SKILL.md) | Optimise, iterative reweighting, convergence, the fit |
| [`gadget-diagnostics`](skills/gadget-diagnostics/SKILL.md) | Jitter, retro and Mohn's rho, leave-out, likelihood profiles, model comparison |
| [`gadget-projections`](skills/gadget-projections/SKILL.md) | Reference points and catch scenarios |
| [`gadget-report`](skills/gadget-report/SKILL.md) | Model chapters, advice and slides with wise-writing and wise-presentations |
| [`gadget-run`](skills/gadget-run/SKILL.md) | Long runs detached with logs |
| [`gadget-install`](skills/gadget-install/SKILL.md), [`gadget-update`](skills/gadget-update/SKILL.md) | Lifecycle |

## 🗂️ Two folder formats

| | IMR format | Icelandic format |
|---|---|---|
| From | IMR deep-water models (beaked redfish, NEA Greenland halibut) | MFRI models in [gadget-models](https://github.com/gadget-framework/gadget-models) |
| Run | `source("_RUN_THE_MODEL.R")` | `source("00-setup/setup.R")` |
| Model structure | `config.yaml` (`MODEL`), numbered scripts `00_`–`14_` | Plain variables in `setup.R`, `setup-*.R` |
| Data | Data-loop → a data contract of CSV tables | mfdb queries → `data/*.Rdata` |
| Output | `YYYYMMDD_model_<description>/` | `model/<vers>/` |

Both templates are tested: [`config/validate-scaffold.R`](config/validate-scaffold.R) scaffolds each from the [synthetic example](examples/synthetic/config.yaml), compiles the model and fits it. See [`knowledge/layouts.md`](knowledge/layouts.md).

## 📚 What's in this repo

- [`AGENTS.md`](AGENTS.md) / [`CLAUDE.md`](CLAUDE.md) — the agent contract.
- [`skills/`](skills/) — the twelve `gadget-*` skills; `gadget-model/references/` holds a source-referenced digest of gadget3 and its helper packages, `gadget-docs/references/` the documentation map.
- [`knowledge/`](knowledge/) — gadget3 in one page, action order and timing, folder formats and the data contract, data-loops, constraints, packages, the wise-writing contract, the workflow, and [publications using Gadget](knowledge/publications.md).
- [`project-template/`](project-template/) — `common/` (report partials, memory), `imr/` and `iceland/` model templates.
- [`scaffold.R`](scaffold.R) — `scaffold_gadget()`.
- [`examples/synthetic/`](examples/synthetic/) — a filled `config.yaml` for a synthetic stock.

## ✍️ Built on wise-writing, part of Fiskwise

gadget-wise owns the gadget3 model layer. [wise-writing](https://github.com/DeepWaterIMR/wise-writing) owns the project layout, scientific style, document templates (data report, assessment report, benchmark report, advice sheet) and rendering; `scaffold.R` calls its `scaffold_document()`. [wise-presentations](https://github.com/DeepWaterIMR/wise-presentations) makes the slides. Related packs:

- [BAIT](https://github.com/DeepWaterIMR/BAIT) — IMR Biotic data: the default data-loop for IMR users.
- [index-wise](https://github.com/DeepWaterIMR/index-wise) — sdmTMB survey indices; its versioned assessment index feeds a gadget model's survey indices.
- [spict-wise](https://github.com/DeepWaterIMR/spict-wise) — SPiCT surplus production assessments, often run beside a gadget model.
- [ggFishPlots](https://github.com/DeepWaterIMR/ggFishPlots) — growth, maturity and length-weight starting values.

Use `fiskwise-workflow` for requests spanning packs. For R code, always `r-code-style`.

## 🔒 Confidentiality

This repository holds **instructions and code only — never data or model output**. The IMR template is distilled from an IMR assessment model with all stock data, outputs, parameter values and internal paths removed. Model projects keep raw data, model inputs and runs out of git (`.gitignore`), and Biotic data follow BAIT's privacy rules.

## 📖 Citation and credits

gadget3: Lentin, Elvarsson, Butler and contributors, [gadget-framework/gadget3](https://github.com/gadget-framework/gadget3). Gadget: Begley & Howell (2004), ICES CM 2004/FF:13. Iterative reweighting: Taylor et al. (2007). gadget-wise is maintained by the Deep-water species and cartilaginous fish group at the Institute of Marine Research. License: GPL-3.
