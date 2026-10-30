# Open issues

- The BAIT data-loop (`R/data_loop_bait.R`) is a skeleton checked against the `indall` column names
  only; raising and survey-sample qualification must follow `biotic-survey-analysis` per stock.
- The mfdb data-loops (IMR `R/data_loop_mfdb.R`, Icelandic `setup-*-data.R`) are untested without
  an mfdb database.
- The Icelandic `setup-advice.R` is a stub pointing to g3experiments; the full projection workflow is
  in the IMR template (13/14).
- The synthetic data are not simulated from a gadget3 model, so the synthetic fits do not recover
  known values; they test that the templates compile and fit.
- `docs/gadget/` partials are not yet render-tested inside a wise-writing document.
- Publication list: entries tagged [unverified]/[inferred] in `knowledge/publications.md` need checking.
- Tested on synthetic data (2026-10-30): both layouts scaffold, compile and fit; IMR reweighting,
  jitter, retro (Mohn's rho), leave-out, profile and long/short-term projections run. The Icelandic
  `setup-diagnostics.R` (retro, jitter, leave-out) is not yet run-tested.
