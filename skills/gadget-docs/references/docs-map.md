# Gadget documentation map (gadget2 vs gadget3) - digest for the gadget knowledge pack

Sources: the gadget-framework GitHub repositories (HEAD commits as of 2026-10-30; "freshness" = HEAD commit date) and the published sites. Re-check dates before relying on them.
Legend: G2 = gadget2 / Rgadget era (C++ binary, text input files); G3 = gadget3 (R package producing R/TMB objective function). OBSOLETE = do not use as source for new gadget3 work (still valid for understanding concepts or reading legacy models).

---------------------------------------------------------------------------
## 1. Documentation locations

| # | Item | URL | Repo path (clone) | Ver | Topic | Freshness | Status |
|---|------|-----|-------------------|-----|-------|-----------|--------|
| 1 | gadget2 user guide (bookdown, 17 chapters) | https://gadget-framework.github.io/gadget2/userguide/ (chapter pages `chap-stock.html`, `chap-like.html`, `chap-order.html` ...) | `gadget2/docs/userguide/index.Rmd` (6608 lines) | G2 | Input file formats and model equations for the gadget2 binary | clone HEAD 2026-06-19 (merge commit, content older: describes 2.1.x-2.3.x) | Format details OBSOLETE for gadget3; equations/concepts CURRENT (gadget3 cites chap-order and chap-like) |
| 2 | gadget2 landing page | https://gadget-framework.github.io/gadget2/ | `gadget2/docs/index.Rmd` | G2 | Links to user guide, reference manual, course | 2026-06-19 | G2 |
| 3 | gadget2 source / man page | https://github.com/gadget-framework/gadget2 | `gadget2/src`, `gadget.1`, `gadget2/DESCRIPTION` (Version 2.3.99, Date 2023-04-11) | G2 | C++ code (the `gadget` executable), example models in `examples/` | 2026-06-19 | G2 maintenance only |
| 4 | gadget3 pkgdown (release docs) | https://gadget-framework.github.io/gadget3/ | `gadget-framework.github.io/gadget3/` (built 2026-01-12, pkgdown 2.2.0; nav shows version 0.15-1) | G3 | Reference (`reference/`), 7 articles, changelog | built 2026-01-12 | CURRENT stable. Changelog page lists 0.15-0 and earlier |
| 5 | gadget3-master pkgdown (development docs) | https://gadget-framework.github.io/gadget3-master/ | `gadget-framework.github.io/gadget3-master/` (built 2026-10-08, nav shows 0.15-1-999) | G3 dev | Same structure as 4 but tracks git master | built 2026-10-08 | CURRENT, may document functions not on CRAN yet (e.g. `g3_param_project_bootstrap`, `from_year_f` args, per NEWS 0.15-1-999). A copy also sits in `gadget3/master/` inside the release site |
| 6 | gadget3 source | https://github.com/gadget-framework/gadget3 | `gadget3/` (DESCRIPTION 0.15-1-999, Date 2026-01-12; HEAD 2026-10-08) | G3 | R sources `R/*.R` (action_*.R, likelihood_*.R, stock*.R, run_tmb.R ...), `NEWS.md`, `man/*.Rd` | 2026-10-08 | CURRENT |
| 7 | gadget3 articles (vignettes) | https://gadget-framework.github.io/gadget3/articles/ | `gadget3/vignettes/*.Rmd`, `vignettes/articles/random-effect-recruitment.Rmd` | G3 | see section 2 | 2026-10-08 | CURRENT |
| 8 | gadgetutils | https://github.com/gadget-framework/gadgetutils (no pkgdown site; README is a stub) | `gadgetutils/` v0.0.0.9000 | G3 | `g3_fit`, `g3_iterative`, `g3_optim`, `g3_retro`, `g3_jitter`, `g3_leaveout`, `g3_sensitivity`, `g3_init_guess`, `mohnrho`, ... | 2026-10-22 | CURRENT (active development, unstable API) |
| 9 | gadgetplots | https://gadget-framework.github.io/gadgetplots/ | `gadgetplots/` v0.3.11, `docs/` (pkgdown), `CLAUDE.md` | G3 | `gadget_plots()`, `make_html()`, `plot_*` on a `g3_fit` object | 2026-10-26 | CURRENT |
| 10 | g3experiments | https://github.com/gadget-framework/g3experiments | `g3experiments/` v0.3.999 (DESCRIPTION date 2022-10-07, HEAD 2026-01-15); no roxygen docs; `exportPattern("^g3\\w+?_|^proj_.+")` | G3 | experimental: `g3a_report_stock_better`, hcr actions (`action_hcr.R`, `action_sam_hcr.R`), `g3p_project.R` (projection helpers `g3p_setup_pars`), `hockey_fleet.R`, `proj_stock_actions.R` | 2026-01-15 | EXPERIMENTAL; some content migrated into gadget3 (`g3l_bounds_penalty`, `g3a_trace_*`, quota functions). Check before use |
| 11 | mfdb pkgdown | https://gadget-framework.github.io/mfdb/ | `gadget-framework.github.io/mfdb/` ; source `mfdb/` v7.4-0-999 (2026-01-24) ; HEAD 2026-06-16 | both | Marine Ecosystem Database: import (`mfdb_import_*`), query (`mfdb_sample_count`, `mfdb_sample_totalweight`, `mfdb_survey_index_*`, `mfdb_stomach_*`), grouping (`mfdb_group`, `mfdb_interval`, `mfdb_timestep_quarterly`, `mfdb_bootstrap_group`), dplyr access (`mfdb_dplyr_sample`...) | pkg site built 2026-10-08 | CURRENT. NOTE gadget2-only parts: `gadget_directory`, `gadget_dir_write`, `gadget_file`, `gadget_areafile`, `gadget_fleet_component`, `gadget_likelihood_component`, `gadget_stockfile_*`, `read.gadget_file` (these write gadget2 text files). In gadget3 you pass the query result data.frame directly to `g3l_*` / `g3_timeareadata` |
| 12 | mfdb articles | https://gadget-framework.github.io/mfdb/articles/ | `mfdb/vignettes/*.Rmd` | both | `import_hydrography_cmems`, `population`, `tow_data`, `trip`, `weightmeasurements` (data-model/import topics) | 2026-10-08 | CURRENT |
| 13 | gadget-framework.github.io landing | https://gadget-framework.github.io/ | `gadget-framework.github.io/index.html` | both | Lists Gadget3 block (gadget3, gadget-utils, gadgetplots, gadget-models) and Gadget2 block (gadget2, rgadget, gadget-course, Gadget2 paper) and MFDB | 2026-10-08 | CURRENT index |
| 14 | gadget-course (bookdown) | https://hafro.github.io/gadget-course/ (README); also linked as https://gadget-framework.github.io/gadget-course/ | `gadget-course/*.Rmd` (see section 3), `_bookdown.yml` chapter order | **G2 only** (Rgadget) | Course on building gadget2 models with Rgadget | HEAD 2021-03-16 | OBSOLETE for model building; useful for concepts (growth, maturation, iterative reweighting) |
| 15 | gadget-models | https://github.com/gadget-framework/gadget-models (fishvice/gadget-models in older links) | `gadget-models/` | both | Informal Icelandic model repository; see `iceland-layout.md` | 2026-03-23 | README lists three gadget3 models: 06-ling/gadget3, 07-bling/gadget3, vendace/g3_vendace. In the clone also `07-bling/gadget3 - WKBDEEP` (most complete) |
| 16 | Publications | https://gadget-framework.github.io/publications/ | `gadget-framework.github.io/publications/`, source in `publications/` repo | G3 / history | see section 6 | 2026-10-08 / 2026-10-14 | mixed |
| 17 | gadget2to3 converter | https://github.com/gadget-framework/gadget2to3 | not cloned | G2->G3 | Converts gadget2 model configuration to gadget3 (listed in gadget3 README) | unknown | status unverified |
| 18 | Rgadget | https://github.com/hafro/rgadget (linked as "rgadget") | not cloned | G2 | R utilities for gadget2 (`gadget.iterative`, `gadget.fit`, `gadget.forward`, ...) | n/a | OBSOLETE for gadget3 |

