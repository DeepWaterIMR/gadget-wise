---
name: gadget-new-model
description: Start a new gadget3 model for a stock — run the structured questionnaire (purpose, stock, years, time steps, areas, sub-stocks, ages and lengths, fleets and surveys, data per fleet, survey indices, natural mortality, recruitment, data-loop BAIT/mfdb/custom, folder format IMR/Icelandic), confirm a plan, then scaffold the project with scaffold_gadget() from config.yaml. Use when the user says 'set up a gadget model for <stock>', 'start a gadget3 assessment', or 'scaffold a gadget-wise project'.
---

<!-- pack-resources:start -->
**Pack resources:** resolve `gadget-wise` from `~/.gadget-wise/config.json` → `gadget_wise_path` (or
`~/.fiskwise/config.json` → `components.gadget-wise.path`). If neither exists, use the checkout
containing this skill, or locate/obtain the pack through its install instructions. Paths such as
`knowledge/`, `config/`, `examples/` and `project-template/` belong to that repository, not the
current model directory. Keep bundled `references/` links relative to the skill. Never assume
`../../` from an agent's global skills folder reaches the repository. Use absolute resolved paths.
<!-- pack-resources:end -->

# Start a new gadget3 model

Goal: turn *"let's build a gadget3 model for `<stock>`"* into a scaffolded project ready for the
workflow. **Ask, plan, then scaffold.** Do not write model code before the plan is agreed.

Read first: `knowledge/workflow.md`, `knowledge/layouts.md`, `knowledge/data-loops.md`,
`knowledge/constraints.md`, `knowledge/wise-writing.md`, and the `gadget-model` skill. wise-writing
must be installed before scaffolding (`academic-writing-install`).

## Step 1 — The questionnaire

Ask in small groups (3-5 questions at a time), offer defaults, accept "don't know" and record it as
an open question. Never invent answers: authors, data sources and decisions come from the user.

**A. Purpose and identity**
1. Purpose: annual assessment, benchmark candidate, research/ecosystem question, MSE, teaching?
2. Stock: common and Latin name, stock code (e.g. ICES `cod.27.1-2`), areas, working group, assessment and advice years.
3. Accountable authors and affiliations (for the documents).
4. Existing model or assessment to follow or compare with (gadget2, SS3, SAM, SPiCT)?

**B. Structure**
5. Years: first model year (a catch-only spin-up period before the data?) and last data year.
6. Time steps: yearly, quarterly, or custom months; when do fisheries and surveys happen within the year?
7. Areas: one or several (migration between them?).
8. Stocks: one stock, or immature + mature sub-stocks (maturity data available?), or sex-split?
   Ages (min = recruitment age, max/plus group) and length range (cm) and model length bin per stock.
9. Growth: von Bertalanffy starting values (Linf, K, t0) and their source; estimate Linf/K?
10. Natural mortality: constant, by age, fixed or estimated; source.
11. Recruitment: log-AR(1) process (default), free with random-walk penalty, or random effects; recruitment age.

**C. Fleets and data**
12. Commercial fleets: names, what defines each (gear, nation, area), catch units and years, shared selectivities.
13. Surveys: names, season, gear, years.
14. Data per fleet: length distributions, age-length (ages read? age reading error?), maturity, sex.
15. Survey indices: biomass or abundance, by length group, from index-wise or another analysis; CVs?
16. Selectivity per fleet: logistic by length (default), dome (Andersen), logistic by age, constant.
17. Data-loop: **BAIT** (IMR Biotic data; default at IMR), **mfdb**, or **custom** files. Landings source.

**D. Project**
18. Folder format: **IMR** (default) or **Icelandic** (`knowledge/layouts.md`).
19. Where to create the project; git remote now or later; server for long runs (`gadget-run`).
20. Documents needed: data report, assessment report, benchmark report, advice sheet, presentation.

## Step 2 — The plan

Summarise the answers as a table and a short plan: structure, data per fleet and its source, the
likelihood components, the timing conventions this implies (`knowledge/action-order.md`: index years,
age offset), first diagnostics, documents. List open questions. Get explicit agreement.

## Step 3 — config.yaml and scaffold

Copy `examples/synthetic/config.yaml`, fill it from the answers (identity block, `LAYOUT`, `MODEL`),
then:

```r
source("<gadget-wise>/scaffold.R")
scaffold_gadget("config.yaml", "<path>/<stock>-gadget", types = c("data-report", "assessment-report"))
```

Add `"benchmark-report"` or `"advice-sheet"` to `types` when asked. `scaffold_gadget()` validates the
config, lays down wise-writing's base, overlays the gadget layer, stamps tokens and reports leftovers.

## Step 4 — After scaffolding

1. `git init` in the project (no remote unless the user asks).
2. Write the questionnaire answers and the plan to `ai/memory/scaffold-interview.md`; add open
   questions and decisions as separate memory notes.
3. Check the project with the synthetic data before real data (optional but recommended):
   `make_synthetic_data("config.yaml", "data/output/model-input")` from `config/make_synthetic_data.R`
   (IMR) and source the run script with `run_optim <- FALSE`: the model must compile.
   Delete the synthetic tables afterwards.
4. Next: `gadget-compile-data`.

## Notes for the Icelandic format

The options are stamped as plain variables into `00-setup/setup.R`; the stock definitions into
`setup-stocks.R`. The mfdb queries in `setup-fleet-data.R`, `setup-catchdistribution.R`,
`setup-indices.R` need the database's sampling types and gear codes. See
[references/iceland-layout.md](references/iceland-layout.md) for how the MFRI models are organised.
