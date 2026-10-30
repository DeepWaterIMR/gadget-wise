# Icelandic model folder layout (gadget-models) - digest, focused on gadget3 variants

Source: clone `gadget-models/` (single commit, HEAD 2026-03-23; informal repo, code is "working scripts", not a package; contains hard-coded paths, commented-out blocks, Icelandic comments). Treat as examples, not as an API.

---------------------------------------------------------------------------
## 1. Inventory: gadget2 vs gadget3

| Folder | Engine | Content |
|---|---|---|
| `02-haddock/00-setup` | gadget2 (Rgadget) | setup*.R, bootrun.R, figures.R, run.R |
| `06-ling/00-setup`, `06-ling/99-docs` | gadget2 (Rgadget, `gadget.iterative`, `gadget.retro`) | tag-less ling gadget2 model; `99-docs/pre` presentations |
| **`06-ling/gadget3/00-setup`** | **gadget3** | 15 files (see 3.1), plus `00-setup_random/` (random-effect variant) |
| **`07-bling/gadget3/00-setup`** and `00-setup_24` | **gadget3** | blue ling 2020/2024 development versions |
| **`07-bling/gadget3 - WKBDEEP`** | **gadget3** | most complete: `00-setup/` (15 R files), `data/` (6 .Rdata), `models/` (2 output folders). This is the ICES WKBDEEP benchmark / NWWG assessment model (older twin: `00-setup_24` has `base_dir <- 'benchmarks/WKBDEEP/gadget3'`) |
| `08-tusk/00-setup`, `08-tusk/99-docs` | gadget2 | tusk; `itterfitter.sh`, `optinfofile` |
| `09-wolffish/00-setup`, `01-firsttry`, `99-docs` | gadget2 | wolffish; `01-firsttry` has generated gadget2 text files (`params.in`, `likelihood`, `wolfimm`) |
| `2018_lin.27.5a` | - | empty folder |
| `Anchovy_9a_South_2022/Anchovy2022_def_estesi_4run_shortopt` | gadget2 | full generated model dir (Aggfiles, Data, Modelfiles, `main`, `optfile`, WGTS, `Runner.r`, `gadget_fit4_2step_2019.r`, `gadget_project.r`, slurm outputs) |
| `sprat_10_05` | gadget2 (Rgadget, `gadget_dir_write`) | Baltic sprat |
| `ven_rin_08.3` | gadget2 (Rgadget) | vendace (ven) + herring (rin) two-species |
| `vendace/g2_vendace` | gadget2 | |
| **`vendace/g3_vendace`** | **gadget3** | Baltic vendace: setup.R, setup_model.R, setup_fleets(_data).R, setup_initial_parameters.R, setup_indices.R, setup_catchdistribution.R, setup_likelihood.R, area_units.R; **older explicit style** (`~g3_param("venimm.init.scalar")` inline formulas, mfdb `Baltic`/`bothnia` database) |
| `R/utils.R`, `forward.R`, `forwardling.R`, `forwardtusk.R`, `prognling*.R`, `progntusk*.R`, `lingtusk_fits.R`, `reading_progn.R` | gadget2 (Rgadget forward projections) | top-level helper scripts |
| `Readme.md` | | lists the three gadget3 models: `06-ling/gadget3`, `07-bling/gadget3`, `vendace/g3_vendace`; plus external: Fishing-into-the-future/random-effects, boqueron anchovy `gadget34anchovy_2023_4a.r` |

Telltale: gadget2 folders contain `optinfofile`, `itterfitter.sh`, `figures.R`, `bootrun.R`, and `library(Rgadget)`; gadget3 folders contain only `setup*.R` + `.Rdata`. Caution: `06-ling/gadget3/00-setup/setup-bootstrap.R` is a leftover copy of gadget2 code (`gadget_update("catchdistribution", ...)`, `gadget.variant.dir`, `source('06-ling/00-setup/...')`); it is not used by `setup.R`.

---------------------------------------------------------------------------
## 2. File trees (gadget3 variants, <=4 levels; data blobs summarised)

### 2.1 `07-bling/gadget3 - WKBDEEP` (reference variant)
```
gadget3 - WKBDEEP/
  00-setup/                        # all code; directory is copied/mounted as <base_dir>/00-setup
    setup.R                        # 874 lines: options, defaults, stocks, data, actions, params, compile, ALL diagnostics
    setup-sexratio_suitability.R   # defines g3_suitability_blueling() (female/male-weighted maturity proxy used as spawning proportion)
    setup-stocks.R                 # g3_stock objects: imm_stock, mat_stock, dummy_stock (or single_stock)
    setup-model.R                  # two-stock actions -> stock_actions (imm_actions, mat_actions, dummy_actions)
    setup-model-single-stock.R     # alternative one-stock actions (single_stock_model <- TRUE)
    setup-fleets.R                 # g3_fleet objects + fleet_actions, quota function for projections
    setup-likelihood.R             # likelihood_actions (catchdistribution, abundancedistribution, understocking)
    setup-randomeffects.R          # random_actions: g3l_random_walk on recruitment (penalised recruitment)
    setup-fleet-data.R             # [read_data] landings by fleet via mfdb -> fleet_data.Rdata
    setup-catchdistribution.R      # [read_data] length / age-length / maturity data via mfdb (+ MAR db for deep surveys) -> catchdistribution_data.Rdata, lw/init constants
    setup-indices.R                # [read_data] autumn survey length-group indices -> indices.Rdata
    setup-initial_parameters.R     # [read_data] lw.constants, init.cv, mat.l50, von B start values -> init_param.Rdata
    setup-bootstrap_divisions.R    # [one-off] finds mfdb divisions with too few samples -> nodata_divs.Rdata
    setup-advice.R                 # annual ICES advice: loads fit, adds interim-year fleets, runs projections over harvest rates
    projections-assess_model.R     # design notes + g3_quota_assess_bl() prototype
    projections-functions.R        # plot_stockrecruit, g3p_run, g3p_process_reports, run_proj
  data/                            # Rdata snapshots written by the setup-data scripts, read when read_data <- FALSE
    catchdistribution_data.Rdata (377 kB)  fleet_data.Rdata  indices.Rdata  init_param.Rdata  nodata_divs.Rdata  sexratio.Rdata
    # + bootstrap_*.Rdata (not in clone) written when save_bootstrap_data = TRUE
  models/
    22-baseline_IFgr_Linf0_K1_t00_mlgg4_reccv0_penrec1_sd0.4_agedata0_t0/
      fit.Rdata                    # g3_fit() result
    22-variant_IFgr_Linf1_K1_t00_mlgg4_reccv0_penrec1_sd0.4_agedata1_t0/
      fit.Rdata  r_model.Rdata (23 MB)
```
At runtime (not in clone) a run adds: `<base_dir>/<vers>/{defaults.Rdata, tmb_param.Rdata, r_model.Rdata, tmb_model.Rdata, WGTS/, RETRO/, JITTER_0|1/, BOOTSTRAP[_SHORT]/, LEAVEOUT/, M_PROFILE[_SHORT]/, K_LINF_PROFILE_v2/, figs/, prognosis.Rdata, catch_options.csv}`.
The scripts hard-code `base_dir <- 'assessment_model'` and `vers <- file.path('model', paste0('nwwg_', year))`, i.e. in the assessment repo the layout is `assessment_model/{00-setup,data,model/nwwg_<year>/...}`, plus `R/model_functions.R`, `advice/tables/ref_points.csv`, `data/greenland/logbooks_00-23.csv` (not in clone).

