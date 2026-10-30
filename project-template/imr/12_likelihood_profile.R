## ---------------------------
##
## Script name: Likelihood profile
##
## Purpose of script: Profile the likelihood components over fixed values of one parameter (e.g.
## the natural mortality, "*.M", or a survey catchability) with gadgetutils::g3_sensitivity. Each
## value is a full optimisation with the parameter fixed.
##
## Creates: profile_out, figures/Profile_<parameter>.png
##
## ---------------------------

profile_start <- if (exists("optim_param")) optim_param else tmb_param
profile_switch <- grep(glob2rx(profile_parameter), profile_start$switch, value = TRUE)
if (length(profile_switch) != 1) stop("profile_parameter must match one parameter: ", paste(profile_switch, collapse = ", "))

invisible(g3_tmb_adfun(tmb_model, profile_start))

profile_out <- gadgetutils::g3_sensitivity(
  gd = base_dir,
  outdir = paste0("profile_", gsub("[^A-Za-z0-9]+", "_", profile_switch)),
  model = tmb_model,
  params = profile_start,
  par_name = profile_switch,
  par_values = profile_values,
  control = list(maxit = maxit),
  mc.cores = ncores
)

save(profile_out, profile_switch, profile_values,
  file = file.path(base_dir, paste0("profile_", gsub("[^A-Za-z0-9]+", "_", profile_switch), ".rda")), compress = "xz"
)
