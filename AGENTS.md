# AGENTS.md — gadget-wise

gadget-wise is part of [Fiskwise](https://deepwaterimr.github.io/fiskwise/). See the
[ecosystem repository](https://github.com/DeepWaterIMR/fiskwise) for the canonical pack names.

You are helping a scientist build, modify, fit, diagnose, project or report a **gadget3** model
([gadget-framework](https://github.com/gadget-framework)) for any stock or ecosystem question. You
write **R** with **tidyverse** syntax and **Quarto** documents, and you use the gadget3 packages:
gadget3, gadgetutils, gadgetplots and g3experiments. mfdb only when the user asks for it or their
data are in mfdb.

> Entry point for Codex, Cursor, Gemini CLI and other agents. Claude Code reads
> [`CLAUDE.md`](CLAUDE.md). Keep substantive guidance in sync.

## What gadget-wise is

A **vendor-neutral knowledge pack** — not a trained model and not a project you fill in place. It
teaches an agent gadget3 and **generates a new project folder** in one of two formats (IMR,
Icelandic). The skills work in any gadget3 project, whatever its structure.

It sits on [wise-writing](https://github.com/DeepWaterIMR/wise-writing), which owns the project
skeleton, scientific style, document templates and rendering; `scaffold.R` calls its
`scaffold_document()`. Install wise-writing on demand before scaffolding. Use the installed
**`r-code-style`** skill for every R task. Keep gadget-wise usable without Fiskwise. In managed
mode, follow `fiskwise-install`, `fiskwise-update` or `fiskwise-uninstall`; honour saved R-install
consent, disabled toggles and `renv.lock`. BAIT is needed only for IMR Biotic data; index-wise only
for sdmTMB survey indices; Biotic database refresh is a separate opt-in BAIT action.

## How to work

1. **Route** with the skills (README table). For any gadget3 question start with `gadget-model`;
   for "where is this documented" `gadget-docs`; new model `gadget-new-model`.
2. **Detect the layout** of an existing project (`knowledge/layouts.md`) before editing.
3. **Check gadget3 behaviour in the installed source** before relying on a signature, default or
   parameter name (`args()`, `gadget3:::fn`, GitHub). The references in
   `skills/gadget-model/references/` cite file:line for gadget3 0.15-1-999 (October 2026).
4. **Never mix gadget2 and gadget3** (`knowledge/constraints.md`, `gadget-docs`).
5. **Follow the hard constraints** in `knowledge/constraints.md`.

## Repository map

| Path | Purpose |
|---|---|
| `skills/gadget-*/` | The twelve skills; `references/` are bundled detail |
| `knowledge/` | Shared source of truth; prefer improving it over repeating guidance in skills |
| `project-template/common/` | Report partials (`docs/gadget/`) and project memory skeleton |
| `project-template/imr/` | IMR-format model template (tested) |
| `project-template/iceland/` | Icelandic-format model template (tested) |
| `scaffold.R` | `scaffold_gadget(config, target)` |
| `config/` | `validate-scaffold.R`, synthetic data generators |
| `examples/synthetic/` | Filled `config.yaml` |
| `memory/` | Development memory of this pack (not of generated projects) |

## Confidentiality

**Public repository: never commit data, model output, parameter values from real assessments, or
private paths.** Examples use synthetic values. Generated projects keep data and runs out of git.

## Versioning

Fiskwise version policy: every ordinary commit increments the patch version by 0.0.1 and updates the
date in `VERSION` (the `.githooks/pre-commit` hook does it: `git config core.hooksPath .githooks`).
Minor or major bumps only on explicit request.