### 2.2 `07-bling/gadget3/00-setup` (earlier, 2020 version) and `00-setup_24`
`00-setup`: setup.R, setup-model.R, setup-model-single-stock.R, setup-stocks.R, setup-fleets.R, setup-fleet-data.R, setup-catchdistribution.R, setup-indices.R, setup-likelihood.R, setup-initial_parameters.R. `00-setup_24`: same plus `setup-randomeffects.R`, `setup-bootstrap_divisions.R`, `test_projections.R`. Differences: `base_dir <- '07-bling/gadget3'` / `'benchmarks/WKBDEEP/gadget3'`; `year_range <- 1982:2020` / `1970:2023`; `vers <- 'models/01-baseline'` / `'models/04-baseline'` with suffix built by `paste0` (active code here, commented out in WKBDEEP); `timevarying_K <- TRUE` (older); no output folders in the clone.

### 2.3 `06-ling/gadget3`
```
gadget3/
  00-setup/
    setup.R                  # runner (225 lines); base_dir '06-ling/gadget3'; read_data/run_iterative/run_retro/bootstrap flags
    setup-model_tagging.R    # stocks (imm/mat, with tag dimension) -> imm_stock, mat_stock, stocks
    setup-model_components.R # stock actions as separate named lists: initial_conditions_imm/mat, natural_mortality_*, ageing_*, renewal_imm, growmature_*, spawning
    setup-model.R            # older untagged stock/actions version
    setup-fleets.R           # igfs, lln, bmt, gil, foreign fleets + fleet_actions (totalfleet landings)
    setup-fleets_prognosis.R # projection fleets (tac.hr.high, tac.trigger params)
    setup-tagging.R          # tagging_actions
    setup-likelihood.R       # g3l_understocking(weight 1e6), ldist/aldist per fleet, matp.igfs, SI per length group
    setup-randomeffects.R    # random_actions (random walk on 'ling.rec' random=TRUE), random_actions2/3
    setup-TEST_RANDOM.R      # test script for random effects
    setup-fleet-data.R, setup-catchdistribution.R, setup-indices.R, setup-initial_parameters.R   # mfdb data scripts [read_data]
    setup-bootstrap.R        # LEFTOVER gadget2 code, unused
  00-setup_random/           # variant for random-effects recruitment: setup-randomeffects.R, setup-likelihood(_alphabeta).R, setup-initial_parameters.R, setup-model.R, setup-fleets.R, setup-catchdistribution.R, setup_random.R
```
(no data/ or models/ folder; `setup.R` creates `06-ling/gadget3/{data,model}`.)

### 2.4 `vendace/g3_vendace`
Flat folder of `setup*.R` + `area_units.R`; uses the old explicit `~g3_param()` style; `mfdb('Baltic', db_params=list(dbname="bothnia"))`; stocks `ven_imm` (ages 0-1, lengths 3.5-17.5 by 0.5) and `ven_mat`; `defaults.ven` with ICES rectangles of SD 30-31.

---------------------------------------------------------------------------
## 3. Orchestration: order of execution in WKBDEEP `setup.R`

Run from the repository root (paths are `file.path(base_dir, '00-setup', ...)`); `source()` order:

1. **Libraries**: `mfdb, gadget3, gadgetutils, gadgetplots, mar` (internal MFRI `mar` package; `g3experiments` commented out in WKBDEEP, loaded in `setup-advice.R` and in the 00-setup variant).
2. **Options block** (no config file; all top-level R variables): `base_dir`, `vers`, `year_range <- 1975:(year-1)`, `species_name <- 'bli'`; flags `read_data`, `read_bootstrap_data`, `run_iterative/retro/bootstrap/mprofile/growthprofile/jitter/leaveout`; folder names (`wgts_folder='WGTS'`, `retro_folder='RETRO'`, `boot_folder='BOOTSTRAP'`, `jitter_folder='JITTER'` + `_0/_1` suffix); diagnostic parameters (`number_of_peels=6`, `nboots=100`, `boot_short`, `bootstrap_cores=35`, `number_of_jitters=100`, `jitter_fraction=0.1`, `M_values`, `gw_values`); `optim_control <- list(maxit=2000, reltol=1e-10)`; model switches (see 5).
3. **Derived settings** (`boot_repl <- 1; peel <- 0`; `M_values` repeated by `profile_reps`).
4. **Spatial/temporal defaults**: `reitmapping` from `mfdb` demo data; `defaults <- list(area=mfdb_group("1"=unique(reitmapping$SUBDIVISION)), timestep=mfdb_timestep_quarterly, year=year_range, project_years, species=toupper(species_name), save_bootstrap_data=FALSE)`; `areas <- structure(seq_along(defaults$area), names=names(defaults$area))` (single area "1"); `time_actions <- list(g3a_time(start_year, end_year, defaults$timestep), list())`.
5. `fs::dir_create(<base_dir>/{data, vers})`; `save(defaults, areas, file=<vers>/defaults.Rdata)` (later reloaded by setup-advice.R).
6. `source` **setup-sexratio_suitability.R** -> function `g3_suitability_blueling()`; **setup-stocks.R** -> `imm_stock, mat_stock, dummy_stock, stocks` (or `single_stock`); **setup-model.R** (or `-single-stock.R`) -> `stock_actions`.
7. **Data**: if `read_data`: `mdb <- mfdb('Iceland', db_params=list(host='<host>'))`, source `setup-fleet-data.R`, `setup-catchdistribution.R`, `setup-indices.R`, `setup-initial_parameters.R`, `mfdb_disconnect(mdb)`. Else: `fs::dir_ls(<base_dir>/data) |> str_subset('.Rdata') |> str_subset('bootstrap', negate=TRUE) |> lapply(load, .GlobalEnv)` -> loads all data objects into the global env (hence downstream scripts use them as globals).
8. `source` **setup-fleets.R** -> `lln, bmt, foreign, aut, deep_surveys, comm, fleets, quotafunction, fleet_actions`; **setup-likelihood.R** -> `likelihood_actions` (uses `boot_repl`, `peel`); **setup-randomeffects.R** -> `random_actions`.
9. **Collate**: `actions <- c(stock_actions, fleet_actions, likelihood_actions, if (recruitment_free_pars && penalise_recruitment==1) random_actions, time_actions)`.
10. **Compile**: `tmb_model <- g3_to_tmb(c(actions, list(g3a_report_detail(actions)), list(g3l_bounds_penalty(actions))))`; `model <- g3_to_r(attr(tmb_model,'actions'))`.
11. **Parameters**: `tmb_param <- attr(tmb_model,'parameter_template') |> g3_init_val('*.rec.#', 50, lower=0.001, upper=100) |> g3_init_val('*.Linf', ...) |> ...` (full chain in skeleton).
12. Test run: `result <- model(tmb_param$value)`; `gadgetplots::gadget_plots(g3_fit(model, tmb_param), file_type='html', path='TEST')`; `save(tmb_param, model, tmb_model)` into `<base_dir>/<vers>/`.
13. **Grouping list** for iterative reweighting (`sind` = all 7 autumn survey indices, `bmt`, `aut`, or `comm`).
14. Diagnostics, each gated by a flag (see section 6): iterative -> retro -> jitter -> leaveout -> M profile -> growth profile -> bootstrap data (re)read -> bootstrap.