### gadget3 vs gadget3-master
* `gadget3/` site = documentation of the released CRAN version (shown as 0.15-1 in navbar, built 2026-01-12). `gadget3-master/` = documentation of the git development version (0.15-1-999, built 2026-10-08, includes later NEWS entries such as `g3_param_project_bootstrap()`, `from_year_f/to_year_f` in `g3_param_project_*`, breaking change `lastx_f` removed in `g3_param_project_ar1/logar1`). Both list the same article set. When an API question arises, prefer master docs if the user installs from GitHub (`remotes::install_github("gadget-framework/gadget3")`), release docs if from CRAN.
* NEWS timeline (gadget3/NEWS.md): 0.9-0, 0.10-0, ..., 0.14-0 (2025-10-15), 0.15-0, 0.15-1-999 (dev). Notable: parameters can be `type = "LOG"` (0.15-0/dev), `g3_tmb_fn()` for projection runs, `g3a_trace_var`, `g3a_trace_timings`, `g3l_bounds_penalty()` has configurable scale, `interim_value` re-worked to be per-fleet.

---------------------------------------------------------------------------
## 2. gadget3 articles (all G3, all updated 2026-10-08)

| Article (vignette) | URL suffix | Content |
|---|---|---|
| Introduction to gadget3: A single stock model | `articles/introduction-single-stock.html` | Time (`g3a_time`), stock (`g3_stock`, `g3s_livesonareas`, `g3s_age`), stock actions (initial conditions, mortality, age, growmature, renewal), fleet actions, landings data, length and age-length data, `g3l_*`, `g3_to_r/g3_to_tmb`, parameter template, optimisation, reporting |
| Incorporating observation data into models | `articles/incorporating-observation-data.html` | Data frame column conventions (year, step, area, age, length, number, weight, stock, fleet, predator); `g3_distribution_preview()`; mfdb query -> likelihood; **contains the official gadget2<->gadget3 translation table for likelihood components** (section 5 here) |
| Modelling maturity & sex with multiple stocks | `articles/multiple-substocks.html` | Immature/mature (and sex) stocks, `output_stocks`, stock-distribution via `stock` column, survey indices, `g3_init_val`/optimise, report |
| Model customisation | `articles/model-customisation.html` | Replace defaults via `*_f` formulas; custom formula injection |
| Random effects & projections | `articles/random-effect-recruitment.html` | `g3l_random_walk`/`g3l_random_dnorm`, `random = TRUE` parameters, `TMB::sdreport`, `g3_param_project_*` projections |
| Debugging a gadget3 model | `articles/model-debugging.html` | edit model code, NaN in likelihood, "initial value in vmmin not finite", `g3a_trace_nan`, TMB crashes, interactive debugging |
| Structure of a gadget3 model (Advanced) | `articles/model-structure.html` | formulas/tilde, actions, stocks, parameterisation, combining actions, ordering (`g3_action_order`) |
| Writing G3 Actions (Advanced) | `articles/writing_actions.html` | G3 global env, `g3_native`, stock steps, R code destined for C++, `g3_global_formula` |
| (notes) `gadget3/notes/tmb-gotchas.Rmd` | not on web | TMB gotchas, developer note |

