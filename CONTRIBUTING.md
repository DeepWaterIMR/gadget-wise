# Contributing to gadget-wise

gadget-wise is a **public knowledge pack** for building gadget3 models. It contains **instructions
and code only — never data**. Contributions from any gadget user are welcome.

## The golden rule: no data, no private paths

- Never commit data (`.rds`, `.rda`, `.RData`, `.csv`, `.xlsx`), model output, or parameter values
  and weights from real assessments. `.gitignore` is a safety net, not a guarantee.
- Never commit local or internal paths, server names or database hosts. Use placeholders.
- Examples use synthetic values (`config/make_synthetic_data.R`).

## What lives where

- `knowledge/` — the shared source of truth. Prefer improving it over duplicating guidance in skills.
- `skills/gadget-*/SKILL.md` — one skill per recurring task; frontmatter `name` and `description`;
  link into `knowledge/` and `references/` for detail.
- `project-template/` — `common/` (both layouts), `imr/`, `iceland/`. Only gadget-specific files;
  anything shared with other packs belongs in wise-writing.
- `memory/` — development memory of the pack.

## Changing the templates

1. Check every gadget3 function you use against the installed source.
2. Run `Rscript config/validate-scaffold.R` (both layouts scaffold, compile and fit).
3. Describe the change in the commit message; the pre-commit hook bumps `VERSION`
   (`git config core.hooksPath .githooks`).

## Gadget-framework improvements

Generic helpers that every gadget user needs (e.g. the Blim-cut hockey-stick quota, a sum of squares
without the `avoid_zero()` floor) should go upstream to gadgetutils, gadget3 or g3experiments by pull
request; the template copies can then shrink.