Note: sections 7 and 8 are re-`source`d inside loops for retro (`peel` = 1..6) and bootstrap (`boot_repl` = 1..nboots): `setup-likelihood.R` reads those two globals to subset data (`year <= max(defaults$year) - peel`) and to select the bootstrap data replicate (`ldist.bmt[[boot_repl]]`, `aut.SI[[boot_repl]]`). Data lists are therefore always lists of length 1 (standard) or `nboots` (bootstrap), hence the idiom `ldist.aut[[boot_repl]]`.

---------------------------------------------------------------------------
## 4. Files: what they create and consume

| File | Consumes (globals) | Creates | Data source |
|---|---|---|---|
| setup.R | all | `defaults, areas, time_actions, actions, tmb_model, model, tmb_param, grouping, params.out, fit, retro_fit, jitter_fit, boot_fit...` | |
| setup-sexratio_suitability.R | - | `g3_suitability_blueling()` (formula returning `~1/(1+exp(-0.23*(stock__midlen-91.5856))) + 0.5/(1+exp(0.1668*(stock__midlen-82.8539)))`; values hard-coded) | |
| setup-stocks.R | `areas`, `species_name`, `single_stock_model` | `imm_stock` (lengths 20-112 by 4, ages 2-15), `mat_stock` (36-140, ages 5-20), `dummy_stock` (ages 0..minage-1, projection recruits), `stocks`; or `single_stock` (20-140 by 4, ages 3-20) | |
| setup-model.R | stocks, options (`timevarying_K`, `initabun_by_age`, `initabun_by_stock`, `init_rec_scalar`, `recruitment_free_pars`, `exponentiate_*`, `maxlengthgroupgrowth`, `mean_len_recl`), `defaults$project_years` | `initabun` (renewal_initabund), `common_pars` (mean_len, var_len, mean_rec_len), `imm_actions`, `mat_actions`, `dummy_actions`, `stock_actions` | |
| setup-fleets.R | stocks, `mat_stock`, fleet options (`single_fleet`, `dome_*`, `timevarying_*`, `bmt_age`), `lln_landings, bmt_landings, foreign_landings, aut_landings, comm_landings, deep_landings` | `lln, bmt, foreign, aut, deep_surveys, comm, fleets, quotafunction(), lln_par, bmt_par, fleet_actions` | |
| setup-likelihood.R | `ldist.*[[boot_repl]]`, `matp.aut`, `aut.SI`, `peel`, `stocks`, fleets, `si_len_slopes`, `selection_si_lik`, `bmt_age` | `likelihood_actions` incl. `g3l_understocking`, `ldist_lln/bmt/aut` (`g3l_catchdistribution`, `g3l_distribution_sumofsquares()`), `matp_aut`, `si_len0XX_AUT` (7 abundance-distribution indices via `g3l_abundancedistribution(fleets=list(), g3l_distribution_surveyindices_log(beta=1))`) | |
| setup-randomeffects.R | `penalise_recruitment`, stock names | `random_actions`: `g3l_random_walk(nll_name='recruitment', param_f=log(avoid_zero(<imm>.rec by year)), period='year', sigma_f=g3_parameterized('bling_recruitment_sigma'))` | |
| setup-fleet-data.R | `mdb, defaults` | `aut_landings` (dummy: total_weight=1, step 4), `deep_landings`, `lln_landings`, `bmt_landings` (Iceland LND + Greenland logbook csv), `foreign_landings` (`sampling_type='FLND'`), `comm_landings`; saved to `data/fleet_data.Rdata` | `mfdb_sample_totalweight(mdb, NULL, c(list(gear=..., sampling_type='LND', species=...), defaults))` |
| setup-catchdistribution.R | `stocks`, `mdb`, `defaults` | `ldist.aut, matp.aut, ldist.lln, ldist.bmt, ldist.comm` (+ `aldist.*`, `ldist.is` under `if (FALSE)`), `lw.constants`, `init.sigma`, `init.cv`, `init.sigma.coef`, `mat.l50`, `mat.a50`, `vonB.par`, `growth_vals`; saves `catchdistribution_data.Rdata` (or `catchdistribution_bootstrap_data.Rdata` when `save_bootstrap_data`) | `mfdb_sample_count(mdb, c('age','length'), c(list(data_source='iceland-ldist', sampling_type='AUT', age=mfdb_interval('all',c(minage,maxage), open_ended=c('upper','lower')), length=mfdb_interval('len', seq(minlen,maxlen,by=dl), open_ended=c('upper','lower'))), defaults))`; MAR (`mar::les_stod`, `les_syni`, `les_aldur`) for deep-survey age data; `mfdb_dplyr_sample(mdb)` for lw regression |
| setup-indices.R | `si_cv`, `stratified_indices`, `nboots` | `aut.SI` = list(rep) of list(length group) of data.frames; `stratified_indices=TRUE` reads `data/survey_indices.Rdata` (external stratified index, `index=='Combined'`), else `mfdb_sample_count(..., length=mfdb_interval('len', si_len_breaks, open_ended=c('lower','upper')))`; bootstrap replicates drawn with `rlnorm(n, log(x)-s/2, sdlog=sqrt(log(cv^2+1)))`; saved as `indices.Rdata` / `bootstrap_indices.Rdata` | |
| setup-initial_parameters.R | - | (in WKBDEEP these live inside setup-catchdistribution.R; the file saves `init_param.Rdata` = `lw.constants, mat.l50, init.sigma, mat.a50, init.sigma.coef, init.cv`) | |
| setup-bootstrap_divisions.R | mdb | `nodata_divs` (divisions with < 230 aut samples after 2000) | `mfdb_dplyr_sample` joined with `mfdb_dplyr_division` |
| setup-advice.R | saved `WGTS/params_final.Rdata`, `r_model.Rdata`, `WGTS/fit.Rdata`, `defaults.Rdata`, `data/sexratio.Rdata`, `advice/tables/ref_points.csv` | `fit`, `fleet_props`, `inter_fleet_actions`, `proj_actions`, `tmb_proj`, `r_proj`, `proj_runs`, `prognosis`, `prognosis0/_msy/_sq`, `TAC`; writes `prognosis.Rdata`, `catch_options.csv` | |