gadget3 reference index (pkgdown `reference/`), groups: G3 stock functions (`g3_stock`, `g3s_*`), G3 action functions (`g3a_*`, `g3_action_order`), G3 projections (`g3_param_project*`, `g3_quota*`), G3 utilities (`g3_formula`, `g3_parameterized`, `g3_init_val`, `g3_timeareadata`, `g3_timevariable`, suitability functions `g3_suitability_*`), G3 compilation (`g3_to_r`, `g3_to_tmb`, `g3_to_desc`, `g3_tmb_adfun`, `g3_tmb_par/lower/upper/parscale/relist`), G3 internals.

---------------------------------------------------------------------------
## 3. gadget-course chapters (all gadget2 / Rgadget; none uses `g3_`)

Order from `_bookdown.yml`: index, introduction, Tidyverse, getting_started, stock_interactions, day2_lingmodel, day3_fitlingmodel, projections, day4_multi_area, minke_whale_model, mfdb, Gadget_installation, troubleshooting, references. `import_hydrography_cmems.Rmd` and `build.R`, `install-deps.R` exist but are not in the book. Every `.Rmd` has HEAD date 2021-03-16. Libraries: `Rgadget`, `tidyverse`, `mfdb`.

| Chapter file | Title | Base | Key teaching points |
|---|---|---|---|
| `index.Rmd` | About this course | Rgadget/G2 | Objectives: structure input files, run simulation from R via Rgadget, input data and likelihood components, understand iterative reweighting, use `gadget.fit`; reading list (Icelandic cod AJMS, TAMS uncertainty, ling MSE, Baltic cod-herring-sprat); lists ICES assessments using Gadget (ling/tusk 5a, golden redfish, beaked redfish, wolffish, Greenland halibut, southern hake) |
| `introduction.Rmd` | Introduction to Gadget | concept | History (MULTSPEC -> Bormicon -> Fleksibest -> Gadget in EU dst2 project 1999); "minimum realistic models"; Gadget = ecosystem simulator + likelihood function + optimiser; stock as homogeneous group; years with <=12 steps; areas, migration; fleets by effort/selection; likelihood module aggregates model output to data resolution and handles missing data; cost function is negative log-likelihood implemented as weighted sum of squares; optimisers simulated annealing, Hooke & Jeeves, BFGS; combination strategy |
| `Tidyverse.Rmd` | Intro to tidyverse | prerequisite | tibbles, tidy data, pipes, dplyr verbs, ggplot2 - needed since Rgadget/mfdb are tidyverse based |
| `getting_started.Rmd` | Getting started | G2/Rgadget | Rgadget workflow: `gadgetfile`, time file, area file, stock file, main file; run `callGadget`; Gadget variables/params (`#` switches), R expression <-> Gadget formula; predation (suitability), fleet operations (totalfleet, landings data), recruitment (renewal) |
| `stock_interactions.Rmd` | Defining stock interactions | G2 | recruitment, spawning (time variables), consumption (predator-prey, suitability, preference, otherfood) |
| `day2_lingmodel.Rmd` | Building complex Gadget models | G2 | Growth (length update with beta-binomial: `lengthvbsimple`, `beta`, `maxlengthgroupgrowth`), stock file; ling assessment in Icelandic waters; maturation as multi-stock (imm -> mat, transition via maturity function, Maturity timing), initial conditions (numbers at age*exp(-(M+F)age)), renewal, reference weight (must match walpha/wbeta), is-fished/is-eaten, fleets from catch (landings in kg/numbers) or effort; run with fixed params; standard ICES plots via `gadget.fit` |
| `day3_fitlingmodel.Rmd` | Fitting a model to data | G2 | Likelihood components (catchdistribution, stockdistribution, surveyindices, penalty/bound, understocking); bins: lower bound inclusive, outer bins open-ended; data frames need aggregation attributes (area, age, length) even for single bins; compare proportions; sum-of-squares per component; **objective = weighted sum; weights prevent one component dominating and reflect data quality; iterative reweighting (Stefansson 2003, Taylor et al. 2007) in `gadget.iterative`**: (1) initial SS with inverse-SS weights (each component starts at 1); (2) for each component (or group) optimise with weight 10 000 on it so only it drives the fit, estimate residual variance = SS / df* (df* = number of non-zero data points); (3) final weight = 1/variance; penalties (`boundlikelihood`, `understocking`) left unchanged; **grouping** of components (e.g. survey indices by size classes, commercial ldist+aldist) to avoid over-fitting when annual recruitment is estimated; results in `WGTS/` (`params.final`); `resume.final`, `run.serial`, `comp`/`inverse`, `wgts` args; optimisation settings via optinfofile (simann -> hooke -> bfgs); `gadget.fit` for diagnostics |
| `projections.Rmd` | Projections using Rgadget | G2 | Forward projections `gadget_project_time/_stocks/_fleet/_ref_points/_advice/_output` + `gadget_evaluate`; recruitment series (constant, block bootstrap, AR1); harvest control rule (btrigger, hockey-stick recruitment, blim), assessment error (`advice_cv`, `advice_rho` AR1); replicates; MSE-style loops over harvest rates; stock-recruit plot |
| `day4_multi_area.Rmd` | Defining multi area models | G2 | multi-area areafile, migration matrices, area-specific data and survey indices, fleets per area; known quirk: survey indices with >1 area must have data for both areas in a year |
| `minke_whale_model.Rmd` | Marine mammals | G2 | Baleen whale setup: stock without length growth in the fish sense, recruitment, interaction with prey; more complex stock structures |
| `mfdb.Rmd` | Processing input data with MFDB | MFDB (G2 export era) | Database creation, taxonomies, areas/divisions, sampling types, vessel/tow taxonomies, import temperature, survey/commercial samples, stomachs, DATRAS upload, query, dump/restore. Query side is still valid for gadget3; `gadget_dir_write` examples are G2 |
| `Gadget_installation.Rmd` | Installing Gadget from source | G2 | compile the `gadget` binary on Linux/Mac/Windows, put in `~/bin` |
| `troubleshooting.Rmd` | Troubleshooting | G2 | file not found, fleet does not exist in area, missing likelihood scores, starting value outside bounds, update Gadget+Rgadget; known quirks (see above); strange results: programming errors (parameter naming, wrongly named components in grouping), old files in model dir, `GADGET_WORKING_DIR` clash, convergence, understocking, bounds, more NA bins than data, **growth realism** (Linf, k, alpha/beta, `maxlengthgroupgrowth`; with poor ageing data results hinge on growth) |
| `import_hydrography_cmems.Rmd` | hydrography import | mfdb | Copernicus temperature -> mfdb (also in mfdb vignettes) |
| `references.Rmd` | refs | - | empty |

