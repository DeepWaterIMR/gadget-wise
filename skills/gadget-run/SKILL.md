---
name: gadget-run
description: Run long gadget3 jobs safely — full model runs, reweighting, jitter, retro, leave-out, profiles and projections, and slow Quarto renders — detached in a screen session on a server or locally with a log in logs/, with run variants via _RUN_WITH.R, core and memory limits, and the TMB/R compile caches. Use when a gadget run will take more than a few minutes or must survive a closed session.
---

<!-- pack-resources:start -->
**Pack resources:** resolve `gadget-wise` from `~/.gadget-wise/config.json` → `gadget_wise_path` (or
`~/.fiskwise/config.json` → `components.gadget-wise.path`). If neither exists, use the checkout
containing this skill, or locate/obtain the pack through its install instructions. Paths such as
`knowledge/`, `config/`, `examples/` and `project-template/` belong to that repository, not the
current model directory. Keep bundled `references/` links relative to the skill. Never assume
`../../` from an agent's global skills folder reaches the repository. Use absolute resolved paths.
<!-- pack-resources:end -->

# Run long gadget jobs

## Before starting

- Review the code that will run (r-code-style) and the run options; one run per model folder at a time.
- Choose cores by memory: each forked optimisation holds a copy of the model. Start with
  `ncores` ≤ physical cores − 1 and watch memory on the first run. Windows: `ncores <- 1`.
- Compile once before forking (the templates call `g3_tmb_adfun()` first), otherwise parallel
  workers compile the same model at once.

## Run detached with a log

IMR format, from the project root:

```bash
mkdir -p logs
screen -dmS <stock>_run -L -Logfile logs/<base_dir>.log bash -lc 'cd <project> && Rscript -e "source(\"_RUN_THE_MODEL.R\", echo = TRUE)"'
```

Variants without editing the master script:

```bash
screen -dmS <stock>_M03 -L -Logfile logs/20261030_model_M03.log bash -lc 'cd <project> && Rscript run_scripts/_RUN_WITH.R "base_dir <- \"20261030_model_M03\"" "run_retro <- TRUE"'
```

Icelandic format: `Rscript -e 'source("00-setup/setup.R", echo = TRUE)'` the same way.

On servers whose module system is stripped by screen, prepend `module reload >/dev/null 2>&1;`
inside `bash -lc`. Tell the user the session name and the log path; reattach with `screen -r <name>`,
detach with Ctrl-a d. Do not poll in a loop: check the log when asked or when the run should be done.

## Caches

`gadget3_tmb_work_dir/` (compiled TMB) and `gadget3_r_work_dir/` (R model code) are set in
`00_run_first.R` (`options(gadget3.tmb.work_dir = , gadget3.r.work_dir = )`). Delete them after a
gadget3/TMB upgrade or when compiled code looks stale.

## Renders

Quarto documents that load model folders are fast; documents that refit are not. Render detached the
same way with `quarto render docs/<type>/<file>.qmd` and a log; follow wise-writing's rendering
rules (code review first, cache toggles).

## After the run

Check the end of the log for "Finished" and the convergence message, the model folder's
`session/run_times.txt`, and warnings (parameters at bounds, non-finite gradients). Record the run in
`ai/memory/` (what, why, outcome).