Data-pull conventions:
* All queries go through `mfdb` (DB `'Iceland'` on `<host>`; Baltic: `'Baltic'` on local `bothnia`), with `defaults` (area, timestep, year, species) appended to every query, so aggregation matches the model. Output of `mfdb_sample_count`/`totalweight` is a list (one element per bootstrap sample group), data.frames with year/step/area/age/length/number and attributes carrying the aggregation; used directly in `g3l_*`/`g3_timeareadata` after `mutate(area=as.numeric(area), step=as.numeric(step), year=as.numeric(year))`.
* Raw data are queried only when `read_data <- TRUE` (requires MFRI network/DB and `mar` access); otherwise the `.Rdata` snapshots in `<base_dir>/data/` are loaded into the global environment. Bootstrap data are separate files (`bootstrap_*.Rdata`, `catchdistribution_bootstrap_data.Rdata`) written by running the same data scripts with `defaults$area <- mfdb_bootstrap_group(nboots, mfdb_group('1'=unique(newreits$SUBDIVISION)), seed=2298)` and `defaults$save_bootstrap_data <- TRUE`; divisions listed in `nodata_divs` are excluded from the bootstrap pool.
* Data hygiene lives in `setup-likelihood.R` as `filter()` calls (e.g. `filter(year > 2000, year != 2011)` for autumn survey; remove `year==2020 & step==2` bottom-trawl; drop maturity records for specific length groups) rather than in the data scripts.

---------------------------------------------------------------------------
## 5. Settings encoding and output folder naming

Model folder name = `<NN>-<label>` + a suffix built from option values. Example (WKBDEEP): `22-baseline_IFgr_Linf0_K1_t00_mlgg4_reccv0_penrec1_sd0.4_agedata0_t0`, `22-variant_IFgr_Linf1_K1_t00_mlgg4_reccv0_penrec1_sd0.4_agedata1_t0`. The generator is commented out in WKBDEEP `setup.R`; decoding it:

```r
vers <- paste0(vers,
  {if (faroe_growth) '_Fgr' else '_IFgr'},        # growth source: Faroese (Fgr) vs Iceland/Faroes combined (IFgr)
  {if (faroe_M) '_FarM' else NULL},               # Faroese M (0.11)
  '_Linf', as.numeric(estimate_linf),             # Linf0 = fixed, Linf1 = estimated
  '_K',    as.numeric(estimate_k),                # K1 = estimated
  '_t0',   as.numeric(estimate_t0),               # t00 = t0 fixed (label "t0" + "0")
  '_mlgg', maxlengthgroupgrowth,                  # mlgg4
  {if (!estimate_reccv) '_reccv0' else NULL},     # recruit length CV fixed
  {if (recruitment_free_pars) paste0('_penrec', penalise_recruitment) else NULL},   # penrec1 = penalised random-walk recruitment
  {if (recruitment_free_pars && penalise_recruitment==1) paste0('_sd', recruitment_sigma) else NULL},   # sd0.4
  {if (!recruitment_free_pars) paste0('_sd', recruitment_std) else NULL},
  {if (!recruitment_free_pars) paste0('_ar', arima_phi) else NULL},
  '_agedata', as.numeric(bmt_age),                # agedata0/1 = commercial trawl age readings off/on
  {if (dome_bmt) '_bmtAnd' else NULL}, {if (timevarying_bmt) '_bmtTV' else NULL},   # Andersen dome / time-varying selection
  {if (dome_lln) '_llnAnd' else NULL}, {if (timevarying_lln) '_llnTV' else NULL},
  {if (!mean_len_recl) '_t0' else NULL},          # trailing "_t0" = renewal mean length uses t0 (not recl)
  {if (!is.null(si_len_slopes)) '_sislope' else NULL},
  {if (!iter_group_SI) '_aut2gp' else NULL},      # two survey-index groups instead of one
  {if (female_maturation) '_Fmat' else NULL}, {if (female_weight_length) '_Fwl' else NULL},
  paste0('_', growth_origin))                     # (commented line; folders in clone end before this)
```
Older `00-setup_24` scheme: `models/04-baseline_Linf0_K0_t01_penrec1_sigma0.4_agedata0_bmtS0_llnS1_recl1` (`_bmtS`/`_llnS` = dome selection flag, `_recl` = mean_len_recl). Convention: leading number = model/run id (01, 04, 22), word = baseline vs variant; 0/1 digits = FALSE/TRUE of the setting.
Assessment runs use `vers <- file.path('model', paste0('nwwg_', year))` (e.g. `model/nwwg_2026`).

Fixed vs estimated is encoded in the parameter template, not the folder: `g3_init_val('*.Linf', value, lower, upper, optimise = estimate_linf)`.

Important model switches in WKBDEEP (summary): growth fixed pars list by origin (`cc`/`ii`/`ff`; Linf 136/187/125, k 0.099/0.057/0.126, t0 0); `recruitment_free_pars` (one rec parameter per year, penalised random walk if `penalise_recruitment == 1`, else projection via `g3_param_project_logar1`); `initabun_by_age`/`initabun_by_stock` (4 initial-abundance modes, see comments); `single_fleet`/`dome_*`/`timevarying_*` (fleet selection: `g3_suitability_exponentiall50` vs `g3_suitability_andersenfleet`); `bmt_age` (age data likelihood); `stratified_indices`, `si_len_breaks <- c(20,44,56,68,80,92,104,140)`, `si_cv=0.2`; `iter_group_SI`, `cv_floor`; `naturalmortality <- 0.15`, `project_years <- 10`, `maxlengthgroupgrowth <- 4`, `lencv`.

---------------------------------------------------------------------------
## 6. Diagnostics: iterative, retro, bootstrap, jitter, profiles, leave-out, advice

All outputs under `<base_dir>/<vers>/<folder>/`; all rely on `tmb_model` (a compiled `g3_cpp`) and `parallel::mclapply`.