Course folder `docs/` has the PDFs: Icelandshrimp_PJW, Kulatska_baltic_2018, TAMS_Elvarsson, ajms, elvarsson2018ling, lba, ling_pre.

Course philosophy summary (for knowledge pack):
* Modelling philosophy: "develop fisheries science as far as information will support, but strictly no further" (dst2); minimum realistic models; single-step (data aggregated by the model, not pre-processed to catch-at-age as in VPA).
* Data: bring catch data (landings by fleet/year/step/area), length and age-length distributions, maturity-stage (stock) distributions, survey indices by length group, stomach data; aggregate in same bins as model; mfdb is the data warehouse.
* Likelihood weighting: do not hand-tune weights; use iterative reweighting (inverse residual variance per component or group) and check grouping; weights are the most time-consuming part of historic Gadget work.
* Diagnostics: `gadget.fit` standard ICES plots, residuals, likelihood components table, check convergence/understocking/bounds, growth plausibility, bootstrap, retro.
* Projections/MSE: recruitment resampling or AR1, HCR with btrigger, advice error AR1, multiple harvest rates.

---------------------------------------------------------------------------
## 4. Principles that still hold in gadget3 vs gadget2-only terms

### 4.1 Concepts that carry over (gadget3 reproduces gadget2 behaviour on purpose; README: "primarily designed to produce models matching the behaviour of gadget2")
* **Stocks**: homogeneous population in length groups (and optional age); immature/mature split as separate stocks; `output_stocks` replaces `transitionstocks`. Stocks can live on several areas.
* **Areas and time steps**: user-defined integer area ids; year divided into steps (quarterly via `mfdb_timestep_quarterly` = c(3,3,3,3)); months can be non-uniform.
* **Order of calculations** (gadget2 chapter "Order of Calculations"): print, migration, consumption (incl. fleets; predator demand -> cap prey at 95% -> adjust), natural mortality, growth (and maturity calculation), spawning, maturation (applied after spawn), recruitment, straying, likelihood, print, ageing. gadget3 `g3_action_order`: initial -1, report_early 0, time 1, migrate 2, predate 3, naturalmortality 4, grow 5, spawn 6, mature 7, renewal 8, straying 9, likelihood 10, report 11, age 12, quota 13 (the `run_at` argument of every action). New recruits cannot be eaten in the step they appear; fish cannot mature and spawn in the same step; ageing happens in the last step (birthday).
* **Growth**: length update by mean growth (von Bertalanffy `lengthvbsimple`: dL = (Linf - L)(1 - exp(-k dt))) spread over length groups by a **beta-binomial** distribution (parameters: mean growth scaled by group width, `beta`, `maxlengthgroupgrowth` = max number of length groups a fish can grow in one step; high beta = narrow, low beta = dispersed with right tail; beta with alpha<1 unstable). Weight update through a length-weight relationship w = a L^b (`walpha`, `wbeta`, plus `g3a_grow_weightsimple`). In practice `maxlengthgroupgrowth` is set a few groups larger than plausible (4-5 in bling).
* **Natural mortality**: N_a = N_a exp(-m_a dt) per age group.
* **Maturation**: logistic in length (and age) with alpha, l50 (a50, beta) - gadget2 `constant` (annual, listed steps) and `continuous` (hazard form, every step); gadget3 `g3a_mature_constant` / `g3a_mature_continuous` (the Icelandic models use continuous with `mat.alpha`, `mat.l50`).
* **Recruitment/renewal**: recruits per year x step with normal length distribution (mean, sd, weight via alpha/beta); spawning-recruitment functions (Ricker, Beverton-Holt, hockey stick, fecundity, simple SSB).
* **Predation / fleets**: fleets are predators with a **suitability function** of prey length (`exponentiall50` S-shape, `andersen` / `andersenfleet` dome shape, `gamma`, `richards`, `straightline`, `constant`), consuming a prescribed amount (landings, totalfleet), a rate (linear/effort fleet) or quota; stock-stock predation with max consumption, prey preference and Holling II/III responses.
* **Likelihood** = sum of component scores x weight. Component families: catch (length/age-length) distribution (sum of squares, multinomial, ...), stock distribution (maturity stage / sex proportion), survey indices (log-linear fit with slope beta), catch statistics (mean length/weight), understocking (penalty if required catch exceeds available stock), bounds penalty, stomach content, tagging recaptures. Proportions are formed within each aggregation then compared; bin convention: lower inclusive, outer bins open-ended.
* **Weighting and optimisation**: weights from iterative reweighting (Stefansson 2003; Taylor et al. 2007): weight = 1/ residual variance, with grouping of components; final run with those weights. Optimiser: gadget3 uses gradient-based BFGS/`nlminb` via TMB autodiff, so the simulated annealing + Hooke-Jeeves + BFGS hybrid is not needed; but multi-start/jittering (g3_jitter) fills the "global search" role. Penalties for parameters outside bounds still matter (`g3l_bounds_penalty`).
* **Diagnostics**: retrospective (peel years), bootstrap (resample areas/divisions in mfdb: `mfdb_bootstrap_group`, 100 replicates), profile likelihoods (M, Linf/K), leave-one-out data groups, Mohn's rho, jitter.
* **Projections/MSE**: stochastic recruitment, HCR with btrigger, advice error AR1, quota fleets.

