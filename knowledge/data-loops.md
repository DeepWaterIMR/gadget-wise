# Data-loops

A data-loop is the code that pulls data from their sources and turns them into model inputs. Keep it
separate from the model, so the model can be rerun without database access and the data can be
updated without touching the model.

| Loop | For | How |
|---|---|---|
| **BAIT** (default, IMR) | IMR Biotic data | `R/data_loop_bait.R` reads the local BioticExplorer DuckDB (BAIT skills `biotic-connect`, `biotic-query`, `biotic-survey-analysis`). Landings from BAIT `catch-data` (Norwegian sales notes) or official statistics; survey indices from index-wise |
| **mfdb** (default, Icelandic format) | Users with an mfdb database | `mfdb_sample_count()`, `mfdb_sample_totalweight()` with `mfdb_interval()`/`mfdb_group()` and a `defaults` list (area, timestep, year, species) |
| **custom** | Anything else | Your code writes the contract tables |

## Rules

- Raw extracts stay local (`data/source/`, gitignored). Model inputs (`data/output/`) are gitignored too.
- Every selection (gear, survey series, area, months, maturity scale) is a stock-specific decision:
  record it in the data report with the reason.
- Compositions: decide raw counts vs raised numbers (catch-sample raising) and document it; for
  surveys follow `biotic-survey-analysis` (true zeros, sampling units).
- Survey indices for gadget usually come from a separate analysis: the **index-wise** assessment index
  (`assessment-index.rds`, the [versioned hand-off](https://github.com/DeepWaterIMR/index-wise/blob/main/knowledge/assessment-index-handoff.md), read by `prepare_index()` in the
  IMR template) or a stratified index. Keep its provenance. Ask whether anomalous years were
  checked with index-wise's [influence
  diagnostics](https://github.com/DeepWaterIMR/index-wise/blob/main/knowledge/influence-diagnostics.md):
  an AR1 index spreads a one-cruise coverage artefact into neighbouring years, which gadget then
  fits as recruitment or growth.
- Life-history starting values (growth, length-weight, maturity): estimate them in the data report,
  e.g. with ggFishPlots (`biotic-lifehistory`), and write `life_history.yaml`.
- Check sample sizes per year-step; drop or merge years with too few fish and say so.
