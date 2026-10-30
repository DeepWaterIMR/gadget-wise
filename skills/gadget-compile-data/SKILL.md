---
name: gadget-compile-data
description: Compile the data for a gadget3 model — write or run the data-loop (BAIT/IMR Biotic by default, mfdb, or custom), produce the model-input tables (catches, length, age-length and maturity distributions, survey indices, life-history starting values), check sample sizes and timing conventions, and write the data report. Use after a gadget project is scaffolded, when data change, or when the user asks to add a fleet's data or a survey index.
---

<!-- pack-resources:start -->
**Pack resources:** resolve `gadget-wise` from `~/.gadget-wise/config.json` → `gadget_wise_path` (or
`~/.fiskwise/config.json` → `components.gadget-wise.path`). If neither exists, use the checkout
containing this skill, or locate/obtain the pack through its install instructions. Paths such as
`knowledge/`, `config/`, `examples/` and `project-template/` belong to that repository, not the
current model directory. Keep bundled `references/` links relative to the skill. Never assume
`../../` from an agent's global skills folder reaches the repository. Use absolute resolved paths.
<!-- pack-resources:end -->

# Compile the data

Read `knowledge/data-loops.md`, `knowledge/layouts.md` (the data contract) and
`knowledge/action-order.md`. For BAIT, use its skills: `biotic-connect`, `biotic-query`,
`biotic-survey-analysis`, `biotic-lifehistory`, `biotic-privacy`. For mfdb, the mfdb section of
`gadget-model/references/helper-packages.md`.

## Step 1 — Decide per data set

For each fleet and index, agree with the user (and record in the data report):

- selection: survey series / gear / nation / area / months; years used and dropped (with reasons);
- raw counts or raised numbers for compositions; how hauls are weighted;
- length bins of the likelihood (can be coarser than the model's), age groups and plus group;
- maturity scale → immature/mature; sex if used;
- index: source (index-wise assessment index, stratified estimate), unit (biomass/abundance),
  length groups, uncertainty, and the year/age timing convention.

## Step 2 — The data-loop

**IMR format.** Edit `R/data_loop_<bait|mfdb|custom>.R` (chosen by `MODEL$DATA_LOOP`) so that
`run_data_loop()` writes the contract tables to `data/output/model-input/`:

- BAIT: fill `BIOTIC_FILTERS` (one entry per fleet), set `MODEL$BIOTIC_SPECIES` (Norwegian common
  name, verified against `aphia`), adapt the maturity mapping and raising; landings go through
  `prepare_catches()` (official statistics in `data/source/landings.csv`) and indices through
  `prepare_index()` (index-wise `assessment-index.rds` in `data/source/`).
- custom: write the tables from your files.
- Run with `reload_data <- TRUE` in `_RUN_THE_MODEL.R` (or `source("02-0_data_loop.R")` after `01_settings.R`).

**Icelandic format.** Edit the mfdb queries in `00-setup/setup-fleet-data.R`,
`setup-catchdistribution.R`, `setup-indices.R`, `setup-initial_parameters.R`; run once with
`read_data <- TRUE` to write `data/*.Rdata`.

## Step 3 — Life-history starting values

Estimate growth (von Bertalanffy), length-weight and maturity ogives (length and age) from the
individual data, e.g. `ggFishPlots::plot_growth()`, `plot_lw()`, `plot_maturity()`
(`biotic-lifehistory`). Write them to `life_history.yaml` (IMR; format in
`data/output/parameters/README.md`) or `init_param.Rdata` (Icelandic). Weight in kg, length in cm.

## Step 4 — Checks

- Sample sizes per year-step and fleet (the IMR `02-3` script warns below `min_sample`).
- Plots of every composition (`02-3` writes `figures/<Fleet>_ldist.png`) and the indices.
- Catches in kg; surveys have nominal catches.
- Timing: compare observed length at age with the expected model length at age at the sampling step;
  decide the age offset and index year shift (`MODEL$LIKELIHOOD$age_offset`, index `year_shift`).
- Lengths outside the stock length range are clamped into the first/last group: check how many.

## Step 5 — The data report

Use wise-writing `academic-data-report` in `docs/data-report/`: one section per data set with the
selection, the figures, sample sizes, and the decisions above. Numbers by inline R. Then go to
`gadget-build-model`.
