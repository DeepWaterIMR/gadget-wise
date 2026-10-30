# gadget3 reference digest (for AI-agent knowledge pack)

- Package: gadget3 0.15-1-999 (DESCRIPTION:4-5, Date 2026-01-12). Maintainer Jamie Lentin; authors Elvarsson, Butler. License GPL-2.
- Source root `S` = `.../gadget3`. All `file:line` cites below are relative to `S` (e.g. `R/stock.R:156`).
- What it is (paraphrasing DESCRIPTION:11-14): a framework for building marine ecosystem models that generates R or C++ code, which is then optimised with TMB and ordinary R tools; designed principally to reproduce gadget2 models in TMB but extensible beyond gadget2.
- Core idea: a model = a flat `list` of *actions*. An action = a named list of R formulas (`~`) carrying their own environment. `g3_to_r(actions)` or `g3_to_tmb(actions)` sort/dedupe the steps by name, wrap them in one `while (TRUE)` time loop and emit an R function or C++ (TMB) template. No input-file format exists: the model is an R script (vignettes/introduction-single-stock.Rmd:93).
- Exports: 130 `export()` + S3 methods `edit`/`print` for `g3_r` and `g3_cpp` (NAMESPACE).
- Provenance flags used below: **[src]** = read from R source, **[doc]** = from man/*.Rd or vignette text, **[run]** = verified by running the installed package (0.15.1.999) in this session, **[infer]** = my inference from source (flagged so it can be double-checked).
- Naming conventions: `g3a_*` actions, `g3l_*` likelihood actions (also actions), `g3s_*` stock-dimension builders (pipe-able: `g3_stock(...) |> g3s_age(..) |> g3s_livesonareas(..)`), `g3_*` helpers. Instance variables inside the model: `<stock>__num`, `<stock>__wgt` etc. (double underscore).

---------------------------------------------------------------------

## 1. Exported function inventory (signatures verbatim from R/ source)

Unless stated, "creates params" lists parameter *names as they appear in the parameter template* for a stock named `S` (e.g. `fish_imm`) and fleet/predator named `P` (e.g. `comm_is`). `by_stock=TRUE` -> prefix `S.`; `by_stock='species'` -> prefix is the *name-part* called `species` (stock built as `g3_stock(c(species="fish","imm"),..)` -> `fish.`). See section 5 for the full naming grammar. Parameter names marked [run] were printed from a real `g3_to_tmb()` template.

### 1.1 Stock construction & dimensions (`g3_stock`, `g3s_*`) -- see also section 3

```r
g3_stock <- function(var_name, lengthgroups, open_ended = TRUE)                 # R/stock.R:156
g3_fleet <- function(var_name)                                                   # R/stock.R:155
g3s_clone <- function(inner_stock, var_name)                                     # R/stock.R:158
g3_is_stock <- function (stock)                                                  # R/stock.R:66
g3_stock_def <- function(stock, name)                                            # R/stock.R:2
g3_stock_instance <- function (stock, init_value = NA, desc = "")                # R/stock.R:15
g3s_age <- function(inner_stock, minage, maxage)                                 # R/stock_age.R:1
g3s_agegroup <- function(inner_stock, agegroups)                                 # R/stock_age.R:49
g3_areas <- function (area_names)                                                # R/stock_areas.R:1
g3s_livesonareas <- function(inner_stock, areas)                                 # R/stock_areas.R:5
g3s_areagroup <- function(inner_stock, areagroups)                               # R/stock_areas.R:109
g3s_tag <- function(inner_stock, tag_ids, force_untagged = TRUE)                 # R/stock_tag.R:1
g3s_time <- function(inner_stock, times, year = NULL, step = NULL)               # R/stock_time.R:35
g3s_time_convert <- function (year_or_time, step = NULL)                         # R/stock_time.R:1
```

| fn | purpose |
|---|---|
| `g3_stock(var_name, lengthgroups, open_ended=TRUE)` | Stock with a *length* dimension. `var_name` may be multi-part, e.g. `c(species="fish","imm")`; parts joined with `_` give `$name` ("fish_imm"); `$name_parts` kept for parameter naming/likelihood-data matching (R/stock.R:52-56,156). `lengthgroups` = vector of lower bounds; `open_ended=TRUE` makes last group `x:Inf`, `FALSE` treats final value as upper bound of previous group (R/stock.R:89-98; man/stock.Rd). |
| `g3_fleet(var_name)` | Same storage object but with no length dimension (R/stock.R:155). Used as predator/fleet. |
| `g3s_clone(s, name)` | copy of dims with a new name (R/stock.R:158). |
| `g3_stock_instance(stock, init_value=NA, desc="")` | Returns an array shaped like the stock (what e.g. `fish__num` looks like); attr `desc` shown in generated code (R/stock.R:15-41). |
| `g3_stock_def(stock, name)` | Pull definition out of stock env, e.g. `g3_stock_def(fish,"midlen")`, `"minage"`, `"maxage"`, `"minlen"`, `"upperlen"`; a list of stocks gives a list (R/stock.R:2-7). Prefix `stock__` is optional. |
| `g3s_age(s, minage, maxage)` | adds `age` dim `minage..maxage` (dimnames "age1","age2",...) (R/stock_age.R:1-46). Applying again to a stock that already has age *modifies* it. **Quirk:** `stock__maxage` is converted using `is.numeric(minage)` (R/stock_age.R:4) -- harmless for numeric args. |
| `g3s_agegroup(s, agegroups)` | age dim of *groups*, e.g. `list(1:3, 4:10)`; names default `"1:3"` or `"1,3,5"` (R/stock_age.R:48-60). Mainly used internally for likelihood data. |
| `g3_areas(area_names)` | `structure(seq_along(area_names), names = area_names)` -> named integer vector (R/stock_areas.R:1-3). |
| `g3s_livesonareas(s, areas)` | stock lives in integer areas; unnamed areas get names `area<N>`; a single area simplifies loops (R/stock_areas.R:5-106). Defines vars `area_<name>`. |
| `g3s_areagroup(s, areagroups)` | areas grouped, `list(1:2, 3)`; degenerates to `g3s_livesonareas` if all groups length 1 (R/stock_areas.R:109-158). |
| `g3s_tag(s, tag_ids, force_untagged=TRUE)` | tag dim; `tag_ids` must be **integer** vector (`stopifnot(is.integer(tag_ids))`, R/stock_tag.R:3); 0 = "untagged", added automatically as first entry named "untagged" if missing and `force_untagged` (R/stock_tag.R:9-16). |
| `g3s_time(s, times, year, step)` | time dimension, `times` = vector of `year*100+step` codes (R/stock_time.R:35-80). Used for likelihood data. |
| `g3s_time_convert(year, step=NULL)` | `year*100L + step`, or `year*100L` if no step; parses "1999-01" strings; errors if step > 99 (R/stock_time.R:1-20). |

Internal (not exported, but referenced by actions/vignettes): `g3_storage`, `g3s_length` (R/stock.R:68), `g3s_manual` (R/stock_manual.R:6), `g3s_stockproduct` (R/stock_product.R:1), `g3s_modeltime` / `g3s_modeltime_fishingyear` (R/stock_time.R:83,109), `g3s_sparsedata` (R/likelihood_sparsesample.R:2).

### 1.2 Time, ageing, mortality, weight loss, migration

```r
g3a_time <- function(
        start_year,
        end_year,
        step_lengths = c(12),
        final_year_steps = quote( length(step_lengths) ),
        project_years = g3_parameterized("project_years", value = 0, optimise = FALSE),
        retro_years = g3_parameterized("retro_years", value = 0, optimise = FALSE),
        run_at = g3_action_order$initial,
        run_stop_at = g3_action_order$time)                                      # R/action_time.R:17-25

g3a_age <- function(
        stock,
        output_stocks = list(),
        output_ratios = rep(1 / length(output_stocks), times = length(output_stocks)),
        run_f = ~cur_step_final,
        run_at = g3_action_order$age,
        transition_at = g3_action_order$age )                                    # R/action_age.R:2-8

g3a_naturalmortality_exp <- function (
        param_f = g3_parameterized('M', by_stock = by_stock, by_age = TRUE),
        by_stock = TRUE,
        action_step_size_f = ~cur_step_size)                                     # R/action_naturalmortality.R:1-4
g3a_naturalmortality <- function (
        stock,
        mortality_f = g3a_naturalmortality_exp(),
        run_f = TRUE,
        run_at = g3_action_order$naturalmortality)                               # R/action_naturalmortality.R:10-14

g3a_weightloss <- function (
        stock,
        rel_loss = NULL,
        abs_loss = NULL,
        min_weight = 1e-7,
        apply_to_pop = quote( stock__num ),
        run_f = TRUE,
        run_step = NULL,
        run_at = g3_action_order$naturalmortality )                              # R/action_weightloss.R:1-9

g3a_migrate_normalize <- function(row_total = 1)                                 # R/action_migrate.R:1
g3a_migrate <- function(
        stock,
        migrate_f,
        normalize_f = g3a_migrate_normalize(),
        run_f = TRUE,
        run_at = g3_action_order$migrate)                                        # R/action_migrate.R:21-26
```

| fn | purpose / params created |
|---|---|
| `g3a_time` | timekeeping (see section 2). Params: `project_years`, `retro_years` (unprefixed, `optimise=FALSE`, value 0) [run]. Defines `cur_time, cur_step, cur_step_size, cur_year, cur_year_projection, cur_step_final, total_steps, total_years, start_year, end_year, step_lengths, step_count` (R/action_time.R:8-16,44-66). `step_lengths` = months per step, must sum to 12 (error otherwise, R/action_time.R:27); `final_year_steps` 0 => end_year exclusive, default => inclusive (man/action_time.Rd). `mfdb_group` accepted for step_lengths (R/action_time.R:26). |
| `g3a_age` | At `cur_step_final`: oldest age group -> `output_stocks` (split by `output_ratios`) or, if no outputs, stays as **plus group** (older cohort merged with the cohort below: `stock_combine_subpop`, R/action_age.R:70-74); minage group zeroed; others shift up. Single-age stock + outputs => move-and-zero; single age, no outputs => no-op (R/action_age.R:22-46). Params: none. |
| `g3a_naturalmortality_exp` | formula `exp(-(param_f) * action_step_size_f)` (R/action_naturalmortality.R:5-7). Default param `S.M.<age>` per age (by_age = TRUE since 0.11 -- NEWS.md:106). Use `action_step_size_f = 1` for actions run once/year. |
| `g3a_naturalmortality` | multiplies `S__num` by `mortality_f` (R/action_naturalmortality.R:24-31). Params: `S.M.<age>` [run]. |
| `g3a_weightloss` | sets `S__wgt <- ((wgt - min_weight)*(1-rel_loss))+min_weight` and/or `dif_pmax(wgt - abs_loss, min_weight, 1e7)`; `apply_to_pop` restricts to a sub-population via `ratio_add_pop` (R/action_weightloss.R:20-53). `rel_loss`/`abs_loss` are formulas/params you supply (no defaults). |
| `g3a_migrate` / `g3a_migrate_normalize` | `migrate_f` is a formula in source `area` and `dest_area`; `normalize_f` (default squares entries, then sets stay-in-place proportion so row sums to `row_total`, then divides) (R/action_migrate.R:1-18). Builds `S__migratematrix` (dest_area x area). Run at order 2. |

### 1.3 Growth & maturity

```r
g3a_grow_lengthvbsimple <- function (
        linf_f = g3_parameterized('Linf', by_stock = by_stock),
        kappa_f = g3_parameterized('K', by_stock = by_stock),
        by_stock = TRUE)                                                         # R/action_grow.R:44-47
g3a_grow_weightsimple <- function (
        alpha_f = g3_parameterized('walpha', by_stock = by_stock),
        beta_f = g3_parameterized('wbeta', by_stock = by_stock),
        by_stock = TRUE)                                                         # R/action_grow.R:58-61
g3a_grow_length_multspec <- function(
        p0 = g3_parameterized('multispec.p0', value = 1, by_stock = by_stock),
        p1 = g3_parameterized('multispec.p1', value = 1, by_stock = by_stock),
        p2 = g3_parameterized('multispec.p2', value = 1, by_stock = by_stock),
        p3 = g3_parameterized('multispec.p3', value = 0, by_stock = by_stock),
        temperature = 0,
        by_stock = TRUE)                                                         # R/action_grow.R:73-79
g3a_grow_weight_multspec <- function(
        p4 = g3_parameterized('multispec.p4', value = 1, by_stock = by_stock),
        p5 = g3_parameterized('multispec.p5', value = 1, by_stock = by_stock),
        p6 = g3_parameterized('multispec.p6', value = 0, by_stock = by_stock),
        p7 = g3_parameterized('multispec.p7', value = 1, by_stock = by_stock),
        p8 = g3_parameterized('multispec.p8', value = 0, by_stock = by_stock),
        temperature = 0,
        by_stock = TRUE)                                                         # R/action_grow.R:83-90
g3a_grow_length_weightjones <- function(
        p0 = g3_parameterized('weightjones.p0', value = 0, by_stock = by_stock),
        p1 = g3_parameterized('weightjones.p1', value = 0, by_stock = by_stock),
        p2 = g3_parameterized('weightjones.p2', value = 1, by_stock = by_stock),
        p3 = g3_parameterized('weightjones.p3', value = 0, by_stock = by_stock),
        p4 = g3_parameterized('weightjones.p4', value = 1, by_stock = by_stock),
        p5 = g3_parameterized('weightjones.p5', value = 100, by_stock = by_stock),
        p6 = g3_parameterized('weightjones.p6', value = 1, by_stock = by_stock),
        p7 = g3_parameterized('weightjones.p7', value = 1, by_stock = by_stock),
        reference_weight = 0,
        temperature = 0,
        by_stock = TRUE)                                                         # R/action_grow.R:101-112
g3a_grow_weight_weightjones <- function(
        q0 = g3_parameterized('weightjones.q0', value = 1, by_stock = by_stock),
        q1 = g3_parameterized('weightjones.q1', value = 1, by_stock = by_stock),
        q2 = g3_parameterized('weightjones.q2', value = 1, by_stock = by_stock),
        q3 = g3_parameterized('weightjones.q3', value = 1, by_stock = by_stock),
        q4 = g3_parameterized('weightjones.q4', value = 1, by_stock = by_stock),
        q5 = g3_parameterized('weightjones.q5', value = 0, by_stock = by_stock),
        max_consumption = g3a_predate_maxconsumption(temperature = temperature),
        temperature = 0,
        by_stock = TRUE)                                                         # R/action_grow.R:122-131
g3a_grow_impl_bbinom <- function (
        delta_len_f = g3a_grow_lengthvbsimple(by_stock = by_stock),
        delta_wgt_f = g3a_grow_weightsimple(by_stock = by_stock),
        beta_f = g3_parameterized('bbin', by_stock = by_stock),
        maxlengthgroupgrowth,
        by_stock = TRUE)                                                         # R/action_grow.R:145-150
g3a_growmature <- function(stock,
                     impl_f,
                     maturity_f = ~0,
                     output_stocks = list(),
                     output_ratios = rep(1 / length(output_stocks), times = length(output_stocks)),
                     transition_f = ~cur_step_final,
                     run_f = ~TRUE,
                     run_at = g3_action_order$grow,
                     transition_at = g3_action_order$mature)                     # R/action_grow.R:344-352

g3a_mature_continuous <- function (
        alpha = g3_parameterized('mat.alpha', by_stock = by_stock),
        l50 = g3_parameterized('mat.l50', by_stock = by_stock),
        beta = 0,
        a50 = 0,
        bounded = TRUE,
        by_stock = TRUE)                                                         # R/action_mature.R:1-7
g3a_mature_constant <- function (alpha = NULL, l50 = NA, beta = NULL, a50 = NA, gamma = NULL, k50 = NA)  # R/action_mature.R:44
g3a_mature <- function(stock, maturity_f, output_stocks, output_ratios = rep(1 / length(output_stocks), times = length(output_stocks)), run_f =~TRUE, run_at = g3_action_order$grow, transition_at = g3_action_order$mature)  # R/action_mature.R:141
```

| fn | purpose / params created |
|---|---|
| `g3a_grow_lengthvbsimple` | Mean length increment per length group: `avoid_zero((linf_f - stock__midlen) * (1 - exp(-(kappa_f) * cur_step_size)))`. Params `S.Linf`, `S.K` [run: shown as `fish_mat.Linf`, `fish_mat.K`]. `avoid_zero` clamps negative growth to ~0 (comment R/action_grow.R:49-52, gadget3 issue #18). |
| `g3a_grow_weightsimple` | Weight increment matrix (length x delta): `alpha*((L_i+dL_j)^beta - L_i^beta)` built from `g3a_grow_vec_rotate/extrude`. Params `S.walpha`, `S.wbeta`. |
| `g3a_grow_length_multspec` / `g3a_grow_weight_multspec` | Multispecies growth (needs a `stock__feedinglevel` from `g3a_predate_catchability_predator`). Params `S.multispec.p0..p8`. |
| `g3a_grow_length_weightjones` / `_weight_weightjones` | Jones growth (gadget2 growthcalc.cc:311). Params `S.weightjones.p0..p7`, `q0..q5`; uses `g3a_predate_maxconsumption` params `P.consumption.m0..m3` of the *stock acting as predator*. Allows zero mean weight (NEWS 0.14 #228). |
| `g3a_grow_impl_bbinom` | Returns list(`delta_dim`=0..maxlengthgroupgrowth, `len`, `wgt`) implementing beta-binomial length-jump matrix. **`maxlengthgroupgrowth` has no default and is coerced to integer**; always pass `4L`-style (R/action_grow.R:151). Mean growth in length groups is `delta_len_f / stock__plusdl` -- assumes evenly sized groups (comment R/action_grow.R:219-220). Param `S.bbin` (wrapped in `avoid_zero`) [run]. |
| `g3a_growmature` | Combined growth + maturation. If `output_stocks` empty maturity code is discarded (R/action_grow.R:376-378). When `transition_f` TRUE for the step, growth is split into non-maturing (stays) and maturing portion by `maturity_f` (proportion per length) into `S__transitioning_num/wgt`, which are moved to `output_stocks` at `transition_at` (order 7) sub-step 90 (R/action_grow.R:380-386,463-500). `strict=TRUE` adds checks that total number is conserved. Growth matrices are cached when parameters depend only on `cur_step_size` (or also `cur_year`) (R/action_grow.R:396-414). |
| `g3a_mature_continuous` | Maturity-by-growth (gadget2 maturity.cc:301): `m0 %*% t(alpha*ldelta + beta*cur_step_size)` where `m0 = g3a_mature_constant(...)`; bounded to 0..1 by `dif_pminmax(.,0,1,1e5)` if `bounded`. Params `S.mat.alpha`, `S.mat.l50` (shown as `fish_imm.mat.alpha` in [run]). **Use with `g3a_growmature(maturity_f=...)` only** -- it needs `growth_delta_l`. |
| `g3a_mature_constant` | Logistic: `1/(1+exp(-alpha*(midlen-l50) - beta*(age-a50) - gamma*(wgt-k50)))`. `l50` required if `alpha`; `a50` if `beta`; `k50` if `gamma` (R/action_mature.R:44-74). Note: `alpha`,`beta`,`gamma` default NULL (term omitted), so `g3a_mature_constant()` alone is `1/(1+exp(0))=0.5` for all. |
| `g3a_mature` | Stand-alone maturation (no growth): moves `S__num*maturity_ratio` into transitioning arrays at `run_at` (default grow = 5, sub 1) and into `output_stocks` at `transition_at` (7, sub 2). `maturity_f` is any formula in `age`, `stock__midlen`, `stock_ss(stock__wgt)`; `output_ratios` must sum to 1 or be a list of formulas (R/action_mature.R:149-150). |

### 1.4 Renewal, initial conditions, other food, spawning, surplus production

```r
g3a_renewal_vonb_recl <- function(
        Linf = g3_parameterized('Linf', value = 1, by_stock = by_stock),
        K = g3_parameterized('K', value = 1, by_stock = by_stock),
        recl = g3_parameterized('recl', by_stock = by_stock),
        recage = g3_parameterized('recage', by_stock = FALSE, optimise = FALSE),
        by_stock = TRUE)                                                         # R/action_renewal.R:8-13
g3a_renewal_vonb_t0 <- function(
        Linf = g3_parameterized('Linf', value = 1, by_stock = by_stock),
        K = g3_parameterized('K', value = 1, by_stock = by_stock),
        t0 = g3_parameterized('t0', by_stock = by_stock),
        by_stock = TRUE)                                                         # R/action_renewal.R:22-26
g3a_renewal_vonb <- g3a_renewal_vonb_recl                                        # alias, R/action_renewal.R:34
g3a_renewal_initabund <- function(
    scalar = g3_parameterized('init.scalar', value = 1, by_stock = by_stock),
    init = g3_parameterized('init', value = 1, by_stock = by_stock, by_age = TRUE),
    M = g3_parameterized('M', by_stock = by_stock, by_age = TRUE),
    init_F = g3_parameterized('init.F', by_stock = by_stock_f),
    recage = g3_parameterized('recage', by_stock = FALSE, optimise = FALSE),
    proportion_f = ~1,
    by_stock = TRUE,
    by_stock_f = FALSE)                                                          # R/action_renewal.R:36-44
g3a_initialconditions_normalparam <- function (
        stock,
        factor_f = g3a_renewal_initabund(by_stock = by_stock),
        mean_f = g3a_renewal_vonb_t0(by_stock = by_stock),
        stddev_f = g3_parameterized('init.sd', value = 10,
            by_stock = by_stock, by_age = by_age),
        alpha_f = g3_parameterized('walpha', by_stock = wgt_by_stock),
        beta_f = g3_parameterized('wbeta', by_stock = wgt_by_stock),
        age_offset = quote( cur_step_size ),
        by_stock = TRUE,
        by_age = FALSE,
        wgt_by_stock = TRUE,
        run_f = ~cur_time == 0L,
        run_at = g3_action_order$initial)                                        # R/action_renewal.R:104-117
g3a_initialconditions_normalcv <- function (
        stock,
        factor_f = g3a_renewal_initabund(by_stock = by_stock),
        mean_f = g3a_renewal_vonb_t0(by_stock = by_stock),
        cv_f = g3_parameterized('lencv', by_stock = by_stock, value = 0.1,
            optimise = FALSE),
        alpha_f = g3_parameterized('walpha', by_stock = wgt_by_stock),
        beta_f = g3_parameterized('wbeta', by_stock = wgt_by_stock),
        age_offset = quote( cur_step_size ),
        by_stock = TRUE,
        by_age = FALSE,
        wgt_by_stock = TRUE,
        run_f = ~cur_time == 0L,
        run_at = g3_action_order$initial)                                        # R/action_renewal.R:139-152
g3a_renewal_normalparam <- function (
        stock,
        factor_f = g3_parameterized('rec',
            by_stock = by_stock,
            by_year = TRUE,
            scale = g3_parameterized(
                name = 'rec.scalar',
                by_stock = by_stock),
            ifmissing = g3_parameterized(
                name = 'rec.proj',
                optimise = FALSE,
                by_stock = by_stock )),
        mean_f = g3a_renewal_vonb_t0(by_stock = by_stock),
        stddev_f = g3_parameterized('rec.sd', value = 10, by_stock = by_stock),
        alpha_f = g3_parameterized('walpha', by_stock = wgt_by_stock),
        beta_f = g3_parameterized('wbeta', by_stock = wgt_by_stock),
        by_stock = TRUE,
        wgt_by_stock = TRUE,
        run_age = quote(stock__minage),
        run_projection = TRUE,
        run_step = 1,
        run_f = NULL,
        run_at = g3_action_order$renewal)                                        # R/action_renewal.R:191-213
g3a_renewal_normalcv <- function (
        stock,
        factor_f = <same default as normalparam>,
        mean_f = g3a_renewal_vonb_t0(by_stock = by_stock),
        cv_f = g3_parameterized('lencv', by_stock = by_stock, value = 0.1,
            optimise = FALSE),
        alpha_f = g3_parameterized('walpha', by_stock = wgt_by_stock),
        beta_f = g3_parameterized('wbeta', by_stock = wgt_by_stock),
        by_stock = TRUE,
        wgt_by_stock = TRUE,
        run_age = quote(stock__minage),
        run_projection = TRUE,
        run_step = 1,
        run_f = NULL,
        run_at = g3_action_order$renewal)                                        # R/action_renewal.R:234-257
g3a_otherfood <- function (
        stock,
        num_f = g3_parameterized('of_abund', by_year = TRUE, by_stock = by_stock,
            scale = g3_parameterized(
                'of_abund.step', value = 1, by_step = TRUE, by_stock = by_stock),
            ifmissing = "of_abund.proj" ),
        wgt_f = g3_parameterized('of_meanwgt', by_stock = by_stock),
        by_stock = TRUE,
        force_lengthvector = !any(grepl("__midlen$", all.vars(num_f))),
        run_f = quote( cur_time <= total_steps ),
        run_at = g3_action_order$initial)                                        # R/action_renewal.R:276-286
g3a_otherfood_normalparam <- function (stock, factor_f = g3_parameterized('of_abund', by_year = TRUE, by_stock = by_stock, scale = g3_parameterized('of_abund.step', value = 1, by_step = TRUE, by_stock = by_stock), ifmissing = "of_abund.proj" ), mean_f = g3a_renewal_vonb_t0(by_stock = by_stock), stddev_f = g3_parameterized('init.sd', value = 10, by_stock = by_stock, by_age = by_age), alpha_f = g3_parameterized('walpha', by_stock = wgt_by_stock), beta_f = g3_parameterized('wbeta', by_stock = wgt_by_stock), by_stock = TRUE, by_age = FALSE, wgt_by_stock = TRUE, run_f = quote( cur_time <= total_steps ), run_at = g3_action_order$initial)   # R/action_renewal.R:311-327
g3a_otherfood_normalcv <- function (stock, factor_f = <as above>, mean_f = g3a_renewal_vonb_t0(by_stock = by_stock), cv_f = g3_parameterized('lencv', by_stock = by_stock, value = 0.1, optimise = FALSE), alpha_f = ..., beta_f = ..., by_stock = TRUE, by_age = FALSE, wgt_by_stock = TRUE, run_f = quote( cur_time <= total_steps ), run_at = g3_action_order$initial)   # R/action_renewal.R:342-358

g3a_spawn <- function(
        stock,
        recruitment_f,
        proportion_f = 1,
        mortality_f = 0,
        weightloss_f = 0,
        weightloss_args = list(),
        output_stocks = list(),
        output_ratios = rep(1 / length(output_stocks), times = length(output_stocks)),
        mean_f = g3a_renewal_vonb_t0(by_stock = by_stock),
        stddev_f = g3_parameterized('rec.sd', value = 10, by_stock = by_stock),
        alpha_f = g3_parameterized('walpha', by_stock = wgt_by_stock),
        beta_f = g3_parameterized('wbeta', by_stock = wgt_by_stock),
        by_stock = TRUE,
        wgt_by_stock = TRUE,
        run_step = NULL,
        run_f = ~TRUE,
        run_at = g3_action_order$spawn,
        recruit_at = g3_action_order$renewal)                                    # R/action_spawn.R:86-104
g3a_spawn_recruitment_fecundity <- function (p0 = g3_parameterized('spawn.p0', value = 1, by_stock = by_stock), p1 = ...'spawn.p1' value 1, p2 = 'spawn.p2' value 1, p3 = 'spawn.p3' value 1, p4 = 'spawn.p4' value 1, by_stock = TRUE)   # R/action_spawn.R:1-7
g3a_spawn_recruitment_simplessb <- function (mu = g3_parameterized('spawn.mu', by_stock = by_stock), by_stock = TRUE)   # :19
g3a_spawn_recruitment_ricker <- function (mu = g3_parameterized('spawn.mu', by_stock = by_stock), lambda = g3_parameterized('spawn.lambda', by_stock = by_stock), by_stock = TRUE)   # :31
g3a_spawn_recruitment_bevertonholt <- function (mu = g3_parameterized('spawn.mu', by_stock = by_stock), lambda = g3_parameterized('spawn.lambda', by_stock = by_stock), by_stock = TRUE)   # :43
g3a_spawn_recruitment_bevertonholt_ss3 <- function (
        h = g3_parameterized('spawn.h', lower = 0.1, upper = 1, value = 0.5, by_stock = by_stock ),
        R = g3_parameterized('spawn.R', by_year = TRUE, exponentiate = TRUE, scale = "spawn.R0", by_stock = by_stock),
        B0 = g3_parameterized('spawn.B0', by_stock = by_stock),
        by_stock = TRUE )                                                        # R/action_spawn.R:56-67
g3a_spawn_recruitment_hockeystick <- function (r0 = g3_parameterized('spawn.r0', by_stock = by_stock), blim = g3_parameterized('spawn.blim', value = 1, by_stock = by_stock), by_stock = TRUE)   # :73

g3a_spmodel_logistic <- function(
        r = g3_parameterized("spm_r", lower = 0.01, upper = 1, value = 0.5, by_stock = by_stock),
        p = g3_parameterized("spm_p", lower = 0.01, upper = 10, value = 1, by_stock = by_stock),
        K = g3_parameterized("spm_K", lower = 100, upper = 1e6, value = 1000, by_stock = by_stock),
        by_stock = TRUE)                                                         # R/action_spmodel.R:1-8
g3a_spmodel <- function (
        stock,
        spm_num = g3a_spmodel_logistic(),
        spm_num_init = g3_parameterized("spm_n0", by_stock = TRUE),
        spm_wgt = 1,
        run_f = TRUE,
        run_at = g3_action_order$initial)                                        # R/action_spmodel.R:14-20
```

| fn | purpose / params created |
|---|---|
| `g3a_renewal_vonb_t0` | mean length formula `Linf*(1-exp(-1*K*(age - t0)))`. Params `S.Linf` (value 1), `S.K` (value 1), `S.t0` [run]. **Default `mean_f` for all `*_normalparam`/`*_normalcv`** (NEWS.md:126). |
| `g3a_renewal_vonb_recl` (= `g3a_renewal_vonb`) | `Linf*(1-exp(-1*K*(age-(recage+log(1-recl/Linf)/K))))`. Params `S.Linf`, `S.K`, `S.recl`, `recage` (unprefixed, optimise=FALSE). |
| `g3a_renewal_initabund` | `scalar * init * exp(-1*(M+init_F)*(age-recage)) * proportion_f`. Params `S.init.scalar` (1), `S.init.<age>` (1), `S.M.<age>`, `init.F` (**unprefixed** unless `by_stock_f` set), `recage` (**unprefixed**, optimise FALSE) [run]. |
| `g3a_initialconditions_normalparam` | At `cur_time==0` set `num = 10000 * factor * normalize(dnorm(midlen, mean, sd))`, `wgt = walpha*midlen^wbeta` for every age/area. **`age` in `mean_f`/`stddev_f` is replaced with `age - cur_step_size`** (`age_offset`) i.e. pretends it runs at time -1 (R/action_renewal.R:120-124; NEWS 0.10). Params: `S.init.sd` (value 10; `S.init.sd.<age>` when `by_age=TRUE`), plus whatever `factor_f`/`mean_f` bring: `S.init.scalar`, `S.init.<age>`, `S.M.<age>`, `init.F`, `recage`, `S.Linf/K/t0`, `S.walpha/wbeta` [run]. |
| `g3a_initialconditions_normalcv` | same with `stddev = mean_f * cv_f`; param `S.lencv` (value 0.1, optimise FALSE) [run]. |
| `g3a_renewal_normalparam` | recruits at `age == run_age` (default stock minage), `cur_step == run_step` (default 1; NULL = every step), and not in projection if `run_projection=FALSE`. Default `run_f = age && step && proj` (R/action_renewal.R:215-219). Recruit number `= rec.<year> * rec.scalar * 10000 * normalised dnorm`. Params [run]: `S.rec.<year>` (one per model year), `S.rec.scalar`, `S.rec.proj` (optimise=FALSE; used when year missing, i.e. in projections), `S.rec.sd` (10), `S.Linf/K/t0`, `S.walpha/wbeta`. Stock array `S__renewalnum` / `S__renewalwgt` hold the last recruits (not reset on non-renewal steps -- [run]). |
| `g3a_renewal_normalcv` | `stddev = mean_f*cv_f`, param `S.lencv` (NB shared name with initialconditions_normalcv, so one `lencv` for both). |
| `g3a_otherfood`, `_normalparam`, `_normalcv` | non-dynamic prey: **replaces** `num`/`wgt` every step at order -1 (initial) for use as prey by predators. Params: `S.of_abund.<year>`, `S.of_abund.step.<step>` (scale, value 1), `S.of_abund.proj` (ifmissing, by_stock), `S.of_meanwgt`; the normal* variants use `walpha/wbeta`, `init.sd` etc. Note `num_f` is padded with `+0*stock__midlen` if it does not mention midlen (force_lengthvector, R/action_renewal.R:290-293). |
| `g3a_spawn` | Two steps: at `run_at`(6) compute `S__spawnprop`, `S__spawningnum = num*spawnprop`, total spawn stat `s` (sum over cells of `recruitment_f$s`), offspring `r = recruitment_f$r`, apply `mortality_f` (via `g3a_naturalmortality_exp(mortality_f, action_step_size_f=1)`) and optional `g3a_weightloss` (from `weightloss_args`; deprecated `weightloss_f` -> `rel_loss`, `min_weight=0`); then at `recruit_at`(8) distributes `r` into `output_stocks` (age == minage only; normal-by-midlen with `mean_f, stddev_f`; weight `alpha*L^beta`) times `output_ratios`. `recruitment_f` must be `list(s=, r=)` exactly. Params from recruitment_f plus `S_out.rec.sd`, `walpha`, `wbeta`, `Linf,K,t0` of **output** stock (shown in [run]: `fish_imm.rec.sd`, `fish_imm.Linf` ...). `proportion_f` is evaluated with the stock iterators (age, length...) and `predstock`->'spawn'. |
| `g3a_spawn_recruitment_*` | return `list(s, r)`: `fecundity` (`s = sum(midlen^p1 * age^p2 * spawningnum^p3 * wgt^p4)`, `r = p0*s`; params `S.spawn.p0..p4`), `simplessb` (`r = mu*s`; `S.spawn.mu`), `ricker` (`mu*s*exp(-lambda*s)`; `S.spawn.mu`, `S.spawn.lambda`), `bevertonholt` (`mu*s/(lambda+s)`), `bevertonholt_ss3` (`4*h*s*R/(B0*(1-h)+s*(5h-1))`; params `S.spawn.h` [0.1,1]=0.5, `S.spawn.R.<year>_exp`, `S.spawn.R0`, `S.spawn.B0` [run]), `hockeystick` (`r0*logspace_add(-1000*s/blim,-1000)/-1000`, differentiable min; `S.spawn.r0`, `S.spawn.blim`). `s` = sum(wgt*spawningnum) (SSB) for all except fecundity. |
| `g3a_spmodel`, `g3a_spmodel_logistic` | Surplus-production model on a stock treated as a single biomass pool (stock gets `num = pool`, `wgt = spm_wgt`). Step: `cur_time == 0` -> `num = spm_n0`; else `num += spm_num` where `spm_num = r*s*(1-(s/K)^p)`, `s=sum(num)`. Params `S.spm_r` [0.01,1]=0.5, `S.spm_p` [0.01,10]=1, `S.spm_K` [100,1e6]=1000, `S.spm_n0` (R/action_spmodel.R). Runs at order -1. |

### 1.5 Predation (fleets & predators), catchability, suitability

```r
g3a_predate <- function (
        predstock,
        prey_stocks,
        suitabilities,
        catchability_f,
        overconsumption_f = quote( dif_pmin(stock__consratio, 0.95, 1e3) ),
        run_f = ~TRUE,
        run_at = g3_action_order$predate )                                       # R/action_predate.R:240-247
g3a_predate_fleet <- function (fleet_stock, prey_stocks, suitabilities, catchability_f, overconsumption_f = quote( dif_pmin(stock__consratio, 0.95, 1e3) ), run_f = ~TRUE, run_at = g3_action_order$predate)   # :423
g3a_predate_totalfleet <- function (fleet_stock, prey_stocks, suitabilities, amount_f, overconsumption_f = quote( dif_pmin(stock__consratio, 0.95, 1e3) ), run_f = ~TRUE, run_at = g3_action_order$predate)   # :479

g3a_predate_catchability_totalfleet <- function (E)                              # :1
g3a_predate_catchability_numberfleet <- function (E)                             # :7
g3a_predate_catchability_linearfleet <- function (E)                             # :13
g3a_predate_catchability_project <- function (
    quota_f = NULL,
    landings_f = NULL,
    interim_f = g3_parameterized("quota.interim", value = 0,
        by_predator = TRUE, by_step = TRUE),
    quota_prop = g3_parameterized("quota.prop", by_predator = TRUE, value = 1),
    cons_step = g3_parameterized("cons.step", by_predator = TRUE, by_step = TRUE,
        value = quote( step_lengths / 12.0 )),
    interim_unit = unit,
    unit = c("biomass", "biomass-year", "harvest-rate", "harvest-rate-year",
             "individuals", "individuals-year") )                                # :20-32
g3a_predate_catchability_effortfleet <- function (catchability_fs, E)            # :117
g3a_predate_catchability_quotafleet <- function (quota_table, E, sum_stocks = list(), recalc_f = NULL)   # :128
g3a_predate_maxconsumption <- function (
        m0 = g3_parameterized('consumption.m0', value = 1, by_predator = TRUE, optimise = FALSE),
        m1 = g3_parameterized('consumption.m1', value = 0, by_predator = TRUE, optimise = FALSE),
        m2 = g3_parameterized('consumption.m2', value = 0, by_predator = TRUE, optimise = FALSE),
        m3 = g3_parameterized('consumption.m3', value = 0, by_predator = TRUE, optimise = FALSE),
        temperature = 0 )                                                        # :190-199
g3a_predate_catchability_predator <- function (
        prey_preferences = 1,
        energycontent = g3_parameterized('energycontent', value = 1, by_stock = by_stock, optimise = FALSE),
        half_feeding_f = g3_parameterized('halffeeding', by_predator = by_predator, optimise = FALSE),
        max_consumption = g3a_predate_maxconsumption(temperature = temperature),
        temperature = 0,
        by_predator = TRUE,
        by_stock = TRUE )                                                        # :207-216

g3a_predate_tagrelease <- function (fleet_stock, prey_stocks, suitabilities, catchability_f, output_tag_f, mortality_f = 0, run_f = ~TRUE, run_at = g3_action_order$predate, ...)   # R/action_tagging.R:1
g3a_tag_shedding <- function (stocks, tagshed_f, run_f = ~TRUE, run_at = g3_action_order$straying)   # :57

g3_suitability_exponentiall50 <- function (alpha = g3_parameterized("alpha", by_stock = by_stock, by_predator = by_predator), l50 = g3_parameterized("l50", by_stock = by_stock, by_predator = by_predator), by_stock = TRUE, by_predator = TRUE)   # R/suitability.R:5
g3_suitability_andersen <- function (p0, p1, p2, p3 = p4, p4, p5 = quote(predator_length))   # :15
g3_suitability_andersenfleet <- function (
        p0 = g3_parameterized('andersen.p0', value = 0, optimise = FALSE, by_stock = by_stock),
        p1 = g3_parameterized('andersen.p1', value = log(2), by_stock = by_stock, by_predator = by_predator),
        p2 = g3_parameterized('andersen.p2', value = 1, optimise = FALSE, by_stock = by_stock),
        p3 = g3_parameterized('andersen.p3', value = 0.1, exponentiate = exponentiate, by_stock = by_stock, by_predator = by_predator),
        p4 = g3_parameterized('andersen.p4', value = 0.1, exponentiate = exponentiate, by_stock = by_stock, by_predator = by_predator),
        p5 = quote( stock__maxmidlen ),
        by_stock = TRUE,
        by_predator = TRUE,
        exponentiate = TRUE)                                                     # :32-46
g3_suitability_gamma <- function(alpha, beta, gamma)                             # :60
g3_suitability_exponential <- function (alpha, beta, gamma, delta)               # :69
g3_suitability_straightline <- function(alpha, beta)                             # :77
g3_suitability_constant <- function(suit = g3_parameterized("suit", by_stock = by_stock, by_predator = by_predator), by_stock = TRUE, by_predator = TRUE )   # :82
g3_suitability_richards <- function(p0,p1,p2,p3,p4)                              # :90
```

| fn | purpose / params created |
|---|---|
| `g3a_predate(predstock, prey_stocks, suitabilities, catchability_f, ...)` | General predator/fleet-eats-prey action (fleets are just predators). `predstock` may be a list (run for each). `prey_stocks` **must be a list**. `suitabilities`: formula (always used) or **named list by prey stock name** (+ optional unnamed default) (`resolve_stock_list`, R/step.R:597-612; `list_to_stock_switch` R/step.R:565). `catchability_f`: list(suit_unit, suit, cons[, feeding_level]) from `g3a_predate_catchability_*`; a bare formula is treated as back-compat total-biomass cons (R/action_predate.R:266-270). Sub-steps (order 3): `000:000` zero prey totalpredate; `000:001` zero predstock totalsuit; `001` collect suitable prey into `S_P__suit`; `002` scale to desired consumption `S_P__cons`; `004` overconsumption (cap `consratio` at 0.95 via `dif_pmin`, update `S__num <- num*(1-consratio)`, store `S__overconsumption`); `005` rescale `S_P__cons` by `consconv` (NB man/action_predate.Rd writes `(predstock)_(prey_stock)__cons`, but the actual names are prey first: `fish_f_surv__cons` [run]); `099` (fleet wrapper) `S__predby_P` for back-compat. |
| `g3a_predate_fleet`, `g3a_predate_totalfleet` | Older interface wrappers; `_totalfleet(..., amount_f)` = `_fleet(..., catchability_f = g3a_predate_catchability_totalfleet(amount_f))`. man says `g3a_predate_fleet` is "deprecated" but still the vignette idiom. Same behaviour; adds `S__predby_P` array. |
| `g3a_predate_catchability_totalfleet(E)` | Desired catch by **biomass** (e.g. landings): `C = E * F / sum(F)` with `F = suit * N * W`. `E` generally `g3_timeareadata("landings", df, "weight", areas=area_names)`. Implemented as `_project(landings_f=E, unit="biomass")`. |
| `..._numberfleet(E)` | same with E in **individuals** (`unit="individuals"`). |
| `..._linearfleet(E)` | `C = E * dt * F` (harvest-rate): `_project(landings_f=E, cons_step=cur_step_size, unit="harvest-rate-year")`. |
| `..._effortfleet(catchability_fs, E)` | `C = c_s * E * cur_step_size * suit` with per-stock catchability (`catchability_fs` = formula or named list). |
| `..._quotafleet(quota_table, E, sum_stocks, recalc_f)` | `C = q * E * cur_step_size * suit` with q chosen from `quota_table` (data.frame with columns exactly `biomass`,`quota`; last biomass must be `Inf`; `quota` a list-column of formulas) by total biomass of `sum_stocks`; `recalc_f` formula (e.g. `~cur_step == 1`) caches the quota. |
| `..._project(quota_f, landings_f, interim_f, quota_prop, cons_step, interim_unit, unit)` | Projection-aware: historical period uses `landings_f` (in `unit`), projection years (`cur_year_projection`) use `quota_f` (from `g3_quota`), with `interim_f` used when quota is NaN (gap between landings and first quota). Params [run]: `P.quota.prop` (1), `P.quota.interim.<step>` (0), `P.cons.step.<step>` (default value = `step_lengths/12`). `unit` one of biomass, biomass-year, harvest-rate, harvest-rate-year, individuals, individuals-year; `-year` units multiply by `cons_step` (share of year quota to this step). **Quirk:** the `interim_unit` argument is overwritten by `match.arg(unit)` at R/action_predate.R:39 so it has no effect. A quota in biomass with landings in individuals (or vice versa) -> error. |
| `g3a_predate_catchability_predator(...)` | Multispecies predator (gadget2 stockpredator.cc:144): `suit_unit = "energy content"`; feeding level `psi = total_predsuit/(half_feeding*dt + total_predsuit)`; cons `= N_pred * maxcons * psi * suit / (energycontent * total_predsuit)`. Params [run]: `S.energycontent` (1, optimise FALSE), `P.halffeeding` (optimise=FALSE, **no default value -> 0**), `P.consumption.m0..m3`. |
| `g3a_predate_maxconsumption` | `m0 * cur_step_size * exp(m1*T - m2*T^3) * predator_length^m3`; params `P.consumption.m0 (1) /m1 /m2 /m3 (0)`. |
| `g3a_predate_tagrelease`, `g3a_tag_shedding` | Tag-release harvest: does a regular predate then releases a proportion (`1-mortality_f`) of the caught numbers back into the stock's `tag` dimension at the tag chosen by `output_tag_f` (numeric or formula, typically `g3_timeareadata(..., value_field="tag")` with `tag` ids). Fleet must have no multi-area (`Don't support multi-area fleets`). `g3a_tag_shedding(stocks, tagshed_f)`: moves `num*exp(-tagshed_f)` back to untagged at order 9 (straying). |
| `g3_suitability_exponentiall50` | `1/(1+exp(-alpha*(stock__midlen - l50)))`. Params `S.P.alpha`, `S.P.l50` (stock first, then predator: `fish_imm.comm_is.l50`) [run]. Pass `by_stock='species'` for a shared parameter across immature/mature (`fish.comm_is.l50`) -- vignettes/multiple-substocks.Rmd:278-328. |
| `g3_suitability_andersen(p0,p1,p2,p3=p4,p4,p5=predator_length)` | gadget2 Andersen: low-level; supply formulas. |
| `g3_suitability_andersenfleet()` | fleet-specialised Andersen; p5 = `stock__maxmidlen`. Params [run]: `S.andersen.p0`(0,fixed), `S.andersen.p2`(1,fixed), `S.P.andersen.p1` (log 2), `S.P.andersen.p3_exp`, `S.P.andersen.p4_exp` (exponentiated, value 0.1 -- `_exp` suffix means optimiser works on log scale: `g3_init_val` auto-logs). `by_predator = TRUE` default since 0.11 (NEWS.md:106). |
| `g3_suitability_gamma(alpha,beta,gamma)` | gadget2 gamma. |
| `g3_suitability_exponential(alpha,beta,gamma,delta)` | `delta/(1+exp(-alpha - beta*midlen - gamma*predator_length))`. |
| `g3_suitability_straightline(alpha,beta)` | `alpha + beta*midlen`. |
| `g3_suitability_constant(suit=...)` | constant suitability; param `S.P.suit`. |
| `g3_suitability_richards(p0..p4)` | `exponential(p0..p3)^(1/p4)`. |

Suitability reports: `g3a_predate` auto-adds `g3a_suitability_report` (R/suitability.R:97-152) that REPORTs `suit_<S>_<P>__report` (dims only those the suitability uses; refreshed once, per year or per step depending on whether it mentions `cur_year`/`cur_step`) at order 0 (report_early).

### 1.6 Likelihood (`g3l_*`, `g3_distribution_preview`) -- details in section 4

```r
g3l_catchdistribution <- g3l_distribution                                        # R/likelihood_distribution.R:439
g3l_abundancedistribution <- g3l_distribution                                    # :440
# g3l_distribution (not exported; both exports are aliases of it), R/likelihood_distribution.R:177-191:
function (
        nll_name,
        obs_data,
        fleets = list(),
        stocks,
        function_f,
        predators = list(),
        transform_fs = list(),
        missing_val = 0,
        area_group = NULL,
        report = FALSE,
        nll_breakdown = FALSE,
        weight = g3_parameterized(paste0(nll_name, "_weight"),
            optimise = FALSE, value = 1),
        run_at = g3_action_order$likelihood)
g3l_distribution_sumofsquares <- function (over = c('area', 'predator', 'predator_tag', 'predator_age', 'predator_length'))   # :28-29
g3l_distribution_multinomial <- function (epsilon = 10)                          # :41
g3l_distribution_multivariate <- function (rho_f, sigma_f, over = c('area'))     # :62
g3l_distribution_surveyindices_log <- function (alpha = NULL, beta = 1)          # :124
g3l_distribution_surveyindices_linear <- function (alpha = NULL, beta = 1)       # :125
g3l_distribution_sumofsquaredlogratios <- function (epsilon = 10)                # :128
g3_distribution_preview <- function (
        obs_data,
        predators = list(),
        fleets = list(),
        stocks = list(),
        area_group = NULL)                                                       # :138-143
g3l_understocking <- function (
        prey_stocks,
        power_f = ~2,
        nll_breakdown = FALSE,
        weight = 1e+08,
        run_at = g3_action_order$likelihood)                                     # R/likelihood_understocking.R:1-6
g3l_bounds_penalty <- function(
        actions_or_parameter_template,
        weight = 1,
        scale = 1e6,
        run_at = g3_action_order$likelihood)                                     # R/likelihood_bounds.R:30-34
g3l_random_dnorm <- function (
        nll_name,
        param_f,
        mean_f = 0,
        sigma_f = 1,
        log_f = TRUE,
        period = 'auto',
        nll_breakdown = FALSE,
        weight = g3_parameterized(paste0(nll_name, "_weight"),
            optimise = FALSE, value = 1),
        run_at = g3_action_order$likelihood)                                     # R/likelihood_random.R:14-24
g3l_random_walk <- function (
        nll_name,
        param_f,
        sigma_f = 1,
        log_f = TRUE,
        period = 'auto',
        nll_breakdown = FALSE,
        weight = g3_parameterized(paste0(nll_name, "_weight"),
            optimise = FALSE, value = 1),
        run_at = g3_action_order$likelihood)                                     # :62-71
g3l_sparsesample <- function (
        nll_name,
        obs_df,
        stocks,
        measurement_f = quote( wgt ),
        function_f = g3l_sparsesample_linreg(),
        predstocks = list(),
        area_group = NULL,
        weight = g3_parameterized(paste(
            if (length(predstocks) > 0) "csparse" else "asparse",
            function_f_name,
            nll_name,
            "weight",
            sep = "_"), optimise = FALSE, value = 1),
        run_at = g3_action_order$likelihood )                                    # R/likelihood_sparsesample.R:134-148
g3l_sparsesample_linreg <- function (fit = c('log', 'linear'), slope = 1, intercept = NULL )   # :79-82
g3l_sparsesample_sumsquares <- function (weighting = "model_stddev" )            # :100-101
g3l_ckmr_po <- function (
        nll_name,
        obs_data,
        parent_stocks,
        offspring_stocks,
        weight = g3_parameterized(paste0(nll_name, "_weight"),
            optimise = FALSE, value = 1),
        run_at = g3_action_order$likelihood)                                     # R/likelihood_ckmr_po.R:1-8
```

### 1.7 Parameters & projection (`g3_parameterized`, `g3_param_project*`, `g3_quota*`, `g3_timevariable`, `g3_timeareadata`, `g3_init_val`)

```r
g3_parameterized <- function(
        name,
        by_stock = FALSE,
        by_predator = FALSE,
        by_year = FALSE,
        by_step = FALSE,
        by_age = FALSE,
        by_area = FALSE,
        prepend_extra = list(),
        exponentiate = FALSE,
        avoid_zero = FALSE,
        scale = 1,
        offset = 0,
        ifmissing = NULL,
        ...)                                                                     # R/params.R:43-57
g3_init_val <- function (
        param_template,
        name_spec,
        value = NULL,
        spread = NULL,
        lower = if (!is.null(spread)) min(value * (1-spread), value * (1+spread)),
        upper = if (!is.null(spread)) max(value * (1-spread), value * (1+spread)),
        optimise = !is.null(lower) & !is.null(upper),
        parscale = if (is.null(lower) || is.null(upper)) NULL else 'auto',
        random = NULL,
        auto_exponentiate = TRUE)                                                # R/init_val.R:1-11
g3_timevariable <- function (lookup_name, fs)                                    # R/timevariable.R:1
g3_timeareadata <- function(lookup_name, df, value_field = 'total_weight', areas = NULL)   # R/timedata.R:89

g3_param_project <- function (
        param_name,
        project_fs = g3_param_project_rwalk(),
        by_step = TRUE,
        by_stock = FALSE,
        weight = g3_parameterized(
            paste("proj", project_fs$name, param_name, "weight", sep = "_"),
            optimise = FALSE, value = 1),
        scale = 1,
        offset = 0,
        random = TRUE )                                                          # R/param_project.R:440-450
g3_param_project_dnorm <- function (mean_f = g3_parameterized("proj.dnorm.mean", value = 0, optimise = FALSE, prepend_extra = quote(param_name) ), stddev_f = g3_parameterized("proj.dnorm.stddev", value = 1, optimise = FALSE, prepend_extra = quote(param_name) ), from_year_f = NULL, to_year_f = NULL )   # :97
g3_param_project_dlnorm <- function (lmean_f = g3_parameterized("proj.dlnorm.mean", value = 1e-5, optimise = FALSE, type = "LOG", prepend_extra = quote(param_name) ), lstddev_f = g3_parameterized("proj.dlnorm.stddev", value = 0.2, optimise = FALSE, type = "LOG", prepend_extra = quote(param_name) ), from_year_f = NULL, to_year_f = NULL )   # :48
g3_param_project_rwalk <- function (mean_f = g3_parameterized("proj.rwalk.mean", value = 0, optimise = FALSE, prepend_extra = quote(param_name) ), stddev_f = g3_parameterized("proj.rwalk.stddev", value = 1, optimise = FALSE, prepend_extra = quote(param_name) ))   # :142
g3_param_project_ar1 <- function (phi_f = g3_parameterized("proj.ar1.phi", value = 0.8, lower = 0, upper = 1, optimise = FALSE, prepend_extra = quote(param_name) ), stddev_f = g3_parameterized("proj.ar1.stddev", value = 1, optimise = FALSE, prepend_extra = quote(param_name) ), level_f = g3_parameterized("proj.ar1.level", value = 0, prepend_extra = quote(param_name) ), from_year_f = NULL, to_year_f = NULL )   # :185
g3_param_project_logar1 <- function (phi_f = g3_parameterized("proj.logar1.phi", value = 0.8, lower = 0, upper = 1, optimise = FALSE, prepend_extra = quote(param_name) ), lstddev_f = g3_parameterized("proj.logar1.stddev", value = 0.2, optimise = FALSE, type = "LOG", prepend_extra = quote(param_name) ), loglevel_f = g3_parameterized("proj.logar1.level", value = 1, type = "LOG", prepend_extra = quote(param_name) ), from_year_f = NULL, to_year_f = NULL )   # :274
g3_param_project_bootstrap <- function (from_year_f = quote(start_year), to_year_f = quote(end_year), block_size_f = 1L )   # :361

g3_quota_hockeystick <- function (
        predstocks,  # Predator / fleet stocks forming a name for quota
        preystocks,  # Mature spawning-stocks
        preyprop_fs = 1,  # NB: Doesn't have to sum to 1
        trigger = g3_parameterized("hs.trigger", by_stock = predstocks),
        target = g3_parameterized("hs.target", by_stock = predstocks),
        stddev = g3_parameterized("hs.stddev", by_stock = predstocks, value = 0),
        unit = c("harvest-rate-year", "biomass-year", "individuals-year") )      # R/quota.R:1-8
g3_quota_hockeyfleet <- function (predstocks, preystocks, preyprop_fs = 1, btrigger = g3_parameterized("hf.btrigger", by_stock = predstocks), harvest_rate = g3_parameterized("hf.harvest_rate", by_stock = predstocks), stddev = g3_parameterized("hf.stddev", by_stock = predstocks, value = 0) )   # :68-74
g3_quota_assess <- function (predstocks, preystocks, assess_f, unit = c("biomass-year", "biomass", "harvest-rate", "harvest-rate-year", "individuals", "individuals-year") )   # :87-92
g3_quota <- function (
        function_f,
        quota_name = attr(function_f, 'quota_name'),
        init_val = NaN,
        year_length = 1L,
        start_step = 1L,
        run_revstep = -1,
        run_historical = FALSE,
        run_f = TRUE,
        run_at = g3_action_order$quota )                                         # :121-130
```

### 1.8 Compilation / running / reporting / debugging / utilities

```r
g3_to_r <- function(
        actions,
        work_dir = getOption('gadget3.r.work_dir', default = tempdir()),
        trace = FALSE,
        strict = FALSE,
        cmp_options = list(optimize = 3) )                                       # R/run_r.R:5-10
g3_to_tmb <- function(actions, trace = FALSE, strict = FALSE)                    # R/run_tmb.R:709
g3_tmb_adfun <- function(
        cpp_code,
        parameters = attr(cpp_code, 'parameter_template'),
        compile_flags = getOption('gadget3.tmb.compile_flags', default =
            if (.Platform$OS.type == "windows") c("-O1", "-march=native")
            else c("-O3", "-flto=auto", "-march=native") ),
        work_dir = getOption('gadget3.tmb.work_dir', default = tempdir()),
        output_script = FALSE,
        compile_args = list(
            framework = getOption("gadget3.tmb.framework", default = "TMBad") ),
        ...)                                                                     # R/run_tmb.R:1118-1128
g3_tmb_fn <- function (cpp_code, def.parameters = attr(cpp_code, 'parameter_template'), ... )   # :1329-1332
g3_tmb_par <- function (parameters, include_random = TRUE)                       # :1401
g3_tmb_lower <- function (parameters) ; g3_tmb_upper <- function (parameters) ; g3_tmb_parscale <- function (parameters)   # :1412-1414
g3_tmb_relist <- function (parameters, par)                                      # :1416
g3_to_desc <- function(actions, minor_steps = FALSE)                             # R/run_desc.R:2
g3_action_order <- list(initial = -1L, report_early = 0L, time = 1L, migrate = 2L, predate = 3L, naturalmortality = 4L, grow = 5L, spawn = 6L, mature = 7L, renewal = 8L, straying = 9L, likelihood = 10L, report = 11L, age = 12L, quota = 13L)   # R/action_order.R

g3a_report_stock <- function (report_stock, input_stock, report_f, include_adreport = FALSE, run_f = TRUE, run_at = g3_action_order$report)   # R/action_report.R:1
g3a_report_history <- function (
        actions,
        var_re = "__num$|__wgt$",
        out_prefix = "hist_",
        run_f = TRUE,
        run_at = g3_action_order$report)                                         # :142-147
g3a_report_detail <- function (actions,
    # NB: We could in theory remove report_detail, but g3_fit looks for it in params
    run_f = quote( g3_param('report_detail', optimise = FALSE, value = 1L,
        source = "g3a_report_detail") == 1 ),
    abundance_run_at = g3_action_order$report_early,
    run_at = g3_action_order$report)                                             # :177-182
g3a_trace_var <- function (
        actions,
        check_finite = TRUE,
        check_positive = FALSE,
        check_strictly_positive = FALSE,
        on_error = c("continue", "browser", "stop"),
        print_var = FALSE,
        var_re = c("__num$", "__wgt$"))                                          # R/action_trace.R:1-8
g3a_trace_timings <- function (actions, action_re = NULL )                       # :95-97

g3_eval <- function (f, ...)                                                     # R/eval.R:2
g3_formula <- function (code, ...)                                               # R/formula_utils.R:30
g3_native <- function(r, cpp, depends = c())                                     # R/aaa_lang.R:5
g3_global_formula <- function(f = quote(noop), init_val = NULL)                  # R/aaa_lang.R:22
g3_env  # top-level environment all models are evaluated in (R/aab_env.R:3)
g3_step <- function(step_f, recursing = FALSE, orig_env = environment(step_f))   # R/step.R:12
g3_array_agg <- function(
        ar,
        margins = NULL,
        agg = c("sum", "length_mean", "length_sd", "predator_length_mean", "predator_length_sd" ),
        opt_time_split = !("time" %in% margins || "time" %in% ...names()),
        opt_length_midlen = FALSE,
        ... )                                                                    # R/array_utils.R:19-26
g3_array_combine <- function(arrays, agg = sum, init_val = 0 )                   # :160-163
g3_array_plot <- function (ar, legend = "topright" )                             # :240-242
```

Purpose lines for 1.7-1.8 and the parameter-name grammar are expanded in sections 5 and 6.

---------------------------------------------------------------------

## 2. Action order, step naming, and timing semantics

### 2.1 `g3_action_order` (R/action_order.R:1-17, verbatim)

```r
g3_action_order <- list(
  # NB: Using -1 is okay, but -2 will sort incorrectly
  initial = -1L,
  report_early = 0L,
  time = 1L,
  migrate = 2L,
  predate = 3L,
  naturalmortality = 4L,
  grow = 5L,
  spawn = 6L,
  mature = 7L,
  renewal = 8L,
  straying = 9L,
  likelihood = 10L,
  report = 11L,
  age = 12L,
  quota = 13L )
```

Every `g3a_*`/`g3l_*` action takes `run_at` (default one of these). The docs point to gadget2's "Order of Calculations" (man/action_order.Rd, vignettes/model-structure.Rmd:264-268). The *order inside the list you pass to `g3_to_*` is irrelevant* (vignettes/introduction-single-stock.Rmd:221-223).

### 2.2 How ordering is implemented

- Each step in an action list is named by `step_id(...)` (R/step.R:523-544): numbers -> `sprintf("%03d")` (so `-1` -> `-01`), stocks/characters -> `sprintf("%-20s")` (padded to 20 chars), parts joined with `:`. Example names from a real model [run]:

```
"-01:-"                                       g3a_time clock tick (cur_time, cur_year, ...)  (run_at = initial)
"-01:g3a_initialconditions:fish :<hash>"      initial conditions
"000:000:g3a_report_var :dstart_fish__num"    start-of-step abundance report (report_early)
"000:g3a_suitability_report..."               suitability report (report_early)
"001"                                         g3a_time stop check:  if (cur_time > total_steps) return(nll)
"003:g3a_predate :000:000:fish"               zero prey totalpredate
"003:g3a_predate :001:f_surv :fish :<hash>"   collect suitable biomass
"003:g3a_predate :002:..."                    scale to desired catch
"003:g3a_predate :004:fish"                   overconsumption (once per prey)
"003:g3a_predate :005:f_surv :fish"           rescale cons by overconsumption
"003:g3a_predate :099:f_surv :fish"           __predby_ back-compat
"004:fish :<hash>"                            natural mortality
"005:fish :<hash>"                            growth(+maturity)
"008:g3a_renewal :fish :<hash>"               renewal
"010:g3l_distribution :...:001:..."           catch/abundance collection  | ":003:num" comparison
"010:g3l_understocking :000/001/002"
"011:000:g3a_report_var :detail_..."          end-of-step reports
"012:001:fish"                                g3a_age
```
- `g3_collate()` (R/run.R:31-72) flattens nested lists, pulls "ancillary" steps hidden in formula environments (names matching `^(\d|-)\d{2}:`), names unnamed steps `999:g3_collate:i`, **de-duplicates by name keeping the last occurrence** (`!duplicated(names, fromLast = TRUE)`), then sorts by name with `method = 'radix'` (C-locale string order). Identical steps from repeated actions are thus collapsed; steps meant to be shared (e.g. prey overconsumption `004`) rely on this. The trailing hash is `unique_action_name()` = first 20 chars of `sha1(deparse(sys.call(-1)))` (R/step.R:546-550): **two actions whose calls deparse identically collapse into one**; to run an action twice, vary an argument (e.g. `run_f = ~age == 5` vs `~age == 7`) -- repeated in every man page ("A model can have any number of g3a_X actions, so long as the calling arguments are different").
- Models are wrapped in `while (TRUE) { ...sorted steps... }`; `g3a_time` at `-1` advances the clock; at `time = 1` (`run_stop_at`) it returns `nll` when `cur_time > total_steps` (R/action_time.R:69-86). Anything with `run_at <= 1` therefore runs also on the final `cur_time == total_steps + 1` pass (this is how end-of-run reporting and sparse-sample/projection nll sums run at `initial`: e.g. `g3l_sparsesample` final nll uses `g3_action_order$initial` with `if (cur_time > total_steps)` R/likelihood_sparsesample.R:254; `g3_param_project` `R/param_project.R:505-509`).

### 2.3 What runs at each order position

| order | name | what typically runs there |
|---|---|---|
| -1 | initial | `g3a_time` clock update; `g3a_initialconditions_*` (run only when `cur_time == 0`, ages by `cur_step_size`); `g3a_otherfood*` (replaces abundance each step); `g3a_spmodel`; `g3_param_project` parameter/projection generation; `g3l_sparsesample` final nll (when `cur_time > total_steps`) |
| 0 | report_early | **start-of-step** reports: `dstart_<stock>__num/__wgt` (from `g3a_report_detail(abundance_run_at = report_early)`); suitability report; final `REPORT()` of everything at `cur_time > total_steps` (sub-order 009) |
| 1 | time | stop check (`return(nll)` when finished) |
| 2 | migrate | `g3a_migrate` |
| 3 | predate | `g3a_predate*` (all fleets/predators): collect suitable -> scale to quota/landings -> overconsumption cap (0.95 of prey) -> rescale |
| 4 | naturalmortality | `g3a_naturalmortality`, `g3a_weightloss` (default `run_at`) |
| 5 | grow | `g3a_growmature` (growth; maturing fraction moved to `transitioning_*`), `g3a_mature` step 1 (move maturing fish into `transitioning_*`) |
| 6 | spawn | `g3a_spawn` main step (compute offspring numbers from parents; mortality of parents) and its optional `g3a_weightloss` (R/action_spawn.R:178) |
| 7 | mature | `g3a_step_transition`: maturing fish moved into `output_stocks` (`transition_at`, sub-step `90` for growmature/`2` for g3a_mature) |
| 8 | renewal | `g3a_renewal_*` (recruits added), **`g3a_spawn` recruit step (`recruit_at`)** |
| 9 | straying | `g3a_tag_shedding` (used as a placeholder) |
| 10 | likelihood | `g3l_distribution` collect+compare, `g3l_understocking`, `g3l_bounds_penalty`, `g3l_random_*`, `g3l_ckmr_po` compare |
| 11 | report | end-of-step reports `detail_*` (cons, suit, renewalnum, spawnednum), `hist_*`, `g3a_report_stock` |
| 12 | age | `g3a_age` (default only when `cur_step_final`) and its transition to output stocks (sub-step 90) |
| 13 | quota | `g3_quota` assessment for next fishing year |

Within a position, the sub-order is the 2nd number in the name, then stock/strings alphabetically (names padded to 20 chars). E.g. predate: `000:000` zero totals, `000:001` zero predator totals, `001` collect, `002` scale, `004` overconsumption, `005` rescale, `099` back-compat arrays (R/action_predate.R:314-464). For growmature: reset transitioning arrays at `grow:<stock>` (R/action_grow.R:380), grow step `grow:<stock>:<hash>`, transition at `mature:090:<stock>`.

### 2.4 Likelihood / abundance sampling time (run_at defaults)

- `g3l_catchdistribution`/`g3l_abundancedistribution`: **collection and comparison both at `likelihood` (10)** (R/likelihood_distribution.R:352,397). So at step *t* the model snapshot used is: after migration (2), predation/fishing (3), natural mortality (4), growth (5), spawn (6), maturation (7), renewal (8) of that step, and **before ageing (12)**.
  - Catch distributions use the step's consumption arrays `predprey__cons` (post-overconsumption, i.e. what was actually caught). Abundance distributions use `stock__num`/`stock__wgt` at that moment (after the fishery & mortality of the same step).
  - If `obs_data` has **no `step` column**, data are aggregated over the year: `done_aggregating_f = ~cur_step_final` (compare at the final step of the year, model counters summed across steps and then zeroed); if there is a `step` column compare at every step present (`~TRUE`) (R/likelihood_data.R:228). Data rows for steps not listed are simply not compared.
  - Recruits: `g3a_renewal_*` (8) runs **before** likelihood (10) in the same step, so a survey in the renewal step (default `run_step = 1`) **sees the new recruits** (age = stock minage). `dstart_*` reports at the start of the *following* step first show them; and `detail_<stock>__renewalnum` is stale after the renewal step (not reset) [run].
  - Ageing is at the end of year (12, after likelihood) so ages in the final step still refer to the "old" age; the age-N group is only relabelled N+1 in the next year's first step. A Jan-1 "birthday" corresponds to `step 1` of a year.
- `dstart_<stock>__num/wgt` (from `g3a_report_detail`): snapshot at `report_early` (0) *after* the `-1` clock/initial-conditions step and *before* anything else in that step, i.e. **start-of-step abundance** (initial conditions already applied at step 1; the *previous* step's renewal and any year-end ageing already applied, this step's predation/mortality/growth/renewal not yet) [run: age-1 abundance in `dstart` at 1990-02 excludes the recruits added in step 2, which first appear in `dstart` at 1990-03]. For "end of step" abundance use `g3a_report_history(actions, "__num$|__wgt$", out_prefix = "dend_")` (default `run_at = report` 11, vignettes/articles/random-effect-recruitment.Rmd:99 "NB: Late reporting") or `g3a_report_detail(abundance_run_at = g3_action_order$report)` which then uses prefix `detail_` (R/action_report.R:197-202).
- `g3l_understocking`: runs at likelihood (10) summing `stock__overconsumption` computed in predate (3).
- `g3l_bounds_penalty`: only `cur_time == 0` (R/likelihood_bounds.R:13,50).
- `g3a_initialconditions_*` are **not** run at the true start: `age_offset = quote(cur_step_size)` replaces `age` by `age - cur_step_size` in `mean_f`/`stddev_f`, i.e. state is "as if at the previous step", then the first step's predation/growth etc. runs on top (R/action_renewal.R:119-124; NEWS 0.10, NEWS.md:127-128).

### 2.5 Implications for survey index vs recruits (practical)

1. Put the survey/abundance data for year/step X into `g3l_abundancedistribution(..., obs_data)` with a `step` column matching the survey season; the model value is the stock after that step's fishing, mortality, growth and renewal, before ageing.
2. If recruitment step (`g3a_renewal_*(run_step=)`) <= survey step, recruits are in the survey abundance in that same year; if recruitment step > survey step, they only appear in the next step (not in this year's index).
3. Because ageing is at the end of year and the survey runs before it, "age 3 in 2010 survey" = fish with `age == 3` group at that step (label increments at the end of the final step).
4. A yearly data row (no `step` column) compares model collected over *all* steps of the year at the final step; for `surveyindices_*` this makes `stock__num` of several steps get summed (not averaged) -- prefer an explicit `step` for indices (the vignettes always supply `step`).
5. Fleet-catch data compare consumption (biomass, `weight` col; or numbers via `/wgt`, `number` col) from the *fleet predation action of the same step*; fleets need `run_f`/`landings` data only for steps they operate.

---------------------------------------------------------------------

## 3. Stock model

### 3.1 Dimensions & the stock object

- A `g3_stock` is a classed list with: `dim`, `dimnames` (shape of every instance array), `iterate`/`intersect`/`interact`/`with` (code templates containing `extension_point` that actions splice code into), `iter_ss` (the index symbol per dimension), `env` (stock constants), `name_parts`, `name` (R/stock.R:43-57). Printing a stock shows only dimnames (R/stock.R:60-63).
- Dimension *order = order of piping*, with `length` always first for `g3_stock()`: `g3_stock(..) |> g3s_livesonareas(1) |> g3s_age(1,5)` gives `length x area x age`; reports/arrays follow this (vignette run: `dim(dstart_fish__num) = length 10, area 1, age 5, time 12`) [run]. Dimension names: `length`, `area`, `age`, `tag`, plus appended `time`/`year` in reports. Fleet (`g3_fleet`) has no length (or age); can have area (`g3s_livesonareas`).
- **Length**: `lengthgroups` are *lower bounds*; names are `"10:20"`, last `"50:Inf"` when open-ended (R/stock.R:100-103) [run]. Fish below the first lower bound are not represented. `stock__midlen = lower + dl/2` (the plus group uses `plusdl` = mode of the diffs, R/stock.R:74-91,108). Env vars: `stock__minlen, midlen, maxlen, dl, plusdl, upperlen, minmidlen, maxmidlen` (R/stock.R:142-150) [run].
- **Age**: `g3s_age(min,max)` -> dimnames `age<N>` (e.g. `"age3"`); env `stock__minage`, `stock__maxage`. Reports/filters use `age = 3` with `g3_array_agg` -> `"age3"` (man/array_utils.Rd). `g3s_agegroup` (age *groups*) is used for data.
- **Area**: `g3_areas(c('IXa','IXb'))` -> `c(IXa=1L, IXb=2L)`; stock created with `g3s_livesonareas(area_names["IXa"])` (single named area) or several `g3s_livesonareas(c(1,2))` (unnamed -> `area1`,`area2`). Area variables available in formulas: `area` (iterator), `area_<name>`. Multi-area models need `g3a_migrate` to move fish; predation intersects on `area` (a fleet only preys where it lives; `ignore_dims=c('predator_area')`, R/action_predate.R:285). Single-area stocks use simplified loops (R/stock_areas.R:24-64).
- **Tag**: `g3s_tag(tag_ids integer)`; tag `0` = untagged; iterator var `tag`, index `stock__tag_idx`, `stock__untagged_idx`. Renewal into a tagged stock only goes into the untagged entry (`renewal_into()`, R/action_renewal.R:2-5). Tag actions: `g3a_predate_tagrelease`, `g3a_tag_shedding` (section 1.5).
- **Time dimension** only on helper stocks (`g3s_time`, `g3s_modeltime`, `g3s_modeltime_fishingyear`) for reports / likelihood data / quotas.
- `stock_ss(var, ...)`, `stock_iterate`, `stock_intersect`, `stock_interact`, `stock_with`, `stock_reshape`, `stock_switch`, `stock_prepend`, `stock_hasdim`, `stock_assert`, `stock_combine_subpop`, `debug_label`, `debug_trace` = the mini-language that `g3_step()` expands (R/step.R:1-11,217-). Documented in man/step.Rd; `stock_ss(stock__num)` gives the length-vector for the current area/age iteration (default `vec = length`); `vec = single/full/<dimname>`; `default`/`missing` placeholders in overrides (man/step.Rd).
- **stock_reshape** between different length structures builds a fractional-overlap matrix (`<src>_<dst>_lgmatrix`) automatically; plus-group guessed as 1 long if infinite (R/step.R:233-291). This is how likelihood data bins (different from the stock's) are aggregated.

### 3.2 Sub-stocks (immature/mature, sex): `g3a_growmature`, `g3a_mature*`, `g3a_age`

The multi-stock pattern (vignettes/multiple-substocks.Rmd:84-135):

```r
st_imm <- g3_stock(c(species = "fish", 'imm'), seq(5L, 100L, 5)) |> g3s_age(1L, 5L) |> g3s_livesonareas(area_names["IXa"])
st_mat <- g3_stock(c(species = "fish", 'mat'), seq(5L, 100L, 5)) |> g3s_age(3L, 10L) |> g3s_livesonareas(area_names["IXa"])
stocks <- list(imm = st_imm, mat = st_mat)
actions_st_imm <- list(
  g3a_growmature(st_imm,
    g3a_grow_impl_bbinom(maxlengthgroupgrowth = 4L),
    maturity_f = g3a_mature_continuous(),   # add maturation
    output_stocks = list(st_mat),
    transition_f = ~TRUE),                  # allow maturation every step (default: final step of year only)
  g3a_naturalmortality(st_imm),
  g3a_initialconditions_normalcv(st_imm),
  g3a_renewal_normalcv(st_imm),             # recruits go into imm only
  g3a_age(st_imm, output_stocks = list(st_mat)),   # oldest imm ages into mat by default
  NULL)
actions_st_mat <- list(
  g3a_growmature(st_mat, g3a_grow_impl_bbinom(maxlengthgroupgrowth = 4L)),
  g3a_naturalmortality(st_mat), g3a_initialconditions_normalcv(st_mat), g3a_age(st_mat), NULL)
actions_likelihood_st <- list(g3l_understocking(stocks, nll_breakdown = TRUE), NULL)
```

- Transition mechanics: a transition step (`g3a_step_transition`, R/action_mature.R:78-134) takes `input_stock__transitioning_num/wgt`, and for each output stock (`output_ratios` default equal; must sum to 1 or be formulas; names matched by stock name) does `stock_iterate(outstock, stock_intersect(instock, stock_combine_subpop(out__num, in__transitioning_num * ratio)))`. Anything that **cannot be matched** to an output cell (e.g. ages outside the destination's age range) is put back into the input stock (`__transitioning_remainder`, only when `move_remainder = TRUE`, i.e. for growmature/mature; not for ageing) (R/action_mature.R:97-133). Gotcha: **if the destination lacks the ages that fish mature at, they stay behind** silently.
- Weights are preserved through combining: `stock_combine_subpop` mixes means weighted by abundance (R/step.R:293-).
- `g3a_age(stock, output_stocks)`: with `output_stocks` the oldest age group moves to the other stock and is **not** kept as a plus group; without outputs the oldest group is a plus-group (R/action_age.R:60-74). "At that point it matures 'by default'" (vignettes/multiple-substocks.Rmd:142-144).
- Sex-split / maturity-split stocks: give each stock a name part (e.g. `c(species='fish','imm','f')`) so parameters (`by_stock = 'species'`) and likelihood data (`stock = 'imm'` or `'fish_f'`) can address groups of stocks.
- `g3a_mature(stock, maturity_f, output_stocks)` does maturation without growth; `maturity_f` formulas can use `age`, `stock__midlen`, `stock_ss(stock__wgt)`.
- Fecundity / spawning stock: `g3a_spawn(mature_stock, recruitment_f, output_stocks = list(imm))` replaces `g3a_renewal_*` for the immature stock (spawn computes numbers at order 6; recruit at 8).

### 3.3 Initial conditions & renewal (recruitment)

| action | when | what |
|---|---|---|
| `g3a_initialconditions_normalparam/_normalcv` | `cur_time == 0` (order -1) | `N(age,len) = 10000*factor*normalize(dnorm(midlen, mean(age - cur_step_size), sd))`, factor default `g3a_renewal_initabund()` = `init.scalar * init.<age> * exp(-(M+init.F)*(age-recage))`. Weight `walpha*midlen^wbeta`. `_normalparam` sd param `init.sd` (optionally `by_age`); `_normalcv` sd = mean*`lencv`. Replaces (not adds to) stock state. |
| `g3a_renewal_normalparam/_normalcv` | each year at `cur_step == run_step` (1) for `age == run_age` (minage) incl. projection years unless `run_projection=FALSE` | adds recruits `rec.<year>*rec.scalar` (with `rec.proj` when year not in table, e.g. projection) in the same normal-length form; **adds** to stock (`stock_combine_subpop`). |
| `g3a_otherfood*` | every step while `cur_time <= total_steps` | **replaces** abundance with parametrised/time-series prey for predators; params `of_abund.<year>`, `of_abund.step.<step>`, `of_meanwgt`. |
| `g3a_spawn` + `g3a_spawn_recruitment_*` | spawn (6)/recruit (8) | stock-recruit; recruits spread normally over midlen about `mean_f`, sd `rec.sd`, into `age == stock__minage` of each output stock. |
| `g3a_spmodel` | initial | biomass-dynamics pool. |

NEWS notes: `run_projection` TRUE by default for renewal, with `rec.proj` covering projections (NEWS 0.13, NEWS.md:66); `g3a_renewal_vonb_t0` default `mean_f` (0.10, NEWS.md:126); `scale = 0.001` removed from default `K` parameters (0.10, NEWS.md:125); initialconditions offset by `cur_step_size` (0.10, NEWS.md:127); `g3a_initialconditions`/`g3a_renewal` (manual) hidden/unexported in 0.14 (NEWS.md:45).

### 3.4 Growth

- Two-part design: `delta_len_f` (mean growth in length per length group) and `delta_wgt_f` (weight increment, length x delta matrix) combined by `g3a_grow_impl_bbinom()` into `stock__growth_l` (length group -> jump probability, columns `0..maxlengthgroupgrowth`) and `stock__growth_w`; then `g3a_grow_apply` multiplies to get new `num`/`wgt` (R/action_grow.R:215-339).
- Growth options: `g3a_grow_lengthvbsimple` + `g3a_grow_weightsimple` (default; vB with `Linf`,`K`, weight `walpha`,`wbeta`); `g3a_grow_length_multspec` + `g3a_grow_weight_multspec` (multispecies, needs predator feedinglevel); `g3a_grow_length_weightjones` + `g3a_grow_weight_weightjones` (Jones; needs `stock__feedinglevel`, `g3a_predate_maxconsumption`, `growth_delta_w`).
- `maxlengthgroupgrowth` is how many length groups an individual can jump per step; `delta_len_f / stock__plusdl` assumes (roughly) even length groups; `beta_f` (`bbin`) is the beta-binomial dispersion (vignette sets bounds 1e-5..10 or 1500).
- Beta-binomial growth cannot make length shrink: `avoid_zero` on the mean increment; fish in the final (plus) length group stay there (R/action_grow.R:233-270).

### 3.5 Natural mortality

`g3a_naturalmortality(stock, mortality_f = g3a_naturalmortality_exp())`: `num <- num * exp(-M*cur_step_size)`; `M` per age by default (`S.M.<age>`), set `g3a_naturalmortality_exp(g3_parameterized("M", by_stock = TRUE, by_age = FALSE))` for one M (vignettes/model-customisation.Rmd:17-21). Custom formulae may use `age`, `stock__midlen`, `cur_year`, `area` ...

### 3.6 Spawning

See 1.4: `g3a_spawn(stock, recruitment_f, proportion_f=1, mortality_f=0, weightloss_f=0, weightloss_args=list(), output_stocks, output_ratios, mean_f, stddev_f, alpha_f, beta_f, by_stock, wgt_by_stock, run_step=NULL, run_f=~TRUE, run_at, recruit_at)`.
`proportion_f` = proportion of each cell spawning (formula in age/length, e.g. `g3_suitability_exponentiall50(...)`); `mortality_f` = parent mortality as rate (`exp(-mortality_f)`, `action_step_size_f = 1`) (R/action_spawn.R:161-163); `run_step`/`run_f` restrict timing/area; `recruitment_f$s` is summed over all parent cells and `$r` yields total recruits that are normalised across `output_stocks`. Stock vars: `__spawnprop`, `__spawningnum`, `__offspringnum`; output `__spawnednum`, `__spawnedwgt`.

### 3.7 Migration

`g3a_migrate(stock, migrate_f, normalize_f = g3a_migrate_normalize(), run_f = TRUE)`; `migrate_f` is a formula for the (pre-normalisation, squared) flow from `area` to `dest_area`; the matrix is NaN-reset each step then lazily filled per source area (R/action_migrate.R:44-79). If `run_f` is FALSE for a cell, individuals simply copy over. Requires `stock$dim$area`.

### 3.8 Predation / fishing

- Fleets are `g3_fleet("name") |> g3s_livesonareas(area)`; they "predate" prey stocks (vignettes/introduction-single-stock.Rmd:330,468-475).
- Catch equation chain (see 1.5): suitability `S` (per length) x numbers/biomass -> `predprey__suit` (F); desired consumption `C = E * F/sum(F)` for total/number fleets, `E*dt*F` for linear/effort/quota fleets; prey capped to 95% of biomass per cell/step (`overconsumption_f`), excess recorded as `stock__overconsumption` (feeds `g3l_understocking`).
- `landings_f` data: `g3_timeareadata("landings_f_surv", landings_df, "weight", areas = area_names)` with columns `year`, optionally `step`, `area` (names mapped by `areas`), value column. Missing combos -> **0 landings**. Gaps are therefore "fleet inactive" not NA (R/timedata.R:147).
- Predator with feeding level/energy (`g3a_predate_catchability_predator`): dynamics for seals/cod-style multispecies; `g3a_predate(predstock = stock_with_length, ...)` where predators have length/age (predator_length used by suitability functions as `predator_length`).
- Projections / MSE: `g3a_predate_catchability_project(quota_f = g3_quota(g3_quota_hockeyfleet(list(fleet), list(mature_stock))), landings_f = <timeareadata>, unit = "biomass")`. During `cur_year_projection` the quota (per fishing year, `quota_*__var`) replaces landings; `NaN` quota (before first assessment) -> `interim_f` (default `quota.interim.<step>`=0). `g3_quota(function_f, quota_name, init_val = NaN, year_length = 1L, start_step = 1L, run_revstep = -1, run_historical = FALSE, ...)` stores a quota value per *fishing year* (`g3s_modeltime_fishingyear`) assessed at `run_revstep` (negative = steps before the end of the fishing year) (man/quota.Rd).
- Unit vocabulary for quotas: `biomass`, `biomass-year`, `harvest-rate`, `harvest-rate-year`, `individuals`, `individuals-year`; `-year` = yearly total, multiplied by `cons_step` (proportion per step; default `step_lengths/12`).
- `g3_quota_hockeystick(predstocks, preystocks, preyprop_fs=1, trigger, target, stddev, unit)` -> `target * dif_pmin(SSB/trigger, 1, 1e3)`; `stddev > 0` replaces the value by `exp(rnorm(1, out - stddev**2/2, stddev))` (R/quota.R:57-61) -- **[infer] this exponentiates the quota value itself (looks like a log-space formula applied to a linear quantity); no test covers `stddev` (grep tests/test-quota*.R), so keep `stddev = 0` (default) unless you have checked the output.** `g3_quota_hockeyfleet(...)` = same with `unit = "harvest-rate-year"`, params `P.hf.btrigger`, `P.hf.harvest_rate`, `P.hf.stddev` [run]. `g3_quota_assess(predstocks, preystocks, assess_f, unit)` lets `assess_f` see `cons`, `abund`, `meanwgt` lists built from `detail_<prey>_<pred>__cons`, `dstart_<prey>__num/__wgt` (needs `g3a_report_detail` variables, R/quota.R:96-118).

### 3.9 Weight loss, tagging, other

`g3a_weightloss` (natural mortality slot, order 4) reduces mean weight (spawning loss uses `apply_to_pop = stock__spawningnum`); `g3a_tag_shedding` and `g3a_predate_tagrelease` for tag-recapture; `g3l_ckmr_po` for close-kin mark-recapture (parent-offspring pairs) requires `g3a_spawn` parent stocks.

---------------------------------------------------------------------

## 4. Likelihood

### 4.1 Overview

Every likelihood action adds to the global `nll` (order 10). Two-stage design (vignettes/incorporating-observation-data.Rmd:27-33):

1. **Aggregation** -- `obs_data` columns are inspected, the observation is converted to an array (`obsstock__num` and/or `obsstock__wgt`) and the model's own abundance/catch is aggregated into an identically-shaped `modelstock__num/wgt` array (R/likelihood_data.R `g3l_likelihood_data`).
2. **Comparison** -- `function_f` (a formula over `obsstock__x`/`modelstock__x`; `x` replaced by `num` or `wgt`) gives the nll for each (time, area, age, ...) slice; the result is summed and multiplied by `weight` (R/likelihood_distribution.R:375-394).

- `g3l_catchdistribution(...)` requires `fleets`/`predators` (compares catch = `predprey__cons`); error otherwise "fleets/predators must be supplied for g3l_catchdistribution". `g3l_abundancedistribution(...)` compares `stock__num/wgt` and errors if fleets/predators supplied (R/likelihood_distribution.R:246-249).
- `nll_name` -> internal names: `nll_name` is rewritten to `cdist_<fn>_<name>` (or `adist_...` without fleets) where `<fn>` is `function_f`'s name minus `g3l_distribution_` (`sumofsquares`, `surveyindices_log`, `multinomial`,...; `custom` for non-call) (R/likelihood_distribution.R:252-261).
  - Default `weight` parameter: `<cdist|adist>_<fn>_<name>_weight` (optimise FALSE, value 1) -- e.g. `cdist_sumofsquares_ld_weight`, `adist_surveyindices_log_si_weight` [run]. (Default arg is a promise evaluated after `nll_name` rewrite.)
  - Reported variables (with `report=TRUE`): `cdist_<fn>_<name>_model__num|wgt`, `..._obs__num|wgt` (e.g. `cdist_sumofsquares_ld_model__num`) and always (via `g3a_report_detail`'s `nll_*` regex) `nll_cdist_<fn>_<name>__num|wgt` and `nll_cdist_<fn>_<name>__weight` -- one value per timestep if `nll_breakdown=TRUE` else a scalar [run]. For surveyindices also `<model>__params` (alpha, beta used).
- `report = TRUE`: model arrays kept (not zeroed) and added to the report (R/likelihood_distribution.R:384,402-437); `nll_breakdown = TRUE`: nll report broken down by timestep (`g3s_modeltime`).
- `missing_val = 0` default: gaps within dimensions present in data compare to 0; `'stop'` -> error on missing values (R/likelihood_data.R:210-215). **Whole missing years/steps are not compared at all** (gaps in `year`/`step` are skipped); gaps in `length`/`age`/`area`/`stock`/`fleet` rows are filled with `missing_val`. An area not mentioned in data at all is not compared.

### 4.2 `obs_data` columns -> array dimensions

`g3l_likelihood_data` (R/likelihood_data.R:35-232) builds `modelstock`/`obsstock` dimension by dimension in this order: **length, [time if surveyindices], age, tag, stock, predator_length, predator_age, predator_tag, predator, fleet, time (late), area**. Any remaining column after the known ones is treated as an observation column; `number` -> `num`, `weight` -> `wgt`; unknown other columns in catch/abundance data -> error "Unknown column in likelihood data" (R/likelihood_distribution.R:296) [src]. At least one observation column required ("Should be at least one observation in likelihood data").

| column | required | meaning / how inferred |
|---|---|---|
| `year` | yes (or `time` strings "1999-01") | "Data must contain a year column"; step/year -> time code `year*100+step` (R/likelihood_data.R:40-51) |
| `step` | no | If absent: yearly data (model summed over steps, compared at last step); if present compared at that step. Steps > 99 error. |
| `area` | no | Names mapped to integer model areas by `area_group` (a named integer vector, e.g. `g3_areas(...)` or `list(north=1:2,south=3:5)`); without `area_group` area values must be integers ("Areas in data don't have integer names, but areas not provided"). MFDB area attributes are ignored. Unnamed areas in model are summed. (R/likelihood_data.R:178-198) |
| `length` | no | Factor / strings like `"[10,20)"`, `"10:20"` (as `cut(..., right = FALSE)` or MFDB). Model length groups are re-binned to the data's groups via `stock_reshape` matrix. Missing/gaps: **"Gaps in length groups are not supported"**; must be inclusive-lower (`right = FALSE`) else error "length intervals should be inclusive-lower". Open upper bound (`Inf`) detected from last level; MFDB attrs `min/max/min_open_ended/max_open_ended` honoured (R/likelihood_data.R:234-301). No `length` column -> all lengths summed (single `0:Inf` group). |
| `age` | no | Numeric (each distinct age a group, `min..max`), factor/cut strings like `"[1,1]"`, `[2,4]`, or MFDB age attributes (groups of ages). Missing ages compare to 0 (R/likelihood_data.R:303-356). Absent -> all ages summed. |
| `tag` | no | numeric ids or factor |
| `stock` / `stock_re` | no | Stock names (full or *parts*, e.g. `"imm"`, `"fish_f"`); each model stock goes in the group that matches (shortest-part matches first, longer overrides); a stock can only be in one group; groups matching nothing -> error "stock groups matched no stock in likelihood data"; `stock_re` = regex on stock names (first listed wins). Both `stock` and `stock_re` -> error (R/likelihood_data.R:377-459; NEWS 0.13 NEWS.md:54). |
| `fleet` / `fleet_re` | no | same logic against `fleets` |
| `predator` / `predator_re` | no | against `predators` |
| `predator_length`, `predator_age`, `predator_tag` | no | like length/age/tag but for the predator (NEWS 0.12) |
| `number` | one of | compare individuals |
| `weight` | one of | compare biomass (`num*wgt` for abundance, `cons` for catch) |

`g3_distribution_preview(obs_data, predators = list(), fleets = list(), stocks = list(), area_group = NULL)` returns the array that would be built (+ attrs `stock_map`, `fleet_map`, `predator_map`) [run]. Use it to check aggregation before running.

`transform_fs` (list named by dimension): `length = <matrix formula>` (matrix-multiplies the model length vector; **applied before aggregation, expressed in terms of the stock's length groups** (NEWS 0.9 NEWS.md:146-147), NEWS 0.12 NEWS.md:78) and `age = <vector formula>` (uses preage index / "previous age" loops, R/likelihood_distribution.R:303-348). Per-stock formulas allowed via named list.

### 4.3 Comparison functions (`function_f`)

| fn | what it computes | notes |
|---|---|---|
| `g3l_distribution_sumofsquares(over = c('area','predator','predator_tag','predator_age','predator_length'))` | `sum((p_model - p_obs)^2)` where `p = x / total` and *total* = sum over **all dims except** `time` and those in `over` (i.e. dims dropped by `stock_ssinv(x, time, over...)`: so for age-length data the whole age x length table within one time/area sums to 1) (R/likelihood_distribution.R:3-39) | "Strat" sums per length if `'length' %in% over`. `over` unknown dims ignored (a fleet has no age). Matches gadget2 catchdistribution/sumofsquares. Ratio of obs to total => **absolute sample size does not matter; a time/area slice with obs total 0 gives 0/avoid_zero(0) = 0** |
| `g3l_distribution_multinomial(epsilon = 10)` | `2*(-sum(obs*log(pmax(model_prop, 1/(n*epsilon))))+sum(lgamma(1+obs)) - lgamma(1+sum(obs)))` | per length vector of each age/area/time cell; gadget2 multinomial.cc |
| `g3l_distribution_multivariate(rho_f, sigma_f, over = c('area'))` | TMB `SCALE(AR1(rho), sigma)(model_prop - obs_prop)` (AR1 correlated residuals across lengths). In R: `sum(dnorm(rho*lag(x,1), 0, sqrt(1-rho^2)*sigma))` | you must supply `rho_f`, `sigma_f` (formulas / `g3_parameterized(...)`) |
| `g3l_distribution_surveyindices_log(alpha = NULL, beta = 1)` / `_linear` | `sum((alpha + beta * log(N_model) - log(I_obs))^2)`; **NB the code is** `(alpha + beta*N - I)^2` with `N=log(model)`, `I=log(obs)` (R/likelihood_distribution.R:107-122). Sum over the time vector of each area/age/length cell. | `alpha`/`beta` NULL => fitted by linear regression of I on N inside the model each run; supplying a value fixes it. Since 0.11 default `beta = 1` (slope fixed at 1; set `beta = NULL` for old behaviour -- NEWS.md:102). Used values stored in `modelstock__params` and reported (`*_surveyindices_*__params` regex in `g3a_report_detail`). Works with or without a `step` column; the model history gets an *early* time dimension (`model_history = 'early'`, R/likelihood_distribution.R:202-204). Regression only evaluated at the last time point (`modelstock__time_idx == max_time_idx`). `avoid_zero(...)` before log. |
| `g3l_distribution_sumofsquaredlogratios(epsilon = 10)` | `sum((log(obs + epsilon) - log(model + epsilon))^2)` | gadget2 `catchinkilos`-style; use with `weight` column (R/likelihood_distribution.R:127) |

gadget2 -> gadget3 mapping (vignettes/incorporating-observation-data.Rmd:96-111):
- CatchDistribution -> `g3l_catchdistribution` + matching `g3l_distribution_*`; data `year, step, area, age, length, number`.
- SurveyIndices -> `g3l_abundancedistribution` + `g3l_distribution_surveyindices_log/linear`; data `year, step, area, length, number`.
- CatchInKilos -> `g3l_catchdistribution(function_f = g3l_distribution_sumofsquares())`; data `year, step, area, fleet, weight`. (There is also `g3l_distribution_sumofsquaredlogratios`, documented in the source as catchinkilo's sumofsquares, R/likelihood_distribution.R:127.)
- StockDistribution (maturity stage) -> catchdistribution with `stock` column (vignettes/multiple-substocks.Rmd:200-223).

### 4.4 `g3l_understocking(prey_stocks, power_f = ~2, nll_breakdown = FALSE, weight = 1e+08, run_at = likelihood)`

Sum over prey_stocks of `stock__overconsumption` (biomass that predators wanted above the 95% cap, recorded in `g3a_predate` step 004) , `total^power_f * weight`. Report: `nll_understocking__wgt` [run]. Add to every model with predation, passing **all prey stocks** (`list(imm, mat)`). Per-area breakdown differs from gadget2 (comment R/likelihood_understocking.R:26-27). Weight 1e8 is huge: non-zero understocking dominates nll.

### 4.5 `g3l_bounds_penalty(actions_or_parameter_template, weight = 1, scale = 1e6, run_at)`

Soft penalty `weight * (logspace_add(scale*(p-upper)/(upper-lower),0) + logspace_add(scale*(lower-p)/(upper-lower),0))^2` once (`cur_time == 0`) (R/likelihood_bounds.R:11-24,48-60).
- Given an **actions list** (usual: `g3l_bounds_penalty(actions)`): reads `param_lower/param_upper` at run time (so bounds come from the parameter table you pass at `g3_tmb_adfun()` time) for *every* parameter; non-finite bounds skip.
- Given a **parameter-template data.frame**: bakes bounds into source for parameters with `optimise` and finite lower & upper.
- Lets optimisers without box constraints (BFGS) respect bounds (vignettes/introduction-single-stock.Rmd:590-607). `scale` configurable (NEWS 0.15, NEWS.md:22).

### 4.6 Random-effect priors: `g3l_random_dnorm`, `g3l_random_walk`

`g3l_random_dnorm(nll_name, param_f, mean_f = 0, sigma_f = 1, log_f = TRUE, period = 'auto', nll_breakdown = FALSE, weight = <param nll_name_weight>, run_at)` adds `-dnorm(param_f, mean_f, sigma_f, log)` (negative log density when `log_f`) for each period; `g3l_random_walk(nll_name, param_f, sigma_f=1, log_f=TRUE, period='auto', ...)` same on successive values (`dnorm(param, prev, sigma)`). `period = 'auto'` inferred from `g3_parameterized_breakdown(param_f)`: no table -> `single`, `cur_year` -> `year`, `cur_year+cur_step` -> `step`; per-stock tables error ("Per-stock random parameters not supported yet"), seasonal only -> error (R/likelihood_random.R:1-12) [run: error confirmed]. `period` can be 'year','step','single','auto'. `period='single'` evaluates at `cur_time == total_steps`; `'year'` at `cur_step_final`. `param_f` must be a `g3_parameterized(...)` formula. Use together with `random = TRUE` params (`g3_init_val(..., random = TRUE)`).

### 4.7 `g3l_sparsesample(nll_name, obs_df, stocks, measurement_f = quote(wgt), function_f = g3l_sparsesample_linreg(), predstocks = list(), area_group = NULL, weight, run_at)`

Individual-based / sparse data (e.g. mean weight-at-age samples): each `obs_df` row defines a subset (year [required], step, area, age, length -> *nearest* length group) and a measured `mean` (optional `number`, `stddev`); model predictions are aggregated per row as `model_sum`, `model_sqsum`, `model_n`; gaps are **not** zero-filled. Columns: `year` required; `mean` required; **`number`/`stddev` optional**. **[infer] the code drops the last column of `obs_df` before building the row dimensions (`obs_df[,-ncol(obs_df)]`, R/likelihood_sparsesample.R:163)**: put all dimension columns first and `mean` (then `stddev`, `number`) last, as the tests do (tests/test-likelihood_sparsesample.R:31-50).
- `measurement_f` formula: `wgt` -> mean weight; `length` -> midlen of observed group; other vars allowed (`age`..).
- With `predstocks` -> compared against *catch* (cons/wgt individuals), else abundance.
- `function_f`: `g3l_sparsesample_linreg(fit = c('log','linear'), slope = 1, intercept = NULL)` (regression of obs mean on model mean, `intercept` NULL fits it) or `g3l_sparsesample_sumsquares(weighting = "model_stddev")` (also `"obs_stddev"` or a custom formula). Default `weight` param name `asparse|csparse_<fn>_<name>_weight`. Final nll is added at `cur_time > total_steps` (initial order) (R/likelihood_sparsesample.R:254-261). Reports: `nll_(asparse|csparse)_<fn>_<name>__nll|obs_mean|model_sum|model_n|...`.

### 4.8 `g3l_ckmr_po(nll_name, obs_data, parent_stocks, offspring_stocks, weight, run_at)`

Close-kin mark-recapture parent-offspring pairs. `obs_data` must have **exactly** columns `year, parent_age, offspring_age, mo_pairs, n_comparisons` in that order (`stopifnot(colnames(obs_data) == ...)`, R/likelihood_ckmr_po.R:14). Collects, at spawn steps (it checks `sum(parent__spawningnum) > 0`), per-year parent numbers and offspring (via `__offspringnum`) by age; at the final step of each data year computes expected pair probability = fecundity-of-parent-at-birth-year / total offspring and adds `-weight * dpois(mo_pairs, n_comparisons*pr, log = TRUE)`. Requires parents with `g3a_spawn`. Single-area only (comment R/likelihood_ckmr_po.R:29-31).

### 4.9 Other likelihood-like pieces

- `g3_param_project()` adds the prior nll of random-effects time series (section 5.6).
- Penalty/prior via `g3_formula(quote(nll <- nll + ...))` custom actions (vignettes/writing_actions.Rmd).
- Test-only: `g3l_test_dummy_likelihood()` (tests/, unexported).

---------------------------------------------------------------------

## 5. Parameters

### 5.1 The three layers

1. **`g3_param` family** (pseudo-functions inside formulas; documented in man/language.Rd): `g3_param(name, value=0, optimise=TRUE, random=FALSE, lower=NA, upper=NA)` scalar; `g3_param_vector(name, value)` vector param dereferenced with `[[`; `g3_param_table(name, table, value, optimise, random, lower, upper, ifmissing)` lookup table of scalar params (one per row of `expand.grid(...)`), looked up by in-model integer variables (`cur_year`, `cur_step`, `age`, `area`...). The same name used twice = same parameter. Extra g3_param args recognised by the compiler: `parscale`, `type`, `source` (R/run_tmb.R:775-796); misspelling `optimize=` is an error ("optimise parameter should be spelt with an s", R/run_tmb.R:773). Internal variants: `g3_param_array`, `g3_param_nodef`, `g3_param_lower/upper` (R/run_r.R:114-121).
   - `optimise` default **FALSE unless both bounds supplied** (`is.finite(lower) && is.finite(upper) && isFALSE(random)`, R/run_tmb.R:781; NEWS 0.14 NEWS.md:43) -- the Rd for `g3_param` still says "Default TRUE", the code wins.
   - `type` keywords (colon separated): `LOG` (value logged inside model, optimiser works in log space; values/bounds converted automatically, NEWS 0.14 NEWS.md:40; `g3_init_val` errors on negative values for LOG params, R/init_val.R:111-123), `ARRAY`, `VECTOR`, `MATRIX` (R/run_tmb.R:787-788,1146-1151).
2. **`g3_parameterized(name, ...)`** -- the recommended front-end that generates a `g3_param`/`g3_param_table` call with systematic names (below). All action defaults are built with it.
3. **Parameter template**: result of compiling (`attr(model, "parameter_template")`), which you fill in and give to the model function / `g3_tmb_adfun`.

### 5.2 `g3_parameterized` arguments (man/params.Rd; R/params.R:43-223)

| arg | meaning |
|---|---|
| `name` | suffix of the parameter name; a vector is pasted with "." (`c("M","x")` -> "M.x", R/params.R:102) |
| `by_stock` | `FALSE` no stock prefix; `TRUE` -> prefix with the stock's full `name` ("fish_imm"); character -> choose **name_part(s) by name**, e.g. `'species'` -> "fish" (only *named* parts of `g3_stock(c(species='fish','imm'))` can be selected; R/step.R:442-460 uses `stock$name_part[eval(name_part)]`); a stock or **list of stocks** -> shared parameter whose prefix is the name parts common to all (`stock_common_part`, R/params.R:1-19; if none in common, all full names sorted and joined with "_") |
| `by_predator` | same idea for the *predator/fleet* (`predstock` in the formula); gives `<fleet>.name`, or name_part(s) |
| `by_year` | `TRUE` -> one per model year `seq(start_year, end_year)` (suffix `.1990`); numeric vector (e.g. `1998:2099`) overrides the year range so projections have enough parameters (NEWS 0.11 NEWS.md:88) |
| `by_step` | one per step in year (suffix `.1` .. `.n`); with by_year `.1990.2` |
| `by_age` | one per stock age (needs by_stock; "!by_stock && by_age doesn't make sense"); with list of stocks, union of ages `min(minage)..max(maxage)` |
| `by_area` | one per stock area; needs `by_stock` or `by_predator` ("One of by_stock/by_predator should be set if by_area is set"); suffix = area name |
| `prepend_extra` | extra things (string or stock) prepended to the name via `stock_prepend` |
| `exponentiate` | uses `exp(param)`; **appends `_exp`** to the parameter name (e.g. `rec.1990_exp`, `spawn.R.1990_exp`, `andersen.p3_exp`); optimiser sees log-scale values. `g3_init_val(..., auto_exponentiate=TRUE)` matches `_exp` names and logs your values/bounds |
| `avoid_zero` | wrap with `avoid_zero()` |
| `scale` | `value * scale`. A **character** scale creates another parameter with the same by_stock (e.g. `scale = 'rec.scalar'` -> `S.rec.scalar`) |
| `offset` | `value + offset`; character -> another parameter |
| `ifmissing` | value used when a `by_year`/table key is absent (years outside data, projections): constant or character (becomes another parameter, e.g. `rec.proj`) |
| `...` | passed to `g3_param`: `value`, `lower`, `upper`, `optimise`, `random`, `parscale`, `type` |

**Name grammar** (verified from template printouts [run]): `[<stock>.][<predator>.]<name>[.<year>][.<step>][.<age>][.<area>]` with `_exp` moved to the end; `stock` prefix is outermost, then `predator`, then `prepend_extra`. Examples [run]: `fish_imm.M.3`, `fish_imm.comm_is.l50`, `fish_imm.rec.1990`, `fish_mat.spawn.R.1991_exp`, `comm_is.quota.interim.2`, `fish_imm.fish_mat.alpha` (suitability of prey `fish_imm` for predator `fish_mat`), `init.F`, `recage` (no prefix), `M.1990.1` (param_project), `retro_years`, `project_years`.

### 5.3 Standard parameters created by default actions (name suffix -> source), for stock `S`, step-size `dt`

| name | action(s) | default value | notes |
|---|---|---|---|
| `S.Linf`, `S.K` | `g3a_grow_lengthvbsimple`, `g3a_renewal_vonb_*` | 0 (renewal vonb: 1) | `K` in 1/year (units of `cur_step_size`) |
| `S.t0` | `g3a_renewal_vonb_t0` | 0 | |
| `S.recl`, `recage` | `g3a_renewal_vonb_recl` | | `recage` global, optimise=FALSE |
| `S.walpha`, `S.wbeta` | grow weight, renewal/initial weights, spawn | 0 | weight = `walpha*L^wbeta` |
| `S.bbin` | `g3a_grow_impl_bbinom` | 0 (avoid_zero'd) | |
| `S.M.<age>` | natural mortality & `renewal_initabund` | 0 | |
| `S.init.scalar`, `S.init.<age>`, `init.F`, `recage` | initial conditions | 1, 1, 0, 0 | `init.F` unprefixed |
| `S.init.sd[.<age>]`, `S.lencv` (0.1, fixed), `S.rec.sd` (10) | initial / renewal spread | | |
| `S.rec.<year>`, `S.rec.scalar`, `S.rec.proj` | `g3a_renewal_normalparam/cv` | 0 | `rec.scalar` is NOT fixed by default unless you set it (all start with optimise FALSE since no bounds) |
| `S.mat.alpha`, `S.mat.l50` | `g3a_mature_continuous` | 0 | |
| `S.P.alpha`, `S.P.l50` | `g3_suitability_exponentiall50` | 0 | |
| `S.P.suit` | `g3_suitability_constant` | | |
| `S.P.andersen.p1`, `...p3_exp`, `...p4_exp`, `S.andersen.p0/p2` | `g3_suitability_andersenfleet` | log(2), 0.1, 0.1 / 0, 1 | |
| `P.quota.prop`(1), `P.quota.interim.<step>`(0), `P.cons.step.<step>`(`step_lengths/12`) | `g3a_predate_catchability_project` | | |
| `P.hf.btrigger|harvest_rate|stddev` or `P.hs.trigger|target|stddev` | `g3_quota_hockeyfleet|hockeystick` | 0 (stddev 0) | |
| `S.spawn.*` | spawn recruitment | see 1.4 | |
| `S.of_abund.<year>`, `S.of_abund.step.<step>`, `S.of_abund.proj`, `S.of_meanwgt` | otherfood | | |
| `<cdist|adist>_<fn>_<name>_weight` | likelihood | 1 (fixed) | |
| `report_detail` | `g3a_report_detail` | 1 (fixed) | gadgetutils `g3_fit` looks for it |
| `project_years`, `retro_years` | `g3a_time` | 0 (fixed) | |
| `M.<year>.<step>`, `M.proj.dnorm.mean|stddev`, `proj_dnorm_M_weight` | `g3_param_project("M", g3_param_project_dnorm())` | | random effects |

### 5.4 Parameter template

- **TMB**: `attr(g3_to_tmb(...), "parameter_template")` is a `data.frame`, one row per scalar parameter (row names = switch), columns [run]:
  `switch` (name pre-C++ mangling), `type` (colon-separated keywords: `LOG`, `ARRAY`, `VECTOR`, `MATRIX`), `value` (**list column**, `I()`; vectors allowed), `optimise` (logical), `random` (logical), `lower`, `upper`, `parscale` (numeric, NA default), `source` (character: name of the g3 function that defined it) (R/run_tmb.R:775-796; vignettes/introduction-single-stock.Rmd:620-631). Values default to the `value=` given in the g3_param call (usually 0).
- **R**: `attr(g3_to_r(...), "parameter_template")` is a *named list* of values only (no bounds) (R/run_r.R:263; R/run.R:77). Passing a **data.frame** (TMB-style) to the R function is also accepted: it picks `value`, `lower`, `upper` and converts `LOG`-type values to log (R/run_r.R:229-236); a plain list also logs LOG params since 0.15.1 (NEWS.md:4).
- Template row order is the order parameters were encountered while compiling (not sorted) -- `g3_tmb_adfun` insists `identical(model_params$switch, parameters$switch)` ("Parameters not in expected order", R/run_tmb.R:1155-1158) so never reorder/subset rows; edit values in place.
- Random effects: `random = TRUE` rows are integrated out by TMB (Laplace); `random & optimise` -> error "Parameters with random=TRUE & optimise=TRUE doesn't make sense" (R/run_tmb.R:1191-1196).

### 5.5 Filling the template: `g3_init_val(param_template, name_spec, value = NULL, spread = NULL, lower, upper, optimise, parscale, random = NULL, auto_exponentiate = TRUE)`

- `name_spec`: dot-separated glob; each part may be: `*` (anything, optionally with a prefix e.g. `m*`), `#` (any number, e.g. `age*`/`#`), range `[1979-1984]`, choice `a|b` (e.g. `rec|init`, `[1979-1984]|[2000-2003]`) (man/init_val.Rd; R/init_val.R:24-46). Matching is anchored (`^...$`) on the whole `switch` (plus optional `_exp` when `auto_exponentiate`) and the spec's dots separate parts, so `*.M.#` matches `fish_imm.M.3` but not `M.1990.1` (no literal `.M.`). [run] a `*` part is translated to `.*` (R/init_val.R:39) and **does match across dots** (`*.l50` matched both `fish_imm.comm_is.l50` and `a.b.c.l50`); `*.rec.#` matches `fish_imm.rec.1990_exp` and logs value/bounds (value 5 -> 1.609, bounds 1..10 -> 0..2.30); the vignettes use `*.*.l50` for stock.fleet.l50 (vignettes/introduction-single-stock.Rmd:694-695).
- Doesn't match anything -> `warning("g3_init_val('<spec>') didn't match any parameters")` and template returned unchanged: **watch for typos/stock names**.
- `value`: scalar or vector (recycled/matched per match). `spread`: shorthand `lower = value*(1-spread)`, `upper = value*(1+spread)` (min/max ordered). Setting both bounds auto-sets `optimise = TRUE` and `parscale = 'auto'` (= `upper-lower`). Explicit `optimise = FALSE` overrides. `random = TRUE` clears `optimise`/`lower`/`upper`/`parscale` (if you didn't give them). `optimise` is forced FALSE where `random` is TRUE (R/init_val.R:70-101).
- Warns "Initial parameter values below lower bound" / "above upper bound".
- Works on a data.frame template (all columns) or on the R list template (only `value`, via `param_template[matches] <- value`).
- Idiom (vignettes/introduction-single-stock.Rmd:667-701):

```r
attr(model_code, "parameter_template") |>
  g3_init_val("*.rec|init.scalar", 1, optimise = FALSE) |>
  g3_init_val("*.init.#", 10, lower = 0.001, upper = 30) |>
  g3_init_val("*.rec.#", 1e-4, lower = 1e-6, upper = 1e-2) |>
  g3_init_val("*.rec.proj", 0.002) |>
  g3_init_val("init.F", 0.5, lower = 0.1, upper = 1) |>
  g3_init_val("*.M.#", 0.15, lower = 0.001, upper = 10) |>
  g3_init_val("*.Linf", estimate_linf, spread = 0.2) |>
  g3_init_val("*.K", 0.3, lower = 0.04, upper = 1.2) |>
  g3_init_val("*.t0", estimate_t0, spread = 2) |>
  g3_init_val("*.walpha", 0.01, optimise = FALSE) |>
  g3_init_val("*.wbeta", 3, optimise = FALSE) |>
  g3_init_val("*.*.alpha", 0.07, lower = 0.01, upper = 0.2) |>
  g3_init_val("*.*.l50", estimate_l50, spread = 0.25) |>
  g3_init_val("*.bbin", 1, lower = 1e-05, upper = 10) |>
  identity() -> params.in
```

### 5.6 `g3_param_project` and friends (random effects & projections) -- R/param_project.R

- `g3_param_project(param_name, project_fs = g3_param_project_rwalk(), by_step = TRUE, by_stock = FALSE, weight = ..., scale = 1, offset = 0, random = TRUE)` returns a *formula* (current value) that behaves like `g3_parameterized(param_name, by_year = TRUE, by_step = by_step, random = TRUE, ifmissing = NaN)` but also (1) fills a per-time vector `proj_<fn>_<name>__var` (or `__lvar` for log-space distributions) from parameters for historical years, (2) when `cur_year_projection` and value NaN, *generates* projected values using `project_fs$project`, (3) adds `weight * project_fs$nll` (deviance of the time series from its distribution) at `cur_time > total_steps` (R/param_project.R:440-535). Use inside any arg expecting a formula, e.g. `g3a_naturalmortality_exp(g3_param_project("M", g3_param_project_dnorm()))` -> params `M.<year>.<step>` (random=TRUE by default), `M.proj.dnorm.mean/stddev`, `proj_dnorm_M_weight` [run].
- `by_stock` must be `FALSE`, a stock or list of stocks; `TRUE`/"species" -> error "by_stock = TRUE not supported for g3_param_project(), must be explicit stock objects" (R/param_project.R:453-462).
- **Quirk**: with explicit stocks the default weight name becomes `paste("proj", name, c(by_stock, param_name), "weight", sep="_")` collapsed with "." -> `proj_logar1_fish_imm_weight.proj_logar1_rec_weight` [run, also in vignettes/articles/random-effect-recruitment.Rmd:135].
- Distributions (return `list(name, nll, project)`):
  - `g3_param_project_dnorm(mean_f = "proj.dnorm.mean"(0), stddev_f = "proj.dnorm.stddev"(1), from_year_f=NULL, to_year_f=NULL)`
  - `g3_param_project_dlnorm(lmean_f ("proj.dlnorm.mean" 1e-5 LOG), lstddev_f ("proj.dlnorm.stddev" 0.2 LOG), ...)` -- **linear-space parameters since 0.14** (NEWS.md:46)
  - `g3_param_project_rwalk(mean_f (0), stddev_f (1))`
  - `g3_param_project_ar1(phi_f = "proj.ar1.phi"(0.8, [0,1], fixed), stddev_f(1), level_f = "proj.ar1.level"(0), ...)`
  - `g3_param_project_logar1(phi_f(0.8), lstddev_f ("proj.logar1.stddev" 0.2 LOG), loglevel_f ("proj.logar1.level" 1 LOG), ...)`
  - `g3_param_project_bootstrap(from_year_f = quote(start_year), to_year_f = quote(end_year), block_size_f = 1L)` -- (block) bootstrap of existing years, nll = 0, new in 0.15-1 (NEWS.md:7). Whole years copied so per-step patterns kept.
  - `from_year_f/to_year_f` on dnorm/dlnorm/ar1/logar1: use the mean of existing (finite) values between those years instead of the mean/level parameter; setting either ignores `*_f` level parameter. Years removed by `retro_years` or already projected are NaN and ignored (R/param_project.R:1-26, NEWS.md:8).
  - ar1/logar1: `lastx_f` removed in 0.15-1; level now the log of the arithmetic mean for logar1; negative levels no longer clamped (NEWS.md:11-13).
  - Parameter names for the distribution parameters: `(by_stock).<param_name>.proj.<dist>.<param>` e.g. `fish_imm.rec.proj.logar1.level` (the Rd text says `proj.loglevel`, code is `proj.logar1.level`).
- Reporting names: `proj_<dist>_<param_name>__var|__lvar|__nll`; included automatically by `g3a_report_detail` via regex `^proj_`.
- Needs `ADREPORT` of projection totals (R/param_project.R:511-512).

### 5.7 Quotas / `retro_years` / `project_years`

- `project_years` (param, default 0): run extra years beyond `end_year`; `cur_year_projection` TRUE for them; renewal uses `rec.proj` (when `run_projection = TRUE`, default); `g3_parameterized(by_year = 1998:2099)` form guarantees enough per-year params. Change it in the **parameter template**, not in `g3a_time()`: `g3_init_val("project_years", 40)` (vignettes/articles/random-effect-recruitment.Rmd:187,202). For TMB prefer `g3_tmb_fn()` for projection runs since `project_years` changes array dims (NEWS 0.14 `g3_tmb_fn` #237, NEWS.md:39).
- `retro_years` (param, default 0): finish `retro_years` years early for retrospective analyses (`true end = end_year - retro_years + project_years`, man/action_time.Rd).
- `g3_quota*`: see 3.8.

### 5.8 Time-varying helpers

- `g3_timeareadata(lookup_name, df, value_field = 'total_weight', areas = NULL)` -- returns formula looking up `df[[value_field]]` for current `cur_year`, `cur_step`, `area`, `age` depending on which columns exist in `df` (any of age, area, year, step); no match -> 0; a df with only a single `area` value wraps `if (area != our_area) 0 else ...` (R/timedata.R:89-157). Key packing assumes steps < 12.., ages within a power of 10 of the max in data ("a bit of a shaky assumption" R/timedata.R:127-130). `lookup_name` must be unique.
- `g3_timevariable(lookup_name, fs)` -- gadget2-style "timevariable": named list of formulas: first **must** be named `init` (value at start), then `"1999"` (step 1) or `"1999-02"` (year-step) entries that replace the value from that time onward (R/timevariable.R:1-31). Prefer `g3_timeareadata` or `by_year`.

---------------------------------------------------------------------

## 6. Model compilation and running

### 6.1 Minimal end-to-end recipe (assembled from vignettes/introduction-single-stock.Rmd)

```r
library(gadget3); library(dplyr)
area_names <- g3_areas(c('IXa', 'IXb'))
fish <- g3_stock("fish", seq(10, 100, 10)) |> g3s_livesonareas(area_names["IXa"]) |> g3s_age(1L, 5L)
f_surv <- g3_fleet("f_surv") |> g3s_livesonareas(area_names["IXa"])

actions <- c(
  list(g3a_time(1990L, 2023L, step_lengths = c(3L, 3L, 3L, 3L))),
  list(g3a_growmature(fish, g3a_grow_impl_bbinom(maxlengthgroupgrowth = 4L)),
       g3a_naturalmortality(fish),
       g3a_initialconditions_normalcv(fish),
       g3a_renewal_normalcv(fish, run_step = 2),
       g3a_age(fish),
       g3l_understocking(list(fish), nll_breakdown = TRUE)),
  list(g3a_predate_fleet(f_surv, list(fish),
         suitabilities = g3_suitability_exponentiall50(),
         catchability_f = g3a_predate_catchability_totalfleet(
           g3_timeareadata("landings_f_surv", landings_f_surv, "weight", areas = area_names))),
       g3l_catchdistribution("ldist_f_surv", obs_data = ldist_f_surv, fleets = list(f_surv),
         stocks = list(fish), function_f = g3l_distribution_sumofsquares(),
         area_group = area_names, report = TRUE, nll_breakdown = TRUE),
       g3l_abundancedistribution("dist_si_cpue", dist_si_cpue, stocks = list(fish),
         function_f = g3l_distribution_surveyindices_log(alpha = NULL, beta = 1),
         area_group = area_names, report = TRUE, nll_breakdown = TRUE)))

model_code <- g3_to_tmb(c(actions, list(g3a_report_detail(actions), g3l_bounds_penalty(actions))))
params.in <- attr(model_code, "parameter_template") |> g3_init_val("*.M.#", 0.15, lower = 0.001, upper = 10) |> ...
obj.fn <- g3_tmb_adfun(model_code, params.in)                     # compiles C++ & MakeADFun
fit <- nlminb(obj.fn$par, obj.fn$fn, obj.fn$gr, lower = g3_tmb_lower(params.in), upper = g3_tmb_upper(params.in))
# (or optim(...method="L-BFGS-B", control=list(parscale=g3_tmb_parscale(params.in))); or gadgetutils::g3_iterative() / g3_optim())
params.out <- g3_tmb_relist(params.in, fit$par)                    # back to a named list/value column
res <- obj.fn$report(g3_tmb_par(params.in))                        # list of reports (dstart_*, nll_*, ...)
```

### 6.2 `g3_to_r(actions, work_dir, trace = FALSE, strict = FALSE, cmp_options = list(optimize = 3))` (R/run_r.R:5)

- Produces an R function `function(param = parameter_template)` of class `c("g3_r","function")` with attributes `actions` and `parameter_template` (R/run_r.R:226,269-272). `param` may be a **named list** (values) or a **data.frame template**; list values for LOG params are logged internally (R/run_r.R:229-244; NEWS 0.13 "will accept both list & data.frame", NEWS.md:55).
- Return value: the final `nll` (numeric) with **attributes = every `REPORT()`ed variable**: `attr(res, "dstart_fish__num")`, `attr(res, "nll_cdist_..._model...")`, etc. (`g3_env$REPORT`, R/aab_env.R:67-71; vignette: `attr(simple_fn(params), "dstart_fish__num")`). R always has reporting on (`reporting_enabled <- 1L`, R/run_r.R:21). `ADREPORT` is a no-op in R (R/aab_env.R:73-76).
- `trace = TRUE` prints each `debug_label` (action description) via `Rprintf` at run time; `trace = 'full'` also prints `debug_trace` steps; `strict = TRUE` enables `strict_mode` checks (e.g. conservation of numbers in `g3a_growmature`, R/action_grow.R:467-492; `stock_assert()` messages as warnings, `assert_msg` R/aab_env.R:104-110).
- The function body is generated R text written to `work_dir/g3_r_<sha1>.R` and sourced so a srcref exists (RStudio debugging works, NEWS 0.11); byte-compiled with `cmp_options`. `edit(fn)` opens the code (S3 `edit.g3_r`, R/run_r.R:298), `print(fn, with_environment = TRUE, with_template = TRUE)` shows data/parameters.
- Environment closure holds data; model data is ordinary R objects so arbitrary R functions can be used inside formulas under R, but not in TMB (vignettes/writing_actions.Rmd:34-52). `g3_native(r =, cpp =)` is the bridge.
- R semantic = TMB semantic (same code generator), but the R model is much slower; use for debugging and projections via `fn(params)`.

### 6.3 `g3_to_tmb(actions, trace = FALSE, strict = FALSE)` (R/run_tmb.R:709)

Returns a character vector (class `g3_cpp`) of C++ source (print shows code; `edit()` opens `.cpp`). Attributes: `actions`, `parameter_template` (data.frame), `model_data` (environment of DATA_ items), plus `report_renames`, `report_names`, `report_dimnames`, `report_gen_dimnames` (used to restore dimnames on `$report()` output) [run: names(attributes(m))]. Header comment records the gadget3 version; `#include <TMB.hpp>`.
- `reporting_enabled` is a TMB `DATA_SCALAR` (default 0 -> history/report arrays not even filled); `obj$report()` / `obj$simulate()` flip it to 1 temporarily (R/run_tmb.R:1305-1325). Therefore: `obj.fn$fn()` is fast; `obj.fn$report(par)` gives reports.

### 6.4 `g3_tmb_adfun(cpp_code, parameters, compile_flags, work_dir, output_script, compile_args, ...)` (R/run_tmb.R:1118)

- Compiles with `TMB::compile` (flags `-std=gnu++17 -Wno-ignored-attributes -DEIGEN_PERMANENTLY_DISABLE_STUPID_WARNINGS` + `compile_flags`, default `-O3 -flto=auto -march=native` (Windows: `-O1 -march=native`); framework `getOption("gadget3.tmb.framework", "TMBad")`), then `dyn.load` and `TMB::MakeADFun`. Library name = `g3<gadget3 ver>_tmb<TMB ver>_<sha1(code+args)>` in `work_dir` so identical code isn't recompiled in the session and `work_dir` can persist across sessions (`options(gadget3.tmb.work_dir = fs::path_abs('tmb-workdir'))`) (R/run_tmb.R:1203-1218; man/run_tmb.Rd).
- `parameters`: the data.frame template (modified) **or** a plain list of values (merged into the model's template, `I(parameters[switch])`, R/run_tmb.R:1136-1141).
- Mapping to TMB: `optimise == FALSE & random == FALSE` -> `map = factor(NA)` (fixed); `random == TRUE` -> `random=` (Laplace); `LOG` types logged (R/run_tmb.R:1171-1190). Needs at least one `optimise` or `random` parameter ("Set at least one optimisable parameter to run under TMB", also true for `g3_tmb_fn` which forces all optimisable internally).
- `...` goes to `MakeADFun`: `type = "Fun"` (no AD gradient; values only), `silent = TRUE`, `control = list(trace = 2)`, `inner.control = list(trace=3, maxit=1000, tol=1e-7)`, `ADreport`, etc.; `'Type'` argument warns ("use 'type'"). Since NEWS 0.14 the ADGrad function isn't generated unless random effects (#234).
- `output_script = TRUE`: returns path of an R script that rebuilds the ADFun for use with `TMB::gdbsource` (vignettes/model-debugging.Rmd:89-113).
- The returned `fn` has `report()`/`simulate()` wrappers that restore names/dimnames of arrays (`report_patch`, R/run_tmb.R:1277-1325) and `fn$par` (R/run_tmb.R:1326).

Helpers:
- `g3_tmb_par(parameters, include_random = TRUE)` = values for `obj$fn(par)`/`obj$report(par)` (use with `obj.fn$report(g3_tmb_par(params))`). **Errors if called inside `optim`/`nlminb`** ("Don't use g3_tmb_par() with nlminb/optim, use obj.fun$par", NEWS 0.9 NEWS.md:151); `obj.fn$par` already is the right starting vector.
- `g3_tmb_lower/upper/parscale(parameters)` = named vectors for **optimise params only** (random excluded), LOG types logged, vectors expanded (R/run_tmb.R:1376-1414).
- `g3_tmb_relist(parameters, par)` -> list (value of every param, optimised replaced from `par`, LOG back-transformed; accepts `par` with or without random params; "Names of values in par don't match names of parameters$value" otherwise) (R/run_tmb.R:1416-1450; NEWS 0.15-0 fixed double-exp of fixed params #260). Pass result to the R model, or `g3_init_val`... to rebuild a template.
- `g3_tmb_fn(cpp_code, def.parameters, ...)`: single-run/projection function `function(parameters = NULL)` using `type = "Fun"`+`simulate()`; all parameters (including `project_years`) are adjustable per call, successive calls re-draw random projections, returns the list of reports. Parameters can be NULL / a template / a list (R/run_tmb.R:1329-1373; vignettes/articles/random-effect-recruitment.Rmd:172-205).

### 6.5 Reports: `g3a_report_detail`, `g3a_report_history`, `g3a_report_stock`

- Everything `REPORT()`ed is returned (R: attributes of nll, TMB: `$report()` list). Dimnames: stock arrays carry named dims (`length`, `area`, `age`, `tag`, `time`).
- `g3a_report_detail(actions, run_f = report_detail param == 1, abundance_run_at = report_early, run_at = report)` (R/action_report.R:177-211) bundles three `g3a_report_history` calls:
  1. regexes `^.+_surveyindices_.+__params$`, `^step_lengths$`, `^_weight$`, sparse nll vars, `^quota_`, `^proj_`, `^nll$` (no history prefix) -> reported once at end;
  2. `__num$`, `__wgt$` -> history arrays `dstart_<stock>__num|wgt` [dims ... x time] (prefix `dstart_` when `abundance_run_at == report_early` else `detail_`);
  3. `__renewalnum$`, `__spawnednum$`, `__cons$`, `__suit$`, `__suit_`, `__predby_` -> `detail_<...>` e.g. `detail_fish_f_surv__cons`, `detail_fish__renewalnum`, `detail_fish_f_surv__suit`, old name `detail_fish__predby_f_surv` [run].
  Models should include `g3a_report_detail(actions)` for `gadgetutils::g3_fit()` / `gadgetplots::gadget_plots()` (vignettes/introduction-single-stock.Rmd:602-607); the `report_detail` parameter (default 1) lets you turn off the bulky history without recompiling.
- `g3a_report_history(actions, var_re = "__num$|__wgt$", out_prefix = "hist_", run_f = TRUE, run_at = report)`: stores a time-dimensioned copy of any variable matching `var_re` found in `actions` (`hist_<stock>__num` etc.), reported at the end of run (`cur_time > total_steps`). Pass `out_prefix = NULL` to just report the final value. Arrays whose dims already contain `time` are reported as-is. History arrays have `time` as last dim (labels "1990-01", ..., see `g3a_time` micro-model `gen_dimnames`, R/action_time.R:94-103); with `total_steps+1` entries.
  - **Run at report (11)** = end-of-step state ("late"); with `report_early` = start of step.
  - `g3a_report_history(actions, "__cons")` etc. for custom selections; `"__num$|__wgt$"` default matches every stock `__num/__wgt` including likelihood/nll helper arrays.
- `g3a_report_stock(report_stock, input_stock, report_f, include_adreport = FALSE, run_f = TRUE, run_at = report)`: aggregate `input_stock` into a (coarser) `report_stock` (e.g. total by age) every step and report `report_stock__<inst>`; `include_adreport` ADREPORTs the final value (R/action_report.R:1-41). `report_f` must contain a stock variable (`stock_ss(input_stock__num)`).
- **Reading reports**: `g3_array_agg(ar, margins = c('age','year'), age = 2:4, step = 1)`: filter/aggregate; `"time"` split into `year`/`step` automatically unless `time` is a margin/filter (opt_time_split); numeric `age` -> `"age3"`; numeric `length` picks containing group; `agg = "sum"|"length_mean"|"length_sd"|"predator_length_*"` or a function. `g3_array_combine(list_of_arrays, agg = sum, init_val = 0)` unions arrays with disjoint dims (e.g. imm+mat). `g3_array_plot(ar)` (<=2 dims). (R/array_utils.R; man/array_utils.Rd)
- Example from the vignette: `g3_array_agg(attr(fn(params), "dstart_fish__num"), c('age','length'), time = "1990-01")`.

### 6.6 Debugging tools (vignettes/model-debugging.Rmd)

- **View/edit code**: `edit(g3_to_r(actions))` (R) / `edit(g3_to_tmb(actions))`; add `recover()`/`browser()`; the R model is srcref'ed (RStudio breakpoints). `print(model_fn)`, `print(model_fn, with_environment=TRUE)`.
- **NaN hunting**: `g3a_trace_var(actions, check_finite = TRUE, check_positive = FALSE, check_strictly_positive = FALSE, on_error = c("continue","browser","stop"), print_var = FALSE, var_re = c("__num$","__wgt$"))`: adds a check step after every action that assigns a matching variable; on first failure prints `"<var> failed test at <year>-<step>, after '<action label>'"` and optionally drops into `browser()` or stops (R/action_trace.R:1-93; NEWS 0.14 NEWS.md:37 -- based on `g3experiments::g3a_trace_nan`). Idiom:
  ```r
  tmb_model <- g3_to_tmb(c(actions, list(g3a_report_detail(actions), g3a_trace_var(actions), g3l_bounds_penalty(actions))))
  obj.fn <- g3_tmb_adfun(tmb_model, params.in, type = "Fun"); r <- obj.fn$report()
  ```
  (use when optim says "initial value in 'vmmin' is not finite").
- `g3a_trace_timings(actions, action_re = NULL)`: adds timing counters per step; reports `trace_timings` matrix (rows = steps, cols total/min/max/mean seconds) (R/action_trace.R:95-157; NEWS 0.14 #235).
- `g3_to_desc(actions, minor_steps = FALSE)`: named vector of step descriptions (the `debug_label`s) in model order -- a quick outline of the model (R/run_desc.R).
- `trace = TRUE` in `g3_to_r` / `g3_to_tmb`: prints the label of every executed step at run time (`Rprintf`); `'full'` adds `debug_trace` lines. `strict = TRUE`: extra sanity checks (warnings).
- `g3_eval(f, ...)`: evaluate a formula/snippet in a g3-ish environment (named args become variables; stocks make `stock_with` wrap automatically; `g3_param('x')` resolves to the arg `param.x`) (R/eval.R:2-54): e.g. `g3_eval(~stock_iterate(s, stock_reshape(agg, stock_ss(s__num))))`.
- TMB crashes the R session: `writeLines(TMB::gdbsource(g3_tmb_adfun(tmb_ling, tmb_param, compile_flags = "-g", output_script = TRUE)))`; interactive gdb via `R -d gdb`; `.print()` of arrays only compiles if referenced (vignettes/model-debugging.Rmd:89-150). Random-effect debugging: `inner.control = list(trace = 3, maxit = 100)`, `obj.fn$env$tracepar <- TRUE; $tracemgc; $silent <- FALSE`.
- Source-level notes in notes/tmb-gotchas.Rmd: TMB arrays are 1-D under the hood; the model must return something dependent on at least one parameter; `vector = single` not allowed (use `setConstant`); `lgamma(expr)` macro needs a single symbol; no `vector<int>`->`vector<Type>`; Eigen subsetting is by reference (use `.vec()`/copy; see `__postmigrate*` in R/action_migrate.R).

### 6.7 Customisation patterns (vignettes/model-customisation.Rmd is a stub: only the `g3_parameterized` example)

- Change a default parameterisation: pass your own `g3_parameterized(...)`:
  `g3a_naturalmortality(fish, g3a_naturalmortality_exp(g3_parameterized("M", by_stock = TRUE, by_age = FALSE)))` (single M); `by_year = TRUE` for time-varying; `by_stock = 'species'` to share between imm/mat; `g3_suitability_exponentiall50(l50 = g3_parameterized("l50", by_stock = 'species', by_predator = TRUE, by_year = TRUE))` (vignettes/multiple-substocks.Rmd:339-343 -> params `fish.f_surv.l50.<year>`).
- Most `g3a_*`/`g3_suitability_*` accept `by_stock` (and `by_predator`) as a shortcut applied to all their default parameters (vignettes/multiple-substocks.Rmd:330-332).
- Write your own formula args with R `~` and refer to iterators (`age`, `area`, `length`, `stock__midlen`, `cur_year`, `cur_step`, `cur_step_size`, `stock_ss(stock__num)`, ...). Sub-formulas defined in the creating function are auto-included; those mentioning loop vars (`age`) are recomputed inside the loop, others once per step (vignettes/model-structure.Rmd:195-210).
- Custom action: `g3_formula(quote({ ... }), name = value)` or a list of named formulas with step names (`"-01:ut:parrot" = g3_formula(...)` ancillary step pattern, vignettes/writing_actions.Rmd:183-203); `g3_step()` expands `stock_*` calls; `step_id(run_at, "name")`. Use `g3_global_formula(f, init_val)` for model-global state (vignettes/writing_actions.Rmd:139-181), `g3_native(r, cpp, depends)` for R/C++ function pairs.
- Avoid constructs that gadget3 can't translate: only a subset of R is converted to C++ ("we're not generically converting R into C++", vignettes/model-structure.Rmd:85-88). Typing: `3L` for integers, `array(...)` to force arrays (vignettes/writing_actions.Rmd:122-137).
- Model code can be emitted by `g3_to_r(list(f))` for an ad-hoc formula `f` (vignettes/model-structure.Rmd:62-74).

### 6.8 Global environment functions available in formulas (`g3_env`, R/aab_env.R, R/env_dif.R)

`avoid_zero(a)` (= `dif_pmax(a, 0, 1e3)`, smooth max with 0), `normalize_vec(a)`, `bounded(x,a,b)`, `bounded_vec`, `nvl(...)` (R only), `logspace_add(a,b)`, `lgamma_vec`, `dpois`, `as_integer`, `as.numeric` (TMB asDouble), `as_numeric_arr/vec`, `ratio_add_pop(orig_vec, orig_amount, new_vec, new_amount)`, `nonconform_add/mult/div(_avz)` (broadcast vector over array), `REPORT`, `ADREPORT`, `Rprintf`, `REprintf`, `warning`, `assert_msg`, `print_array`, `named_vec_to_factor`; differentiable `dif_pmax(a,b,scale)`, `dif_pmin(a,b,scale)`, `dif_pminmax(a,lower,upper,scale)` (scale ~1e5; logspace-add based, R/env_dif.R; man/env_dif.Rd). Standard statistical functions (`dnorm`, `rnorm`, `exp`, `log`, `sum`, `mean`, `%*%`, `pnorm`, vectorised arithmetic, `ifelse`-like `if/else`, `for`, `seq`, `array`...) are translated by `cpp_code()` (R/run_tmb.R:7-700).

---------------------------------------------------------------------

## 7. Vignette summaries (vignettes/ and vignettes/articles/)

pkgdown article order (_pkgdown.yml): *User guides* = introduction-single-stock, incorporating-observation-data, multiple-substocks, model-customisation, articles/random-effect-recruitment, model-debugging; *Advanced* = model-structure, writing_actions.

### 7.1 `introduction-single-stock.Rmd` (758 lines) -- "Introduction to gadget3: A single stock model"

Walks through a complete single-species, single-area script that generates random data, builds actions, compiles, parameterises and (optionally, `G3_TEST_TMB=1`) optimises with `gadgetutils::g3_iterative()` and plots with `gadgetplots::gadget_plots()`. Explains the gadget framework (gadget3 core; MFDB for data aggregation; gadgetutils; gadgetplots; g3experiments; modelwizard; gadget2to3 per README), that there is **no input file format** (the script is the model), that *actions* are formulas lists re-ordered by `g3_action_order`, how defaults define *model parameters* (e.g. `g3a_naturalmortality` -> `fish.M.<age>`), how to compile to R/TMB, how landings / length / age-length data are aggregated with `cut(..., right = FALSE)`, fleets as stock objects that predate, survey indices as `g3l_abundancedistribution`, and how to fill the parameter template with `g3_init_val`.
Key idioms:
```r
actions_time <- list(g3a_time(1990L, 2023L, step_lengths = c(3L, 3L, 3L, 3L)))
fish <- g3_stock("fish", seq(10, 100, 10)) |> g3s_livesonareas(area_names["IXa"]) |> g3s_age(1L, 5L)
actions_fish <- list(
  g3a_growmature(fish, g3a_grow_impl_bbinom(maxlengthgroupgrowth = 4L)),
  g3a_naturalmortality(fish), g3a_initialconditions_normalcv(fish),
  g3a_renewal_normalcv(fish, run_step = 2), g3a_age(fish))
actions_likelihood_fish <- list(g3l_understocking(list(fish), nll_breakdown = TRUE))
# run once in R and inspect:
simple_fn <- g3_to_r(c(simple_actions, list(g3a_report_detail(simple_actions))))
params <- attr(simple_fn, 'parameter_template'); params$fish.K <- 0.3 ...
g3_array_plot(g3_array_agg(attr(simple_fn(params), "dstart_fish__num"), c('age','length'), time = "1990-01"))
# data
expand.grid(year = 1990:2023, step = 2, area = 'IXa', length = rep(NA, 100)) |> mutate(length = rnorm(n(), 50, 20)) |>
  group_by(year = year, step = step, length = cut(length, breaks = c(seq(0, 80, 20), Inf), right = FALSE)) |>
  summarise(number = n(), .groups = 'keep') -> ldist_f_surv
f_surv <- g3_fleet("f_surv") |> g3s_livesonareas(area_names["IXa"])
g3a_predate_fleet(f_surv, list(fish), suitabilities = g3_suitability_exponentiall50(),
  catchability_f = g3a_predate_catchability_totalfleet(g3_timeareadata("landings_f_surv", landings_f_surv, "weight", areas = area_names)))
g3l_catchdistribution("ldist_f_surv", obs_data = ldist_f_surv, fleets = list(f_surv), stocks = list(fish),
  function_f = g3l_distribution_sumofsquares(), area_group = area_names, report = TRUE, nll_breakdown = TRUE)
g3l_abundancedistribution("dist_si_cpue", dist_si_cpue, stocks = list(fish),
  function_f = g3l_distribution_surveyindices_log(alpha = NULL, beta = 1), area_group = area_names, report = TRUE, nll_breakdown = TRUE)
model_code <- g3_to_tmb(c(actions, list(g3a_report_detail(actions), g3l_bounds_penalty(actions))))
# fit: obj.fn <- g3_tmb_adfun(model_code, params.in); params.out <- gadgetutils::g3_iterative(getwd(), wgts = "WGTS",
#   model = model_code, params.in = params.in, grouping = list(fleet = c("ldist_f_surv","aldist_f_surv"), abund = c("dist_si_cpue")),
#   method = "BFGS", control = list(maxit = 1000, reltol = 1e-10), cv_floor = 0.05)
# fit <- gadgetutils::g3_fit(model_code, params.out); gadgetplots::gadget_plots(fit, "figs", file_type = "html")
```
Facts stated: the single-stock parameter template has names `fish.K, fish.Linf, fish.M.1..5, fish.init.1..5, fish.init.scalar, fish.lencv, fish.t0, fish.walpha, fish.wbeta, init.F, project_years, recage, report_detail, retro_years` (L264-282, test `ok(ut_cmp_identical(...))`). Landings data without all steps => fleet only fishes in listed year/steps. TMB template columns documented at L620-631 (switch, type, value, optimise, random, lower, upper, parscale, source).

### 7.2 `incorporating-observation-data.Rmd` (407 lines)

Details how `g3l_catchdistribution` / `g3l_abundancedistribution` turn an `obs_data` data.frame into the comparison array. Sections: two-stage aggregate/compare; **gadget2 <-> gadget3 translation** (CatchDistribution, SurveyIndices, CatchInKilos); the observation data format by column (`weight`/`number`, `year`/`step`, `length`, `age`, `area`, `stock`, `fleet`, `predator`) with `g3_distribution_preview()` outputs for each; MFDB attributes (`mfdb_sample_count`) are read automatically; `cut()`-factor bins create zero-filled gaps (factor knows empty bins) whereas missing rows of hand-written strings give `NA` (-> `missing_val`); partial stock/fleet names; "a stock can only appear in one grouping".
Idioms:
```r
g3_distribution_preview(read.table(header = TRUE, text="year step number\n1999 2 1020\n2000 2 2040\n2001 3 1902"))
g3_distribution_preview(ldist.lln.agg)                        # factor length from group_by(length = cut(...))
g3_distribution_preview(df_with_area, area_group = area_names)[length = '0:Inf',,]
g3_distribution_preview(df_with_stock, stocks = list(st_imm, st_mat))
g3_distribution_preview(df_with_fleet, fleets = fleets)       # names or parts: 'comm', 'surv_se'
```

### 7.3 `multiple-substocks.Rmd` (496 lines) -- "Modelling maturity & sex with multiple stocks"

Extends the intro to immature + mature stocks (`c(species="fish",'imm')`), `maturity_f = g3a_mature_continuous()`, `output_stocks`, `transition_f = ~TRUE`, `g3a_age(st_imm, output_stocks = list(st_mat))` (oldest immature mature by default), no renewal for mature, shared `by_stock='species'` suitability parameters, stock-column maturity data (`matp_f_surv` with `stock = "imm"|"mat"` partial names), `g3l_understocking(stocks)`, survey index over `stocks`. Shows param template effects: `by_stock = TRUE` -> `fish_imm.f_surv.l50` & `fish_mat.f_surv.l50`; `'species'` -> `fish.f_surv.l50`; custom `g3_parameterized("l50", by_stock='species', by_predator=TRUE, by_year=TRUE)` -> `fish.f_surv.l50.<year>` (L288-353, with tested expected names). Parameter fill-in uses wildcards that work for both single/multi stock: `g3_init_val("*.mat.alpha", ...)`, `"*.mat.l50"`, `"*.bbin"` etc.

### 7.4 `model-structure.Rmd` (314 lines) -- "Structure of a gadget3 model"

Bottom-up explanation: formulas (code + captured environment), compiled by `g3_to_r(list(f))`/`g3_to_tmb`; actions (`g3a_time(1990, ~start_year + 4)` formula arguments allowed); stocks (`g3_stock`, `g3_fleet`, `g3s_*`, `g3_stock_instance`); how formula args see loop vars (`age`, `area`) and sub-formulas that depend on loop vars are recomputed in-loop (`custom_delta_l <- ~area*99`) vs once per step; parameterisation (`g3_param("ling.bbin")` -> `param[["ling.bbin"]]`, `g3_param_vector`, `g3_param_table`); combining actions in any order; **ordering of actions** via step names `NNN:MMM:stock:hash` -- sorted, **deduplicated by name**, hash guarantees repeated calls don't clash while shared steps (overconsumption `003:004`) happen once.
Idioms:
```r
fn <- g3_to_r(g3a_growmature(ling_imm, impl_f = g3a_grow_impl_bbinom(delta_len_f = ~age * 10, delta_wgt_f = ~area * 20,
        beta_f = ~g3_param("ling.bbin"), maxlengthgroupgrowth = 4), transition_f = ~TRUE))
names(g3a_predate_fleet(lln, list(ling_imm), suitabilities = list(ling_imm = g3_suitability_exponentiall50(~g3_param('ling.lln.alpha'), ~g3_param('ling.lln.l50'))), catchability_f = g3a_predate_catchability_totalfleet(1)))
```
(`suitabilities` list names must match prey stock names; unnamed element = default.)

### 7.5 `model-customisation.Rmd` (23 lines) -- stub

Only contains `TODO:` and one example: `g3a_naturalmortality(fish, g3a_naturalmortality_exp(g3_parameterized("M", by_stock = TRUE, by_age = FALSE)))` to get a single M parameter instead of per-age. See also 6.7 here and `man/params.Rd` examples (`param_template_for(g3_parameterized('K', by_stock = TRUE, by_year = TRUE, by_age = TRUE))`).

### 7.6 `model-debugging.Rmd` (226 lines)

Debug recipes: view/edit generated code (`edit(model_fn)`, `edit(tmb_model)`, `g3_tmb_adfun(..., type = "Fun")$report()`), NaN tracing via `g3a_trace_var`, optim error "initial value in 'vmmin' is not finite", TMB verbosity (`control = list(trace = 2)`, `inner.control`, `obj.fn$env$tracepar/tracemgc/silent`), crash debugging via `TMB::gdbsource(g3_tmb_adfun(..., compile_flags = "-g", output_script = TRUE))` and manual `R -d gdb`, random-effect (newton) debugging messages ("Trying early exit - PD Hess?", missing value for `m`, `par - parold`), extracting newton args by editing `obj.fn$env$ff`.

### 7.7 `writing_actions.Rmd` (203 lines)

For action authors: G3 functions (`g3_param`...), the global environment `g3_env` (avoid_zero..., see R/aab_env.R), R functions in formulas under R only vs `g3_native(r =, cpp =)` for both, `g3_step()` and the `stock_*` language (`debug_label`, `stock_with`, `stock_iterate`, `stock_ss`, `stock_intersect`, example from action_mature), R->C++ typing rules (use `array()` to force arrays; numeric constants become `double`, use `3L` for ints), sub-formulas & `g3_global_formula(f, init_val)` (global counters), ancillary steps hidden in a formula's environment under names like `"-01:ut:parrot"` (inserted at model start; step name pattern `^(\d|-)\d{2}:`).
```r
model_fn <- g3_to_r(list(g3a_time(1990, 1990), g3_formula(nll <- nll + fn(9), fn = function (x) x * 10 )))
normalize_vec <- g3_native(r = function (a) a / sum(a), cpp = '[](vector<Type> a) -> vector<Type> { return a / a.sum(); }')
g3_to_r(list(g3a_naturalmortality(st_imm, g3_formula(parrot**2, parrot = 0, "-01:ut:parrot" = g3_formula({ parrot <- runif(1) })))))
```

### 7.8 `articles/random-effect-recruitment.Rmd` (224 lines) -- "Random effects & projections"

Shows `g3_param_project()` as random-effect time-series parameters, the likelihood relating the elements, and projection. Model: single stock, abundance data for ages 4 & 5 with `g3l_distribution_surveyindices_log(alpha = 0, beta = 1)` (fixed so abundance should match); renewal defined by `factor_f = g3_param_project("rec", g3_param_project_logar1(), scale = "scalar", by_stock = stocks, by_step = FALSE)` and `run_step = 1`. Compare optimisation with recruitment as fixed effects (`g3_init_val("*.rec.#", value = 2e3, lower = 1e1, upper = 1e6, random = FALSE)`) vs random (`random = TRUE`, bounds cleared) with `g3_tmb_adfun(model_cpp, params, inner.control = list(trace = 0, maxit = 1000, tol = 1e-3))` and `gadgetutils::g3_optim`. Projections with `fn <- g3_tmb_fn(model_cpp)`; `fn(params.rndout |> g3_init_val("project_years", 40))$dend_fish_imm__num` -- successive calls give different random projections (plot 20). Needs late reporting for `dend_` history (`g3a_report_history(actions, "__num$|__wgt$", out_prefix = "dend_")`). Parameters seen: `*.rec.#`, `fish_imm.rec.proj.logar1.level|stddev` (optimised hyper-parameters) and `proj_logar1_fish_imm_weight.proj_logar1_rec_weight` (relative weight of the random-effect nll). Notes: "sdreport only works with nlminb()" TODO in source.

---------------------------------------------------------------------

## 8. Pitfalls and conventions

### 8.1 Conventions that matter

1. Build the model as a **flat list of actions** (`actions <- c(actions, actions_fish, ...)`); order is irrelevant, `NULL` entries are fine (vignettes end lists with `NULL`). Wrap in `g3_to_tmb(c(actions, list(g3a_report_detail(actions), g3l_bounds_penalty(actions))))` -- the report/bounds actions must be handed `actions` so they can inspect variables/parameters.
2. Use **multi-part stock names** (`c(species='fish','imm')`) from the start; they unlock `by_stock = 'species'`, partial names in likelihood data, and `g3_init_val("*.mat.l50")` wildcards that work for both single- and multi-stock scripts.
3. Always pass `maxlengthgroupgrowth = 4L` (integer) to `g3a_grow_impl_bbinom`.
4. Always pass `prey_stocks`, `output_stocks`, `stocks`, `fleets` as **lists** (`list(fish)`), even single ones (`stopifnot(is.list(...))` in predate/distribution).
5. Fill the template with `g3_init_val()` wildcards; **never reorder rows** of `parameter_template`; check output with `warning`s ("didn't match any parameters").
6. Landings: `g3_timeareadata()` returns 0 when year/step/area missing => no fishing for that cell (not an error). Survey/length data: gaps in year/step skip comparison, gaps in other dims compare as 0 (`missing_val`).
7. Bin observation data with `cut(..., right = FALSE)` and an `Inf` upper break (plus group). Length bins in data need **not** equal stock bins (re-aggregated); but they must be contiguous & inclusive-lower.
8. Units: time steps in **months summing to 12**; `K`, `M` per **year** (multiplied by `cur_step_size`); lengths in whatever unit your `lengthgroups` use; weights `walpha*L^wbeta` must match the weight unit of your data (landings 'weight' is the same unit as `stock__wgt*num`).
9. Name your fleets/stocks without dots (dots separate parameter-name parts; underscores join name parts).
10. **Optimise on scaled values / bounds**: use `spread`/`lower`/`upper` so `parscale` is filled automatically; TMB gradient-based fits need the bounds penalty or box constraints (`g3_tmb_lower/upper`).

### 8.2 Pitfalls derived from source/comments/NEWS

- **Parameter `optimise` defaults to FALSE** unless both bounds exist (NEWS 0.14, NEWS.md:43). An un-initialised template optimises nothing -> `g3_tmb_adfun` error "No parameters with optimise=TRUE or random=TRUE". Old docs say default TRUE (`man/language.Rd`).
- `g3_tmb_par(params)` **cannot be used as the start vector** for `optim`/`nlminb` (error); use `obj.fn$par`; for single evaluations `obj.fn$fn(g3_tmb_par(params))`. `g3_tmb_par` includes random params by default, `obj.fn$par` doesn't (NEWS 0.9, NEWS.md:151; man/run_tmb.Rd).
- `*_exp` parameters (e.g. `andersen.p3_exp`, `spawn.R.<y>_exp`, `rec.<y>_exp` when `exponentiate = TRUE`) are on **log scale in the template** (value = log of true value); `g3_init_val(auto_exponentiate = TRUE)` takes your linear-scale value/bounds and logs them for `_exp` names. Don't pre-log yourself.
- `type = "LOG"` params (param_project hyper-parameters) are logged internally and optimised in log space; template values stay linear; negative values rejected by `g3_init_val` (R/init_val.R:111-123); `g3_param_project_dlnorm/logar1` parameters are **linear-space** since 0.14 (NEWS.md:46).
- Parameters named without the stock (`init.F`, `recage`, `project_years`, `retro_years`, `report_detail`) are model-global; `init.F`/`recage` appear whenever `g3a_renewal_initabund` (initial conditions) is used and must be set (default value 0; the vignettes set `init.F = 0.5` and `recage = 0`, vignettes/introduction-single-stock.Rmd:295-296,679).
- Same-named parameters are shared silently: `lencv` is used by *both* `g3a_initialconditions_normalcv` and `g3a_renewal_normalcv`; `walpha/wbeta` shared between growth, renewal, spawn weights for the same stock; `by_stock = 'species'` shares across stocks. `g3a_spawn`/`g3a_renewal` use `rec.sd` and `lencv` separately (sd vs cv).
- **Duplicate action collapse**: actions whose calls deparse identically hash to the same step name and silently collapse (e.g. two identical `g3a_naturalmortality(stock)`); vary `run_f`/other args to make two (R/step.R:546-550).
- Renewal `g3a_renewal_*`: `run_step = 1` default, `run_age = stock__minage`; set `run_step = NULL` for every-step recruitment; set `run_projection = FALSE` to stop recruitment in projections. `stock__renewalnum` is **not zeroed** on non-renewal steps, so `detail_<stock>__renewalnum` repeats the last recruit numbers for later steps [run] -- filter by step in reports.
- `rec.scalar` multiplies `rec.<year>`; `rec.proj` (optimise=FALSE) is the recruitment used for years with no `rec.<year>` parameter (projection) -- remember to set it (default 0 => no recruits in projections).
- `g3a_mature_constant()` alone is 0.5 maturity: it only includes terms whose coefficient is non-NULL/non-zero (R/action_mature.R:44-74). `g3a_mature_continuous(beta=, a50=)` needs `a50`.
- `g3a_mature_continuous()` only makes sense in `g3a_growmature(maturity_f=)` (uses `growth_delta_l`); for age/length-constant maturity use `g3a_mature(stock, maturity_f = g3a_mature_constant(alpha, l50), ...)`.
- With `g3a_growmature(..., transition_f)` default `~cur_step_final`: maturation happens **only on the final step of the year** unless you pass `transition_f = ~TRUE` (vignette). Immature fish ageing past the immature `maxage` move to the mature stock via `g3a_age(output_stocks=)`.
- Fish that cannot be placed into output stock age/length groups in a transition stay behind (`move_remainder`), unless the transition is from `g3a_age` where they're dropped (R/action_mature.R:97-133, R/action_age.R:44-51).
- `g3a_age(stock)` without `output_stocks` creates a **plus group** at `maxage`; with `output_stocks` it doesn't.
- `g3a_age` handles stocks with age min==max specially (move-and-zero; NEWS 0.9 NEWS.md:137) and multiple areas (fixed in 0.15 #262).
- `g3a_predate` / understocking: cap `overconsumption_f = dif_pmin(consratio, 0.95, 1e3)` -> a fleet can never remove > ~95% of a prey cell per step; excess becomes `g3l_understocking` penalty (weight 1e8). Over-ambitious landings produce huge nll rather than an error. Always add `g3l_understocking(<all prey stocks>)`.
- `g3a_predate_catchability_totalfleet(E)`: `E` is **total biomass** to be taken *by the fleet in the current step/area*, spread across prey/length by suitability*abundance. Landings data per step: put `step` in the landings data.frame, otherwise the data is matched with `cur_year` only and each step would try to take the full annual landing.
- `g3a_predate_catchability_project`: the `interim_unit` argument is ignored (R/action_predate.R:39); `quota_f` unit comes from the attribute `catchability_unit` of the quota formula; `unit` is that of `landings_f`. `g3_quota(init_val = NaN)` must stay NaN to detect interim periods (man/quota.Rd); `run_historical` must be FALSE for the same reason.
- `g3a_predate_catchability_quotafleet`: `quota_table` columns must be exactly `biomass`,`quota` and last biomass `Inf` (stopifnot).
- `g3l_distribution_*` weights are **parameters** named `<cdist|adist>_<fn>_<nll_name>_weight` (set fixed; `optimise = FALSE`); gadgetutils iterative reweighting edits them.
- Likelihood data: `Unknown column in likelihood data` if an extra column exists (only `number`/`weight` allowed as observations; others must be recognised dimension columns -- `year, step, area, length, age, tag, stock, stock_re, fleet, fleet_re, predator, predator_re, predator_length|age|tag`). `time` strings accepted instead of year (R/likelihood_data.R:46-49).
- `stock` / `fleet` columns must name stocks passed to the same likelihood (`stocks=`/`fleets=`); unknown names -> error (NEWS 0.11 NEWS.md:84) and "groups matched no stock". Don't mix `stock` and `stock_re`.
- surveyindices comparisons: log-fit with `beta = 1` default (since 0.11); using `alpha = NULL, beta = NULL` fits both by regression inside the model each run (regression with very few points is degenerate [infer]); the regression is only evaluated at the last timestep of the data (`modelstock__time_idx == max`, R/likelihood_distribution.R:109).
- `g3l_distribution_sumofsquares` compares *proportions within each time/area* so total abundance level is not constrained by catch/age compositions -- use weight/number total-abundance components (`g3l_abundancedistribution` with no length/age) or landings to scale.
- `g3_parameterized(by_age = TRUE)` requires `by_stock`; `by_area = TRUE` requires `by_stock`/`by_predator` (stop messages in R/params.R:132,166).
- `g3_quota_hockeystick/hockeyfleet(stddev > 0)` formula looks wrong (see 3.8); leave at 0.
- `g3_param_project(by_stock = TRUE)` is an error (explicit stock objects only); `g3l_random_*` with per-stock tables error; both random-effects features can only use `random = TRUE` params and TMB (not R).
- `g3s_age(stock, min, max)` re-applied to an existing age stock modifies it; `g3s_tag(tag_ids)` must be integer (use `1L`, or `structure(seq_along(x), names = x)`).
- Because `g3_stock`'s first length group starts at `lengthgroups[1]`, **fish below** the first bound aren't modelled; recruits' length distribution is renormalised over the stock's `midlen` so a wrong mean/sd silently piles recruits into the first/last group (dnorm is normalised by `normalize_vec`, R/action_renewal.R:66) [infer].
- `g3a_initialconditions_*`: `age` is shifted by `cur_step_size` in `mean_f` (NEWS 0.10); so for models with `step_lengths = c(12)` the initial fish are one year "younger" than the formula's age => `t0` interpretations differ from gadget2 (vignette sets `t0 = minage - 0.8`).
- Deprecated/hidden: `g3a_initialconditions()` / `g3a_renewal()` (manual) hidden since 0.14 (NEWS.md:45) -- only reachable as `gadget3:::g3a_initialconditions_manual` / `g3a_renewal_manual`; `stock_param()`/`stock_param_table()` replaced by `stock_prepend()` (0.11, NEWS.md:103); `g3_init_guess()` replaced by `g3_init_val()` (0.11; was in gadgetutils); `g3a_predate_fleet`/`_totalfleet` are legacy wrappers over `g3a_predate`.
- Suspicious/uncleaned source bits noticed (not documented as bugs): `g3s_age` computes `stock__maxage` from `is.numeric(minage)` (R/stock_age.R:4); `g3a_predate_catchability_quotafleet` assigns into `environment(out$C)` where `out$C` is NULL (R/action_predate.R:185); `g3l_sparsesample` drops last `obs_df` column; man pages quote parameter names that differ from the code (`srr_h` vs `spawn.h`, `proj.loglevel` vs `proj.logar1.level`, "optimise default TRUE").
- Compile flags differ on Windows (`-O1 -march=native`, R/run_tmb.R:1121); examples skip `g3_tmb_adfun` on GitHub-CI Windows (man/run_tmb.Rd). Compile needs a C++17 toolchain (`-std=gnu++17`, Rtools on Windows / Xcode CLT on macOS).
- TMB gotchas (notes/tmb-gotchas.Rmd): at least one parameter needed; arrays 1-D; `VECTORIZE` macros need symbols; subsetting by reference.
- **Conflicting definitions** merged from several formulas trigger `warning("Replacing a conflicting definition of <var>")` (R/formula_utils.R:20) -- usually harmless but signals variable-name clashes in custom code.
- Reporting uses `REPORT` of every non-constant global; history arrays can be large (`g3a_report_detail` for long models/many stocks) -- switch off via `report_detail = 0`.
- `reporting_enabled` is DATA in TMB: `obj.fn$fn()` does no reporting; use `obj.fn$report()`.
- The generated TMB library is keyed on gadget3 *and* TMB version; upgrading either recompiles.

### 8.3 NEWS.md breaking changes / features by version (newest first; NEWS has **no dates**; DESCRIPTION Date 2026-01-12 is for 0.15-1-999)

**0.15-1-999 (in development; installed)** -- NEWS.md:1-13
- Fix: `g3_to_r()` converts `type = "LOG"` params to log space when given a *list* of parameters, like the data.frame path.
- New: `g3_param_project_bootstrap()` (block bootstrap); `from_year_f` / `to_year_f` for dlnorm/dnorm/ar1/logar1 (use mean of existing values instead of lmean/mean/level parameters).
- **Breaking**: `g3_param_project_ar1()/logar1()` `lastx_f` removed -> `from_year_f/to_year_f` (old nll used a different level in R vs TMB and included projected values); logar1 level now log of arithmetic mean (as dlnorm); ar1 no longer clamps negative levels to 0 for nll.

**0.15-0** -- NEWS.md:15-25
- Fixes: `g3_tmb_relist()` double-exp'ing fixed params (#260); multi-area `g3a_age()` (#262).
- New: configurable `scale` in `g3l_bounds_penalty()` (#263).
- **Breaking**: `interim_value` re-worked to be per-fleet and a parameter by default (#264) (now `interim_f = g3_parameterized("quota.interim", by_predator = TRUE, by_step = TRUE)`).

**0.14-0** -- NEWS.md:27-46
- Fixes: `g3a_predate_catchability_project` scaling with quotas in individuals (#222); resistant to packages redefining head/tail S3 (#224, `R/headtail.R`); `g3_param_project` projections tending to zero (#226); `g3_quota_hockeyfleet` over-reporting with multiple stocks (#227); zero mean weight in weightjones (#228).
- New: `g3a_trace_var` (#231), `g3a_trace_timings` (#235), `g3_tmb_fn()` for projection runs (#237), parameters `type="LOG"` (#251).
- **Breaking**: `optimise` defaults to FALSE unless default bounds provided (#233); ADGrad function not generated unless random effects used (#234); `g3a_initialconditions`/`g3a_renewal` hidden (not the `_normalparam/_normalcv` ones) (#240); `g3_param_project_dlnorm()/_logar1()` take parameters in linear not log space (#251).

**0.13-0** -- NEWS.md:48-67
- Fixes: all-zero length groups in initialconditions / maturity ratios > 1 no longer NaN (#187 #182).
- New: `stock` column in likelihood data may contain name *parts*; `g3_to_r` models accept list & data.frame params; arbitrary R functions in `g3_to_r` models (#194); `g3_array_agg`, `g3_array_combine` (#193 #213); `g3a_spmodel` (#209); projections/MSE: `g3_param_project()`, AR1/logAR1, `g3_quota()` (#210 #220); `g3_array_plot`.
- **Breaking**: `run_projection` TRUE by default for renewal, `rec.proj` parameter covers projection; `detail_x__num` renamed `dstart_x__num` (#200).

**0.12-0** -- NEWS.md:69-78
- Fix: `g3a_spawn()` splits offspring into multiple output stocks correctly.
- New: split likelihood distributions by `predator_length/age/tag` (#154); predation support `g3a_predate`/`g3a_predate_catchability_predator` (#29); `g3a_otherfood*` (#155); length `transform_fs` in `g3l_catchdistribution` (#95).

**0.11-0** -- NEWS.md:80-106
- Fixes: R-Studio debugging of `g3_to_r`; unknown stock names in likelihood data now an error; `g3l_distribution_surveyindices_*` by age.
- New: `g3_parameterized(by_year = 1998:2099)`; `g3a_initialconditions_normalcv`, `g3a_renewal_normalcv` (`lencv`); `by_predator`; defaults for `g3_suitability_exponentiall50`; cut()-formatted character columns in obs data; `g3_init_val()` (replaces `gadgetutils::g3_init_guess()`); `g3_areas()`; `g3_distribution_preview()`; optional `period` for `g3l_random_*`; `g3l_bounds_penalty()` from actions.
- **Breaking**: surveyindices default `beta = 1` (set `beta = NULL` for old behaviour); `stock_param()/stock_param_table()` -> `stock_prepend()`; removed `g3_to_tmb(adreport_re)` (#60); natural mortality `M` by-age by default (#113); `g3_suitability_andersenfleet()` `by_predator = TRUE` default (#133).

**0.10-0** -- NEWS.md:108-128
- New: `g3_parameterized(by_step = TRUE)` (#115); R factor levels as well as MFDB attributes for obs data (dplyr `group_by(length = cut(...))`, #112); parameterised defaults for `g3l_understocking`, `g3a_naturalmortality`, `g3a_renewal_normalparam`; `g3a_renewal_vonb_t0`/`_recl` (`g3a_renewal_vonb` = `_recl`).
- Fixes: `g3s_modeltime()` history with `final_year_steps`; 1-D R arrays no longer assumed to be TMB vectors.
- **Breaking**: removed `scale = 0.001` from default `K` in `g3a_grow_*`, `g3a_renew_*`; `g3a_renewal_vonb_t0()` default `mean_f` of `*_normalparam()`; `g3a_initialconditions_normalparam()` offsets `age` in `mean_f` by `cur_step_size` (runs at step -1).

**0.9-0** -- NEWS.md:130-155
- Fixes: `g3_suitability_andersen()` sensible (#108); `g3a_age()` single-age stocks.
- New: `recage` parameter for `g3a_renewal_vonb/initabund`; `g3_suitability_andersenfleet()`; public `g3_is_stock()`; `g3_eval()`; `as.vector(array)` in TMB formulas.
- **Breaking**: `transform_fs` now applied *before* aggregation (matrices in terms of stock, not aggregated age); `g3_param_table()` returns NaN with warning on missing value (instead of aborting); `optim(g3_tmb_par(...))` is an error (use `obj.fun$par`).

**0.8-0**: initial CRAN release (NEWS.md:157-161).

---------------------------------------------------------------------

## 9. Differences from gadget2 conventions (as stated in source/docs)

- **No input files**: the model is an R script; no stock/fleet/likelihood/time/area files (vignettes/introduction-single-stock.Rmd:93). Gadget2 text files ->  `g3_stock`, `g3_fleet`, `g3a_*`, `g3l_*`; `gadget2to3` converts old config; MFDB (or dplyr `group_by(cut())`) supplies aggregated data; `gadgetutils`/`gadgetplots` replace gadget2's optimisation/reporting (vignettes/introduction-single-stock.Rmd:51-66, README.md).
- **Stocks are generic dimension containers** (length x area x age x tag...), "stock" != species: use separate stock objects for immature/mature/sex and give them name parts (vignettes/multiple-substocks.Rmd:45-53,95-99). A fleet is a stock without length (predator).
- **Order of calculations is a table of integers** (`g3_action_order`) matching gadget2's *Order of Calculations* but each action can override `run_at`; steps are sorted/deduplicated by name (vignettes/model-structure.Rmd:262-314). (The source links to gadget2's user-guide chapter 'order'; the integers above are g3's encoding of it.)
- **Parameters are explicit `g3_param`s, not gadget2 switches**; names follow `(stock).(param)[.year][.age]`; per-stock/per-year/per-age expansion via `g3_parameterized` (gadget2's `timevariable` is retained only for backwards compat: `g3_timevariable`; "gadget2 insisted that first item's timestep matched start year", R/timevariable.R:7).
- **Likelihood components collapsed**: CatchDistribution/SurveyIndices/CatchInKilos/StockDistribution -> `g3l_catchdistribution`/`g3l_abundancedistribution` + `function_f` (see 4.3). SurveyIndices defaults changed: since 0.11 slope fixed (`beta = 1`) (NEWS.md:102). Understocking is computed per stock total not per area ("To match gadget2, g3l_understocking_total should be per-area..." R/likelihood_understocking.R:26-27). `g3l_distribution_sumofsquaredlogratios` = catchinkilos' sumofsquares (R/likelihood_distribution.R:127).
- **Initial conditions** run "at time -1" (age shifted by `cur_step_size`) -- differs from naive gadget2 reading (NEWS 0.10, R/action_renewal.R:119-124). Initial/renewal numbers are `10000 * factor * normalised-normal` (gadget2's `*10000` convention) (R/action_renewal.R:64).
- **Renewal** is parameterised by `rec.<year>` x `rec.scalar` x normal-by-length; spawn-recruit functions (`g3a_spawn_recruitment_*`) follow gadget2 spawn (`SpawnData::calcRecruitNumber`, R/action_spawn.R:29-30,123 comments) plus new SS3-style Beverton-Holt and hockey-stick.
- **Growth** = gadget2's beta-binomial with `maxlengthgroupgrowth`; named `g3a_grow_impl_bbinom`; `growmature` merges grow & maturity as in gadget2's `AgeBandMatrix::Grow` (R/action_grow.R:361). Weight growth matrix `growmemberfunctions.cc:61`.
- **Maturity**: `g3a_mature_continuous` = gadget2 `MaturityA` continuous; `g3a_mature_constant` = gadget2 constant-maturity logistic (links in R/action_mature.R:9,45).
- **Predation**: fleets handled as predators (totalfleet/numberfleet/linearfleet/effortfleet/quotafleet/predator/project catchability; names mirror gadget2 fleet types [infer]; the source explicitly cites gadget2 `stockpredator.cc:144` for the multispecies predator, R/action_predate.R:217); **overconsumption capped at 95%** like gadget2 `prey.cc:208`; `E == wanttoeat`, `predprey__cons == (*cons[inarea][prey])[predl]` (R/action_predate.R:364-366). `numberfleet` is "individuals" units.
- `g3a_otherfood` = gadget2 "otherfood" non-dynamic prey. `g3a_migrate` = gadget2 migration matrices (normalised by squaring).
- **Beyond gadget2**: TMB/AD & random effects, `g3_param_project*` projections, `g3_quota*` MSE, `g3a_spmodel` surplus-production, tags (`g3s_tag`), sparse/individual-level likelihood (`g3l_sparsesample`), CKMR (`g3l_ckmr_po`), `g3a_weightloss`, `g3a_trace_*`.
- **Suitability functions** correspond to gadget2 suitability types (`exponentiall50`, `andersen`, `gamma`, `exponential`, `straightline`, `constant`, `richards`); `g3_suitability_gamma` is "implemented as in gadget2" even though beta & gamma could be one parameter (R/suitability.R:61-62).
- **Time**: `step_lengths` in months summing to 12 like gadget2 timefile; `final_year_steps` replaces `laststep`; `project_years`, `retro_years` extras. Max 99 steps per year (R/stock_time.R:3).
- **Data aggregation attributes**: MFDB (`mfdb_sample_count`) attributes `length`/`age` groups are read; R factors from `cut()` also work (NEWS 0.10).
- **Length groups**: lower-bound vector + open-ended last group (gadget2 `LengthGroupDivision`, R/stock.R:69) with `plusdl` guess.

---------------------------------------------------------------------

## Appendix A -- the g3 formula language (what you can write inside `~`)

- Formulas are R `~` objects; their environment supplies data (numbers, vectors, arrays, other formulas, functions). Every `g3a_*` returns a named list of formulas (`names()` = step ids, section 2.2).
- **Iterators/loop vars** available inside stock loops: `age`, `area`, `length` (for midlen vectors use `stock__midlen`), `tag`; for two interacting stocks: `predator_*` prefixed (`predator_age`, `predator_length`, ...). `interactvar_*` internal.
- **Time vars**: `cur_time, cur_year, cur_step, cur_step_size, cur_step_final, cur_year_projection, total_steps, total_years, start_year, end_year, step_count, step_lengths`.
- **Stock variables**: `<stock>__num`, `<stock>__wgt`, `__midlen`, `__minlen`, `__maxlen`, `__dl`, `__plusdl`, `__minage`, `__maxage`, `__areas`, ... Inside `stock_with`/`stock_iterate` the generic prefix `stock__` is renamed to the final stock name (e.g. `fish_imm__num`). Other instance arrays: `__transitioning_num/wgt`, `__growth_l/w`, `__renewalnum/wgt`, `__spawnprop/spawningnum/offspringnum/spawnednum/spawnedwgt`, `__consratio`, `__overconsumption`, `__totalpredate`, `__totalsuit`, `__feedinglevel`, `S_P__cons`, `S_P__suit`, `__migratematrix`, `__postmigratenum/wgt`.
- **Mini-language**: `stock_ss(var, dim = expr, vec = ...)`, `stock_ssinv`, `stock_iterate(stock, code)`, `stock_intersect(stock, code)`, `stock_interact(stock, code, prefix = 'predator')`, `stock_with(stock, code)`, `stock_reshape(dest_stock, expr)`, `stock_switch(stock, name = expr, ..., default)`, `stock_prepend(stock, g3_param(...), name_part)`, `stock_hasdim(stock, 'dim')`, `stock_isdefined(var)`, `stock_combine_subpop(stock_ss(a__num), stock_ss(b__num))` (merge abundance and abundance-weighted mean weight), `stock_assert(expr, msg...)`, `debug_label(...)`, `debug_trace(...)`, `g3_idx(i)` (0-based in C++), `g3_with(x := expr, ..., body)`, `g3_param*`.
- **`g3_formula(code, ...)`**: build a formula with explicit environment from named args: `g3_formula(quote(x * y), x = 1, y = g3_parameterized('y'))` (R/formula_utils.R:30-47).
- **`g3_global_formula(f, init_val)`**: a formula with an iterative `f` (evaluated every step) and an `init_val` (evaluated once outside the loop) giving model-global state; non-constant globals are auto-REPORTed (vignettes/writing_actions.Rmd:139-181).
- **Types**: constants become C++ `double`; use `1L` for integer; `array(...)` for arrays; `as_integer()` for int conversion; vectors: `as_force_vector`/`force_vector` internal marker for 1-element vectors.
- Do not use arbitrary R libraries in formulas (only under R via closures); use `g3_native` for a paired R/C++ implementation. `g3_native(r, cpp, depends)`: `cpp` is a C++ lambda (string), `list("fname","Type",...)` to cast args to a TMB-native function, or `NULL` when natively supported; `depends` names other g3_env functions needed.

## Appendix B -- Quick reference: where each report variable comes from

| variable pattern | produced by | dims / notes |
|---|---|---|
| `dstart_<stock>__num|wgt` | `g3a_report_detail` (abundance_run_at = report_early) | [length, (area), (age), time]; start-of-step |
| `detail_<stock>__renewalnum|renewalwgt` | detail report | last recruit amount (stale between renewals) |
| `detail_<stock>__spawnednum` | detail | per spawn |
| `detail_<prey>_<pred>__cons` | detail | biomass consumed by predator from prey per step (**prey first** in the product name, e.g. `detail_fish_f_surv__cons` = prey `fish`, predator `f_surv`) |
| `detail_<prey>_<pred>__suit` | detail | suitable biomass |
| `detail_<stock>__predby_<pred>` | detail (legacy) | prey-shaped array of catch by predator |
| `suit_<prey>_<pred>__report` | `g3a_suitability_report` | suitability (alpha/l50 curve) per length |
| `nll` | `REPORT(nll)` | total |
| `nll_cdist_<fn>_<name>__num|wgt|weight` | `g3l_distribution` | nll per timestep if `nll_breakdown=TRUE` |
| `cdist_<fn>_<name>_model__num|wgt`, `_obs__num|wgt` | `report = TRUE` | arrays in data's dims (time last) |
| `nll_understocking__wgt` | `g3l_understocking` | |
| `nll_random_dnorm_<name>__dnorm`, `nll_random_walk_<name>__dnorm` | `g3l_random_*` | |
| `nll_(asparse|csparse)_<fn>_<name>__nll|obs_mean|model_sum|...` | `g3l_sparsesample` | |
| `proj_<dist>_<param>__var|lvar|nll` | `g3_param_project` | |
| `quota_<name>__var` | `g3_quota` | per fishing year |
| `hist_<var>` / custom prefix | `g3a_report_history` | time added as last dim |
| `trace_timings` | `g3a_trace_timings` | matrix |
| `<report_stock>__<inst>` (`report_stock__num`...) | `g3a_report_stock` | |
| `step_lengths` | detail | |

(`<prey>_<pred>` ordering: the `g3s_stockproduct(prey, predator = pred)` name = `paste(stocks[[1]]$name, stocks[[2]]$name)` i.e. prey then predator, R/stock_product.R:41-45, verified in [run] names `detail_fish_f_surv__cons`.)

## Appendix C -- Files read / evidence base

Read in full: NAMESPACE, NEWS.md, DESCRIPTION, all of R/ except `test_utils.R`, `formula_utils.R` beyond L1-50, and the C++ translator body of `R/run_tmb.R` (L7-700) which was only sampled; all 8 vignettes; man/*.Rd for params, init_val, language, run_tmb, step, action_{order,predate,grow,renewal,spawn,mature,age,naturalmortality,migrate,time,report,tagging,weightloss}, quota, param_project, likelihood_{distribution,sparsesample}, stock*, array_utils, env_dif, timedata, timevariable; notes/tmb-gotchas.Rmd. Runtime checks (installed 0.15.1.999, Rscript): parameter templates of default actions, step names (`g3_collate`), R-model report names/timing, `g3_distribution_preview`, `g3_init_val`, error for per-stock random params. TMB compilation was **not** executed.

## Appendix D -- Worked parameter template [run]

Model: stocks `fish_imm` (ages 1-3, 10 length groups, 1 area) and `fish_mat` (ages 3-4), fleet `comm_is` (= `g3_fleet(c("comm", country="is"))`, so name `comm_is`), `g3a_time(1990, 1992, c(6,6))`; actions: `g3a_growmature` (imm with `g3a_mature_continuous()` & `transition_f = ~TRUE`, mat plain), `g3a_naturalmortality` x2, `g3a_initialconditions_normalcv` x2, `g3a_renewal_normalcv(imm)` (default `run_step = 1`), `g3a_age(imm, output_stocks = list(mat))`, `g3a_age(mat)`, `g3a_predate_fleet(comm_is, list(imm, mat), g3_suitability_exponentiall50(by_stock = 'species'), g3a_predate_catchability_totalfleet(1))`, `g3l_understocking`, `g3l_abundancedistribution("si", ..., g3l_distribution_surveyindices_log())`, `g3l_catchdistribution("ld", ...)`, plus `g3a_report_detail(actions)` and `g3l_bounds_penalty(actions)` (the last adds no new rows). `g3_to_tmb()` template row order and defaults (all `optimise = FALSE`, no bounds):

```
retro_years                        g3a_time                           0
fish_imm.Linf                      g3a_renewal_vonb_t0                1      <- imm: first defined by renewal vonb (value 1)
fish_imm.K                         g3a_renewal_vonb_t0                1
fish_imm.t0                        g3a_renewal_vonb_t0                0
fish_imm.lencv                     g3a_renewal_len_dnorm              0.1    <- shared by initialconditions_normalcv & renewal_normalcv
fish_imm.init.scalar               g3a_renewal_initabund              1
fish_imm.init.1 .. .3              g3a_renewal_initabund              1
fish_imm.M.1 .. .3                 g3a_naturalmortality_exp           0
init.F                             g3a_renewal_initabund              0      <- global, no stock prefix
recage                             g3a_renewal_initabund              0      <- global
fish_imm.walpha / wbeta            g3a_renewal_wgt_wl                 0
fish_mat.Linf / K                  g3a_grow_lengthvbsimple            0      <- mat: first defined by growth (value 0!)
fish_mat.t0                        g3a_renewal_vonb_t0                0      <- needed by mat initial conditions
fish_mat.lencv                     g3a_initialconditions_normalparam  0.1
fish_mat.init.scalar               g3a_renewal_initabund              1
fish_mat.init.3 / .4               g3a_renewal_initabund              1
fish_mat.M.3 / .4                  g3a_naturalmortality_exp           0
fish_mat.walpha / wbeta            g3a_grow_weightsimple              0
report_detail                      g3a_report_detail                  1
fish.comm_is.alpha / l50           g3a_predate (suitability)          0      <- by_stock='species' => prefix "fish"
fish_imm.bbin / fish_mat.bbin      g3a_grow_impl_bbinom               0
fish_imm.mat.alpha / mat.l50       g3a_mature_constant                0      <- maturity of imm
fish_imm.rec.proj                  g3a_renewal_len_dnorm              0
fish_imm.rec.1990 .. .1992         g3a_renewal_len_dnorm              0
fish_imm.rec.scalar                g3a_renewal_len_dnorm              0
adist_surveyindices_log_si_weight  g3l_abundancedistribution          1
cdist_sumofsquares_ld_weight       g3l_catchdistribution              1
project_years                      g3a_time                           0
```
(42 rows with the ranges expanded.) Lessons: (1) `fish_mat` has no renewal params (`rec.*`, `rec.sd`), no `fish_imm.rec.sd` appears here because `normalcv` uses `lencv`; (2) the `Linf`/`K` default value depends on which action registers the parameter first (1 vs 0) -- always set them with `g3_init_val`; (3) wildcards from the vignettes: `"*.rec|init.scalar"`, `"*.init.#"`, `"*.rec.#"` (also matches `rec.proj`? No: `#` is digits only, so `rec.proj` needs its own call), `"*.M.#"`, `"*.Linf"`, `"*.K"`, `"*.t0"`, `"*.walpha"`, `"*.wbeta"`, `"*.*.alpha"` (suitability: for by_stock='species' it is `fish.comm_is.alpha`, 3 parts -- but `*` is `.*` so also `fish_imm.mat.alpha` (maturity!) matches `*.*.alpha`; the multi-stock vignette therefore sets the maturity params *after* with the more specific `"*.mat.alpha"`, vignettes/multiple-substocks.Rmd:433-437, relying on call order).

## Appendix E -- Cookbook (task -> idiom, all from source/vignettes unless noted)

| task | idiom |
|---|---|
| Quarterly steps, 1990-2023 | `g3a_time(1990L, 2023L, step_lengths = c(3L,3L,3L,3L))` |
| Stop mid-final-year | `g3a_time(..., final_year_steps = 2)` (0 = exclude end_year) |
| Retrospective run | `params |> g3_init_val("retro_years", 3)` (R & TMB; `retro_years` is a fixed parameter) |
| Projection (R/TMB) | `params |> g3_init_val("project_years", 10)`; use `g3_tmb_fn(model_code)` for repeated stochastic projections; give per-year params `by_year = 1990:2100` where the default `seq(start_year,end_year)` isn't enough |
| One shared param for imm & mat | `g3_parameterized("Linf", by_stock = 'species')` (stock built with a named part `species=`) |
| Per-year parameter | `g3_parameterized("l50", by_stock = TRUE, by_predator = TRUE, by_year = TRUE)` |
| Seasonal parameter | `g3_parameterized("x", by_step = TRUE)` -> `x.1`, `x.2` |
| Single M instead of per-age | `g3a_naturalmortality(s, g3a_naturalmortality_exp(g3_parameterized("M", by_stock = TRUE, by_age = FALSE)))` |
| Fix a parameter | `g3_init_val(p, "*.walpha", 0.01, optimise = FALSE)` |
| Estimate with spread | `g3_init_val(p, "*.Linf", 100, spread = 0.2)` |
| Second fleet | repeat `g3_fleet()` + `g3a_predate_fleet()` + likelihoods with a different name; per-fleet suitability param `S.<fleet>.alpha` created automatically |
| Different suitability per prey | `suitabilities = list(fish_imm = g3_suitability_exponentiall50(...), fish_mat = ...)` (names = *stock names*, `stock$name`; an unnamed element is the default) |
| Fleet catches in numbers | `g3a_predate_catchability_numberfleet(E)` with data `number`; likelihood with `number` col |
| Fishing mortality-driven fleet | `g3a_predate_catchability_linearfleet(E)` with `E = g3_parameterized("F", by_predator = TRUE, by_year = TRUE)` (formula `E * cur_step_size * suit`) |
| Catch in kg likelihood | `g3l_catchdistribution("c", df(year, step, fleet?, weight), fleets, stocks, g3l_distribution_sumofsquares())` ; or `sumofsquaredlogratios()` |
| Length-composition likelihood | data.frame with `year, step, area, length(cut factor), number` -> `g3l_catchdistribution(..., g3l_distribution_sumofsquares())` (or `multinomial`) |
| Age-length (ALK) likelihood | add `age` column |
| Survey biomass index | `g3l_abundancedistribution("si", df(year, step, weight), stocks, g3l_distribution_surveyindices_log(alpha = NULL, beta = 1))`; use `length` column to restrict to a length range (index by length group) |
| Maturity-ogive data | `stock` column with `imm`/`mat` (partial names) |
| Tagging | stock `|> g3s_tag(c(...integer ids))`, `g3a_predate_tagrelease(...)`, `g3a_tag_shedding(...)`, likelihood with `tag` column |
| Recruitment from SSB | `g3a_spawn(mat, g3a_spawn_recruitment_ricker(), output_stocks = list(imm), run_step = 1)` instead of `g3a_renewal_*` |
| Random-effects recruitment | `g3a_renewal_normalparam(imm, factor_f = g3_param_project("rec", g3_param_project_logar1(), scale = "scalar", by_stock = stocks, by_step = FALSE), run_step = 1)` + `g3_init_val("*.rec.#", value = 2e3, random = TRUE)` (see 7.8) |
| Quota-driven projection | `g3a_predate_catchability_project(quota_f = g3_quota(g3_quota_hockeyfleet(list(fleet), list(mat_stock))), landings_f = <historic data formula>, unit = "biomass")` |
| Report abundance at end of step | `g3a_report_history(actions, "__num$|__wgt$", out_prefix = "dend_")` |
| Aggregate report | `g3_array_agg(attr(res,"dstart_fish_imm__num"), c('age','year'), step = 1, age = 2:4)` |
| See what the data will become | `g3_distribution_preview(df, stocks = list(...), fleets = list(...), area_group = area_names)` |
| Find a NaN | add `g3a_trace_var(actions)`; `obj.fn$report()` / R run prints first offending step |
| Inspect step order/labels | `g3_to_desc(actions)`; `names(gadget3:::g3_collate(actions))` |
| Run one TMB eval | `obj.fn$fn(g3_tmb_par(params))` (not `optim(g3_tmb_par(...))`) |
| Convert fit to R-model params | `g3_tmb_relist(params.in, fit$par)` then `g3_to_r(actions)(that_list)` |
| Persist compiled model | `options(gadget3.tmb.work_dir = "tmb-workdir")` before `g3_tmb_adfun` |
