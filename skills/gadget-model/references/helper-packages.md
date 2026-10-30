# gadget3 helper packages: reference digest

Sources (clones, read-only): gadgetutils, gadgetplots, g3experiments, mfdb. Version stamps: gadgetutils DESCRIPTION 0.0.0.9000 (no NEWS file, README is a 10-line stub); gadgetplots 0.3.11 (README says 0.3.8; no NEWS); g3experiments 0.3.999 (2022-10-07; README is 2 lines; NO roxygen docs at all, only `# comment` headers); mfdb 7.3-99 (NEWS.md present).
Signatures below were extracted programmatically from `R/` (parse + deparse), so they are verbatim modulo deparse spacing/quote style (single quotes in source appear as double quotes). `file:line` is the line of the `name <- function` definition.
Conventions used in this digest: "params" = gadget3 parameter template data.frame (`attr(model_cpp,'parameter_template')`, columns include switch, value, lower, upper, optimise, random, parscale, type, source; `value` is a list-column; rownames = switch). "tmb model" = `gadget3::g3_to_tmb(actions)` (class `g3_cpp`); "R model" = `g3_to_r(actions)` (class `g3_r`, has `attr(,'actions')`).

---------------------------------------------------------------------------
# PART A. gadgetutils
---------------------------------------------------------------------------

Purpose (DESCRIPTION): "A collection of functions to aid (1) setting up and maintaining gadget3 models, (2) optimising, analysing, and running diagnostics on gadget3 models." Authors W. Butler, B. T. Elvarsson, J. Lentin, M. Vihtakari (MFRI Iceland). Imports: dplyr, gadget3, magrittr, purrr, rlang, tibble, tidyr, tidyselect, modelr, parallel. Suggests unittest. Install: `devtools::install_github("gadget-framework/gadgetutils")` (README is only this + "in active development"). Tests: tests/test-g3_fit-modelformats.R, tests/test-g3_iterative-default_grouping.R (unittest style, run via script not testthat).
NAMESPACE exports (36): %>%, add_g3_attributes, bind_fit, bind_fit_components, estimate_weights, estimate_weights_adist, estimate_weights_cdist, eval_bounded, extract_year_step, g3_add_parscale, g3_data, g3_fit, g3_init_guess, g3_iterative, g3_iterative_default_grouping, g3_iterative_setup, g3_jitter, g3_leaveout, g3_lik_out, g3_optim, g3_retro, g3_sensitivity, g3_stock_name, g3_update_weights, init_abund, init_sd, jitter_params, model_actions, mohnrho, read.g3.param, stock_renewal, stock_species, tabulate_SS, value_from_bounds, write.g3.file, write.g3.param.
NOT exported (internal, in R/internal_functions.R / g3_optim.R): `run_g3_optim` (the parallel driver used by every g3_* analysis), `check_params_out`, `check_null_params`, `echo_message`, `save_obj`, `g3_fit_inner`, `split_length`, `replace_inf`, `split_age`.

## A.1 Typical workflow (as used in gadget-models/07-bling/gadget3*/00-setup/setup.R)

1. Data: `mfdb::mfdb_sample_count(...)` OR `gadgetutils::g3_data(df, params=list(...))` / `add_g3_attributes()` -> data.frames carrying gadget3 aggregation attributes -> `gadget3::g3l_catchdistribution()` etc.
2. Actions: hand-written, or the helper `model_actions(imm, mat, ...)`; add `g3l_bounds_penalty(actions)` (now in gadget3, NOT g3experiments) and `g3a_report_detail(actions)` for reporting.
3. `tmb_model <- gadget3::g3_to_tmb(actions)`; `tmb_param <- attr(tmb_model,'parameter_template')`; set initial values with `gadget3::g3_init_val(...)` or `gadgetutils::g3_init_guess(...)`.
4. `params.out <- g3_iterative(gd, wgts='WGTS', model=tmb_model, params.in=tmb_param, grouping=..., cv_floor=..., control=optim_control, use_parscale=TRUE, shortcut=FALSE, resume_final=FALSE)` (or plain `g3_optim`).
5. `fit <- g3_fit(model, params.out)`; `save(fit, file=.../fit.Rdata)`; `gadgetplots::gadget_plots(fit, path, file_type='html')`; `TMB::sdreport(obj.fun, g3_tmb_par(params.out))`.
6. Diagnostics: `g3_retro` (analytical retro), `g3_jitter`, `g3_leaveout`, `g3_sensitivity` / profile runs, `mohnrho`; map `g3_fit` over each returned parameter table to get a list of `gadget.fit` for plot_retro/plot_jitter/plot_leaveout. Example from setup.R: `retro_fit <- 1:n |> set_names(paste0('r',1:n)) |> purrr::map(function(x) g3_fit(model=retro_model[[x]], params=retro[[x]] |> g3_init_guess('project_years',1)))`.
7. Projections: `g3_fit(r_proj, x)` mapped over `g3experiments::g3p_setup_pars()` output (Part C); combine with `bind_fit_components(proj_runs,'res.by.year')`.

Cross-cutting facts (apply to every g3_* analysis function):
* Every analysis function takes `gd` (base dir) + `outdir` (sub-dir name), creates `file.path(gd,outdir)`, and writes `.Rdata` inputs/outputs plus an `optim.summary.*` text file there.
* If `model` has class `g3_r` it is recompiled with `g3_to_tmb(attr(model,'actions'))` (so the R model must carry the 'actions' attribute). A TMB (`g3_cpp`) model is expected.
* `params` MUST be the data.frame template (checked with `inherits(params,'data.frame')`), not a list.
* Parallelism: all go through `run_g3_optim()`. `mc.cores = parallel::detectCores()` default (ALL cores incl. hyperthreads -> RAM blow-ups with big TMB models); `mc.cores==1` -> serial `lapply`; otherwise `parallel::mclapply` (FORK). Warnings inside forks are captured and replayed afterwards. `gc()` is called before forking. `serial_compile=TRUE` first builds one `g3_tmb_adfun` per parameter set serially (message "COMPILING MODEL AND CREATING ADFUN IN SERIAL") and then forks only the optimisation, "potentially helping with memory issues".
* OS caveats: `mclapply` forking is unavailable on Windows (mc.cores>1 errors -> use mc.cores=1). `echo_message()` is implemented with `system(sprintf("echo '%s'", ...))` so it needs a POSIX shell and breaks on messages containing a single quote. `g3_jitter` also uses mclapply for the jitter generation itself when mc.cores>1. The bling script wraps g3_iterative in `parallel::mclapply(..., mc.cores=bootstrap_cores)` with inner `mc.cores = 1` to avoid nested forking.
* Result list elements may be `NULL` or `try-error` if a fork died; `check_params_out` / `check_null_params` convert these into summary rows (`return_complete = 0`) and warnings.
* Quirk (bug-like): in g3_jitter/g3_retro/g3_leaveout/g3_sensitivity the guard is `if (!exists(out_path)) dir.create(...)` -- `exists()` tests for an R *object* of that name, so it is always FALSE and dir.create is always attempted (harmless, `showWarnings=FALSE`). g3_iterative uses the correct `dir.exists`.

## A.2 Exported function inventory

### A.2.1 Data preparation

**g3_data** — aggregate a plain data.frame into gadget3-ready data (mimics `mfdb_sample_*` without a DB). 
`R/g3_data.R:36`
```r
g3_data <- function(x, params = list(), method = "count", column_names = c(year = "year", step = "month", area = "areacell"), floating_point_correction = TRUE, verbose = FALSE)
```
Returns: data.frame (cols: year, step, area, + the non-year/step/area names of `params`, then `number` (method="count") or the summed column named by `method`); attributes: `year` (named list), one attribute per `params` entry (mfdb_group as-is; `list` -> as-is; mfdb_interval -> list of `seq(min,max-1)` calls with attrs min/max/min_open_ended/max_open_ended), `generator="g3_data"`. Details in A.3.1.

**add_g3_attributes** — attach gadget3 aggregation attributes (and missing constant columns) to an existing data.frame (manual import, no mfdb).
`R/add_g3_attributes.R:22`
```r
add_g3_attributes <- function(x, params, warn = 1)
```
Returns `x` with attributes `year`, per-param attrs, `generator="add_g3_attributes"`; adds missing columns named in `params` filled with the first-level label. Temporarily sets `options(warn=warn)` (use warn=2 to error on attribute/column mismatch; warn is restored at the end, but not on error exit). Warns "Unique column and attribute values for <k> do not match: ...". Source comment example: `read.csv(...) %>% rename(year=startyear, weight=bm) %>% add_g3_attributes(params=list(year=model_params$year_range, step=model_params$timestep_fun, length=mfdb_interval("all", c(40, maxlength), open_ended="upper")))`.

### A.2.2 Optimisation and analysis runners

**g3_optim** — wrapper around `stats::optim` that builds the TMB objective and returns the parameter template with optimised values. 
`R/g3_optim.R:15`
```r
g3_optim <- function(model, params, use_parscale = TRUE, method = "BFGS", control = list(), print_status = FALSE, print_id = "g3_optim", check_finite = TRUE, ...)
```
Returns: params data.frame with optimised `value`s (from `obj_fun$env$last.par.best`, so random effects included) and attribute `summary` (1-row data.frame: type='g3.optim', id, method, maxiter, reltol, optim_complete, fn_calls, gd_calls, convergence (TRUE/FALSE/NA), score, wallclock_s, return_complete, comment). `model` may be a `g3_cpp` model (then `gadget3::g3_tmb_adfun(model, params, ...)` is built, `...` passes to it, e.g. `inner.control`, `silent`, `type`) OR an already built objective list with `par`,`fn`,`gr` (e.g. from `g3_tmb_adfun`). Defaults injected into `control` if absent: `maxit=1000`, `trace=2`, `reltol=.Machine$double.eps^2`. `method='L-BFGS-B'` uses `g3_tmb_lower/upper(params)` bounds; any other method is unbounded (+/-Inf). `use_parscale=TRUE` adds `control$parscale = g3_tmb_parscale(params)` and errors on NA parscale (names offending params). `check_finite=TRUE` evaluates fn/gr at start and at optimum and WARNS (suggests `g3a_trace_nan()`) on non-finite nll or gradient. If optim throws, returns a template with `value` NA and `summary$optim_complete=0`. `print_id` appended to messages. Errors use `cat(); stop()` (message printed before stop).

**g3_iterative** — iterative likelihood re-weighting (Taylor et al. style). 
`R/g3_iterative.R:76`
```r
g3_iterative <- function(gd, wgts = "WGTS", model, params.in, grouping = g3_iterative_default_grouping(params.in), use_parscale = TRUE, method = "BFGS", control = list(), shortcut = FALSE, cv_floor = 0, resume_final = FALSE, serial_compile = FALSE, mc.cores = parallel::detectCores())
```
Full algorithm in A.3.2. Returns: final params data.frame (also saved as `params_final.Rdata`), or `NULL` if every stage-2 run failed.

**g3_iterative_default_grouping** — build `grouping` list from weight parameter names. 
`R/g3_iterative.R:393`
```r
g3_iterative_default_grouping <- function(params.in, nll_dist_names = c("ldist", "aldist", "matp", "sexdist", "SI", "len\\d+SI"))
```
Expects rownames of `params.in` of the form `^(.dist|.sparse)_(surveyindices_log|[a-z]+)_(<nll_source>)_(<nll_dist>)_weight$` where nll_dist in `nll_dist_names` (default ldist, aldist, matp, sexdist, SI, len\d+SI). Returns named list nll_source -> character vector `"<source>_<dist>"` (e.g. `list(comm=c("comm_ldist","comm_aldist"), surv="surv_si")`). Weight-0 parameters are dropped with a warning; non-matching components (e.g. `argle`) silently omitted. Note the default regexes use `SI`/`len\d+SI` (case-sensitive), so lower-case `si` indices need `nll_dist_names=c(..., "si")` (the unit test does this).

**g3_iterative_setup** — build stage-1 parameter sets. 
`R/g3_iterative.R:431`
```r
g3_iterative_setup <- function(lik_out, grouping = list())
```
`lik_out` is the output of `g3_lik_out` (only rows with weight>0 are passed by g3_iterative). Errors if grouping names don't match component names (hint if a stale `log_` prefix is used). Returns named list of params (one per group; ungrouped components become their own group named by component), attribute `grouping` = data.frame(comp, group, param_name). Initial weight = 1/value (inverse SS) for ALL components in every set; for the group being optimised the weight is multiplied by 1e4.

**g3_lik_out** — run model once, tabulate likelihood component df/value/weight. 
`R/g3_iterative.R:488`
```r
g3_lik_out <- function(model, param)
```
Builds `g3_tmb_adfun(model,param,type='Fun')`, `$report()`; if `res$nll` is NULL, recompiles with `g3a_report_detail(actions, run_f=TRUE)` appended. Returns tibble(comp, df, value, weight) with attrs `param`, `nll`. df = count of >0 entries in `^(a|c)dist_.+_obs__(wgt|num)$`; value = sum of `nll_.dist_..__(wgt|num)`; sparse data (`asparse`) handled via `nll_asparse_*__obs_mean` length and `__nll` (linreg: named `nll`); source comment "SHOULD USE OBS_N IF IT EXISTS, NEED TO ADD".

**g3_update_weights** — stage-2 weights. 
`R/g3_iterative.R:577`
```r
g3_update_weights <- function(lik_out_list, grouping, cv_floor)
```
variance = value/df; weight = 1/variance (0 if value==0 or weight==0). `cv_floor` applied ONLY to components whose name contains `_surveyindices_`: `variance <- pmax(variance, cv_floor)`, i.e. max weight = 1/cv_floor. Returns list of params (same names as lik_out_list) with new weights written for ALL grouped components.

**tabulate_SS** — component score tables. 
`R/g3_iterative.R:626`
```r
tabulate_SS <- function(lik_out, grouping)
```
Returns `list(SS=, SS_norm=)` data.frames; rows = group (rownames), first col `.id` (components joined by '.'), one column per component; SS_norm divides each group's own components by the value in that group's own row (so diagonal-ish entries = 1).

