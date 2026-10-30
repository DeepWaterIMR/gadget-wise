# Model folder formats

gadget-wise supports two layouts. The gadget3 code is the same kind in both; they differ in how a
project is organised, configured and run. Skills must work in either: detect the layout first.

| | IMR format | Icelandic format |
|---|---|---|
| Detect by | `_RUN_THE_MODEL.R` and `01_settings.R` at the root | `00-setup/setup.R` |
| Origin | IMR deep-water models (reb-gadget, NEA Greenland halibut) | MFRI models in `gadget-framework/gadget-models` (ling, blue ling) |
| Model structure | `config.yaml` `MODEL` section, read at run time | Plain variables at the top of `00-setup/setup.R` |
| Run options | `_RUN_THE_MODEL.R` sections 1-5; `run_scripts/_RUN_WITH.R` overrides | Flags at the top of `setup.R` |
| Pipeline | Numbered scripts `00_` … `14_`, sourced in order | `setup-*.R` sourced by `setup.R` |
| Data | Data-loop (`02-0`, `R/data_loop_<bait|mfdb|custom>.R`) → the data contract in `data/output/model-input/` | mfdb queries in `setup-*-data.R` → `data/*.Rdata` snapshots |
| Default data source | BAIT (IMR Biotic DuckDB) | mfdb |
| Output | `YYYYMMDD_model_<description>/` with `data/ optim/ reweighting/ jitter/ retro/ figures/ scripts/ session/` | `model/<vers>/` with `WGTS/ RETRO/ JITTER/ figs/` |
| Diagnostics | `07_reweighting` … `12_likelihood_profile` | `setup-diagnostics.R` |
| Projections | `13_long_term_projections.R` (reference points), `14_short_term_projections.R` | `setup-advice.R` (g3experiments) |
| Documents | `docs/` (wise-writing), `docs/gadget/` partials | same |

## The data contract (IMR format)

One CSV per data set in `data/output/model-input/`, so any data-loop feeds the same model code:

| File | Columns |
|---|---|
| `catches_<Fleet>.csv` | year, step, area, total_weight (kg) or number |
| `ldist_<Fleet>.csv` | year, step, area, length (cm), number |
| `aldist_<Fleet>.csv` | year, step, area, age, length, number |
| `matp_<Fleet>.csv` | year, step, area, length, maturity_stage (imm/mat), number |
| `index_<Name>.csv` | year, step, area, [length], weight or number, [lwr, upr] |
| `life_history.yaml` | Linf, K, t0, walpha, wbeta, mat_l50, mat_alpha, mat_a50, mat_a_alpha, … |

`R/data_contract.R` validates the tables and bins lengths and ages to `"[lower,upper)"` labels, the
`cut()` form gadget3 parses (`gadget3:::parse_levels`), so mfdb is not needed.

## Converting between layouts

The model code maps one to one (stocks ↔ `setup-stocks.R` + `setup-model.R`, fleets ↔
`setup-fleets.R`, likelihood ↔ `setup-likelihood.R`, parameters ↔ the `g3_init_val()` chain in
`setup.R`). To move a model, port the actions and the parameter chain, then compare the nll of both
at the same parameters: they must agree to rounding.

Icelandic-format detail (file trees, folder-name codes, diagnostics): `skills/gadget-new-model/references/iceland-layout.md`.
