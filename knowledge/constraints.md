# Hard constraints

1. **gadget3, not gadget2.** Never give gadget2 input-file syntax, `Rgadget::`, `gadget -s -i`,
   `gadget.iterative` or paramin advice for a gadget3 model. Check telltale signs in
   `skills/gadget-docs/SKILL.md`.
2. **Verify against the source.** Function arguments, defaults and parameter names change between
   gadget3 versions (see NEWS.md). Before relying on a signature, check `args(gadget3::fn)` or the
   GitHub source. Record the gadget3 version (`packageVersion("gadget3")`) in every run's session info.
3. **Data stay local.** Never commit data, model inputs or model output. Biotic data follow BAIT's
   privacy rules.
4. **Every estimated parameter has bounds** and starts inside them; `g3l_bounds_penalty()` is in the model.
5. **Reweight after changes.** Likelihood weights belong to one data set and structure.
6. **Diagnostics before conclusions.** No result is reported from a fit that has not converged, has
   parameters at bounds unexplained, or has not been checked with jitter and retro.
7. **Projections use the fitted parameters** of the reported model folder, never a refit.
8. **Accountable humans.** Never invent authors, reviewers or decisions; model choices are the
   user's, recorded in `ai/memory/` and `NEWS.md`.
9. **Long runs** (reweighting, jitter, retro, projections) run detached with a log (`gadget-run`).
10. **Package installs** need consent (r-package-setup / Fiskwise consent record).