| Diagnostic | Flag / folder | Mechanism | Outputs |
|---|---|---|---|
| Iterative reweighting | `run_iterative`, `WGTS/` | `g3_iterative(file.path(base_dir, vers), wgts='WGTS', model=tmb_model, params.in=tmb_param, grouping=grouping, method='BFGS', control=optim_control, use_parscale=TRUE, shortcut=FALSE, cv_floor=cv_floor, resume_final=FALSE)`; then `fit <- g3_fit(model, params.out |> g3_init_guess('project_years',1))`; `sdout <- TMB::sdreport(obj.fun, g3_tmb_par(params.out))` | `WGTS/params_final.Rdata` (`params_final`, data.frame; weights are rows `*_weight`), `WGTS/fit.Rdata`, `WGTS/sdout.Rdata`, `figs/` (gadget_plots html) |
| Retrospective | `run_retro`, `RETRO/`, `number_of_peels=6` | For `peel` in 1..6: re-source `setup-likelihood.R` (data truncated by `peel`), rebuild `g3_to_tmb`, set `retro_params[[peel]]$value$retro_years <- peel`, starting from `params_final`; `parallel::mclapply(..., g3_optim(model, params, control))`; `g3_fit` each | `RETRO/retro_fit.Rdata` (`retro_fit`, list r1..r6); consumed by `gadgetplots::plot_retro`, `gadgetutils::mohnrho`. Alternative: `gadgetutils::g3_retro()` (commented) |
| Jitter | `run_jitter`, `JITTER_0/` or `JITTER_1/` (suffix = `jitter_optimised_pars`) | `gadgetutils::g3_jitter(file.path(base_dir,vers), outdir=jitter_folder, model=tmb_model, params=pars.in, njits=100, jitter_fraction=0.1, control=optim_control, mc.cores=bootstrap_cores)`; if `jitter_optimised_pars=FALSE` the non-weight parameters are reset to initial values and only weights taken from WGTS | `jitter_fit.Rdata` |
| Leave-out | `run_leaveout`, `LEAVEOUT/` | `gadgetutils::g3_leaveout(gd, outdir, model, param=pars.in, grouping=..., control)` (leave one likelihood group out) | `leaveout_fit.Rdata` (note script has typos `groupings`, `leaveout_optimised_pars` undefined) |
| M profile | `run_mprofile`, `M_PROFILE[_SHORT]/` | for `M_values <- seq(0.08,0.2,0.01)`: `g3_init_val('*.M.#', M)`; `profile_short=TRUE` -> `g3_optim` only (weights fixed from WGTS), else full `g3_iterative` per M in `WGTS_<name>` | `summary.txt` (`write.g3.file`), `profile_run.Rdata`, `profile_fit.Rdata` |
| Growth profile | `run_growthprofile`, `K_LINF_PROFILE_v2/` | grid `expand.grid(K=seq(0.06,0.2,0.02), Linf=seq(90,150,10))`, fixed via `g3_init_val(..., optimise=FALSE)`, `g3_iterative` each | `gw_profile_run.Rdata`, `gw_profile_fit.Rdata` |
| Bootstrap | `run_bootstrap`, `BOOTSTRAP[_SHORT]/`, `nboots=100`, `boot_short` | build `boot_model[[i]]` for `boot_repl` in 1..nboots by re-sourcing `setup-likelihood.R` (picks bootstrap data replicate); `boot_short=TRUE`: `g3_optim(boot_model[[i]], params_final)` (weights fixed), else `g3_iterative` per replicate (`BOOTSTRAP/WGTS_<i>`); parallel with `bootstrap_cores` | `boot_model.Rdata`, `boot_run.Rdata`, `boot_fit.Rdata` (list bs1..bsN); `plot_*` via `gadget_plots(fit, ..., boot_fit=boot_fit)` |
| Annual advice / projection | `setup-advice.R` | loads `params_final`, `fit`; interim-year catch fleets (`inter_bmt`, `inter_lln`; `g3a_predate(... g3a_predate_catchability_totalfleet(E = g3_timeareadata(...)), run_f = cur_year == tyr)`); `proj_actions <- c(attr(model,'actions'), inter_fleet_actions)`; `g3_to_tmb` -> `g3_to_r`; `g3p_setup_pars(r_proj, fit$params, blim, btrigger, harvest_rates = seq(0,0.5,0.01), rec_method='constant', rec_years=(tyr-3):(tyr-1), project_years=10, hr_pattern='project_hr.[0-9]')` (g3experiments) -> list of parameter sets -> `mclapply(..., g3_fit(r_proj, x))`; collate via `gadgetutils::bind_fit_components`; find harvest rate giving Fmsy (0.11) / status-quo F; TAC = catch scenario at Fmsy | `prognosis.Rdata` (`proj_runs, TAC, prognosis0, prognosis_msy, prognosis_sq`), `catch_options.csv` |

Projection machinery in the model itself: `dummy_stock` (ages 0..minage-1) carries projected recruits via `g3a_spawn(..., g3a_spawn_recruitment_hockeystick(r0 = scale * g3_param_table('project_rec', expand.grid(cur_year = ...)), blim=g3_parameterized('spawn_blim')))` with `run_f = cur_year >= end_year - minage + 1 && cur_step == 1`, and `g3a_age(dummy_stock, output_stocks = list(imm_stock), run_at = 1, transition_at = 8)`; fleets use `g3a_predate_catchability_project(quota_f = quotafunction(fleet), landings_f = g3_timeareadata(...), unit='biomass')` with `g3_quota(g3_quota_assess(predstocks, preystocks, function_f = g3_formula(assess_fn(...ftarget = g3_parameterized('F_target')...))), year_length=1L, start_step=4L, run_revstep=-3, run_f = quote(cur_year > end_year))` (`assess_fn` is defined in `R/model_functions.R`, not in the clone).

gadgetutils function use summary: `g3_iterative` (reweighting), `g3_optim` (single optimisation returning params + `attr(,'summary')`), `g3_fit` (fit object for plotting), `g3_init_guess` (set parameters by regexp; used in `params |> g3_init_guess('project_years', 1)` to switch off projection), `g3_jitter`, `g3_leaveout`, `g3_stock_name`, `bind_fit_components`, `write.g3.file`, `mohnrho`, `jitter_params`, internal `init_abund`, `init_sd`, `stock_renewal`, `model_actions`.

---------------------------------------------------------------------------
## 7. Annotated skeleton template (abridged, data-specific numbers removed)

File order: options -> stocks -> stock actions -> data -> fleets -> likelihood -> compile -> parameters -> diagnostics.

