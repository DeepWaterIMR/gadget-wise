# validate-scaffold.R — structural and compile check of gadget-wise.
#
# Scaffolds both layouts from examples/synthetic/config.yaml into a temporary folder, writes
# synthetic data, builds and compiles each model, checks the nll is finite, and runs a short
# optimisation that must lower it. Needs wise-writing, gadget3, gadgetutils, gadgetplots, TMB.
#
# Usage (from the gadget-wise folder):
#   Rscript config/validate-scaffold.R           # both layouts
#   Rscript config/validate-scaffold.R imr       # one layout

args <- commandArgs(trailingOnly = TRUE)
layouts <- if (length(args)) args else c("imr", "iceland")

suppressPackageStartupMessages(library(dplyr))
source("scaffold.R")
source("config/make_synthetic_data.R")
source("config/make_synthetic_iceland.R")

root <- tempfile("gadget-wise-validate-")
dir.create(root)
ok <- TRUE

check <- function(cond, what) {
  cat(if (cond) "  PASS " else "  FAIL ", what, "\n", sep = "")
  if (!cond) ok <<- FALSE
}

for (layout in layouts) {
  cat("\n== ", layout, " layout ==\n", sep = "")
  cfg_file <- file.path(root, paste0("config-", layout, ".yaml"))
  txt <- readLines("examples/synthetic/config.yaml", encoding = "UTF-8")
  writeLines(sub("^LAYOUT: .*", paste("LAYOUT:", layout), txt), cfg_file, useBytes = TRUE)
  target <- file.path(root, paste0("syn-", layout))

  w <- character()
  withCallingHandlers(
    invisible(capture.output(scaffold_gadget(cfg_file, target))),
    warning = function(cnd) {
      w <<- c(w, conditionMessage(cnd))
      invokeRestart("muffleWarning")
    }
  )
  check(!any(grepl("Leftover placeholders", w)), "no leftover placeholders")
  check(file.exists(file.path(target, "AGENTS.md")), "AGENTS.md present")
  check(dir.exists(file.path(target, "docs", "gadget")), "docs/gadget partials present")

  run <- if (layout == "imr") {
    make_synthetic_data(cfg_file, file.path(target, "data/output/model-input"))
    check(file.exists(file.path(target, "_RUN_THE_MODEL.R")), "_RUN_THE_MODEL.R present")
    'base_dir <- "validate_model"; maxit <- 50; plot_html <- FALSE; ncores <- 1; keep_settings <- TRUE
     source("_RUN_THE_MODEL.R")
     nll0 <- model(tmb_param$value)[[1]]
     nll1 <- attributes(optim_param)$summary$score
     cat("RESULT", nll0, nll1, "\n")'
  } else {
    make_synthetic_iceland(cfg_file, target)
    check(file.exists(file.path(target, "00-setup", "setup.R")), "00-setup/setup.R present")
    s <- readLines(file.path(target, "00-setup", "setup.R"))
    writeLines(sub("^run_iterative <- TRUE", "run_iterative <- FALSE", s), file.path(target, "00-setup", "setup.R"))
    'source("00-setup/setup.R")
     nll0 <- result[[1]]
     p <- gadgetutils::g3_optim(tmb_model, tmb_param, control = list(maxit = 50))
     nll1 <- attributes(p)$summary$score
     cat("RESULT", nll0, nll1, "\n")'
  }
  script <- file.path(target, "validate_run.R")
  writeLines(run, script)
  out <- system2("Rscript", c("--vanilla", "-e", shQuote(paste0('setwd("', target, '"); source("validate_run.R")'))), stdout = TRUE, stderr = TRUE)
  res <- grep("^RESULT", out, value = TRUE)
  check(length(res) == 1, "model compiles and runs")
  if (length(res) == 1) {
    v <- as.numeric(strsplit(res, " ")[[1]][2:3])
    check(is.finite(v[1]), paste("nll finite at the starting values:", signif(v[1], 4)))
    check(is.finite(v[2]) && v[2] < v[1], paste("optimisation lowers the nll:", signif(v[2], 4)))
  } else {
    cat(tail(out, 20), sep = "\n")
  }
}

unlink(root, recursive = TRUE)
cat("\n", if (ok) "All checks passed." else "Some checks FAILED.", "\n")
quit(status = if (ok) 0 else 1)
