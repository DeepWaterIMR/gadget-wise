---
name: gadget-docs
description: Find the right gadget documentation and tell gadget2 from gadget3 — maps the gadget3 site and articles, gadget3-master (development) docs, gadgetutils/gadgetplots/g3experiments/mfdb pages, the gadget2 user guide, the gadget course, gadget-models examples and publications, with a gadget2→gadget3 glossary. Use when the user asks where something is documented, quotes documentation or a forum snippet, or when a source might be gadget2.
---

<!-- pack-resources:start -->
**Pack resources:** the `gadget-wise` root is `~/.gadget-wise/config.json` → `gadget_wise_path`, else `~/.fiskwise/config.json` →
`components.gadget-wise.path`, else the checkout containing this skill. Paths such as `knowledge/`
and `project-template/` are relative to that root, never `../../` from a skills folder; resolve
links that leave this skill's folder against the source skill there. Use absolute paths.
<!-- pack-resources:end -->

# Find gadget documentation

The online gadget documentation is spread over several sites from different eras. This skill points
to the right place and stops gadget2 material from leaking into gadget3 work. The full map, with
freshness and a gadget2 → gadget3 glossary, is [references/docs-map.md](references/docs-map.md).

## Where to look, in order

| Need | Go to |
|---|---|
| Exact behaviour, arguments, defaults | Installed source: `args(gadget3::fn)`, `gadget3:::fn`, `?fn`; then GitHub `gadget-framework/gadget3` (`R/`, `NEWS.md`, `tests/`) |
| Concepts and worked models (gadget3) | gadget3 site articles: introduction single stock, incorporating observation data, multiple sub-stocks, model structure, model debugging, writing actions, random effects & projections |
| Development (unreleased) behaviour | gadget3-master site (built from the development branch) |
| Fitting, reweighting, diagnostics | gadgetutils source and README; gadgetplots for plots |
| Projections / HCR | g3experiments source (undocumented) and the gadget3 random-effects & projections article |
| Data aggregation | mfdb documentation (only when the user uses mfdb) |
| Real model code | gadget-models (`06-ling/gadget3`, `07-bling/gadget3*`, `vendace/g3_vendace`); the rest is gadget2 |
| Underlying biology and likelihood ideas | gadget2 user guide (concepts only), Begley & Howell 2004, Taylor et al. 2007 (reweighting) |
| Applications | `knowledge/publications.md` |

The gadget course (gadget-framework/gadget-course) is **gadget2/Rgadget**: use it for modelling
principles (data weighting, diagnostics philosophy), never for code.

## Telltale signs of gadget2

Input files (`main`, `stockfile`, `likelihood` files, `[component]` blocks, `;` comments), the
`gadget -s -i params.in` command line, `Rgadget::`, `gadget.iterative()`, `gadget.fit()`, paramin,
simann/hooke/bfgs optimisation settings, `#` switch names in input files, `refweightfile`.
gadget3 signs: `g3a_`, `g3l_`, `g3_stock`, `g3_to_tmb`, `g3_init_val`, `gadgetutils::g3_*`.

When a source is gadget2, translate the concept with the glossary in the reference and check the
gadget3 equivalent in the source before using it. Say so to the user.

## How to answer a documentation question

1. Identify the package and version (`packageVersion()`), and whether the user is on CRAN or GitHub gadget3.
2. Point to the most specific page (article, function help, source file:line). Quote at most a line.
3. Confirm in the source; report a mismatch between docs and code (docs lag the code).
4. If nothing documents it, say so and show how to inspect it (`g3_to_r(actions)` and read the generated code).