### 4.2 gadget2 terms/file formats that do NOT exist in gadget3
* The executable and CLI: `gadget -s -main main -i params.in -o params.out -opt optinfofile -l -n`, `-printinitial`, `-printfinal`, `-f`, `GADGET_WORKING_DIR`, `Sys.setenv(GADGET_WORKING_DIR=...)`.
* **Main file** (`main`: `timefile`, `areafile`, `printfiles`, `[stock] stockfiles`, `[tagging]`, `[otherfood] otherfoodfiles`, `[fleet] fleetfiles`, `[likelihood] likelihoodfiles`) and all input files: time file, area file (areas, temperature), stock files (`livesonareas`, `minage`, `maxage`, `minlength`, `maxlength`, `dl`, `refweightfile`, `growthandeatlengths`, `doesgrow`, `naturalmortality`, `iseaten`, `preylengths`, `doeseat`, `predator`, `initialconditions`, `doesmigrate`, `doesmature`, `doesmove`, `doesrenew`, `doesspawn`, `doesstray`), fleet files, likelihood files (`[component]` blocks), aggregation files (`areaaggfile`, `lenaggfile`, `ageaggfile`, `preyaggfile`), data files in `Data/`, `Aggfiles/`, `Modelfiles/`, `Modelfiles/time`, print files, time-variable/stock-variable files (`timevariable`, `stockvariable`, `actionattime`), otherfood files, tag files.
* Parameter file `params.in` (`switch value lower upper optimise`), `#`-prefixed parameter names inside input files, "Gadget formulas" (`(* #k 0.001)`, prefix notation). In gadget3 parameters are discovered from `g3_param()` calls and exposed as a data.frame (`parameter_template`) with `switch`, `value`, `lower`, `upper`, `optimise`, `random`, `parscale`.
* Optimisation file (`optinfofile`: `[simann]`, `[hooke]`, `[bfgs]`, `simanniter`, `hookeiter`, `bfgsiter`, `rt`, `t`, `vm`...), `paramin` (parallel PVM optimiser), the simulated annealing and Hooke & Jeeves algorithms, "likelihood score" print outputs `lik.out`, `likelihoodprint` files. gadget3: `optim(method='BFGS')` / `nlminb` / `g3_optim`.
* **Rgadget** (and all `gadget.*` functions): `gadget.iterative`, `gadget.fit`, `gadget.forward`, `gadget.retro`, `gadget.bootstrap`, `gadget.variant.dir`, `gadget.skeleton`, `gadget.optimize`, `gadget_project_*`, `gadget_evaluate`, `read.gadget.file`, `write.gadget.file`, `gadgetfile`, `gadgetstock`, `gadgetfleet`, `gadgetlikelihood`, `gadget_update`, `init.params`, `read.gadget.parameters`, `read.printfiles`, `callGadget`, `Rgadget::`.
* `WGTS/` folders with `main.final`, `params.final` text files; in gadget3 `g3_iterative` writes `WGTS/params_final.Rdata`, `WGTS/fit.Rdata` (R objects).
* Stock-level options with no direct gadget3 action: `doesstray` (straying; action order slot exists, not implemented as action), tag files (`g3s_tag`/`g3a_predate_tagrelease` provide tagging differently), linear/effort/number fleet types as separate file classes (replaced by `catchability_f` variants).