### 7.1 `setup.R` (runner)
```r
library(mfdb); library(gadget3); library(gadgetutils); library(gadgetplots)

## --- options (all plain variables; no config file) ---------------------------
base_dir <- 'assessment_model'
vers     <- file.path('model', paste0('run_', lubridate::year(Sys.Date())))
year_range   <- <FIRST_YEAR>:(lubridate::year(Sys.Date()) - 1)
species_name <- '<code>'                    # mfdb species code is toupper(species_name)
read_data <- FALSE                          # TRUE: query mfdb and write <base_dir>/data/*.Rdata
run_iterative <- TRUE; run_retro <- TRUE; run_bootstrap <- FALSE; run_jitter <- FALSE
wgts_folder <- 'WGTS'; retro_folder <- 'RETRO'; number_of_peels <- 6
nboots <- 100; boot_short <- TRUE; bootstrap_cores <- 35
optim_control <- list(maxit = 2000, reltol = 1e-10)
## model switches
estimate_linf <- FALSE; estimate_k <- FALSE; estimate_t0 <- FALSE
maxlengthgroupgrowth <- 4; naturalmortality <- 0.15; project_years <- 10
penalise_recruitment <- 1; recruitment_sigma <- 0.4
boot_repl <- 1; peel <- 0                   # globals read by setup-likelihood.R

## --- spatial / temporal defaults ---------------------------------------------
defaults <- list(
  area      = mfdb_group("1" = <SUBDIVISIONS>),
  timestep  = mfdb_timestep_quarterly,
  year      = year_range,
  project_years = project_years,
  species   = toupper(species_name),
  save_bootstrap_data = FALSE)
areas <- structure(seq_along(defaults$area), names = names(defaults$area))
time_actions <- list(g3a_time(start_year = min(defaults$year),
                              end_year   = max(defaults$year),
                              defaults$timestep), list())
fs::dir_create(file.path(base_dir, c('data', vers)))
save(defaults, areas, file = file.path(base_dir, vers, 'defaults.Rdata'))

## --- sub-scripts, in dependency order ----------------------------------------
source(file.path(base_dir, '00-setup', 'setup-stocks.R'))   # -> imm_stock, mat_stock, dummy_stock, stocks
source(file.path(base_dir, '00-setup', 'setup-model.R'))    # -> stock_actions
if (read_data) {
  mdb <- mfdb('<DB>', db_params = list(host = '<HOST>'))
  source(file.path(base_dir, '00-setup', 'setup-fleet-data.R'))
  source(file.path(base_dir, '00-setup', 'setup-catchdistribution.R'))
  source(file.path(base_dir, '00-setup', 'setup-indices.R'))
  source(file.path(base_dir, '00-setup', 'setup-initial_parameters.R'))
  mfdb_disconnect(mdb)
} else {
  fs::dir_ls(file.path(base_dir, 'data')) |>
    stringr::str_subset('.Rdata') |> stringr::str_subset('bootstrap', negate = TRUE) |>
    lapply(load, .GlobalEnv)
}
source(file.path(base_dir, '00-setup', 'setup-fleets.R'))        # -> fleet_actions
source(file.path(base_dir, '00-setup', 'setup-likelihood.R'))    # -> likelihood_actions
source(file.path(base_dir, '00-setup', 'setup-randomeffects.R')) # -> random_actions

## --- compile ------------------------------------------------------------------
actions <- c(stock_actions, fleet_actions, likelihood_actions,
             if (penalise_recruitment == 1) random_actions, time_actions)
tmb_model <- g3_to_tmb(c(actions, list(g3a_report_detail(actions)),
                         list(g3l_bounds_penalty(actions))))
model     <- g3_to_r(attr(tmb_model, 'actions'))

## --- parameters (glob patterns: '*' any, '#' any index) ------------------------
tmb_param <- attr(tmb_model, 'parameter_template') |>
  g3_init_val('*.rec.#',   50, lower = 0.001, upper = 100) |>
  g3_init_val('*.init.#',  50, lower = 0.001, upper = 100) |>
  g3_init_val('*.rec.sd',   5, lower = 0.1,   upper = 10)  |>
  g3_init_val('*.Linf', <LINF>, lower = <>, upper = <>, optimise = estimate_linf) |>
  g3_init_val('*.K',    <K>,    lower = <>, upper = <>, optimise = estimate_k) |>
  g3_init_val('*.t0',   <T0>,   lower = -2, upper = 0,  optimise = estimate_t0) |>
  g3_init_val('*.bbin', <BBIN>, lower = 1e-3, upper = <>) |>
  g3_init_val('*.M.#',  naturalmortality) |>                     # fixed (no lower/upper -> optimise by default? set optimise=FALSE if needed)
  g3_init_val('*.alpha', 0.1, lower = 0.01, upper = 1.5) |>      # S-shaped selection
  g3_init_val('*.l50',   <MEAN_MIDLEN>, spread = 0.5) |>
  g3_init_val('*.mat.alpha', 0.07, lower = 0.01, upper = 0.2) |>
  g3_init_val('*.mat.l50',   <L50_FROM_DATA>, spread = 0.5) |>
  g3_init_val('*.walpha', <A>) |> g3_init_val('*.wbeta', <B>) |> # length-weight constants from lw.constants
  g3_init_val('<sp>_recruitment_sigma', recruitment_sigma)

## --- test run and persistence --------------------------------------------------
result <- model(tmb_param$value)
gadget_plots(g3_fit(model, tmb_param), file_type = 'html', path = 'TEST')
save(tmb_param, file = file.path(base_dir, vers, 'tmb_param.Rdata'))
save(model,     file = file.path(base_dir, vers, 'r_model.Rdata'))
save(tmb_model, file = file.path(base_dir, vers, 'tmb_model.Rdata'))

## --- iterative reweighting ------------------------------------------------------
grouping <- list(sind = c(<SURVEY_INDEX_NLL_NAMES>), bmt = 'ldist_bmt', aut = 'ldist_aut')
if (run_iterative) {
  obj.fun    <- g3_tmb_adfun(tmb_model, tmb_param)
  params.out <- g3_iterative(file.path(base_dir, vers), wgts = wgts_folder,
                             model = tmb_model, params.in = tmb_param,
                             grouping = grouping, method = 'BFGS',
                             control = optim_control, use_parscale = TRUE,
                             shortcut = FALSE, cv_floor = 0, resume_final = FALSE)
  fit <- g3_fit(model, params.out |> g3_init_guess('project_years', 1))
  save(fit, file = file.path(base_dir, vers, wgts_folder, 'fit.Rdata'))
  gadget_plots(fit, file.path(base_dir, vers, 'figs'), file_type = 'html')
  save(TMB::sdreport(obj.fun, g3_tmb_par(params.out)) -> sdout,
       file = file.path(base_dir, vers, wgts_folder, 'sdout.Rdata'))
}

## --- retrospective (peel = years removed; likelihood script truncates data) ------
if (run_retro) {
  load(file.path(base_dir, vers, wgts_folder, 'params_final.Rdata'))
  retro_model <- retro_params <- list()
  for (peel in 1:number_of_peels) {
    source(file.path(base_dir, '00-setup', 'setup-likelihood.R'))
    ra <- c(stock_actions, fleet_actions, likelihood_actions,
            if (penalise_recruitment == 1) random_actions, time_actions)
    retro_model[[peel]]  <- g3_to_tmb(c(ra, list(g3a_report_detail(ra)),
                                        list(g3l_bounds_penalty(ra))))
    retro_params[[peel]] <- params_final
    retro_params[[peel]]$value$retro_years <- peel
  }
  peel <- 0
  retro <- parallel::mclapply(1:number_of_peels, function(x)
             g3_optim(retro_model[[x]], retro_params[[x]], control = optim_control),
             mc.cores = parallel::detectCores())
  retro_fit <- purrr::map(setNames(1:number_of_peels, paste0('r', 1:number_of_peels)),
                 function(x) g3_fit(retro_model[[x]], retro[[x]] |> g3_init_guess('project_years', 1)))
  save(retro_fit, file = file.path(base_dir, vers, retro_folder, 'retro_fit.Rdata'))
}
## jitter / leaveout / profiles / bootstrap follow the same pattern (see section 6)
```
(Caveat: `retro_years` must be a parameter of the model: `g3l_*` data must be restricted by `year <= max(year)-peel` in setup-likelihood.R; the `retro_years` value set on params is only meaningful if the model defines that parameter; check against current gadget3/gadgetutils.)

### 7.2 `setup-stocks.R`
```r
imm_stock <- g3_stock(c(species = tolower(species_name), 'imm'), seq(<LMIN>, <LMAX>, <DL>)) |>
  g3s_livesonareas(areas[c('1')]) |>
  g3s_age(minage = <A_MIN_IMM>, maxage = <A_MAX_IMM>)
mat_stock <- g3_stock(c(species = tolower(species_name), 'mat'), seq(<LMIN2>, <LMAX2>, <DL>)) |>
  g3s_livesonareas(areas[c('1')]) |>
  g3s_age(minage = <A_MIN_MAT>, maxage = <A_MAX_MAT>)
## Dummy ages below the recruitment age: carries projected recruits (no data)
dummy_stock <- g3_stock(c(species = tolower(species_name), 'dummy'),
                        lengthgroups = seq(min(g3_stock_def(imm_stock, 'minlen')),
                                           tail(g3_stock_def(imm_stock, 'maxlen'), n = 2)[[1]],
                                           min(g3_stock_def(imm_stock, 'dl')))) |>
  g3s_livesonareas(areas[c('1')]) |>
  g3s_age(minage = 0, maxage = g3_stock_def(imm_stock, 'minage') - 1)
stocks <- list(imm_stock, mat_stock)    # dummy_stock is NOT in `stocks` (not fished / no likelihood)
```

