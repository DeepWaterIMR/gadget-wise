# Architecture

- **Skills are layout-independent.** `gadget-model` and `gadget-docs` work in any gadget3 code; the
  workflow skills detect the layout and name the file per layout (`knowledge/layouts.md`).
- **Two templates, both tested** by `config/validate-scaffold.R` with synthetic data
  (`config/make_synthetic_data.R`, `make_synthetic_iceland.R`).
- **IMR format** is a config-driven rewrite of an IMR assessment model's pipeline: model structure in
  `config.yaml` `MODEL`, run options in `_RUN_THE_MODEL.R`, numbered scripts. Stock-specific options
  (index splits, specific fleets) were generalised away; no data, parameter values or weights kept.
- **Data contract** (`R/data_contract.R`): data-loops write CSV tables; the model scripts read only
  those. Lengths and ages are binned to `"[lower,upper)"` labels that gadget3 parses
  (`gadget3:::parse_levels`), so mfdb is not required.
- **Icelandic format** follows the MFRI gadget-models structure (setup.R + setup-*.R, plain-variable
  options, `data/*.Rdata`, `model/<vers>/`); options are stamped from `config.yaml` at scaffold time.
- **wise-writing overlay**: `scaffold_gadget()` calls `scaffold_document()` then overlays
  `project-template/common/` and the layout folder; `gitignore-gadget.txt` is appended to `.gitignore`.
- **References**: `skills/gadget-model/references/*.md` and `gadget-docs/references/docs-map.md` are
  source-referenced digests made from the gadget-framework repositories (October 2026, gadget3
  0.15-1-999, commit 0853fda). Re-check against the source when gadget3 changes.
- **Model versioning in projects** is date-based (`YYYY.MM.DD.N`, `R/version.R`), separate from the
  pack's semantic version.