---------------------------------------------------------------------------
## 5. Glossary: gadget2 -> gadget3

| gadget2 file/keyword/component | gadget3 equivalent | Notes |
|---|---|---|
| time file (`firstyear firststep lastyear laststep notimesteps`) | `g3a_time(start_year, end_year, step_lengths)`; `mfdb_timestep_quarterly` | step lengths in months; `project_years` argument for projections; `cur_year`, `cur_step`, `cur_time`, `cur_year_projection` available in formulas |
| area file (areas, size, temperature) | `g3_areas`/`g3s_livesonareas(areas[c('1')])`; integer area map built from `mfdb_group` | |
| stock file | `g3_stock(c(species='x','imm'), lengthgroups) |> g3s_livesonareas() |> g3s_age(minage, maxage)` + a list of `g3a_*` actions | stock name composed from parts, e.g. `bli_imm`; `g3_stock_def(stock,'minage')` accessors |
| `minlength maxlength dl` | `lengthgroups` vector, e.g. `seq(20, 112, 4)` | |
| `refweightfile` | Not needed; weight at length from `g3a_grow_weightsimple(walpha,wbeta)` / `walpha`, `wbeta` params | |
| `doesgrow` + growthfunction lengthvbsimple | `g3a_growmature(stock, impl_f = g3a_grow_impl_bbinom(delta_len_f = g3a_grow_lengthvbsimple(), delta_wgt_f = g3a_grow_weightsimple(), beta_f, maxlengthgroupgrowth))` | other growth: `g3a_grow_length_multspec`, `g3a_grow_weight_multspec`, `g3a_grow_length_weightjones`, `g3a_grow_weight_weightjones` |
| `beta`, `maxlengthgroupgrowth` | `beta_f = g3_parameterized('bbin')`, `maxlengthgroupgrowth` argument | beta-binomial growth is the only implementation |
| `naturalmortality` | `g3a_naturalmortality(stock, g3a_naturalmortality_exp(M))` | M by age: `g3_parameterized('M', by_stock=, by_age=TRUE)` |
| `initialconditions` (normalparam/normalcondition/numberfile) | `g3a_initialconditions_normalparam` / `g3a_initialconditions_normalcv`; abundance factor often `g3a_renewal_initabund(scalar, init, M, init_F)` | |
| `doesrenew` (renewal data) | `g3a_renewal_normalparam` / `g3a_renewal_normalcv` (`factor_f` = rec by year via `g3_parameterized('rec', by_year=TRUE)`) | |
| `doesspawn` (fecundity, simpleSSB, ricker, bevertonholt, hockeystick) | `g3a_spawn(..., recruitment_f = g3a_spawn_recruitment_*())` | also `_bevertonholt_ss3`, `_fecundity`, `_simplessb`, `_ricker`, `_hockeystick` |
| `doesmature` (constant / continuous / fixedlength / constantweight) | `g3a_mature_constant`, `g3a_mature_continuous` inside `g3a_growmature(maturity_f=, output_stocks=)` | |
| `doesmove` (transition to other stock) | `g3a_age(stock, output_stocks=list(next))` or `g3a_growmature(..., transition_f)` | ageing step = last step of year |
| `doesmigrate` (migration matrices) | `g3a_migrate`, `g3a_migrate_normalize` | |
| `doesstray` | no equivalent action | |
| `iseaten` / `preylengths` | prey defined by passing the stock to a predator action (`g3a_predate`, `g3a_predate_fleet`) | |
| `doeseat` (predator, suitability, preference, maxconsumption, halffeedingvalue) | `g3a_predate(predstock, preystocks, suitabilities, catchability_f = g3a_predate_catchability_predator(...))`, `g3a_predate_maxconsumption`, `g3a_predate_totalfleet` | |
| otherfood file | `g3a_otherfood`, `g3a_otherfood_normalparam`, `g3a_otherfood_normalcv` | |
| fleet file `totalfleet` | `g3_fleet('lln') |> g3s_livesonareas(...)` + `g3a_predate_fleet(..., catchability_f = g3a_predate_catchability_totalfleet(g3_timeareadata('lln_landings', df)))` | landings data.frame (year, step, area, total_weight) from `mfdb_sample_totalweight` |
| `linearfleet` | `g3a_predate_catchability_linearfleet` | |
| `numberfleet` | `g3a_predate_catchability_numberfleet` | |
| `effortfleet` / `quotafleet` | `g3a_predate_catchability_effortfleet`, `g3a_predate_catchability_quotafleet`; modern quota: `g3a_predate_catchability_project(quota_f = g3_quota(...), landings_f=, unit='biomass')` with `g3_quota_hockeyfleet`, `g3_quota_hockeystick`, `g3_quota_assess` | used for projections |
| suitability `exponentiall50`, `andersen`, `andersenfleet`, `gamma`, `richards`, `straightline`, `exponential`, `constant` | `g3_suitability_exponentiall50`, `_andersen`, `_andersenfleet`, `_gamma`, `_richards`, `_straightline`, `_exponential`, `_constant` | (in gadget3 NAMESPACE) |
| `timevariable`, `stockvariable`, `actionattime` | `g3_timevariable()`, `g3_timeareadata()`, `g3_parameterized(by_year=, by_step=)`, `g3_formula()` with `cur_year` | |
| `[tagging]` | `g3s_tag`, `g3a_predate_tagrelease`, `g3a_tag_shedding`, `g3l_*` tag likelihoods via `g3l_catchdistribution` | |
| likelihood `type catchdistribution` | `g3l_catchdistribution(nll_name, obs_data, fleets, stocks, function_f)` | `function_f` one of `g3l_distribution_sumofsquares`, `_multinomial`, `_multivariate`, `_sumofsquaredlogratios`; data columns year, step, area, age, length, number |
| `type stockdistribution` | `g3l_catchdistribution` with `stock` column in data (see article "multiple-substocks") | in bling: `matp_aut` via `rename(stock = maturity_stage)` |
| `type surveyindices` (sitype lengths/ages/fleets/acoustic/effort) | `g3l_abundancedistribution(..., function_f = g3l_distribution_surveyindices_log(beta=1))` (or `_linear`); with fleet: `g3l_catchdistribution(... fleets=list(aut))` | fit types `loglinearfit`, `fixedslopeloglinearfit` -> `beta = NULL` (estimated) or `beta = 1` (fixed slope) |
| `type catchstatistics` | no direct component; use `g3l_catchdistribution` or sparsesample/regression variants | check reference |
| `type catchinkilos` | `g3l_catchdistribution(function_f = g3l_distribution_sumofsquares())` with data (year, step, area, fleet, weight) | per gadget3 translation table |
| `type understocking` | `g3l_understocking(stocks, weight = )` | |
| `type penalty` (BoundLikelihood) | `g3l_bounds_penalty(actions)` (now in gadget3; earlier `g3experiments`) | |
| `type stomachcontent`, `recaptures`, `recstatistics`, `migrationpenalty/proportion` | `g3l_sparsesample*`, tagging via recaptures; stomach: predator column in data | partial |
| likelihood `weight` | parameter `<nll_name>_weight` (e.g. `ldist_bmt_weight`), set via `g3_init_val`, estimated by `g3_iterative`; `_weight$` switches copied across retro/boot runs | |
| aggregation files | data frame attributes (from mfdb) or factor levels: `year`, `step`, `area`, `age`, `length` columns; `g3_distribution_preview()` shows resulting array | |
| `gadget.iterative` (Rgadget) | `gadgetutils::g3_iterative(gd, wgts='WGTS', model, params.in, grouping=, cv_floor=, shortcut=, resume_final=)`; `g3_iterative_default_grouping()` | `shortcut` variant in `g3_iterative_shortcut.R` |
| `gadget.fit` | `gadgetutils::g3_fit(model, params)` -> list with `res.by.year`, `stock.std`, `fleet.info`, `catchdist.fleets`, `stockdist`, `sdout`, ... | plots with `gadgetplots::gadget_plots(fit, path, file_type='html')`, `make_html()` |
| `gadget.retro` | `g3_retro(gd, outdir='RETRO', model, params, nyears)` (or loop with `retro_years` param) | |
| `gadget.bootstrap` | `mfdb_bootstrap_group(n, groups, seed)` + one model per replicate (data replicate index `boot_repl`) + `g3_optim` | see iceland-layout |
| `gadget.forward` / `gadget_project_*` | `project_years` argument to `g3a_time`, `g3_param_project_*`, `g3_quota_*`, `g3a_predate_catchability_project`; gadget2to3 helpers `g3experiments::g3p_setup_pars` | |
| `simann/hooke/bfgs` | `optim(method='BFGS')`, `nlminb`, `gadgetutils::g3_optim` | analytic gradients from TMB |
| `paramin` | not needed | |
| `params.in/out/final` | `parameter_template` data.frame; `g3_init_val(params, 'pattern', value, lower, upper, optimise)` or `gadgetutils::g3_init_guess`; `write.g3.param` / `read.g3.param` | `g3_init_val('*.rec.#', 50)` glob syntax: `*` any, `#` index |
| printfile | `g3a_report_detail(actions)`, `g3a_report_history`, `g3a_report_stock`; reports read from `attributes(model(params))` or `obj.fun$report()` | |
| Rgadget `init.params` | `g3_init_val` | |
| `mfdb::gadget_dir_write(gadget_directory(...), ...)` | not used; pass query results straight in | |