### 7.3 `setup-model.R` (two-stock actions)
```r
initabun <- g3a_renewal_initabund(
  scalar = g3_parameterized('init.scalar', value = 1, by_stock = stocks),
  init   = g3_parameterized('init', by_stock = stocks, by_age = TRUE, value = 1),
  M      = g3_parameterized('M',    by_stock = stocks, by_age = TRUE),
  init_F = g3_parameterized('init_F', by_stock = stocks, value = 0, optimise = FALSE),
  proportion_f = g3a_initial_ageprop(),        # logistic split of age classes between imm/mat
  recage = g3_stock_def(imm_stock, 'minage'))

common_pars <- list(
  mean_len = g3a_renewal_vonb_t0(K = g3_parameterized('K', by_stock = stocks), by_stock = stocks),
  var_len  = g3_parameterized('lencv', by_stock = stocks, by_age = TRUE))

imm_actions <- list(
  g3a_initialconditions_normalcv(imm_stock, factor_f = initabun,
                                 mean_f = common_pars$mean_len, cv_f = common_pars$var_len),
  g3a_naturalmortality(imm_stock, g3a_naturalmortality_exp(by_stock = stocks)),
  g3a_age(imm_stock, output_stocks = list(mat_stock)),
  g3a_growmature(imm_stock,
    impl_f = g3a_grow_impl_bbinom(
      delta_len_f = g3a_grow_lengthvbsimple(kappa_f = g3_parameterized('K', by_stock = stocks),
                                            by_stock = stocks),
      beta_f = g3_parameterized('bbin', by_stock = stocks, exponentiate = TRUE),
      maxlengthgroupgrowth = maxlengthgroupgrowth),
    maturity_f = g3a_mature_continuous(),
    output_stocks = list(mat_stock),
    transition_f = ~TRUE),
  g3a_renewal_normalcv(imm_stock,                 # free annual recruitment
    factor_f = g3_parameterized('rec', by_stock = TRUE, by_year = TRUE,
                                scale = g3_parameterized('rec.scalar', value = 1, by_stock = TRUE),
                                ifmissing = NaN),
    mean_f = common_pars$mean_len,
    cv_f   = g3_parameterized('recl.cv', by_stock = stocks),
    run_projection = FALSE),
  list())

mat_actions <- list(                               # same pattern: init conditions, M, age, growth (no maturity/output)
  g3a_initialconditions_normalcv(mat_stock, factor_f = initabun, mean_f = common_pars$mean_len, cv_f = common_pars$var_len),
  g3a_naturalmortality(mat_stock, g3a_naturalmortality_exp(by_stock = stocks)),
  g3a_age(mat_stock),
  g3a_growmature(mat_stock, impl_f = <same g3a_grow_impl_bbinom as above>),
  ## projection recruitment: mature stock "spawns" into dummy stock
  g3a_spawn(stock = mat_stock, proportion_f = g3_suitability_<sp>(),
            recruitment_f = g3a_spawn_recruitment_hockeystick(
               r0 = ~scale * g3_param_table('project_rec', expand.grid(cur_year = <PROJ_YEARS>), value = 0, optimise = FALSE, ifmissing = 0),
               blim = g3_parameterized('spawn_blim', value = 1, optimise = FALSE)),
            output_stocks = list(dummy_stock),
            mean_f = <mean_rec_len>, stddev_f = <mean_rec_len * recl.cv>,
            run_f = g3_formula(cur_year >= (end_year - minage + 1) && cur_step == 1, list(minage = <MINAGE_IMM>))),
  list())

dummy_actions <- list(g3a_age(dummy_stock, output_stocks = list(imm_stock),
                              run_f = g3_formula(cur_year >= (end_year - minage + 2) && cur_step == 1),
                              run_at = 1, transition_at = 8))
stock_actions <- c(imm_actions, mat_actions, dummy_actions, list())
```
(Single-stock variant `setup-model-single-stock.R`: one `single_stock` with `g3a_initialconditions_normalcv`, M, age, `g3a_growmature` without maturity, renewal.)

### 7.4 `setup-fleets.R`
```r
lln <- g3_fleet('lln') |> g3s_livesonareas(areas[c('1')])
bmt <- g3_fleet('bmt') |> g3s_livesonareas(areas[c('1')])
foreign <- g3_fleet('foreign') |> g3s_livesonareas(areas[c('1')])
aut <- g3_fleet('aut')  |> g3s_livesonareas(areas[c('1')])      # survey "fleet" with dummy landings
fleets <- list(bmt, lln, foreign)

quotafunction <- function(x) {                  # projection-only quota (active when cur_year > end_year)
  g3_quota(g3_quota_assess(predstocks = x, preystocks = list(mat_stock),
             function_f = g3_formula(assess_fn(cur_year, cons, abund, meanwgt, M = <M>, btrigger = <>,
                                               ftarget = g3_parameterized('F_target'),
                                               trigger_stock = "<sp>_mat", biomass_prop = 1L, lag_steps = 2L))),
           year_length = 1L, start_step = 4L, run_revstep = -3, run_f = quote(cur_year > end_year))
}
fleet_actions <- list(
  lln |> g3a_predate_fleet(stocks,
           suitabilities = g3_suitability_exponentiall50(alpha = g3_formula(g3_param('<sp>.lln.alpha')),
                                                         l50   = g3_formula(g3_param('<sp>.lln.l50'))),
           catchability_f = gadget3:::g3a_predate_catchability_project(
               quota_f    = quotafunction(lln),
               landings_f = g3_timeareadata('lln_landings', lln_landings[[1]] |>
                              mutate(area = as.numeric(area), step = as.numeric(step), year = as.numeric(year))),
               unit = 'biomass')),
  ## bmt and foreign: same, different suitabilities (foreign shares lln selectivity)
  aut |> g3a_predate_fleet(stocks,
           suitabilities = g3_suitability_exponentiall50(by_stock = stocks),
           catchability_f = g3a_predate_catchability_totalfleet(
               g3_timeareadata('aut_landings', aut_landings |> mutate(<numeric area, step, year>)))),
  list())
```
Dome selection alternative: `g3_suitability_andersenfleet(p1 = g3_parameterized('...andersen.p1', by_stock = stocks), p3 = ..., p4 = ..., p5 = max(sapply(stocks, g3_stock_def, 'maxmidlen')), by_stock = stocks)`.

