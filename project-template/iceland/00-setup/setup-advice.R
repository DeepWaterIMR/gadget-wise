## Projections and catch options with g3experiments (as the Icelandic advice scripts): the fitted
## model gets projection years, recruitment is projected (constant over recent years, or bootstrap),
## and catch options are run over a grid of harvest rates. Adapt the harvest control rule and the
## reference points (ICES guidelines) for the stock. See the gadget-projections skill; the IMR
## format's 13/14 scripts show a full long-term (reference points) and short-term workflow.

library(g3experiments)

if (!exists("params_final")) load(file.path(base_dir, vers, wgts_folder, "fit.Rdata"))

blim <- NA # Set from the reference-point analysis (kg)
btrigger <- NA

stopifnot("Set blim and btrigger in setup-advice.R" = !is.na(blim) && !is.na(btrigger))

## Projection stock actions (dummy stock + hockey-stick spawning) and reports, then
## g3p_setup_pars(model, params, blim, btrigger, harvest_rates, ...) gives one parameter set per
## harvest rate and trial; run them with g3_fit() or the TMB function (g3_tmb_fn). See
## g3experiments R/g3p_project.R for the arguments.