---------------------------------------------------------------------------
## 6. Publications and other references
* `gadget-framework.github.io/publications/`: `2024-09-ices-asc-gadget3-evolution-of-gadget-modelling-framework.pdf` (ICES ASC 2024 poster), `2025-12-11-miniCAPAM.html` (Mini-CAPAM 2025: length-based processes, blue ling), `ICES2004_FF13_BegleyandHowell.pdf` (Begley & Howell 2004 overview of Gadget; gadget2 era).
* `publications/` repo (source): `2018-11-01-Ling-paper` (Elvarsson et al. 2018 ling MSE, G2), `2021-12-attempt.Rmd`, `2024-09-ices-asc-poster`, `2025-06-09-gadget3` (gadget3 manuscript with responses to reviewers, supplementary-material-bling.R, `likelihood_distribution_mvtweedie.R`, `bling-with-tweedie.R`), `2025-12-11-miniCAPAM`, `2026-01-06-size-platoons`, `bibliography.bib`.
* WGSAM 2025 presentation: https://presentations.shuttlethread.com/2025-10-09-gadget3-mice.
* Key literature: Begley & Howell 2005 (Gadget overview, ICES), Stefansson 2003 (issues in multispecies models; iterative reweighting), Taylor et al. 2007 (Icelandic cod simple Gadget model), Taylor et al. 2011 (cod multi-area), Elvarsson et al. 2014 (uncertainty, TAMS) and 2018 (ling MSE), Lindstrom et al. 2009, Howell & Bogstad 2010.
* Other gadget3 examples cited in gadget-models Readme: https://github.com/Fishing-into-the-future/random-effects, boqueron_assessment anchovy (gadget3.4 anchovy 4a).

