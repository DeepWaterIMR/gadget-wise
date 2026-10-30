---
name: gadget-install
description: Install or set up gadget-wise for building gadget3 models. Use when the user says 'install gadget-wise', 'install https://github.com/DeepWaterIMR/gadget-wise', 'set up gadget-wise', or first asks to build a gadget3 model and gadget-wise is not installed. Clones the pack, installs its skills globally, and checks the gadget3/TMB toolchain; wise-writing is needed before scaffolding, BAIT only for IMR Biotic data.
---

<!-- pack-resources:start -->
**Pack resources:** the `gadget-wise` root is `~/.gadget-wise/config.json` → `gadget_wise_path`, else `~/.fiskwise/config.json` →
`components.gadget-wise.path`, else the checkout containing this skill. Paths such as `knowledge/`
and `project-template/` are relative to that root, never `../../` from a skills folder; resolve
links that leave this skill's folder against the source skill there. Use absolute paths.
<!-- pack-resources:end -->

# Install gadget-wise

Goal: gadget-wise available **once per machine**, in every project. For a managed machine-wide
install, use `fiskwise-install` when the user chooses managed lifecycle; if this skill was invoked
by it, handle only the gadget-wise checks below and leave cloning, registry and skill registration
to the parent.

## Step 1 — Clone

Reuse an install recorded in `~/.gadget-wise/config.json` (`gadget_wise_path`). Otherwise clone
beside wise-writing (its parent folder, from `~/.wise-writing/config.json` → `academic_writing_path`)
or another user-space folder. **Never clone at a filesystem root or a system directory.**

```bash
git clone https://github.com/DeepWaterIMR/gadget-wise "<path>/gadget-wise"
```

## Step 2 — Install the skills globally

Link each `skills/gadget-*` folder into the agent's user-level skills folder (Claude Code
`~/.claude/skills/`, Codex `~/.agents/skills/`; other agents: point their instructions at
`<gadget-wise>/skills/`). Keep a destination symlink that already resolves to the source; move a
differing entry to a timestamped backup before linking; never touch other packs' entries.

Record the install:

```json
{ "gadget_wise_path": "<path>/gadget-wise", "installed_at": "<date>" }
```

in `~/.gadget-wise/config.json` (`scaffold.R` reads it). In managed mode Fiskwise writes it.

## Step 3 — Toolchain

Use saved consent (Fiskwise) or ask before installing; respect a project's `renv.lock`.

```r
for (p in c("TMB", "gadget3", "tidyverse", "yaml", "cowplot", "pbapply", "ggFishPlots")) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
}
for (p in c("gadgetutils", "gadgetplots", "g3experiments")) {
  if (!requireNamespace(p, quietly = TRUE)) remotes::install_github(paste0("gadget-framework/", p), upgrade = "never")
}
packageVersion("gadget3")
```

Projections in the IMR template need gadget3 with `g3_param_project_bootstrap()` (GitHub ≥ 0.15-1-999):
`"g3_param_project_bootstrap" %in% getNamespaceExports("gadget3")`; if FALSE, offer
`remotes::install_github("gadget-framework/gadget3")`.

A compile failure is a toolchain problem: run wise-writing's `academic-toolchain-setup` (Xcode
command line tools on macOS, Rtools on Windows). Verify with the synthetic model:
`Rscript <gadget-wise>/config/validate-scaffold.R` (scaffolds both layouts and compiles them).

## Step 4 — Related packs, on demand

- **wise-writing** before the first scaffold (`academic-writing-install`).
- **BAIT** only for IMR Biotic data (`bait-install`); **index-wise** for sdmTMB survey indices.
- **mfdb** only if the user's data are in an mfdb database.

## Done

Tell the user gadget-wise is installed with the gadget3 version, and how to start:

> *"Let's set up a gadget3 model for `<stock>` using gadget-wise."* → `gadget-new-model`.
