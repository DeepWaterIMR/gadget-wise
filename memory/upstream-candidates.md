# Upstream candidates (template helpers → gadget-framework)

Generic helpers in `project-template/imr/R/` that every gadget user needs. Open pull requests with
the user's approval per PR; then shrink the template copies.

| Helper | Target | Why |
|---|---|---|
| `g3_quota_hockeystick_blim()` | gadget3 (`g3_quota_hockeystick(blim = )`) | ICES MSY advice rule needs zero catch below Blim |
| `sumofsquares()` without the `avoid_zero()` floor | gadget3 (`g3l_distribution_sumofsquares(scale = )`) | Small survey catches distort proportions |
| SSB-dependent recruitment via a dummy stock for bootstrap projections | gadget3 / g3experiments | Every long-term projection rebuilds it |
| `fleet_suitability()` age-logistic with `+ 0 * stock__midlen` | gadgetutils `g3_fit()` | `g3_fit()` needs a length dimension in the suitability report |
| `model_bio_refpoints()`, `f_plus_group()` | gadgetutils | Reference point and F summaries from a fit |
| Retro that truncates likelihood data per peel | gadgetutils `g3_retro()` | `retro_years` alone mis-handles `surveyindices_log` |