### 7.5 `setup-likelihood.R`
```r
nll_breakdown <- TRUE; lik_report <- TRUE
likelihood_actions <- list(
  g3l_understocking(stocks, nll_breakdown = nll_breakdown, weight = 100),
  g3l_catchdistribution(nll_name = 'ldist_bmt',
      obs_data = ldist.bmt[[boot_repl]] |> filter(year >= min(defaults$year)),
      fleets = list(bmt), stocks = stocks,
      function_f = g3l_distribution_sumofsquares(),
      nll_breakdown = nll_breakdown, report = lik_report),
  ## ldist_lln, ldist_aut: same pattern
  g3l_catchdistribution(nll_name = 'matp_aut',                       # maturity-stage proportions
      obs_data = matp.aut[[boot_repl]] |> rename(stock = maturity_stage) |>
                 mutate(stock = recode(as.factor(stock), <sp>imm = '<sp>_imm', <sp>mat = '<sp>_mat')),
      fleets = list(aut), stocks = stocks, function_f = g3l_distribution_sumofsquares(), ...))

## one survey-index component per length group
si_lik_actions <- list()
for (i in names(aut.SI[[boot_repl]])) {
  si_lik_actions <- c(si_lik_actions, g3l_abundancedistribution(
      nll_name = paste0('si_', fix_name_length(i), '_AUT'),
      obs_data = aut.SI[[boot_repl]][[i]] |> filter(year <= max(defaults$year) - peel),
      fleets = list(), stocks = stocks,
      function_f = g3l_distribution_surveyindices_log(beta = 1),
      nll_breakdown = nll_breakdown, report = lik_report))
}
likelihood_actions <- c(likelihood_actions, list(si_lik_actions), list())
```
(Weights appear as parameters named `<nll_name>_weight`; `g3_iterative` estimates them from the `grouping` list; components not in `grouping` are treated individually; penalty components are left alone.)

### 7.6 `setup-randomeffects.R`
```r
random_actions <- list(
  g3l_random_walk(nll_name = 'recruitment',
                  param_f = substitute(log(avoid_zero(x)),
                              list(x = g3_parameterized(paste0(gadgetutils::g3_stock_name(imm_stock), '.rec'),
                                                        by_year = TRUE, random = penalise_recruitment == 0,
                                                        ifmissing = NaN))),
                  period = 'year',
                  sigma_f = g3_parameterized('<sp>_recruitment_sigma')))
```
(penalise_recruitment = 1: recruitment is a fixed-effect vector penalised by a random-walk nll with fixed sigma; = 0: `random=TRUE` true random effects, requires `nlminb` + `TMB::sdreport`; see gadget3 article "Random effects & projections".)

### 7.7 Data scripts (pattern)
```r
## setup-fleet-data.R
lln_landings <- mfdb_sample_totalweight(mdb, NULL, c(list(gear = c('HLN','LLN'), sampling_type = 'LND',
                                                          species = defaults$species), defaults))
aut_landings <- structure(data.frame(year = defaults$year, step = 4, area = 1, total_weight = 1),
                          area_group = mfdb_group(`1` = 1))                 # survey: nominal catch
save(lln_landings, bmt_landings, foreign_landings, aut_landings, comm_landings, deep_landings,
     file = file.path(base_dir, 'data', 'fleet_data.Rdata'))

## setup-catchdistribution.R
ldist.aut <- mfdb_sample_count(mdb, c('age','length'), c(list(
    data_source = 'iceland-ldist', sampling_type = 'AUT',
    age    = mfdb_interval('all', c(minage, maxage), open_ended = c('upper','lower')),
    length = mfdb_interval('len', seq(minlen, maxlen, by = dl), open_ended = c('upper','lower'))), defaults))
ldist.aut[[1]]$step <- 4                                                    # survey timing fix
matp.aut <- mfdb_sample_count(mdb, c('maturity_stage','age','length'), append(defaults, list(
    sampling_type = 'AUT',
    length = mfdb_interval('len', seq(minlen, maxlen, by = 2*dl), open_ended = c('lower','upper')),
    maturity_stage = mfdb_group(<sp>imm = 1, <sp>mat = 2:5))))             # maturity stage -> stock name
save(ldist.aut, matp.aut, ldist.lln, ldist.bmt, ldist.comm,
     file = file.path(base_dir, 'data', if (defaults$save_bootstrap_data) 'catchdistribution_bootstrap_data.Rdata'
                                        else 'catchdistribution_data.Rdata'))
## start values from data: lw regression (lm(log(weight/1e3) ~ log(length))), init.cv (cv of length by age),
## mat.l50 (smallest length with >50% mature), von Bertalanffy nls() on age-length -> growth_vals
save(lw.constants, mat.l50, init.sigma, mat.a50, init.sigma.coef, init.cv, file = file.path(base_dir, 'data', 'init_param.Rdata'))

## bootstrap data (separate run): defaults$area <- mfdb_bootstrap_group(nboots, mfdb_group('1' = <DIVISIONS_WITH_DATA>), seed = <SEED>)
##                                  defaults$save_bootstrap_data <- TRUE ; re-run catchdistribution + indices scripts
```

### 7.8 Reproducing the structure for a new stock (checklist)
1. Copy `00-setup/` and `data/`; edit options block (`base_dir`, `vers`, `year_range`, `species_name`, flags).
2. Edit stocks (length groups, ages), `common_pars`, fleets (gear codes, sampling types), likelihood names and data filters.
3. Run with `read_data <- TRUE` once (DB access) to create `data/*.Rdata`; then `FALSE`.
4. First get the R model running: `model(tmb_param$value)`; `gadget_plots(g3_fit(model, tmb_param))`; fix NaN with `g3a_trace_nan`/debug article.
5. `g3_iterative` with grouping; check `fit` plots; then retro (6 peels), jitter, bootstrap; then projections/advice script.
6. Name each version `<NN>-<label>_<setting codes>`; keep `fit.Rdata` (small) and drop big `r_model.Rdata` if disk matters.

---------------------------------------------------------------------------
## 8. Observations / gotchas for agents
* Mixed vintage: `g3_init_val` (gadget3 >= 0.14, glob patterns) in WKBDEEP vs `g3_init_guess` (regex, gadgetutils; arguments value/lower/upper/optimise) in `06-ling` and older bling; WKBDEEP still uses `g3_init_guess('project_years', 1)` only to set the number of projection years to 1 for fitting.
* `gadget3:::` internal functions are used (`g3a_predate_catchability_project`, `f_substitute`, `stock_definition`) - may break across versions; `gadgetutils:::split_length`, `gadgetutils:::...` likewise.
* Scripts rely on globals; sub-scripts are re-sourced inside loops (`peel`, `boot_repl`).
* `mc.cores = parallel::detectCores()` default forks all cores; WKBDEEP uses 35 cores for bootstrap; mclapply is not available on Windows.
* ling gadget3 (`06-ling/gadget3`) uses `g3_parameterized(..., by_stock = 'species')`, the older `g3a_renewal_normalparam` with `wgt_by_stock`, tagging stocks, and `g3a_report_history(actions, '^ling_(imm|mat)__(num|wgt|igfs|lln|bmt|gil|foreign|suit_igfs|renewalnum|renewalwgt)$')`; `g3l_understocking(weight = 1e6)`.
* Data scripts reference external things not in the clone (`mar` package, `data/survey_indices.Rdata`, `data/greenland/logbooks_00-23.csv`, `R/model_functions.R`, `setup-interim_catch.R`, `advice/tables/ref_points.csv`).
* Hard-coded values (e.g. `g3_suitability_blueling` coefficients, growth parameters by origin, filters on specific years) are stock-specific and must be revisited for a new stock.