**estimate_weights / estimate_weights_cdist / estimate_weights_adist** — "shortcut" (non-iterative) weights. 
`R/g3_iterative_shortcut.R:7`
```r
estimate_weights <- function(model, params)
```
`R/g3_iterative_shortcut.R:44`
```r
estimate_weights_cdist <- function(dat)
```
`R/g3_iterative_shortcut.R:71`
```r
estimate_weights_adist <- function(dat)
```
estimate_weights: runs model (`type='Fun'`), takes reports `^cdist_(sumofsquares|multinomial)_.+_obs__(wgt|num)` (-> cdist estimator) and `(adist|cdist)_surveyindices_.+_obs__(wgt|num)` (-> adist estimator); returns data.frame(comp, ss, weight=1/ss) with `comp` renamed `..._weight` (matches params$switch). cdist: per-time proportions p, phat = mean p by (age,length) over time, ss = sum((p-phat)^2/n). adist: loess (span .75) of log(Freq) on year, ss = sum(resid^2)/n. Code comment: "TODO Mutate time to include 'step'"; estimate_weights_cdist has a hack for missing age column (author note to Mikko).

**g3_jitter / jitter_params** — jitter analysis. 
`R/g3_jitter.R:20`
```r
g3_jitter <- function(gd, outdir = "JITTER", model, params, njits = 10, jitter_fraction = 0.1, pattern_to_ignore = NULL, within_bounds = TRUE, use_parscale = TRUE, method = "BFGS", control = list(), serial_compile = FALSE, mc.cores = parallel::detectCores())
```
`R/g3_jitter.R:108`
```r
jitter_params <- function(params, jitter_fraction = 0.1, pattern_to_ignore = NULL, within_bounds = TRUE)
```
g3_jitter returns list of optimised param tables named "1".."njits" with class `c('g3.jitter','list')`; writes `jitpar_in.Rdata`, `jitpar_out.Rdata`, `optim.summary.jitter` (id column named jitter_id). jitter_params: multiplicative uniform noise `value*(1+U(-f,f))` on `g3_tmb_par(params, include_random=FALSE)` (parameters named `*_exp` are exp'd, jittered, re-logged); `within_bounds=TRUE` pushes values beyond bounds to 10% inside the bound; `pattern_to_ignore` (regex on params$switch) restores original values (warns if no match). NB: because jittering is multiplicative, parameters with value 0 never move; weights (`*_weight`) are jittered too unless ignored (bling script resets non-weight params to initial values and keeps optimised weights).

**g3_retro** — analytical retrospective. 
`R/g3_retro.R:17`
```r
g3_retro <- function(gd, outdir = "RETRO", model, params, nyears = 5, use_parscale = TRUE, method = "BFGS", control = list(), serial_compile = FALSE, mc.cores = parallel::detectCores())
```
Requires parameter row `retro_years` (comes from `g3a_time`; "Make sure g3a_time is included ... with 'retro_years' set to its default"). For i in 1:nyears sets `value$retro_years <- i` and re-optimises from the SAME starting params (so pass optimised params, typically from g3_iterative, with weights fixed). Returns list named "1".."nyears" (years peeled), class `c('g3.retro','list')`; writes `retro_params_in.Rdata`, `retro_params_out.Rdata`, `optim.summary.retro` (id col `nyears_peeled`), and `retro.params.out.<i>year`. To plot: map `g3_fit` over the list (need models for the shortened series for correct likelihood data? the bling script builds separate retro_model objects; with retro_years the same compiled model is used) -> `gadgetplots::plot_retro`; `mohnrho(fit, retro_fit)`. NB gadgetplots::plot_retro expects the FIRST element to be the un-peeled fit, so prepend the base fit.

**g3_leaveout** — leave-one-out of likelihood components. 
`R/g3_leaveout.R:20`
```r
g3_leaveout <- function(gd, outdir = "LOCV", model, params, grouping = list(), use_parscale = TRUE, method = "BFGS", control = list(), serial_compile = FALSE, mc.cores = parallel::detectCores())
```
Components detected from `params$switch` ending `_weight`, stripped of `^.dist_(surveyindices_log|[a-z]+)_` prefix. `grouping` = list of component-name vectors to drop together; all ungrouped components each become their own group. For each group the weights of matching `_<comp>_weight` params are set to 0 and the model re-optimised. Returns list named by group (class `c('g3.leaveout','list')`); writes `leaveout_params_in.Rdata`, `leaveout_params_out.Rdata`, `optim.summary.leaveout` (columns: type, group_excluded, components_excluded, then method, maxiter, reltol, optim_complete, fn_calls, gd_calls, convergence, score, return_complete, comment). Caveat: the zeroing regex is `paste0('_', x, '_weight')` joined by `|`, unanchored. Plot with `gadgetplots::plot_leaveout(lo_fit)`.

**g3_sensitivity** — one-parameter sensitivity / likelihood-profile runs. 
`R/g3_sensitivity.R:20`
```r
g3_sensitivity <- function(gd, outdir = "SENS", model, params, par_name, par_values, use_parscale = TRUE, method = "BFGS", control = list(), serial_compile = FALSE, return_input_parameters = FALSE, run_optimisations = TRUE, mc.cores = parallel::detectCores())
```
`par_name` is a glob like `g3_init_val` name_spec (`*` wildcard, `#` numeric, `[1979-1984]` range, `|` alternatives, `.`-separated parts; `_exp` variants auto-matched and `par_values` are log()-ed for them). For each `par_values[i]` the matching params are set to that value; names of result list are `paste(gsub('\\*\\.|\\.#','',par_name), value, sep='_')` (e.g. `M_0.2`). Modes: `return_input_parameters=TRUE` -> just the modified templates (no output dir files); `run_optimisations=FALSE` -> returns list of `g3_fit()` on the unoptimised templates (needs R/TMB model with actions); default -> optimise each (fixed values only stay fixed if the matching params have `optimise=FALSE`; if they ARE optimised the function warns "will be optimised" and errors if par_values lie outside lower/upper). Returns list (class `c('g3.sens','list')`); writes `senpar_in.Rdata`, `senpar_out.Rdata`, `optim.summary.sensitivity` (id col `sensitivity_id`). If nothing matches: warning (message says `g3_init_val(...)`) and returns `params`. Likelihood profile recipe (bling setup.R): set `pars.in[[i]] <- pars.tmp |> g3_init_val('*.M.#', M_values[i])` (optimise FALSE), then `try(g3_optim(...))` or `try(g3_iterative(gd, wgts=file.path(profile_folder, paste0('WGTS_',x)), tmb_model, pars.in[[x]], grouping=..., cv_floor=cv_floor, control=optim_control, use_parscale=TRUE, mc.cores=1))` inside `parallel::mclapply(..., mc.cores=bootstrap_cores)`, then `lapply(profile_run, function(x) attr(x,'summary')) |> bind_rows(.id='id')` and `g3_fit` each.

**mohnrho** — Mohn's rho from retro fits. 
`R/mohnrho.R:11`
```r
mohnrho <- function(fit, retrofit, vars = c("total.biomass", "F", "recruitment"), lag = c(0, 1, 1), aggregate_biomass = TRUE)
```
`fit` = un-peeled gadget.fit; `retrofit` = list of gadget.fit (peeled; `peel = final_year - max(year)` computed per element, so order irrelevant); `vars` must be columns of `fit$res.by.year` (default total.biomass, F, recruitment) with per-variable `lag` (years before the peeled terminal year; default 0,1,1 because F and recruitment at the terminal year are poorly determined). `aggregate_biomass=TRUE` adds stock `'All'` (sum of total.biomass over stocks). Bias per peel = (retro value - full-fit value)/full-fit value at year == peel-terminal-year - lag; rho = mean over peels. Returns tibble(stock, <one column per var>) (stock includes 'All'). Roxygen title is a copy-paste ("Generate parameterised g3a_initial_abund") — documentation bug.

### A.2.3 Fit object and combination

**g3_fit** — build the `gadget.fit` list used by gadgetplots (structure in A.3.3). 
`R/g3_fit.R:22`
```r
g3_fit <- function(model, params, rec.steps = 1, steps = 1, printatstart = 1, f_by_age = NULL)
```
`model`: `g3_r` or `g3_cpp` (must contain `g3a_report_detail`, otherwise it adds it and recompiles via `g3_to_r` -- slow, and printatstart=0 additionally adds `g3a_report_history(var_re=c('__num$','__wgt$'), out_prefix='endprint_', run_at=11)`). `params` must be a data.frame. `rec.steps` (default 1; NULL = all steps) = steps counted as recruitment; `steps` (default 1) = steps kept in `res.by.year`; `printatstart` 1 = stock state at start of step, 0 = end; `f_by_age` = ages averaged for annual F (NULL = oldest age of each stock; vector applied to all stocks; named list per stock). Errors if printatstart not 0/1 or f_by_age malformed. F per step = -log(1 - C/N) (C numbers caught by fleets, N numbers at start of step); F-at-age summed over steps then unweighted mean over the age range. `g3_fit_inner` does the work. If `report_detail` exists in params it is set to 1L.

**extract_year_step** — split a `time` column ("2005-01") into integer `year`, `step`; no-op if no `time` column; entries lacking '-' get '-0' appended via a `[[1]]` assignment (fragile: written for single-timestep style names such as annual-only `time`). 
`R/g3_fit.R:896`
```r
extract_year_step <- function(data)
```

**bind_fit_components / bind_fit** — combine fits. 
`R/g3_fit_combine.R:17`
```r
bind_fit_components <- function(fit_list, component)
```
`R/g3_fit_combine.R:40`
```r
bind_fit <- function(fit_list)
```
bind_fit_components: `dplyr::bind_rows(lapply(fit_list, `[[`, component), .id='id')`; id = names(fit_list) or positions. bind_fit: starts from `fit_list[[1]]`, sets every element NA, then row-binds the data.frame elements across fits with `id`; non-data.frame elements stay NA, class gadget.fit retained (so `plot()` works on the combined object, with `id` column). Elements: any element that is NULL in the first fit is skipped.

### A.2.4 Read/write and parameter-template utilities

**write.g3.param / write.g3.file / read.g3.param** 
`R/g3_readwrite.R:6`
```r
write.g3.param <- function(params, gd, file_name)
```
`R/g3_readwrite.R:23`
```r
write.g3.file <- function(obj, gd, file_name)
```
`R/g3_readwrite.R:43`
```r
read.g3.param <- function(gd, file.name)
```
write.g3.param: unlists `value`, converts optimise/random to numeric, empty `type` -> '.', then write.g3.file. write.g3.file: tibble->data.frame, prints `format(obj, drop0trailing=TRUE)` with `row.names=FALSE, max=999999` via `capture.output` to `file.path(gd,file_name)` (plain whitespace table; NOT meant to be re-read -- reading is `.Defunct()`; use the saved `.Rdata`). Note `file.path(gd, file_name)`: when `gd` is a directory string, `file_name` may include subdirs (bling script writes `file.path(vers, profile_folder, 'summary.txt')`).

**g3_init_guess** — set value/bounds/optimise for params matching a *regex* (not glob; superseded in gadget3 by `g3_init_val`, but still used, e.g. `g3_init_guess('project_years',1)`, `g3_init_guess('btrigger',1)`). 
`R/parameter_template_utils.R:11`
```r
g3_init_guess <- function(params, pattern, value = 0, lower = -999, upper = 999, optimise = 0)
```
Behaviour: `pattern` is a regex on `params$switch`; if any switch matches `<pattern>_exp` the pattern becomes `<pattern>_exp|<pattern>` and value/lower/upper are log()-ed; if `pattern\\.[0-9]` matches (time/age varying) pattern widened to `pattern\\.[0-9]|pattern`. If `optimise==1` and value is outside (lower,upper) it is moved inside with a warning (`max(lower,value)+0.01*(upper-lower)` / `min(upper,value)-0.01*(upper-lower)`). Sets columns value, lower, upper, parscale (= upper-lower), optimise (as.logical) on all matched rows. Defaults (value=0, lower=-999, upper=999, optimise=0). Returns the template. Warning: regex matches are unanchored (`'rec'` also hits `rec.scalar`, `recl`...).

**g3_add_parscale** — `.Defunct()` ("No longer needed"; parscale now set by g3_init_guess/gadget3). 
`R/parameter_template_utils.R:65`
```r
g3_add_parscale <- function(parameters)
```

**value_from_bounds / eval_bounded** — bounded-parameter transforms. 
`R/parameter_template_utils.R:76`
```r
value_from_bounds <- function(x, lower, upper)
```
`R/parameter_template_utils.R:88`
```r
eval_bounded <- function(x, lower, upper)
```
value_from_bounds(x,l,u) = log((u-l)/(x-l) - 1) (returns x if l==u==x); eval_bounded(x,l,u) = l + (u-l)/(1+exp(x)). Inverse pair for gadget3 `bounded()`.

**g3_stock_name / stock_species** — stock name parts. 
`R/parameter_utils.R:17`
```r
g3_stock_name <- function(stock, id = "full")
```
`R/parameter_utils.R:6`
```r
stock_species <- function(stock)
```
`g3_stock_name(stock,'full')` -> `stock$name`; `id` can be vector of `names(stock$name_parts)` -> pasted with '_'; stock_species = `g3_stock_name(stock,'species')`. Errors if not `g3_stock`.

### A.2.5 Setup helpers (model construction)

All in R/setup-utils.R; they use `gadget3::g3_parameterized()` with conventions `by_stock`, `by_year`, `by_age`, `exponentiate`, `scale`, `ifmissing`.

**init_abund** — `factor_f` for `g3a_initialconditions_normalparam` via `g3a_renewal_initabund`. 
`R/setup-utils.R:15`
```r
init_abund <- function(imm, mat, comp_id = "species", mature = TRUE, init_mode = 1, exp_init = FALSE, exp_init_scalar = FALSE, exp_init_f = FALSE, naturalmortality = gadget3::g3_parameterized("M", by_stock = TRUE))
```
init_mode 0: single `init.scalar` decaying with mortality (init=~1); 1: `init` parameter per age across stocks (`by_stock=list(imm,mat)`, by_age) plus `init.scalar`, `init.F`, maturity-by-age ogive `bounded(-alpha*(age-a50),0,1)` with params `mat_initial_alpha`, `mat_initial_a50` (inverted `1-p` for the immature stock); 2: `init` per age per stock, no ogive; 3: equilibrium (`prop_mat0`, `N0`, whale case, see gadget-course marine-mammals). `exp_init*` flags exponentiate. Returns formula. Note docs for mode 0 say "single scalar", while `model_actions` docs call mode 0 "initialised at equilibrium".

**stock_renewal** — `g3_parameterized('rec', by_stock=id, by_year=TRUE, exponentiate=exponentiate_rec, scale=g3_parameterized('rec.scalar', by_stock=scalar_id, exponentiate=...), ifmissing=NaN)`. 
`R/setup-utils.R:168`
```r
stock_renewal <- function(stock, id = "species", scalar_id = "species", exponentiate_rec = FALSE, exponentiate_rec_scalar = FALSE)
```

**init_sd** — initial-conditions stddev: parametric `mean_l*(alpha+beta/age+gamma*age)` with params `initial_sigma_alpha/beta/gamma`, else `g3_parameterized('init.sd', by_stock=TRUE, by_age=TRUE)` (note `id` is ignored in the non-parametric branch). 
`R/setup-utils.R:194`
```r
init_sd <- function(stock, id, parametric = FALSE, mean_len)
```

**model_actions** — standard imm/mat action list. 
`R/setup-utils.R:238`
```r
model_actions <- function(imm, mat, mlgg = 15, mature = TRUE, comp_id = "species", rec_id = list(imm, mat), rec_scalar_id = list(imm, mat), init_mode = 1, parametric_sd = FALSE, exp_params = c(), tv_params = c(), by_age_params = c(), recruiting = !mature)
```
Builds, for ONE stock per call (`mature=TRUE` -> `mat`, else `imm`): initial conditions (normalparam with `init_abund`, vonB mean from Linf/K/recl, `init_sd`, weight alpha/beta), `g3a_naturalmortality_exp(M)`, `g3a_age`; if `recruiting` (default `!mature`) `g3a_renewal_normalparam(imm, factor_f=stock_renewal(...), run_f = cur_step==1 && age==minage && cur_time>0 && !cur_year_projection)`; for `imm` (`mature=FALSE`) `g3a_growmature` with `g3a_grow_impl_bbinom` (`g3a_grow_lengthvbsimple`, `g3a_grow_weightsimple`, `maxlengthgroupgrowth=mlgg`) + `g3a_mature_continuous(alpha=mat_alpha,l50=mat_l50)` with `transition_f=~cur_time > 0`; for `mat` (`mature=TRUE`) `g3a_growmature(mat, ...bbinom...)` without a maturity function (no output stocks). Parameter families (case-insensitive): `exp_params` (vector or 'all') among linf,k,bbin,recl,rec.sd,mat_alpha,mat_l50,init,init.scalar,rec,rec.scalar,init.f,m,walpha,wbeta; `tv_params` (by_year, with `ifmissing` = `<name>.proj` non-optimised projection parameter defaulting to 0) among linf,k,walpha,wbeta,bbin,recl,rec.sd,mat_alpha,mat_l50,m; `by_age_params` among linf,k,walpha,wbeta,bbin,mat_alpha,mat_l50,m. Invalid names `stop()` with the list. Scales: K scale 0.001, bbin scale 10, mat_alpha scale 0.001. Returns list of g3 actions. Uses unexported `gadget3:::f_substitute` (fragile against gadget3 internals).

## A.3 Detailed workflow notes

### A.3.1 g3_data
* Purpose: give users without an mfdb database the same aggregated data+attributes that `mfdb_sample_count()` (etc.) returns, so `g3l_catchdistribution()`/`g3l_abundancedistribution()`/`g3_timeareadata()` can read the attributes.
* `x`: data.frame/tibble/data.table with one row per observation (or pre-summed values). `column_names` maps expected names to x's names: default `c(year="year", step="month", area="areacell")` i.e. the mfdb names; renaming is done via `names(dt)[match(column_names,names(dt))] <- names(column_names)` (so if mapped columns missing, silent misrenaming possible).
* `params`: named list; names = columns of x to group by. Values may be `mfdb_interval` (cut right=FALSE; open_ended 'lower'/'upper' -> -Inf/Inf; labels = interval names), `mfdb_group` (numeric -> cut using max of each group; character/factor -> recode to group names), plain `integer` (years: subset; column unchanged), or a `list` (area/step "aggregate all": column forced to "all"). `timestep` is accepted as alias for `step`. Missing `step` in params -> `params$step$all <- sort(unique(dt$step))` (yearly aggregation); missing `area` -> area "all" with the observed area labels. If x has no step column and none mapped, step=1.
* Filtering: ONLY the length column is filtered (rows outside a closed length interval removed; `>= min` unless lower open, `<= max` unless upper open) and `year` (if params$year is integer). All other columns passed in params are NOT filtered ("g3_data does not do filtering unlike mfdb functions") -> NA rows in group columns trigger a warning.
* `method="count"` -> `number = n()` per cell; otherwise `method` names a column that is `sum(..., na.rm=TRUE)`-ed (e.g. "weight", "biomass"); the output column keeps that name.
* `floating_point_correction=TRUE`: adds 1e-6 to values before `cut` for mfdb_interval columns (fixes e.g. 28 and 57 float issues).
* Special case: if k=="age" and the age interval spans (-Inf,Inf) only and cut yields NAs, NAs are replaced by the sole level.
* Factors in the output converted to character; attributes appended as described above; final checks: (a) warns for NA in grouping columns; (b) warns "Unique column and attribute values for <k> do not match." when the data values aren't names of the attribute.
* `add_g3_attributes()` is the same attribute machinery for data that is already aggregated.

### A.3.2 g3_optim / g3_iterative (iterative reweighting)
g3_iterative(gd, wgts='WGTS', model, params.in, grouping=g3_iterative_default_grouping(params.in), use_parscale=TRUE, method='BFGS', control=list(), shortcut=FALSE, cv_floor=0, resume_final=FALSE, serial_compile=FALSE, mc.cores=parallel::detectCores())
* Output folder: `file.path(gd, wgts)` (created recursively). `g3_r` model is compiled to TMB first.
* **grouping**: list name -> vector of component names WITHOUT the `cdist_<function>_`/`adist_..` prefix and WITHOUT `_weight`, e.g. `list(comm=c('ldist_comm','aldist_comm'), surv=c('si_len020_AUT','si_len044_AUT'))`. Components in one group are optimised together in stage 1 (their initial weight scaled by 1e4 all at once) and share one optimisation; this is used when overfitting is likely (e.g. two surveys within a year so recruits have >=2 measurements; or age+length data of one fleet). Ungrouped weight>0 components each form their own group. A leftover `log_` prefix on survey index names is rejected ("should not be supplied any longer").
* **Algorithm (shortcut=FALSE)**:
  1. `obj_fun <- g3_tmb_adfun(model, params.in)` (pre-compile; result otherwise unused).
  2. Stage 0 (skipped when `resume_final=TRUE`): `lik_init <- g3_lik_out(model, params.in)`; error if nll is NaN ("Use $report() and g3a_trace_nan()"); writes `lik.init`. `g3_iterative_setup(lik_init[lik_init$weight>0,], grouping)`: every component weight := 1/SS_initial (initial score = 1 per component), and for the group being optimised weight := 1e4/SS_initial. Writes `lik.groupings`, `params.in.stage1.<group>`, `params_in_s1.Rdata`.
  3. Stage 1: `run_g3_optim` on all groups (parallel, `mc.cores`); `check_null_params` substitutes input (optimise-params -> NA) for crashed groups; writes `params_out_s1.Rdata`, `optim.summary.stage1`, `params.out.stage1.<group>`.
  4. Weights update: for each stage-1 result `g3_lik_out` (mclapply) -> `tabulate_SS` -> writes `lik.comp.score.stage1`, `lik.comp.score.norm.stage1`. `g3_update_weights(lik_s1, grouping, cv_floor)`: variance = SS/df (df = number of non-zero data points: effective-n proxy for degrees of freedom; "gross overestimate for small datasets"); weight = 1/variance; `cv_floor` raises the minimum variance of survey-index components only (`_surveyindices_`): weight <= 1/cv_floor. A component that has value==0 or weight==0 gets weight 0. All weights updated in every group's parameter set; each group's set keeps its own optimised parameter values as starting point.
  5. Failed stage-1 groups (any NA value): their weights are replaced by `estimate_weights()` shortcut weights and their starting values from stage-1 input, with a warning.
  6. Writes `params.in.stage2.<group>`, `params_in_s2.Rdata`; Stage 2: `run_g3_optim` again (all with the new weights); writes `params_out_s2.Rdata`, `optim.summary.stage2`, `params.out.stage2.<group>`; `lik.comp.score.stage2` and `.norm.stage2`.
  7. Final: for each stage-2 result compute `sum(value*weight)`; choose the group with the MINIMUM weighted score -> `params_final` (message "Final parameters taken from component: <group>"); writes `params.final` and `weights.final` (comp, weight columns from the `_weight` params). Warns if some failed; `NULL` + warning "All optimisations failed" if all NA.
  8. Always saves `params_final.Rdata` and returns `params_final`.
* **shortcut=TRUE**: `estimate_weights(model, params.in)` -> writes `weights.final.shortcut`; weights are merged into params.in (match by `switch`); a single `g3_optim`; writes `params.final.shortcut`; saves `params_final.Rdata`. No grouping, no iterations.
* **resume_final=TRUE**: loads `params_out_s1.Rdata`/`params_in_s1.Rdata` from the same folder and starts at the weight update (errors if missing); useful after changing `cv_floor`.
* Concerns: output files use `write.g3.file` text tables (not re-readable) + Rdata; `length(failed_components > 0)` is a mis-parenthesised check that happens to work; docs mention "understocking and penalty" are exempt but if another component is 0 the final optimisation "will not be completed". `mc.cores` also drives the `mclapply` that computes `g3_lik_out`.
* Typical call (bling): `g3_iterative(file.path(base_dir,vers), wgts=wgts_folder, model=tmb_model, params.in=tmb_param, grouping=grouping, method='BFGS', control=optim_control, use_parscale=TRUE, shortcut=FALSE, cv_floor=cv_floor, resume_final=FALSE)` with e.g. `grouping <- list(sind1=c('si_len020_AUT','si_len044_AUT','si_len056_AUT'), sind2=c(...), bmt=c('ldist_bmt','aldist_bmt'), aut=c('ldist_aut','matp_aut'))`.
* `optim_control` typical: list(maxit=..., reltol=...). Defaults from g3_optim: maxit 1000, trace 2, reltol eps^2.

### A.3.3 g3_fit return value (class c("gadget.fit","list"))
Names (in order): sidat, stockdist, catchdist.fleets, sparsedist, suitability, likelihood, stock.prey, stock.std, stock.full, fleet.info, predator.prey, stock.recruitment, res.by.year, params, score. Elements can be NULL when the model lacks that data (sidat, stockdist, catchdist.fleets, sparsedist, likelihood, fleet.info, predator.prey, stock.recruitment). Attribute `summary` (copied from `attr(params,'summary')` of g3_optim) if present. All "length" columns are mid-points of the length group unless stated; area may be converted to numeric index; year/step integer.
* `sidat` (survey indices; from `(adist|cdist)_surveyindices_*__num|wgt` reports + `__params` alpha/beta): name (`<index>.<fleet>`), year, step, area, length, lower, upper, fleet, index, type (log|lin), intercept, slope, observed, number (model), predicted (type 'log': `exp(intercept)*number^slope`; else `intercept+slope*number`).
* `stockdist` (distributions with a `stock`/`stock_re` dimension, i.e. maturity/sex proportions): name, year, step, area, predator_length, stock, stock_re (where present), lower, upper, length (mid), age, observed, obs.ratio, predicted, pred.ratio (ratios within year/step/area/predator_length/length/age/name).
* `catchdist.fleets` (cdist/adist length/age distributions w/o stock dim): name, year, step, area, [stock, stock_re], length (group label), lower, upper, avg.length, age (`all<min>` if single age group else `age<lower>`), obs (counts/weights), total.catch, observed (proportion), pred, total.pred, predicted (proportion), residuals (observed-predicted; NA where observed==0). Source names parsed from `cdist_<function>_<name>_(model|obs)__(num|wgt)`.
* `sparsedist`: year, step, area, data_type (asparse|csparse), function_f, component, age, length, obs_mean, obs_stddev, obs_n, model_sum, model_mean, model_sqsum, model_n (weight & nll columns folded into `likelihood` and dropped). NULL if no `nll_(a|c)sparse_` reports.
* `suitability` (from `suit_<stock>_<fleet>__report` or old `detail_*__suit_*`): stock, fleet, [year, step, area, age, length (mid), predator_length where present], suit. Empty zero-row frame (with warning "Cannot find suitability tables") if none.
* `likelihood`: year, step, component, data_type (e.g. cdist_sumofsquares, adist_surveyindices, model_preystocks for understocking, asparse_sumsquares...), measurement (wgt|num|''), weight, value (per time step). From `nll_*` reports.
* `stock.prey` (per stock/age/step; consumption by fleet predators): year, step, area, stock, age, number_consumed, biomass_consumed, number, mortality (= -log(1-C/N)/step_size; per-year-rate scaling), + number_consumed_total, biomass_consumed_total, mortality_total when non-fleet predators exist.
* `stock.std` (by age): year, step, area, stock, age, number, mean_length, stddev_length, mean_weight.
* `stock.full` (by length): year, step, area, stock, length, number, mean_weight.
* `fleet.info` (by fleet): year, step, area, fleet, harv.bio, amount (biomass consumed), harv.rate (= amount/harv.bio, 0 if no catch). NULL if no predators.
* `predator.prey`: year, step, area, prey, predator, length, number_consumed, biomass_consumed, harv.bio, mortality, tb, suit.
* `stock.recruitment` (youngest age, from `detail_*__spawnednum|renewalnum`, filtered to `rec.steps`): stock, year, step, area, age, recruitment.
* `res.by.year` (filtered to `steps`): stock, year, area, step, total.number, total.biomass, harv.biomass (biomass available to fleets using fleet suitability), catch, num.catch, F (see f_by_age), recruitment. (Without fleets F=NA and catch columns absent.) This is THE input for retro/jitter/mohnrho/plot_annual.
* `params`: the params data.frame as supplied (so `model(fit$params)` re-runs).
* `score`: data.frame(nll=).
* Time-stamp conventions: reports have a `time` dimension "YEAR-STEP" parsed by `extract_year_step`. Stocks/fleet names inferred from report names (`dstart_*`/`detail_*__num|wgt`, `detail_<stock>_<pred>__cons`).

### A.3.4 g3_readwrite
`write.g3.param(params, gd, file_name)` and `write.g3.file(obj, gd, file_name)` write human-readable text tables. `read.g3.param` is defunct: "Now depreciated, using RData files for read/write" -- load the `.Rdata` instead (`params_final.Rdata`, `params_out_s2.Rdata`, ...). `g3_iterative` writes parameters with `write.g3.param` and ALSO saves Rdata; tables of `lik.*` via `write.g3.file`.

### A.3.5 Parameter template utilities summary
`g3_init_guess` (regex-based set of value/lower/upper/optimise/parscale), `g3_add_parscale` (defunct), `value_from_bounds`/`eval_bounded` (logistic bound transform), `jitter_params`. Prefer `gadget3::g3_init_val()` (glob) in new code; `g3_sensitivity`'s `par_name` uses the g3_init_val glob grammar. `parscale` column is read by `g3_tmb_parscale()`; `g3_optim` stops on NA parscale.

### A.3.6 Parallel/OS summary
| function | cores arg | notes |
|---|---|---|
| g3_iterative | mc.cores (default detectCores()) | stage-1 & stage-2 optimisations, plus g3_lik_out evaluations, fork-parallel; shortcut path is serial |
| g3_jitter | mc.cores | jitters generated and optimised in parallel |
| g3_retro | mc.cores | one fork per peel |
| g3_leaveout | mc.cores | one fork per group |
| g3_sensitivity | mc.cores | also used when run_optimisations=FALSE for g3_fit |
| g3_optim | none (single) | |
Windows: set mc.cores=1. memory: set mc.cores to a small number, use serial_compile=TRUE. Beware nested forking (g3_iterative inside mclapply -> pass mc.cores=1).

---------------------------------------------------------------------------
# PART B. gadgetplots
---------------------------------------------------------------------------

Purpose: "Creates plots of gadget.fit objects for gadget3". Replaces the plotting parts of Rgadget (gadget2). **Uses ggplot2** throughout (plus cowplot for multi-panel layouts via `cowplot::plot_grid`, ggridges for ridge plots, plotly::ggplotly + flexdashboard + DT only in `make_html` templates, scales palettes). Version 0.3.11 (DESCRIPTION); README header says 0.3.8. Authors M. Vihtakari (cre), B. T. Elvarsson, W. Butler, J. Lentin. Install: `remotes::install_github("gadget-framework/gadgetplots")` (not on CRAN). Docs site: https://gadget-framework.github.io/gadgetplots/ ; example output article `make_html_output`. Imports: ggplot2, dplyr, magrittr, tidyr, purrr, rlang, scales, zoo, cowplot, rmarkdown, flexdashboard, DT, plotly, ggridges, gadget3, lubridate, fs. Suggests gadgetutils. No tests (CLAUDE.md: "no formal test suite", test by running examples on the bundled `fit`). Maintainer e-mail in DESCRIPTION has a typo (`hi.not`). Datasets (data/): `fit` (early draft Northeast Arctic Greenland halibut `gadget.fit`; stocks e.g. ghl_female_mat; components e.g. EggaN_ldist, EggaN_matp, EggaN_survey), `example_catches` (objects TrawlNor_catches, OtherNor_catches, TrawlRus_catches, OtherRus_catches, Internat_catches), `aldist_example`, `ldist_example`, `sexratio_example`, `stockdist_example`.

README categories: (1) `plot_*()` model OUTPUT from `gadgetutils::g3_fit()`; shorthand `plot(fit, param=...)`; (2) `dplot_*()` INPUT data made with mfdb / `gadgetutils::g3_data()` / `add_g3_attributes()`; (3) `g3d_plot()` plots data directly from a gadget3 model object; (4) `g3plot_*` plot suitability (selectivity) functions from parameter values. Plus `make_html()` (single html diagnostics report) and `gadget_plots()` (batch export).

Cross-cutting conventions: every `plot_*` takes a `gadget.fit` as first arg `fit` (some check `inherits(fit,'gadget.fit')` and `stop("fit must be a gadget fit object.")`); `base_size = 8` (ggplot theme base size; internal helpers `FS()`/`LS()` convert pt to ggplot sizes); many have `return_data=TRUE` to get the underlying tibble instead of a plot; return a `ggplot` (or `cowplot` object for plot_annual/plot_agelength/plot_catchdist) or a NAMED LIST of ggplots when there are several components (plot_catchdist, plot_agelength, plot_stockdist with `stocks='separate'`, plot_suitability with fleets=NULL, plot_ldist/plot_adist for some types). Stock biomass units: kt default (`scale=c("kt","Mt","t")`), recruitment millions (`"millions","billions","thousands"`), abundance in millions. Only time step 1 supported by `plot_sr`. Plots are wrappable by `plotly::ggplotly()`.

## B.1 Exported inventory

### B.1.1 Dispatcher, batch, report
**plot.gadget.fit** (S3, R/plot.gadget.fit.R:39): `plot(x, param="annual", ...)`. param -> function: annual->plot_annual; growth->plot_growth; agelength|age->plot_agelength; resid->plot_resid; f|F->plot_f; rec|recruitment->plot_rec; ssb|spawning|spawning_stock->plot_ssb; biomass->plot_biomass; total->plot_biomass(total=TRUE); abundance->plot_biomass(biomass=FALSE); catch|catches->plot_catch(type='stock'); fleet->plot_catch(type='fleet'); hr->plot_catch(type='hr'); likelihood->plot_likelihood; weighted->type='weighted'; sums->type='sums' (the roxygen lists "pie", but the code maps `sums`); si|survey|surveyindex|surveyindices->plot_si; catchdist; suitability|suit; agecomp|composition|stock.std->plot_agecomp; stockdist|maturity|matp|mat|model_fit->plot_stockdist; stockcomp|stock_composition; weight|weights->plot_weight; param|params|parameter->plot_param. Unknown -> warning, returns NULL. (Not dispatched: ldist, adist, ssb-recruit sr, growth variants, ageclass, retro/jitter/leaveout.)

**gadget_plots** — save all diagnostic graphs. 
`R/gadget_plots.R:17`
```r
gadget_plots <- function(fit, path, file_type = "png", quiet = FALSE, width = NULL, height = NULL, units = "cm", res = 300, ...)
```
`file_type`: ggsave device (eps, ps, tex, pdf, jpeg, tiff, png, bmp, svg, wmf) or "html" (-> `make_html(fit, path, harvest_rate=<in ...>, template=<in ...>)`; only `harvest_rate` and `template` are read from `...`; e.g. `template='iceland_bling'` is used in the bling scripts but is NOT shipped (shipped: standard, iceland, nea_ghl) -> system.file returns "" -> error). Creates `path` if missing (non-recursive `dir.create`). Defaults size 18 x 10 cm when units="cm". Files written (png etc.): `Annual_plot.<ext>` (via grDevices::png regardless of file_type! source bug: always uses `png()` device though extension varies), `Catches_by_fleet`, `Survey_indices`, `Catch_distribution_<name>`, `Stock_distribution_<name>` + `Stock_composition` (only if `fit$stockdist`), `Suitability`, `Growth`, `Agelength_<name>` (if any aldist component), `Age_composition`, `Residuals`, `Likelihood`, `Likelihood_weighted`, `Likelihood_sums`, `Parameters` (out_only=TRUE), `Parameter_weights`. Returns nothing. Uses `bg='white'`, dpi=res.

**make_html** — standalone HTML diagnostic dashboard. 
`R/make_html.R:22`
```r
make_html <- function(fit, path = getwd(), harvest_rate = TRUE, file_name = "model_output_figures.html", template = "standard", model_name = "Gadget model output")
```
Copies `system.file("<template>.Rmd", package="gadgetplots")` to `<path>/template.Rmd`, `rmarkdown::render(input, output_dir=path, output_file=file_name, params=list(fit, harvest_rate, model_name))`, then deletes the copy. Templates (inst/): `standard` (default; flexdashboard, orientation columns; pages: Annual plot [Catches, Harvest rate or F, Recruitment, Biomass]; Catches; Survey indices; Catch distributions [tabs]; Stock distribution [tabs: composition by length/age, length/age distribution]; Suitability; Age [Growth, Age composition, Age group stdev]; Residuals & likelihood [Residuals, Raw/Weighted/Total likelihood]; Parameters [Relative to boundaries, Weights, Growth parameters & Z, All parameters (DT)]), `iceland`, `nea_ghl` (Northeast Arctic Greenland halibut). Title uses `model_name`; author shows Converged/Not converged and date shows `gd_calls/maxiter iterations` from `attr(fit,'summary')`. Interactive figures via plotly::ggplotly. Requires pandoc (rmarkdown). Returns nothing (writes `<path>/model_output_figures.html`).

### B.1.2 Model-output plots (all take `gadget.fit`)
Each line: signature; fit slots used; plot semantics; return.

**plot_annual** — ICES-style 2x2 panel (catches, recruitment, harvest rate or F, stock biomass + shared legend). 
`R/plot_annual.R:14`
```r
plot_annual <- function(fit, harvest_rate = TRUE, color_palette = scales::hue_pal(), base_size = 8, ...)
```
Uses res.by.year (via plot_catch/plot_rec/plot_hr|plot_f/plot_biomass). `color_palette`: palette function (called with nstocks+1 colours; last = "Total") or vector of length nstocks+1, else stop. `...` passed to plot_catch/plot_rec/plot_biomass. Returns cowplot grid.

**plot_biomass** — stock biomass/abundance time series. 
`R/plot_biomass.R:19`
```r
plot_biomass <- function(fit, type = "line", total = FALSE, biomass = TRUE, stocks = NULL, min_catch_length = NULL, return_data = FALSE, base_size = 8, scale = c("kt", "Mt", "t"))
```
Uses stock.full & res.by.year; `type` "line"|"area"; `total` adds total line (no effect for area); `biomass=FALSE` -> abundance (millions); `min_catch_length` filters model population (>=) across stocks; `stocks` subset; `return_data`.

**plot_catch** — catches. 
`R/plot_catch.R:17`
```r
plot_catch <- function(fit, type = "stock", biomass = TRUE, base_size = 8, return_data = FALSE, scale = c("kt", "Mt", "t"))
```
`type`: "stock" (by stock; res.by.year), "fleet" (fleet.info$amount), "total", "hr" (harvest rate by fleet). `biomass=FALSE` -> numbers.

**plot_hr / plot_f** — harvest rate / fishing mortality (both defined in R/plot_f.R). 
`R/plot_f.R:18`
```r
plot_hr <- function(fit, stocks = NULL, min_catch_length = NULL, biomass = TRUE, model_selectivity = TRUE, base_size = 8, return_data = FALSE)
```
`R/plot_f.R:106`
```r
plot_f <- function(fit, stocks = NULL, fbar_ages = NULL, return_data = FALSE, base_size = 8)
```
plot_hr: uses res.by.year (catch / harv.biomass), stock.full, stock.prey. `min_catch_length=NULL`: per-stock HR using model selectivity (harv.biomass); `=0`: HR of entire model population using selectivity (use THIS for finding target HRs in projections); `>0`: assumes flat selectivity above that length (reporting only, "NOT real model harvest rate"). `model_selectivity`, `biomass`, `stocks`. plot_f: `fbar_ages` (e.g. 5:10) -> Fbar over age range from stock.prey mortality, else per-stock F in res.by.year.

**plot_rec** — recruitment by stock (res.by.year$recruitment); `stocks='total'` for sum; `panelrow` doc is a placeholder ("something here"). 
`R/plot_rec.R:16`
```r
plot_rec <- function(fit, panelrow = FALSE, stocks = NULL, return_data = FALSE, base_size = 8, scale = c("millions", "billions", "thousands"))
```

**plot_ssb** — spawning stock biomass; `spawning_stock` name of mature stock (NULL = guessed). 
`R/plot_ssb.R:12`
```r
plot_ssb <- function(fit, spawning_stock = NULL, base_size = 8)
```

**plot_sr** — SSB vs recruitment with `lag`; `spawning_stock` name or minimum length (numeric); time step 1 only (stops otherwise "Other time steps than 1 have not been implemented yet."). 
`R/plot_sr.R:15`
```r
plot_sr <- function(fit, spawning_stock = NULL, lag = 1, years = NULL, add_line = TRUE, base_size = 8)
```

**plot_growth** — mean length by age (stock.std); `type` "annual"|"mean"|"stdev"; `add_models` overlays von Bertalanffy curves from fit$params using grep on parameter names (warning "Did not correct growth parameters. Turning add_models to FALSE"). 
`R/plot_growth.R:15`
```r
plot_growth <- function(fit, type = "annual", stdev = FALSE, add_models = FALSE, base_size = 8)
```

**plot_ageclass** / **plot_agecomp** / **plot_adist** — age structure from stock.std. 
`R/plot_ageclass.R:14`
```r
plot_ageclass <- function(fit, age = 2, biomass = FALSE, base_size = 8, return_data = FALSE)
```
`R/plot_agecomp.R:24`
```r
plot_agecomp <- function(fit, type = "bubble", scales = "fixed", biomass = FALSE, base_size = 8, return_data = FALSE)
```
`R/plot_adist.R:15`
```r
plot_adist <- function(fit, type = "bar", scales = "fixed", ncol = NULL, years = NULL, base_size = 8)
```
ageclass: one age (default 2) tracked over years at start of year (biomass or numbers). agecomp types: "bar" (year x abundance faceted by age, year classes coloured), "line", "ggridges", "bubble" (anything else: bubble plot age vs year sized by abundance). adist: age distributions by year, `type` line|bar|ggridges, `years` subset.

**plot_ldist** — model length distributions per year (stock.full; `by_age=TRUE` synthesises age-specific curves with `number*dnorm(1:120, mean_length, stddev_length)` from stock.std -- absolute values untrustworthy). 
`R/plot_ldist.R:19`
```r
plot_ldist <- function(fit, type = "line", by_age = FALSE, stocks = NULL, scales = "fixed", ncol = NULL, years = NULL, base_size = 8)
```

**plot_stockcomp** — proportions of stocks by length (stock.full) or age (stock.std, `by_age=TRUE`); `type` "line"|"area". 
`R/plot_stockcomp.R:15`
```r
plot_stockcomp <- function(fit, type = "line", by_age = FALSE, base_size = 8)
```

**plot_catchdist** — fit of model to length/age distributions (catchdist.fleets; one plot per `name`, e.g. "EggaN_ldist"); `type` "step" (histogram-like lines showing aggregation intervals) | "line" (through group midpoints). Returns NAMED LIST of cowplot/ggplot objects; warns "No catchdist to plot" if none. 
`R/plot_catchdist.R:15`
```r
plot_catchdist <- function(fit, type = "step", name = NULL, base_size = 8)
```

**plot_agelength** — age-length distribution fits (catchdist.fleets aldist names); list if several. 
`R/plot_agelength.R:10`
```r
plot_agelength <- function(fit, name = NULL, base_size = 8)
```

**plot_stockdist** — fit to stock (maturity/sex) proportion data (`fit$stockdist`; `stocks`: NULL = all in one plot, "separate" = one plot per stock, or vector; `name` component; stops if both `stock` and `stock_re` present; warns if no lower/upper columns). 
`R/plot_stockdist.R:22`
```r
plot_stockdist <- function(fit, stocks = NULL, name = NULL, type = "step", show_intervals = FALSE, color_palette = "default", base_size = 8)
```

**plot_si** — survey indices (sidat). `type` "model_fit" (observed vs predicted by year), "regression" (log-linear regression I = e^a B^b, a = log q, b = density-dependent catchability), "scatter" (predicted vs observed). Warns if regression parameters don't look log-space. 
`R/plot_si.R:13`
```r
plot_si <- function(fit, type = "model_fit", base_size = 8)
```

**plot_suitability** — fleet suitability (selection) curves from `fit$suitability` by year; `fleets` NULL -> separate plot per fleet, "all" -> one plot; fleets whose suitability depends on age are plotted against age; `add_models=TRUE` overlays functions built from parameters whose name resembles the fleet name (grep-based, "does not always work"); `include_missing` keeps years without catch. 
`R/plot_suitability.R:15`
```r
plot_suitability <- function(fit, fleets = "all", add_models = TRUE, include_missing = TRUE, base_size = 8)
```

**plot_resid** — residual plot for each catchdist.fleets component (residuals column). 
`R/plot_resid.R:10`
```r
plot_resid <- function(fit, base_size = 8)
```

**plot_likelihood** — likelihood scores (fit$likelihood). `type`: "direct", "weighted", or anything else ("total"; default) = sums of weighted and raw by component; `use_proportions`, `log_scale`. 
`R/plot_likelihood.R:20`
```r
plot_likelihood <- function(fit, type = "total", log_scale = FALSE, use_proportions = TRUE, base_size = 8)
```

**plot_param / plot_weight** — parameters relative to their bounds (fit$params, or a params data.frame); `out_only=TRUE` shows only those outside bounds (warns if optimise/lower/upper columns missing "Bug in g3_fit?") ; `plot_weight`: likelihood component weights (`_weight` parameters). 
`R/plot_param.R:13`
```r
plot_param <- function(fit, out_only = FALSE, base_size = 8)
```
`R/plot_weight.R:11`
```r
plot_weight <- function(fit, log_scale = FALSE, base_size = 8)
```

### B.1.3 Analysis-collection plots (take LISTS of gadget.fit)
**plot_retro** — `retro_fit`: list of fits, FIRST element = full data, then increasing peels (title label `"<i-1> (<terminal year>)"`); `var` "total.biomass" | "hr"; `by_stock`; `min_catch_length`; ncol. 
`R/plot_retro.R:11`
```r
plot_retro <- function(retro_fit, var = "total.biomass", by_stock = TRUE, min_catch_length = NULL, base_size = 8, ncol = NULL)
```
**plot_jitter** — `jitter_fit`: list of `g3_fit` outputs from `g3_jitter` results; panels for vars c("nll.summary","total.biomass","hr","recruitment") (nll from each fit's `score`; uses `plot_hr(min_catch_length=0)`, `plot_biomass(min_catch_length=0)`, `plot_rec(stocks='total')` with return_data). 
`R/plot_jitter.R:9`
```r
plot_jitter <- function(jitter_fit, vars = c("nll.summary", "total.biomass", "hr", "recruitment"), base_size = 8, ncol = NULL)
```
**plot_leaveout** — `lo_fit`: list from `g3_leaveout`; colours per left-out component, `legend_title`. 
`R/plot_leaveout.R:11`
```r
plot_leaveout <- function(lo_fit, vars = c("nll.summary", "total.biomass", "hr", "recruitment"), ncol = NULL, colors = NULL, base_size = 8, legend_title = "Left-out\ncomponent")
```
(Only default `vars` implemented for jitter/leaveout. There are no plots for g3_sensitivity/profile results or mohnrho.)

### B.1.4 Input-data plots (dplot_*)
x = gadget3-ready data frame (mfdb output, g3_data, add_g3_attributes) with gadget columns (year, step, area, age, length, number...). 
`R/dplot_ldist.R:14`
```r
dplot_ldist <- function(x, type = "bar", scales = "free_y", dir = "v", base_size = 8, ...)
```
`R/dplot_aldist.R:20`
```r
dplot_aldist <- function(x, type = "bar", facet_age = FALSE, dir = "v", color_palette = scales::brewer_pal(palette = "Set1"), base_size = 8, ...)
```
`R/dplot_adist.R:13`
```r
dplot_adist <- function(x, type = "bar", color_palette = scales::brewer_pal(palette = "Set1"), dir = "v", base_size = 8, ...)
```
`R/dplot_catch.R:19`
```r
dplot_catch <- function(x, base_size = 8)
```
`R/dplot_sexr.R:10`
```r
dplot_sexr <- function(x, dir = "v", base_size = 8, ...)
```
`R/dplot_stockdist.R:22`
```r
dplot_stockdist <- function(x, stock_col = "maturity_stage", proportion = FALSE, group_by_sex = FALSE, sexes = c(female = "^female", male = "^male"), colors = NULL, scales = "free_y", dir = "v", base_size = 8, ...)
```
* dplot_ldist: type "bar"|"ggridges"|"line"; facets by year with `scales="free_y"`; `dir="v"` (vertical facets) to compare lengths across years.
* dplot_aldist: type "bar"|"step"|"area" ("step" resembles plot_catchdist), `facet_age`, `color_palette`.
* dplot_adist: "bar"|"ggridges".
* dplot_catch: x a data frame or NAMED LIST of data frames (multiple catch series in one figure).
* dplot_sexr: sex ratio data.
* dplot_stockdist: `stock_col` (default "maturity_stage"), `proportion`, `group_by_sex`, `sexes` regex pair (female/male), `colors`.

### B.1.5 Model-object and function plots
`R/g3d_plot.R:13`
```r
g3d_plot <- function(model, regexp = NULL, scales = "fixed", ncol = NULL, base_size = 8)
```
g3d_plot: `model` = g3_to_r / g3_to_tmb model; plots all observation data embedded in the model (list of ggplots); `regexp` filters components ("adist","cdist","surveyindices","catch"); `ncol`, `scales`.
`R/g3plot_suitability.R:19`
```r
g3plot_exponentiall50 <- function(length, alpha, l50, add = FALSE, base_size = 8, ...)
```
`R/g3plot_suitability.R:70`
```r
g3plot_andersen <- function(length, p0, p1, p2, p3, p4, p5, add = FALSE, base_size = 8, ...)
```
g3plot_exponentiall50(length, alpha, l50): curve `1/(1+exp(-alpha*(length-l50)))`; g3plot_andersen(length, p0..p5): Andersen suitability (see `?gadget3::suitability`); named vectors -> several curves (different linetypes); `add=TRUE` returns a geom layer to add to an existing ggplot (e.g. over plot_suitability). Example: `suit <- fit$params[grepl("ghl_female.ecos.survey", fit$params$switch),]; g3plot_exponentiall50(1:60, alpha=unlist(suit[grepl("alpha",suit$switch),"value"]), l50=unlist(suit[grepl("l50",suit$switch),"value"]))`.

### B.1.6 Utilities exported
`R/repeat_palette.R:13`
```r
repeat_palette <- function(n, pal)
```
repeat_palette(n, pal): repeats colours of palette function `pal` n times so manual scales never run out. 
`R/internal_functions.R:27`
```r
getCores <- function()
```
getCores(): `getOption("mc.cores")` if set, else `min(detectCores(), 4)` (copied from StoX); not used by the plot functions (internal-style helper but exported). `%>%` re-exported.

## B.2 What a minimal call chain looks like
```r
fit <- gadgetutils::g3_fit(model, params)          # must include g3a_report_detail
library(gadgetplots)
plot(fit)                       # = plot_annual(fit)
plot(fit, "catchdist")          # list of plots, one per component
plot_catchdist(fit, name = "EggaN_ldist", type = "line")
plot_hr(fit, min_catch_length = 0, return_data = TRUE)
gadget_plots(fit, "figs", file_type = "png")      # all PNGs
gadget_plots(fit, "figs", file_type = "html")     # = make_html(fit, "figs")
make_html(fit, path = "figs", harvest_rate = FALSE, template = "standard", model_name = "My model")
# analysis lists
plot_retro(c(list(fit), retro_fits)); plot_jitter(jitter_fits); plot_leaveout(lo_fits)
```
Known issues/TODO seen in source: placeholder docs (`plot_rec(panelrow)`: "something here"); `plot_hr` details paragraph truncated in Rd text; gadget_plots always opens `png()` for the annual plot; plot_sr limited to step 1; add_models in plot_growth/plot_suitability is grep-based and brittle; `plot.gadget.fit` docs list `pie` but code uses `sums`; README/DESCRIPTION version mismatch (0.3.8 vs 0.3.11); `template='iceland_bling'` referenced externally but not shipped.

---------------------------------------------------------------------------
# PART C. g3experiments
---------------------------------------------------------------------------

README (entire): "g3experiments: Experimental gadget3 extensions. New methods for gadget3 still under development." DESCRIPTION: v0.3.999 (2022-10-07), GPL-2, authors J. Lentin (cre), B. T. Elvarsson, MFRI; `Imports: gadget3` only; Suggests knitr, rmarkdown, unittest. NAMESPACE is a single line: `exportPattern("^g3\\w+?_|^proj_.+")` -> every function whose name starts `g3<word>_` (g3a_, g3l_, g3p_, g3exp_, g3_step_...) or `proj_` is exported. No roxygen, no man pages, no tests, no vignette in this repo (Makefile has generic targets: install, build, test, check ...). The "random-effect-recruitment" vignette lives in the gadget3 repo (gadget3/vignettes/articles/random-effect-recruitment.Rmd, title "Random effects & projections"), see C.5.
IMPORTANT usage caveats: (1) the package does not `import` anything: code calls unqualified `g3_parameterized`, `g3_init_val`, `g3_to_tmb`, `g3_tmb_adfun`, `g3a_spawn_recruitment_hockeystick`, `g3_param_table`, `g3_stock_instance`, `g3_step`, `%>%`, `arima.sim`, `tseries::tsbootstrap`, `broom::tidy`, and uses unexported `gadget3:::` internals -> `library(gadget3)` (and dplyr/magrittr, tseries, broom for some) must be attached, and functions are tightly coupled to a gadget3 version. (2) Part of this repo has already been upstreamed into gadget3: `g3a_trace_var` (from g3a_trace_nan; gadget3 NEWS #231), `g3l_bounds_penalty` (the file here defines only the DEPRECATED `g3l_bounds_penalty_old`), `g3_quota_hockeyfleet`/`g3_quota` (gadget3/R/quota.R, replacing `g3a_predate_catchability_hockeyfleet` in new models), `g3_tmb_fn`, `g3_param_project`. Prefer the gadget3 versions for new work.
Files: action_hcr.R (150 l), action_sam_hcr.R (128), action_trace.R (90), g3a_report_stock_better.R (81), g3exp_tmb_fn_plot.R (19), g3p_project.R (226), hockey_fleet.R (84), likelihood_penalty.R (39), proj_stock_actions.R (63).

## C.1 Exported inventory (all undocumented; purpose inferred from code/comments)

### C.1.1 Projection set-up (g3p_*): R/g3p_project.R
Workflow idea (setup-advice.R / test_projections.R in gadget-models/07-bling): take the final fit's parameter table (+ bootstrap fits), build many parameter tables each with (a) a bootstrapped/AR/constant future recruitment series filling the `project_rec.*` parameters, (b) a harvest-rate series `project_hr.*` (target HR, optionally with AR(1) lognormal "assessment error"), (c) Btrigger/Blim values, fleet quota proportions, project_years; run the projection model once per table (`g3_fit(r_proj, x)`), collate with `gadgetutils::bind_fit_components`, and summarise (e.g. equilibrium catch/SSB vs HR -> FMSY/Flim/Fpa, risk of B<Blim).
`R/g3p_project.R:108`
```r
g3p_setup_pars <- function(model, params, blim, btrigger, harvest_rates, harvest_rate_trials, fleet_proportions, rec_list, rec_years = NULL, rec_scale = 1e-04, rec_block_size = 7, rec_method = "bootstrap", project_years = 100, assess_err = FALSE, advice_rho = 0.423, advice_cv = 0.212, blim_pattern = "spawn_blim", btrigger_pattern = "*.hf.btrigger", rec_pattern = "project_rec.[0-9]", hr_pattern = "*.hf.harvest_rate", quota_prop_pattern = "*.quota.prop")
```
Arguments: `model` g3_r or g3_cpp (g3_r is compiled; errors otherwise), `params` one params data.frame or list of data.frames (e.g. base fit + bootstrap fits; a single df is wrapped as `list(base=)`), `blim`, `btrigger` (values written with `g3_init_val(pars, btrigger_pattern, btrigger, optimise=TRUE)` / `blim_pattern`), `harvest_rates` (vector of target HRs), `harvest_rate_trials` (replicates per HR), `fleet_proportions` (data.frame with columns `fleet`, `prop`; fleet names get the suffix of `quota_prop_pattern` minus '*' (".quota.prop"); fleets in the template but not listed get prop 0; props rescaled to sum 1 with a warning), `rec_list` (list, one per params element, each data.frame with `year` & `recruitment` columns, e.g. `fit$stock.recruitment`), `rec_years` (default all years in rec_list[[i]]), `rec_scale` (1e-4; recruitment series multiplied by this to match the model's recruitment scale), `rec_block_size` (7, block bootstrap), `rec_method` ('bootstrap'|'AR'|'constant'), `project_years` (100, written to param `project_years`, optimise FALSE), `assess_err` (FALSE: if TRUE multiplicative AR(1) lognormal error on HR with `advice_rho`=0.423, `advice_cv`=0.212), patterns (glob for g3_init_val-like matching but used here with `grepl`: `'*.hf.btrigger'`, `'*.hf.harvest_rate'`, `'*.quota.prop'`, `'spawn_blim'`, `'project_rec.[0-9]'` as regex — note `*` at pattern start is not a valid regex quantifier use but works in grepl/PCRE-less default TRE).
Returns: named list of params data.frames, names `h-<hr>-<trial>-<rep>` (expand.grid over harvest_rates x params x trials), each with: estimated values copied from `params[[rep]]`, `optimise` copied then forced TRUE for the Btrigger/recruitment/HR rows (so `g3_tmb_par()` includes them), `project_rec.*` filled (if present in template), `project_hr.*` filled. Parameters named by default patterns must exist in the model template: `<stock/fleet>.hf.btrigger`, `.hf.harvest_rate`, `project_rec.<year>`, `spawn_blim`, `<fleet>.quota.prop`, `project_years`.
`R/g3p_project.R:2`
```r
g3p_project_rec <- function(par, recruitment, rec_pattern = "project_rec", method = "bootstrap", scale = 1e-04, ...)
```
Fills rows matching `rec_pattern` (default 'project_rec', n = their count) of `par` with `scale * rec` where rec comes from method "bootstrap" (`g3p_project_rec_bootstrap`), "AR" (`g3p_project_rec_arima`) or "constant" (`g3p_project_rec_constant`; `...` forwarded, e.g. block_size). `recruitment` is a data.frame with column `recruitment`. Returns `par`. Pipe-friendly: `par.proj %>% g3p_project_rec(recruitment = fit$stock.recruitment %>% filter(year >= rec_start_year), method='bootstrap') %>% g3p_project_advice_error(hr_target=0.1, advice_cv=0) %>% g3_init_guess('btrigger', 1)`.
`R/g3p_project.R:29`
```r
g3p_project_advice_error <- function(par, hr_target, advice_rho = 0.423, advice_cv = 0.212, hr_pattern = "project_hr")
```
Sets rows matching `hr_pattern` (default 'project_hr') to `hr_target` (advice_cv==0) or `hr_target * exp(arima.sim(n, list(ar=advice_rho), sd=advice_cv/sqrt(1-advice_rho^2)))` — AR(1) multiplicative implementation error. Defaults rho .423 / CV .212 are the ICES-style assessment-error values.
`R/g3p_project.R:50`
```r
g3p_project_rec_arima <- function(recruitment, n_years)
```
`R/g3p_project.R:71`
```r
g3p_project_rec_bootstrap <- function(recruitment, n_years, block_size = 7)
```
`R/g3p_project.R:80`
```r
g3p_project_rec_constant <- function(recruitment, n_years)
```
rec_arima: regress log(R_t) on log(R_{t-1}) (lm via broom), simulate AR(1) with that slope and sigma, scale by mean recruitment, `mrec*exp(rec)`. rec_bootstrap: `tseries::tsbootstrap(recruitment$recruitment, type="block", nb=ceiling(n_years/length), b=block_size)`, flattened and truncated to n_years. rec_constant: geometric mean (`exp(mean(log(R)))`, a single value recycled by assignment). All return numeric vectors.
`R/g3p_project.R:87`
```r
g3p_project_report <- function(actions, abundance_run_at = 1, run_at = 11)
```
Returns `c(g3a_report_history(var_re=c('__num$','__wgt$'), out_prefix='proj_', run_f=~cur_year_projection, run_at=abundance_run_at), g3a_report_history(var_re=c('__renewalnum$','__spawnednum$','__predby_'), out_prefix='proj_', run_f=~cur_year_projection, run_at=run_at))` -- projection-year-only reporting (comment: "Can be merged with g3a_report_detail in the future"). Note: output names are prefixed `proj_` so `g3_fit` (which looks for detail_/dstart_) will NOT parse them; the bling scripts instead report with `g3a_report_detail` in the projection model and read `g3_fit(r_proj, x)`.

### C.1.2 Harvest control rules (g3a_hcr_*): R/action_hcr.R, R/action_sam_hcr.R
Concept: a TAC is computed from stock state inside the model (an in-model "assessment + HCR"), stored in a pseudo stock `hcr` (storage with `hcr__trigger`, `hcr__fishable`, `hcr__tac`), and fleets' catchability is scaled by that TAC.
Header comment (source) with recommended use (ling model, gadget-models/06-ling/gadget3/00-setup/setup-fleets_prognosis.R):
```r
g3a_hcr_assess(
    list(ling_imm, ling_mat),
    fishable_fs = g3a_hcr_biomass_weighted(-100, ~g3_param('ref.cm'), 1),
    trigger_fs  = list(ling_imm = g3a_hcr_biomass_weighted(0,0,0),
                       ling_mat = g3a_hcr_biomass_weighted(0,0,1)),
    tac_f = g3a_hcr_tac_singletrigger(),
    assess_run_f = ~cur_step == 2)
hcr_stock_proportions <- list(0.5)
hcr_fleet_proportions <- quote( stock_param(predstock, 'hcr.prop', value = 1/2) )
g3a_predate_fleet(list(ling_imm, ling_mat),
    catchability_f = g3a_predate_catchability_hcr(
        g3a_predate_catchability_totalfleet(g3_timeareadata('lln_landings', lln_landings_data)),
        hcr_stock_proportions, hcr_fleet_proportions))
```
NB (source): separate `gather_run_f` (when the biomass data are gathered) from `assess_run_f` (when the TAC formula runs).
`R/action_hcr.R:66`
```r
g3a_hcr_assess <- function(stocks, fishable_fs, trigger_fs, tac_f, prevtacweight = 0, assess_run_f = quote(cur_step == 1), gather_run_f = assess_run_f, hcr_name = "hcr", run_at = 12)
```
Arguments: `stocks` (stock or list), `fishable_fs`/`trigger_fs` (each: list stock-name -> formula, or one value applied to all; evaluated per stock and summed into `hcr__fishable`, `hcr__trigger`), `tac_f` formula using `stock_ss(hcr__trigger)`, `stock_ss(hcr__fishable)` (and previous `hcr__tac`), `prevtacweight` (0 = no smoothing; `tac = w*tac_prev + (1-w)*tac_f`), `assess_run_f` (when TAC regenerated; default `quote(cur_step == 1)`), `gather_run_f` (default = assess_run_f), `hcr_name` ('hcr'), `run_at` (12). Returns list of two steps (gather, assess) named via `step_id(run_at, hcr, action_name, 1|2)`; not a single action — append with `c(actions, g3a_hcr_assess(...))`. The `hcr` storage name must match in `g3a_predate_catchability_hcr(hcr_name=)`.
`R/action_hcr.R:31`
```r
g3a_hcr_tac_singletrigger <- function(trigger = g3_parameterized("tac.trigger", by_stock = by_stock), hr_low = g3_parameterized("tac.hr.low", by_stock = by_stock), hr_high = g3_parameterized("tac.hr.high", by_stock = by_stock), by_stock = FALSE)
```
Formula: `(hr_low * bounded(trigger_stat - trigger, 0, 1) + hr_high * (1 - bounded(trigger_stat - trigger, 0, 1))) * fishable` (hr_low applies ABOVE trigger since bounded -> 1; default params `tac.trigger`, `tac.hr.low`, `tac.hr.high`; `by_stock=FALSE`; source TODO: "Ideally would be by_stock = hcr, but cannae do that"). Source comment shows how to preview: `curve(gadget3:::f_eval(g3a_hcr_tac_singletrigger(trigger=50, hr_low=100, hr_high=200), list(hcr__trigger=x, hcr__fishable=1, stock_ss=identity)), 0, 100)`.
`R/action_hcr.R:51`
```r
g3a_hcr_biomass_weighted <- function(param0, param1, param2, by_stock = TRUE)
```
`sum(param2 * stock_ss(stock__num)*stock_ss(stock__wgt) / (1 + exp(-param0*(param1 - stock__midlen))))`: logistic-in-length weighted biomass (param0 slope, param1 L50, param2 overall multiplier). TODO in source: better names; "Is this right? ... triggercoeffs=c(0,0,0,0,0,1) ... actually half" (gadget2 triggercoeffs mapping uncertain).
`R/action_hcr.R:131`
```r
g3a_predate_catchability_hcr <- function(inner_f, stock_prop_fs, fleet_prop_fs, hcr_name = "hcr")
```
Wraps `inner_f`: result `sum(hcr__tac) * stock_prop_f * fleet_prop_f * inner_f` (`stock_prop_fs` list per prey stock; `fleet_prop_fs` list per predator, evaluated with `stock_var="predstock"`). TODO in source: wants `stock_intersect(hcr, stock_ss(hcr__tac))`. Use as `catchability_f` of `gadget3::g3a_predate_fleet()`.
`R/action_sam_hcr.R:1`
```r
g3a_hcr_assess_sam <- function(stock_imm, stock_mat, fleets, conf, tac_f = sam_wrapper, assess_run_f = quote(cur_step == 3), gather_run_f = quote(cur_step == 1), hcr_name = "hcr_sam", run_at = 12)
```
Experimental in-model SAM assessment as HCR (file action_sam_hcr.R, no docs): gathers catch numbers/weights at age over fleets (`hcr__cn`, `hcr__cw` from `stock__predby_<fleet>`), abundance at age at step 1 (`smb`) and step 3 (`smh`), weights (`sw`), imm/mat totals; at `assess_run_f` (default step 3) calls the R function `tac_f` (default `sam_wrapper`, which is NOT defined in this package — user must supply; wrapped via `gadget3:::g3_native(r=tac_f, cpp=NULL)` => R-model only, not TMB) as `tac_f(conf, cn, smb, smh, sw, cw, immtotal, mattotal)` and stores in `hcr__tac`. `hcr` storage has age 0..15 and by-year dimension (hard-coded `maxage = 15`). `conf` = SAM configuration list.

### C.1.3 Hockey-stick fleet and projection stock actions
`R/hockey_fleet.R:2`
```r
g3a_predate_catchability_hockeyfleet <- function(btrigger, hr, proportion_f = 1, E, sum_stocks = list(), recalc_f = NULL)
```
Catchability formula: `hr * smooth_min(B/btrigger, 1) * E * cur_step_size * stock_ss(predprey__suit)`, where the smooth minimum is `logspace_add(-1000*B/btrigger, -1000)/-1000`, B = `sum(stock__num*stock__wgt)` of the predated stock (or summed over `sum_stocks`, weighted by `proportion_f` switch list — e.g. spawning stock), `E` = effort/landings term (e.g. `g3_timeareadata(...)`), `recalc_f` (optional formula/TRUE-cond) recomputes the quota only when true and stores it in a global `stock__hockeyfleet_<id>` variable (annual quota fixed over steps). Used as `catchability_f` in `g3a_predate_fleet()`. Superseded by `gadget3::g3_quota_hockeyfleet(predstocks, preystocks, preyprop_fs=1, btrigger=g3_parameterized("hf.btrigger", by_stock=predstocks), harvest_rate=g3_parameterized("hf.harvest_rate", by_stock=predstocks), stddev=g3_parameterized("hf.stddev", by_stock=predstocks, value=0))` + `g3_quota()` (note: that is why `g3p_setup_pars` default patterns are `*.hf.btrigger`, `*.hf.harvest_rate`). Heavy commented-out code (quota_table variants) inside.
`R/proj_stock_actions.R:1`
```r
proj_stock_actions <- function(num_project_years, mat, imm = NULL, prop_ogive = NULL, comp_id = "species")
```
Returns `c(dummy_actions, spawning_actions)` that let the model project recruitment from SSB with a hockey-stick stock-recruit relation for "pre-recruit" ages: (a) if `imm` minage==0 `dummy_stock <- imm`, else builds a dummy pre-recruit stock (species name from `g3_stock_name(imm)` + 'dummy', ages 0..minage-1, same length groups, area `areas['1']` taken from the calling environment's global `areas`); (b) `g3a_age(dummy_stock, output_stocks=list(imm), run_f=~cur_step==1, run_at=1, transition_at=8)` so the spawned cohort enters `imm` at the right age; (c) `g3a_spawn(mat, output_stocks=list(dummy_stock), recruitment_f = g3a_spawn_recruitment_hockeystick(r0 = scale(1e4) * g3_param_table('project_rec', expand.grid(cur_year = seq(end_year - minage, end_year + num_project_years)), ifmissing=0), blim = g3_parameterized('blim')), proportion_f = prop_ogive (default 1), mean_f=recl, stddev_f=rec.sd, alpha_f=walpha, beta_f=wbeta by_stock=comp_id, run_f = ~cur_year_projection && cur_step == 1)`. Parameters it introduces: `project_rec.<year>` (R0 series per projected cohort year; filled by g3p_project_rec / g3p_setup_pars; note 1e4 scale vs `rec_scale` 1e-4 in g3p_*), `blim`. Depends on a global `areas` and requires `end_year` inside the model env. Note: `g3a_spawn_recruitment_hockeystick` and `g3_param_table`, `g3_parameterized` are unqualified.

### C.1.4 Reporting, tracing, penalties, plotting
`R/g3a_report_stock_better.R:29`
```r
g3a_report_stock_better <- function(reportstock, input_stocks, report_f, include_adreport = FALSE, run_f = TRUE, run_at = g3_action_order$report)
```
`R/g3a_report_stock_better.R:9`
```r
g3_step_foreach_stock_better <- function(stocks, inner, outer_f, predstocks = list())
```
g3a_report_stock_better: like `g3a_report_stock` but allows reshaping: `reportstock` = a stock (instance dims define output array, e.g. `g3_stock(c(species='reptest'), 1:10*10) |> g3s_age(0,10) |> gadget3:::g3s_modeltime()`), `input_stocks` list, `report_f` a formula in terms of `stock_ss(stock__num)` etc. reshaped with `stock_reshape(reportstock, report_f)`; for each input stock it accumulates into the instance `reportstock__<name>`, zeroing first (`if run_f`), and `REPORT()`s (and `ADREPORT()`s if `include_adreport=TRUE`) once `cur_time <= total_steps`. Example in source: `actions <- list(g3a_report_stock_better(st_report, stocks, quote(stock_ss(stock__num))))`. Returns list (single action). `g3_step_foreach_stock_better` is its helper (cloned environments per stock/predstock; TODO comment: `recursing=FALSE` "should be true"). 
`R/action_trace.R:4`
```r
g3a_trace_nan <- function(actions, check_finite = TRUE, check_positive = FALSE, check_strictly_positive = FALSE, on_error = quote({ }), print_var = FALSE, var_re = c("__num$", "__wgt$"))
```
Appends a "does variable contain NaN/non-finite" trace step after every action that assigns a variable matching `var_re` (default `__num$`, `__wgt$`). Checks: `check_finite` (default TRUE), `check_positive` (< 0), `check_strictly_positive` (<= 0); `on_error`: quote({}) default, or the strings "browse" (calls browser()) / "stop"; `print_var`. On first failure per variable it prints (`Rprintf`) `"<var> failed test at <year>-<step>, after '<action desc>'"`. Usage (comment in source): `trace_actions <- g3experiments::g3a_trace_nan(actions, var_re='__wgt$'); actions <- c(actions, list(trace_actions))`. gadgetutils::g3_optim/g3_iterative warnings tell you to use it. Prefer gadget3's `g3a_trace_var`.
`R/likelihood_penalty.R:13`
```r
g3l_bounds_penalty_old <- function(tmb_param, weight = 1)
```
DEPRECATED ("See gadget3::g3l_bounds_penalty"). For every optimised parameter adds, at `cur_time == 0`, `nll <- nll + weight * (logspace_add(1e6*(p-upper)/(upper-lower),0) + logspace_add(1e6*(lower-p)/(upper-lower),0))^2`; returns named list of actions `010:bounds:<switch>`. Takes the param template (`tmb_param`), `weight` default 1. Intended use: `actions <- c(actions, list(g3l_bounds_penalty(tmb_param)))` before final compile. Current models use `gadget3::g3l_bounds_penalty(actions)` (e.g. bling setup.R).
`R/g3exp_tmb_fn_plot.R:2`
```r
g3exp_tmb_fn_plot <- function(model_code, params, par_name, from = params[par_name[[1]], "lower"], to = params[par_name[[1]], "upper"], ...)
```
Plots the objective function (1-D likelihood curve, `curve()`) over `par_name` from `from` to `to` (defaults lower/upper bound of the first par; TODO: "should be 'near value', i.e. where -2*logLik(x) < 1.96 - 2*logLik(opt)"). Sets `optimise=FALSE` and `random=FALSE` for all params except `par_name`; builds `g3_tmb_adfun(model_code, params, type=c("ADFun","Fun"))` (TODO: type "Fun" alone fails, maybe because one param); `...` to `curve`. Requires `g3_cpp` model. Useful as a poor-man's likelihood profile for a single parameter with all others fixed (NOT re-optimised; contrast g3_sensitivity).

## C.2 How these plug into a gadget3 projection / reference-point workflow
1. Historical model: stocks imm/mat, fleets via `g3a_predate_fleet`; for projection years use `g3_quota_hockeyfleet` (current gadget3) or `g3a_predate_catchability_hockeyfleet` (legacy) on the fleets, with parameters `<fleet>.hf.btrigger` / `<fleet>.hf.harvest_rate` (+ `project_hr.<n>` series in the legacy setup-advice.R) and `<fleet>.quota.prop`; `g3a_time(..., project_years = g3_parameterized('project_years'))`; `g3_param_project()` is the modern way to give recruitment/M random-effect or project-time parameters.
2. Recruitment in projection years: either `g3a_renewal_normalparam` with `rec.proj` parameters (gadget3 default `run_projection`), or SSB-driven via `proj_stock_actions()` (hockey-stick stock-recruit with Blim) and `project_rec.*` parameters.
3. Add `g3a_report_detail(actions)`; compile `g3_to_tmb` then `g3_to_r(attr(tmb,'actions'))` (`r_proj`).
4. `input_pars <- g3p_setup_pars(r_proj, fit$params, blim=ref_points$B_lim*1e3, btrigger=ref_points$MSY_btrigger*1e3, harvest_rates=hr_target_range, harvest_rate_trials=1, fleet_proportions=fleet_props, rec_list=list(base=fit$stock.recruitment |> filter(stock=='bli_imm')), rec_years=(tyr-3):(tyr-1), rec_method='constant', project_years=num_project_years, assess_err=FALSE, hr_pattern='project_hr.[0-9]')` (actual call from 07-bling setup-advice.R). 
5. `proj_runs <- parallel::mclapply(input_pars, function(x) g3_fit(r_proj, x), mc.cores=...)`; collate with `gadgetutils::bind_fit_components(proj_runs,'res.by.year')`; compute SSB/F/catch per HR; reference points (Flim, Fpa, FMSY) from percentile/risk criteria — done by user scripts (not in these packages). Use `plot_hr(fit, min_catch_length = 0, return_data = TRUE)` for model-HR consistent with target HRs.
6. HCR-in-the-loop (MSE-style): `g3a_hcr_assess` + `g3a_predate_catchability_hcr` (or `g3a_hcr_assess_sam`).

## C.3 Known bugs / TODO (g3experiments)
All TODO comments in source are quoted above: `g3a_hcr_tac_singletrigger` (by_stock), `g3a_hcr_biomass_weighted` (names; trigger-coefficient semantics), `g3a_predate_catchability_hcr` (stock_intersect), `g3_step_foreach_stock_better` (recursing), `g3exp_tmb_fn_plot` (from/to defaults; "Fun" type). Plus: `proj_stock_actions` relies on global `areas`; g3p_* depend on suggested-not-imported packages (tseries, broom, dplyr via `%>%`), no argument validation (`g3p_project_rec` with unknown method stops "Method not valid, expected constant, AR or bootstrap"); in `g3p_setup_pars` the variable `fleet_proportions` checks `sum != 1` with exact floating comparison (rescales + warns on tiny error); rec_scale (1e-4) vs proj_stock_actions scale (1e4) are separate conventions.

## C.4 Random-effect recruitment / projection vignette (gadget3 repo, summarised)
Title "Random effects & projections". Key points:
* Random effects in TMB = inner optimisation per outer evaluation. In gadget3 use `g3_param_project(name, g3_param_project_dnorm()|_dlnorm()|_logar1()|..., scale=, by_stock=, by_step=)`: like `g3_parameterized(by_year=TRUE)` but also adds a likelihood on the time-vector and parameters for the generating distribution, used to draw values in projections. For `g3_param_project("M", g3_param_project_dnorm())` parameters are `M.(year).(step)` (time-vector), `M.proj.dnorm.mean`, `M.proj.dnorm.stddev`, and the likelihood weight `proj_dnorm_M_weight`.
* Recruitment: `g3a_renewal_normalparam(stocks$imm, factor_f = g3_param_project("rec", g3_param_project_logar1(), scale="scalar", by_stock=stocks, by_step=FALSE), run_step=1)`; parameters include `fish_imm.rec.proj.logar1.level` / `.stddev` (optimised, e.g. level 2e3 in [1e1,5e5], stddev 1 in [1e-15,1e4]) and relative weight param `proj_logar1_fish_imm_weight.proj_logar1_rec_weight` ("Relative weight is important, but g3_iterative isn't handling this for you yet").
* Fixed-effects fit: `g3_init_val("*.rec.#", value=2e3, lower=1e1, upper=1e6, random=FALSE)`; random-effects fit: `g3_init_val("*.rec.#", value=2e3, random=TRUE)` ("By setting random = TRUE, any previous bounds will be cleared"). Objective via `g3_tmb_adfun(model_cpp, params.rnd, inner.control=list(trace=0, maxit=1000, tol=1e-3), silent=TRUE)`; optimise with `gadgetutils::g3_optim(obj.rnd, params.rnd, trace=0)` (the first arg may be an adfun list; extra `...` go to g3_tmb_adfun ONLY when model is g3_cpp) — the vignette passes `control=list(maxit=2000, trace=0)` for the fixed fit. Check `attr(params.rndout,"summary")$convergence`.
* Projections: set `project_years` and run the cheap single-run function `fn <- g3_tmb_fn(model_cpp)`; each `fn(params |> g3_init_val("project_years", 40))` draws new random projection values; collect `dend_<stock>__num` via `g3_array_agg`, plot with `g3_array_plot`. `TMB::sdreport` only works with nlminb, "not g3_optim(), or optim(), but we're getting false convergence" (vignette TODO). `g3l_bounds_penalty(actions)` and `g3a_report_history(actions, "__num$|__wgt$", out_prefix="dend_")` ("Late reporting") are added to the actions.

---------------------------------------------------------------------------
# PART D. mfdb (short)
---------------------------------------------------------------------------

What it is: CRAN package "mfdb: Data management for fisheries model creation" (v7.3-99 dev; NEWS: RPostgres & RSQLite no longer required deps -> install separately; DuckDB supported, SQLite `.sqlite` names recognised). Automates: import fisheries data (survey/sampling, landings, stomach, temperature, taxonomies) into a DuckDB or PostgreSQL schema, sample/aggregate it with grouping, and (legacy) write GADGET2 model files. Based on DST2. Connect: `mdb <- mfdb('Iceland')` (PostgreSQL, db `mf`, guesses hosts /tmp, /var/tmp, localhost...; env vars MFDB_USER/HOST/PORT/PASSWORD/DBNAME/DBDIR override), `mfdb('x.duckdb')` (DuckDB file; schema 'main'), `mfdb('x.sqlite')`; `mfdb(schema_name="", db_params=list(), destroy_schema=FALSE, save_temp_tables=FALSE)` (R/mfdb.R:2); `mfdb_disconnect(mdb)`. `mfdb('Test', destroy_schema=TRUE)` wipes. Sharing: `mfdb_share_with`, dump/restore `mfdb_cs_dump/restore`.
Import API (exports): `mfdb_import_area(mdb, data_in)` (areacells: name, division, size), `mfdb_import_division`, `mfdb_import_survey(mdb, data_in, data_source='default_sample')` (columns year, month, areacell, species, length, count, age, sex, maturity_stage, sampling_type, gear, vessel, weight ...), `mfdb_import_survey_index`, `mfdb_import_temperature`, `mfdb_import_stomach`, `mfdb_import_sampling_type`, taxonomy imports (`mfdb_import_species_taxonomy`, gear, vessel, port, net_type, tow, trip, ...), `mfdb_find_species('cod')`, dplyr views `mfdb_dplyr_sample(mdb)`, `mfdb_dplyr_survey_index`, `_division`, `_predator`, `_prey`, `_table`.
Query functions (all `(mdb, cols, params, ...)`; `cols` = extra grouping columns e.g. c('age','length','maturity_stage'); `params` = named list of filters/groupings; result = list of data.frames, one per "sample" (usually one), each with attributes (year, step, area, age, length... = the grouping definitions) that gadget3 reads):
* `mfdb_sample_count(mdb, cols, params, scale_index = NULL)` -> year, step, area, cols..., `number` (R/mfdb_queries.R:199). `scale_index`: NULL | 'tow_length' (count/tow length) | 'area_size' (count*size) | name of a stored survey index (count * mean index) — abundance scaling.
* `mfdb_sample_meanlength(mdb, cols, params, scale_index=NULL)` (:211) -> number, mean; `mfdb_sample_meanlength_stddev` (adds stddev; TODO "Should take length_var into account"); `mfdb_sample_meanweight(mdb, cols, params, scale_index=NULL, measurements=c('overall'))` (:275; measurements overall|liver|gonad|stomach) and `_stddev`; `mfdb_sample_totalweight(mdb, cols, params, measurements=c('overall'))` (:260) -> `total_weight` (survey indices / landings use this); `mfdb_sample_rawdata` (no group-by, raw_length/raw_weight); `mfdb_sample_scaled(mdb, cols, params, abundance_scale=NULL, scale='tow_length')`.
* `mfdb_survey_index_mean/total(mdb, cols, params, scale_index=NULL)` -> `mean`/`total` of stored survey indices (:122, :147); `params$index_type` is REQUIRED (stop otherwise); `mfdb_area_size`, `mfdb_area_size_depth`, `mfdb_temperature`; stomach: `mfdb_stomach_preycount|preymeanlength|preymeanweight|preyweightratio|presenceratio`; `mfdb_concatenate_results`.
* Source TODOs: "Bootstrapping is very likely broken" (mfdb_queries.R lines ~441, 487, 530 — affects `mfdb_bootstrap_group`); length_var not accounted for in stddev; `#TODO: add x$from somewhere to fudge steps` in mfdb_step_interval.
Grouping helpers (params values):
* `mfdb_interval(prefix, vect, open_ended=FALSE)` (R/mfdb_aggregate_interval.R:4): numeric breakpoints, max exclusive, groups named `paste0(prefix, vect)`, e.g. `mfdb_interval('len', seq(10,100,by=5), open_ended=c('lower','upper'))`; `open_ended` TRUE = 'upper'; lengths [a,b) i.e. `cut(right=FALSE)`.
* `mfdb_group(...)`, `mfdb_group_numbered(prefix, ...)`: named groups of values, e.g. `mfdb_group(blingimm = 1, blingmat = 2:5)` for maturity_stage, `mfdb_group(mat_ages = minage:maxage)`; areas as group of areacells/divisions; `mfdb_na_group`, `mfdb_unaggregated`, `mfdb_bootstrap_group(count, group, seed)`, `mfdb_step_interval(prefix, by, from=0, to=NULL, open_ended=FALSE)`.
* Time steps: `mfdb_timestep_yearly` = group('1'=1:12); `mfdb_timestep_biannually` = '1'=1:6,'2'=7:12; `mfdb_timestep_quarterly` = '1'=1:3,...; custom `mfdb_group('1'=1:3, '2'=4:12)`. Param `year = 1982:2020` (integer vector), `timestep=` (alias `step`), `areacell`/`area` (e.g. `mfdb_group(div1 = c('101','102'))`), `species='COD'`, `sampling_type='IGFS'`, `data_source='iceland-ldist'`, `gear`, `vessel`, `sex`, `maturity_stage`, ... and `age`, `length` as intervals/groups. Other filters prefixed by column name (`gear=c('LLN','HLN')`).
How output feeds gadget3: the returned data.frames carry attributes; `gadget3::g3l_catchdistribution(name, obs_data=<mfdb output>, fleets, stocks, ...)`, `g3l_abundancedistribution` and `g3_timeareadata()` read the `year/step/area/age/length` attributes (see gadget3 vignette incorporating-observation-data: "gadget3 will also automatically read the aggregation attributes used by mfdb_sample_count"); `gadgetutils::g3_data()` / `add_g3_attributes()` reproduce this for non-mfdb data. Example (bling setup-catchdistribution.R): 
```r
ldist.aut <- mfdb::mfdb_sample_count(mdb, c('age','length'), c(list(
    data_source='iceland-ldist', sampling_type='AUT',
    age = mfdb::mfdb_interval("all", c(minage, maxage), open_ended=c("upper","lower")),
    length = mfdb::mfdb_interval("len", seq(minlen, maxlen, by=dl), open_ended=c("upper","lower"))), defaults))
matp.aut <- mfdb::mfdb_sample_count(mdb, c('maturity_stage','age','length'), append(defaults, list(sampling_type='AUT',
    length = mfdb::mfdb_interval('len', seq(minlen, maxlen, by=2*dl), open_ended=c('lower','upper')),
    maturity_stage = mfdb::mfdb_group(blingimm = 1, blingmat = 2:5))))
for (i in seq_along(matp.aut)) attributes(matp.aut[[i]])$age$all <- minage:maxage
```
(`defaults` = list(area/areacell, timestep, year, species)). Gotcha: the age attribute fix-up above for maturity data. Also `scale_index` for abundance indices; use `mfdb_sample_totalweight` for landings (`g3_timeareadata('landings', ...)` ) and `mfdb_survey_index_*` for acoustic/biomass indices (`g3l_abundancedistribution(function_f = g3l_distribution_surveyindices_log(...))`).
Other mfdb parts: `gadget_directory`, `gadget_file`, `gadget_likelihood_component`, `gadget_stockfile_*`, `gadget_fleetfile`, `gadget_areafile` (write GADGET2 text model files; irrelevant for gadget3 TMB models); `mfdb_rpath_params`/ewe_model (Rpath export). Examples in mfdb/examples (iceland, datras, minouw); vignettes: population, tow_data, trip, weightmeasurements, import_hydrography_cmems. mfdb demo/inttest scripts need a database.

---------------------------------------------------------------------------
# PART E. Cross-package gotchas checklist for agents
---------------------------------------------------------------------------
1. `g3_fit` needs a model with reporting (`g3a_report_detail`); otherwise it silently recompiles in R (slow) and ignores `g3_cpp` TMB optimisations. Pass the same actions used for fitting. For gadgetplots, `fit$params` must be the data.frame form.
2. `g3_iterative` grouping names have NO `cdist_sumofsquares_` prefix and NO `_weight`; survey indices have no `log_`.
3. Use `mc.cores = 1` on Windows, small values for large models; `serial_compile=TRUE` for memory. Never nest `mclapply` around g3_* analyses without setting inner `mc.cores = 1`.
4. After `g3_iterative`, the best result is selected as the group whose weighted nll sum is lowest; weights in the returned table are those of that group's stage-2 run (all groups share the same updated weights).
5. For retro: ensure `retro_years` param exists; the retro list is named by peel count "1".."n"; build `retro_fit <- c(list(fit), lapply(retro, g3_fit...))` before `plot_retro`.
6. `g3_init_guess` is regex-based and unanchored; `g3_init_val` (gadget3) is glob-based and anchored — don't mix pattern styles. `g3_sensitivity(par_name=)` uses the glob form.
7. Parameter output text files (`params.final`, `weights.final`, `lik.*`) are for humans; reload `.Rdata` (`params_final.Rdata`, `params_out_s2.Rdata`, `retro_params_out.Rdata`, `jitpar_out.Rdata`, `leaveout_params_out.Rdata`, `senpar_out.Rdata`).
8. `gadget_plots(..., file_type='html')` and `make_html()` require pandoc and write `template.Rmd` transiently into `path`; only templates standard|iceland|nea_ghl exist.
9. g3experiments functions rely on unexported gadget3 internals and unqualified names: attach gadget3 first; check gadget3 NEWS before using (e.g. `g3a_trace_nan` -> `g3a_trace_var`, `g3l_bounds_penalty`, `g3_quota_hockeyfleet`, `g3_tmb_fn`).

---------------------------------------------------------------------------
# PART F. Recipes (assembled from source examples; untested here, no R packages were run)
---------------------------------------------------------------------------

## F.1 Fit, reweight, diagnose (gadgetutils + gadgetplots)
```r
library(gadget3); library(gadgetutils); library(gadgetplots)
actions <- c(actions, list(g3l_bounds_penalty(actions)))              # gadget3, not g3experiments
tmb_model <- g3_to_tmb(c(actions, list(g3a_report_detail(actions))))
tmb_param <- attr(tmb_model, "parameter_template") |>
  g3_init_val("*.K", 0.3, lower = 0.04, upper = 1.2)                    # glob (anchored)
# or regex style: tmb_param <- g3_init_guess(tmb_param, "\\.K$", 0.3, 0.04, 1.2, optimise = 1)

grouping <- g3_iterative_default_grouping(tmb_param)                    # or a hand-made list
params_out <- g3_iterative("models/m1", wgts = "WGTS", model = tmb_model,
  params.in = tmb_param, grouping = grouping, cv_floor = 0.05,
  control = list(maxit = 3000), mc.cores = 4)                           # writes models/m1/WGTS/*
fit <- g3_fit(tmb_model, params_out)                                    # list of class gadget.fit
save(fit, file = "models/m1/WGTS/fit.Rdata")
gadget_plots(fit, "models/m1/figs", file_type = "html")                 # make_html()
plot(fit, "annual"); plot_catchdist(fit)
```
Resume after changing `cv_floor` (reuses stage-1 results): `g3_iterative(..., resume_final = TRUE)`.
Quick weights only: `g3_iterative(..., shortcut = TRUE)` or `w <- estimate_weights(tmb_model, tmb_param)`.

## F.2 Retrospective + Mohn's rho
```r
retro <- g3_retro("models/m1", outdir = "RETRO", model = tmb_model, params = params_out, nyears = 5, mc.cores = 5)
retro_fit <- c(list(fit), lapply(retro, function(p) g3_fit(tmb_model, p |> g3_init_guess("project_years", 1))))
plot_retro(retro_fit, var = "total.biomass")
mohnrho(fit, retro_fit[-1], vars = c("total.biomass", "F", "recruitment"), lag = c(0, 1, 1))
```
(For a time-truncated data set the bling script instead builds separate retro models; for `g3_retro` the `retro_years` parameter does the truncation inside the same model.)

## F.3 Jitter, leave-one-out, sensitivity/profile
```r
jit  <- g3_jitter("models/m1", outdir = "JITTER", model = tmb_model, params = params_out, njits = 20,
                  jitter_fraction = 0.1, pattern_to_ignore = "_weight$", mc.cores = 4)
jit_fit <- lapply(jit, function(p) try(g3_fit(tmb_model, p)))
plot_jitter(jit_fit[!sapply(jit_fit, inherits, "try-error")])

lo   <- g3_leaveout("models/m1", model = tmb_model, params = params_out,
                    grouping = list(comm = c("ldist_comm", "aldist_comm")), mc.cores = 4)
plot_leaveout(lapply(lo, function(p) g3_fit(tmb_model, p)))

sens <- g3_sensitivity("models/m1", outdir = "SENS", model = tmb_model, params = params_out,
                       par_name = "*.M.#", par_values = c(0.1, 0.2, 0.3), mc.cores = 3)
# profile with re-weighting for each value: see 07-bling setup.R (g3_iterative inside mclapply, mc.cores = 1)
```

## F.4 Data from data.frame instead of mfdb
```r
ldist <- g3_data(survey_df,
  params = list(year = 2000:2020, step = mfdb_group("1" = 1:12),         # mfdb_* helpers come from mfdb pkg
                length = mfdb_interval("len", seq(10, 100, 5), open_ended = c("lower", "upper")),
                age = mfdb_interval("age", 1:10, open_ended = "upper")),
  method = "count", column_names = c(year = "year", step = "month", area = "areacell"))
g3l_catchdistribution("ldist_survey", obs_data = ldist, fleets = list(), stocks = stocks, function_f = g3l_distribution_sumofsquares())
```
(`mfdb_interval`/`mfdb_group` objects can be created without a database connection; g3_data's doc says it could be independent of mfdb if these helpers were imported to the project.)

## F.5 Projection runs
See C.2 (g3p_setup_pars -> mclapply(g3_fit) -> bind_fit_components(proj_runs, "res.by.year")).

---------------------------------------------------------------------------
# PART G. Index: file:line of every exported function
---------------------------------------------------------------------------
## gadgetutils
add_g3_attributes  R/add_g3_attributes.R:22
g3_data  R/g3_data.R:36
g3_fit  R/g3_fit.R:22
extract_year_step  R/g3_fit.R:896
bind_fit_components  R/g3_fit_combine.R:17
bind_fit  R/g3_fit_combine.R:40
g3_iterative  R/g3_iterative.R:76
g3_iterative_default_grouping  R/g3_iterative.R:393
g3_iterative_setup  R/g3_iterative.R:431
g3_lik_out  R/g3_iterative.R:488
g3_update_weights  R/g3_iterative.R:577
tabulate_SS  R/g3_iterative.R:626
estimate_weights  R/g3_iterative_shortcut.R:7
estimate_weights_cdist  R/g3_iterative_shortcut.R:44
estimate_weights_adist  R/g3_iterative_shortcut.R:71
g3_jitter  R/g3_jitter.R:20
jitter_params  R/g3_jitter.R:108
g3_leaveout  R/g3_leaveout.R:20
g3_optim  R/g3_optim.R:15
write.g3.param  R/g3_readwrite.R:6
write.g3.file  R/g3_readwrite.R:23
read.g3.param  R/g3_readwrite.R:43
g3_retro  R/g3_retro.R:17
g3_sensitivity  R/g3_sensitivity.R:20
mohnrho  R/mohnrho.R:11
g3_init_guess  R/parameter_template_utils.R:11
g3_add_parscale  R/parameter_template_utils.R:65
value_from_bounds  R/parameter_template_utils.R:76
eval_bounded  R/parameter_template_utils.R:88
stock_species  R/parameter_utils.R:6
g3_stock_name  R/parameter_utils.R:17
init_abund  R/setup-utils.R:15
stock_renewal  R/setup-utils.R:168
init_sd  R/setup-utils.R:194
model_actions  R/setup-utils.R:238
## gadgetplots
dplot_adist  R/dplot_adist.R:13
dplot_aldist  R/dplot_aldist.R:20
dplot_catch  R/dplot_catch.R:19
dplot_ldist  R/dplot_ldist.R:14
dplot_sexr  R/dplot_sexr.R:10
dplot_stockdist  R/dplot_stockdist.R:22
g3d_plot  R/g3d_plot.R:13
g3plot_exponentiall50  R/g3plot_suitability.R:19
g3plot_andersen  R/g3plot_suitability.R:70
gadget_plots  R/gadget_plots.R:17
getCores  R/internal_functions.R:27
make_html  R/make_html.R:22
plot_adist  R/plot_adist.R:15
plot_ageclass  R/plot_ageclass.R:14
plot_agecomp  R/plot_agecomp.R:24
plot_agelength  R/plot_agelength.R:10
plot_annual  R/plot_annual.R:14
plot_biomass  R/plot_biomass.R:19
plot_catch  R/plot_catch.R:17
plot_catchdist  R/plot_catchdist.R:15
plot_hr  R/plot_f.R:18
plot_f  R/plot_f.R:106
plot_growth  R/plot_growth.R:15
plot_jitter  R/plot_jitter.R:9
plot_ldist  R/plot_ldist.R:19
plot_leaveout  R/plot_leaveout.R:11
plot_likelihood  R/plot_likelihood.R:20
plot_param  R/plot_param.R:13
plot_rec  R/plot_rec.R:16
plot_resid  R/plot_resid.R:10
plot_retro  R/plot_retro.R:11
plot_si  R/plot_si.R:13
plot_sr  R/plot_sr.R:15
plot_ssb  R/plot_ssb.R:12
plot_stockcomp  R/plot_stockcomp.R:15
plot_stockdist  R/plot_stockdist.R:22
plot_suitability  R/plot_suitability.R:15
plot_weight  R/plot_weight.R:11
repeat_palette  R/repeat_palette.R:13
## g3experiments
g3a_hcr_tac_singletrigger  R/action_hcr.R:31
g3a_hcr_biomass_weighted  R/action_hcr.R:51
g3a_hcr_assess  R/action_hcr.R:66
g3a_predate_catchability_hcr  R/action_hcr.R:131
g3a_hcr_assess_sam  R/action_sam_hcr.R:1
g3a_trace_nan  R/action_trace.R:4
g3_step_foreach_stock_better  R/g3a_report_stock_better.R:9
g3a_report_stock_better  R/g3a_report_stock_better.R:29
g3exp_tmb_fn_plot  R/g3exp_tmb_fn_plot.R:2
g3p_project_rec  R/g3p_project.R:2
g3p_project_advice_error  R/g3p_project.R:29
g3p_project_rec_arima  R/g3p_project.R:50
g3p_project_rec_bootstrap  R/g3p_project.R:71
g3p_project_rec_constant  R/g3p_project.R:80
g3p_project_report  R/g3p_project.R:87
g3p_setup_pars  R/g3p_project.R:108
g3a_predate_catchability_hockeyfleet  R/hockey_fleet.R:2
g3l_bounds_penalty_old  R/likelihood_penalty.R:13
proj_stock_actions  R/proj_stock_actions.R:1
## mfdb exports (NAMESPACE) grouped
connection/schema: mfdb, mfdb_disconnect, mfdb_share_with, mfdb_cs_dump, mfdb_cs_restore. aggregation: mfdb_group, mfdb_group_numbered, mfdb_interval, mfdb_step_interval, mfdb_na_group, mfdb_unaggregated, mfdb_bootstrap_group, mfdb_timestep_yearly, mfdb_timestep_biannually, mfdb_timestep_quarterly. dplyr: mfdb_dplyr_table, _survey_index, _division, _sample, _predator, _prey. import: mfdb_import_survey, mfdb_import_survey_index, mfdb_import_stomach, mfdb_import_temperature, mfdb_import_area, mfdb_import_division, mfdb_import_sampling_type, mfdb_import_*_taxonomy (bait_type, cs, gear, tow, net_type, population, port, trip, vessel, vessel_owner, species), mfdb_empty_taxonomy. queries: mfdb_area_size, mfdb_area_size_depth, mfdb_temperature, mfdb_survey_index_mean, mfdb_survey_index_total, mfdb_sample_count, mfdb_sample_meanlength, mfdb_sample_meanlength_stddev, mfdb_sample_totalweight, mfdb_sample_meanweight, mfdb_sample_meanweight_stddev, mfdb_sample_rawdata, mfdb_sample_scaled, mfdb_stomach_preycount/preymeanlength/preymeanweight/preyweightratio/presenceratio, mfdb_concatenate_results, mfdb_find_species. GADGET2 file writers: gadget_areafile, gadget_directory, gadget_dir_write, gadget_dir_read, gadget_file, read.gadget_file, gadget_fleet_component, gadget_likelihood_component, gadget_stockfile_extremes/refweight/initialconditions/recruitment. other: mfdb_rpath_params.