---------------------------------------------------------------------------
## 7. Telltale signs: gadget2 vs gadget3 snippets

### gadget2 / Rgadget (obsolete for gadget3 work)
* Shell: `gadget -s -main main -i params.in -o params.out`, `gadget -l -main main -i params.in`, `gadget -main main -s -n -i params.in`, `-printinitial`, `-opt optinfofile`.
* R: `library(Rgadget)`, `Rgadget::`, `gadget.iterative(`, `gadget.fit(`, `gadget.variant.dir(`, `gadget.retro(`, `gadget.forward(`, `gadget_update("catchdistribution", ...)`, `gadget_dir_write(`, `callGadget(`, `read.gadget.file(`, `gadgetfile(`, `init.params`, `params.final`, `WGTS/main.final`, `optinfofile`, `gd$dir`, `Modelfiles/`, `Aggfiles/`, `Data/`.
* Text files: `[stock]`, `[component]`, `[fleetcomponent]`, `stocknames`, `fleetnames`, `areaaggfile`, `lenaggfile`, `type totalfleet`, `doesgrow 1`, `growthandeatlengths`, parameter names with `#` prefix, formulas like `(* 0.001 #ling.k)`, `;` comments, `timefile`.
* Names: `bfgs`, `simann`, `hooke`, `paramin`, `lik.out`.
* gadget-course content, `fishvice/gadget-models` old folders `02-haddock`, `08-tusk`, `09-wolffish`, `06-ling/00-setup`, `sprat_10_05` (Rgadget-based), `ven_rin_08.3`, `vendace/g2_vendace`, `Anchovy_9a_South_2022`, `2018_lin.27.5a` (empty).

### gadget3
* `library(gadget3)`, functions prefixed `g3_`, `g3a_` (actions), `g3l_` (likelihood), `g3s_` (stock modifiers), `g3_to_r`, `g3_to_tmb`, `g3_tmb_adfun`, `g3_tmb_par`, `g3_tmb_relist`, `g3_param(`, `g3_param_table(`, `g3_parameterized(`, `g3_formula(`, `g3_init_val(`, `g3_timeareadata(`, `attr(model,'parameter_template')`, `g3a_time(start_year, end_year, step_lengths)`, `~` formulas (R tilde) containing `stock__midlen`, `cur_year`, `cur_step`, `age`, `g3_param("...")`, TMB (`TMB::sdreport`, `random = TRUE`), `gadgetutils::g3_fit/g3_iterative/g3_optim`, `gadgetplots::gadget_plots`, `params_final.Rdata`, `tmb_param`, `nll_name`.
* Caution: mfdb calls (`mfdb_sample_count`, `mfdb_group`, `mfdb_interval`) appear in both; `gadget_dir_write` / `gadget_directory` in mfdb means gadget2. `gadgetutils::g3_init_guess` is gadget3 even though it resembles Rgadget's `init.params`. Vendace `g3_vendace` uses the old explicit style `~g3_param("venimm.init.scalar")` vs newer `g3_parameterized`.
* Parameter naming style in newer models: `bli_imm.Linf`, `bli.bmt.alpha`, `bli_imm.rec.1982`, `ldist_bmt_weight`, `bling_recruitment_sigma`.
