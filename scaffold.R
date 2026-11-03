# scaffold.R — create a new gadget3 model project.
#
# The project base (folder layout, document setup, docs/render.R, docs/assets/, .gitignore) comes
# from wise-writing's scaffold_document(). This script calls it, then overlays the gadget layer:
# the shared report partials and memory (project-template/common/) and the model code of the chosen
# layout (project-template/imr/ or project-template/iceland/).
#
# There is one copy of the shared infrastructure and it lives in wise-writing. A fix to
# docs/render.R belongs there; a fix to 03_stocks.R or 00-setup/setup-model.R belongs here.
#
# Usage:
#   source("<gadget-wise>/scaffold.R")
#   scaffold_gadget("config.yaml", "../cod-gadget")
#   scaffold_gadget("config.yaml", "../cod-gadget", dry = TRUE)   # preview
#
# Requires: yaml, and wise-writing installed. (install.packages("yaml"))

`%||%` <- function(a, b) if (is.null(a)) b else a

# The document types a gadget project gets by default. A benchmark adds "benchmark-report";
# an advice year "advice-sheet". Pass them through `types`.
GADGET_DOCUMENT_TYPES <- c("data-report", "assessment-report")

GADGET_LAYOUTS <- c("imr", "iceland")

.read_yaml_utf8 <- function(path) {
  txt <- readChar(path, file.info(path)$size, useBytes = TRUE)
  Encoding(txt) <- "UTF-8"
  yaml::yaml.load(txt, eval.expr = FALSE)
}

# --- Locate this pack -----------------------------------------------------------------------
# Order: explicit argument -> ~/.gadget-wise/config.json (written by gadget-install) ->
# the folder this script was sourced from -> the working directory.
.find_gadget_pack <- function(pack = NULL) {
  valid <- function(p) {
    !is.null(p) && dir.exists(file.path(p, "project-template", "imr")) && dir.exists(file.path(p, "skills"))
  }
  if (valid(pack)) return(normalizePath(pack))

  cfg_json <- path.expand("~/.gadget-wise/config.json")
  if (file.exists(cfg_json) && requireNamespace("jsonlite", quietly = TRUE)) {
    p <- tryCatch(jsonlite::read_json(cfg_json)$gadget_wise_path, error = function(e) NULL)
    if (valid(p)) return(normalizePath(p))
  }

  for (frame in rev(sys.frames())) {
    f <- frame$ofile
    if (is.character(f) && length(f) && nzchar(f[[1]])) {
      p <- dirname(normalizePath(f[[1]], mustWork = FALSE))
      if (valid(p)) return(p)
    }
  }
  if (valid(getwd())) return(normalizePath(getwd()))
  stop("Cannot locate the gadget-wise repository. Pass it explicitly via `pack=`.", call. = FALSE)
}

# --- Locate wise-writing ------------------------------------------------------------------
.find_wise_writing <- function(wise_writing = NULL, gadget_pack = NULL) {
  valid <- function(p) !is.null(p) && file.exists(file.path(p, "scaffold.R")) && dir.exists(file.path(p, "project-template"))
  if (valid(wise_writing)) return(normalizePath(wise_writing))

  for (cfg_json in path.expand(c("~/.wise-writing/config.json", "~/.academic-writing/config.json"))) {
    if (file.exists(cfg_json) && requireNamespace("jsonlite", quietly = TRUE)) {
      p <- tryCatch(jsonlite::read_json(cfg_json)$academic_writing_path, error = function(e) NULL)
      if (valid(p)) return(normalizePath(p))
    }
  }
  if (!is.null(gadget_pack)) {
    for (sibling in c("wise-writing", "academic-writing")) {
      p <- file.path(dirname(gadget_pack), sibling)
      if (valid(p)) return(normalizePath(p))
    }
  }
  stop(
    "Cannot locate wise-writing, which gadget-wise builds on.\n",
    "Install it with the `academic-writing-install` skill, or from\n",
    "https://github.com/DeepWaterIMR/wise-writing, then try again.\n",
    "If it is already cloned, pass its path via `wise_writing=`.",
    call. = FALSE
  )
}

# --- Validate the gadget half of the config ------------------------------------------------
.validate_gadget_config <- function(cfg) {
  required <- c("STOCK_CODE", "STOCK_NAME", "STOCK_SLUG", "STOCK_LATIN", "ICES_AREAS", "WORKING_GROUP", "ASSESSMENT_YEAR", "MODEL")
  miss <- setdiff(required, names(cfg))
  if (length(miss)) stop("config.yaml is missing required keys: ", paste(miss, collapse = ", "), call. = FALSE)

  layout <- cfg$LAYOUT %||% "imr"
  if (!layout %in% GADGET_LAYOUTS) stop("LAYOUT must be one of: ", paste(GADGET_LAYOUTS, collapse = ", "), call. = FALSE)

  m <- cfg$MODEL
  miss <- setdiff(c("STOCK_PREFIX", "YEARS", "TIMESTEP", "AREAS", "STOCKS", "M", "FLEETS", "LIKELIHOOD"), names(m))
  if (length(miss)) stop("MODEL is missing: ", paste(miss, collapse = ", "), call. = FALSE)
  if (!grepl("^[a-z][a-z0-9]*$", m$STOCK_PREFIX)) stop("MODEL$STOCK_PREFIX must be lower-case letters and digits (it prefixes parameter names)", call. = FALSE)
  if (length(m$YEARS) != 2 || m$YEARS[[1]] >= m$YEARS[[2]]) stop("MODEL$YEARS must be [first, last]", call. = FALSE)
  if (!(length(m$STOCKS) == 1 || setequal(names(m$STOCKS), c("imm", "mat")))) {
    stop("MODEL$STOCKS must be one stock, or two sub-stocks named imm and mat", call. = FALSE)
  }
  for (k in names(m$STOCKS)) {
    s <- m$STOCKS[[k]]
    if (!all(c("minage", "maxage", "minlength", "maxlength") %in% names(s))) stop("MODEL$STOCKS$", k, " needs minage, maxage, minlength, maxlength", call. = FALSE)
    if (s$minage > s$maxage || s$minlength >= s$maxlength) stop("MODEL$STOCKS$", k, ": min must be below max", call. = FALSE)
  }
  types <- vapply(m$FLEETS, function(f) f$type %||% NA_character_, character(1))
  if (any(!types %in% c("fishery", "survey"))) stop("Every MODEL$FLEETS entry needs type: fishery or survey", call. = FALSE)
  fleet_names <- vapply(m$FLEETS, function(f) f$name, character(1))
  lik_fleets <- unlist(m$LIKELIHOOD[c("ldist", "aldist", "matp")])
  if (length(setdiff(lik_fleets, fleet_names))) stop("MODEL$LIKELIHOOD names unknown fleets: ", paste(setdiff(lik_fleets, fleet_names), collapse = ", "), call. = FALSE)
  if (!(m$DATA_LOOP %||% "custom") %in% c("bait", "mfdb", "custom")) stop("MODEL$DATA_LOOP must be bait, mfdb or custom", call. = FALSE)
  invisible(layout)
}

# --- Tokens of the Icelandic layout's plain-variable options --------------------------------
.iceland_tokens <- function(cfg) {
  m <- cfg$MODEL
  single <- length(m$STOCKS) == 1
  s1 <- m$STOCKS[[1]]
  st <- function(k, f) as.character(if (single) s1[[f]] else m$STOCKS[[k]][[f]])
  fleets <- vapply(m$FLEETS, function(f) f$name, character(1))
  types <- vapply(m$FLEETS, function(f) f$type, character(1))
  q <- function(x) paste0('"', x, '"', collapse = ", ")
  ts <- m$TIMESTEP
  timestep <- if (is.numeric(unlist(ts))) paste0("c(", paste(unlist(ts), collapse = ", "), ")") else switch(ts, yearly = "12", quarterly = "c(3, 3, 3, 3)", monthly = "rep(1, 12)")
  all_len <- unlist(lapply(m$STOCKS, function(s) c(s$minlength, s$maxlength)))
  c(
    "{{RUN_NAME}}" = paste0("run_", cfg$ASSESSMENT_YEAR),
    "{{YEAR_START}}" = as.character(m$YEARS[[1]]),
    "{{YEAR_END}}" = as.character(m$YEARS[[2]]),
    "{{STOCK_PREFIX}}" = m$STOCK_PREFIX,
    "{{SINGLE_STOCK}}" = if (single) "TRUE" else "FALSE",
    "{{MAX_LENGTH_GROUP_GROWTH}}" = as.character(m$MAX_LENGTH_GROUP_GROWTH %||% 15),
    "{{M_VALUE}}" = as.character(m$M$value),
    "{{COMM_FLEETS}}" = q(fleets[types == "fishery"]),
    "{{SURVEY_FLEETS}}" = q(fleets[types == "survey"]),
    "{{TIMESTEP}}" = timestep,
    "{{MFDB_NAME}}" = as.character(m$MFDB$db %||% "<database>"),
    "{{LENGTH_BIN}}" = as.character(m$LENGTH_BIN %||% 1),
    "{{MINLENGTH}}" = as.character(min(all_len)), "{{MAXLENGTH}}" = as.character(max(all_len)),
    "{{MINAGE}}" = st("imm", "minage"), "{{MAXAGE}}" = st("mat", "maxage"),
    "{{IMM_MINLENGTH}}" = st("imm", "minlength"), "{{IMM_MAXLENGTH}}" = st("imm", "maxlength"),
    "{{IMM_MINAGE}}" = st("imm", "minage"), "{{IMM_MAXAGE}}" = st("imm", "maxage"),
    "{{MAT_MINLENGTH}}" = st("mat", "minlength"), "{{MAT_MAXLENGTH}}" = st("mat", "maxlength"),
    "{{MAT_MINAGE}}" = st("mat", "minage"), "{{MAT_MAXAGE}}" = st("mat", "maxage"),
    "{{SI_LENGTH_BREAKS}}" = paste(round(seq(min(all_len), max(all_len), length.out = 6)), collapse = ", ")
  )
}

#' Scaffold a new gadget3 model project
#'
#' @param config Path to a filled-in `config.yaml`. See `examples/synthetic/config.yaml`.
#' @param target Directory to create. Must not exist, or must be empty.
#' @param types Document types to scaffold (wise-writing). Add "benchmark-report" for a benchmark
#'   and "advice-sheet" for an advice year.
#' @param pack Path to the gadget-wise repository. Located automatically when omitted.
#' @param wise_writing Path to the wise-writing repository. Located automatically when omitted.
#' @param dry Preview without writing anything.
#' @return The target path, invisibly.
scaffold_gadget <- function(config, target, types = GADGET_DOCUMENT_TYPES, pack = NULL, wise_writing = NULL, dry = FALSE) {
  if (!requireNamespace("yaml", quietly = TRUE)) stop("The 'yaml' package is required: install.packages('yaml')", call. = FALSE)
  if (!file.exists(config)) stop("No such config file: ", config, call. = FALSE)

  pack <- .find_gadget_pack(pack)
  ww <- .find_wise_writing(wise_writing, gadget_pack = pack)
  msg <- function(...) cat(if (dry) "[dry] " else "", ..., "\n", sep = "")

  cfg <- .read_yaml_utf8(config)
  layout <- .validate_gadget_config(cfg)
  overlays <- file.path(pack, "project-template", c("common", layout))

  # --- Lay down the wise-writing base -------------------------------------------------------
  source(file.path(ww, "scaffold.R"), local = FALSE)
  scaffold_document(config = config, target = target, types = types, pack = ww, dry = dry)
  msg("Laid down the wise-writing base from ", ww)

  if (dry) {
    msg("Would overlay the gadget layer (", layout, " layout) from ", paste(overlays, collapse = " + "))
    return(invisible(target))
  }

  # --- Overlay the gadget layer ---------------------------------------------------------------
  for (ov in overlays) {
    file.copy(list.files(ov, full.names = TRUE, all.files = TRUE, no.. = TRUE), target, recursive = TRUE, overwrite = TRUE, copy.mode = TRUE)
  }
  msg("Overlaid the gadget layer: ", layout, " layout")

  # The model scripts replace wise-writing's generic data script
  unlink(file.path(target, "R", "1_data.R"))
  unlink(file.path(target, "website"), recursive = TRUE)

  # gadget model runs and caches stay out of git
  gi_extra <- file.path(target, "gitignore-gadget.txt")
  if (file.exists(gi_extra)) {
    cat(readLines(gi_extra), sep = "\n", file = file.path(target, ".gitignore"), append = TRUE)
    unlink(gi_extra)
  }
  if (layout == "iceland") {
    cat("\n# --- gadget-wise: model versions ---\nmodel/\nTEST/\n", file = file.path(target, ".gitignore"), append = TRUE)
  }

  # --- Stamp the tokens -------------------------------------------------------------------------
  sentence_case <- function(x) paste0(toupper(substring(x, 1, 1)), substring(x, 2))
  tokens <- c(
    "{{PROJECT_TITLE}}" = as.character(cfg$PROJECT_TITLE),
    "{{PROJECT_SLUG}}" = as.character(cfg$PROJECT_SLUG),
    "{{PROJECT_YEAR}}" = as.character(cfg$PROJECT_YEAR %||% cfg$ASSESSMENT_YEAR),
    "{{AUTHOR_BLOCK}}" = .author_block(cfg$AUTHORS),
    "{{AFFILIATION_BLOCK}}" = .affiliation_block(cfg$AFFILIATIONS),
    "{{LANGUAGE}}" = as.character(cfg$LANGUAGE %||% "en-US"),
    "{{FIG_WIDTH_DOUBLE}}" = format(round((cfg$FIG_WIDTH_DOUBLE_MM %||% 170) / 25.4, 2)),
    "{{FIG_WIDTH_SINGLE}}" = format(round((cfg$FIG_WIDTH_SINGLE_MM %||% 85) / 25.4, 2)),
    "{{TODAY}}" = format(Sys.Date(), "%Y.%m.%d"),
    "{{STOCK_CODE}}" = as.character(cfg$STOCK_CODE),
    "{{STOCK_NAME}}" = as.character(cfg$STOCK_NAME),
    "{{STOCK_NAME_SENTENCE}}" = sentence_case(cfg$STOCK_NAME),
    "{{STOCK_SLUG}}" = as.character(cfg$STOCK_SLUG),
    "{{STOCK_LATIN}}" = as.character(cfg$STOCK_LATIN),
    "{{ICES_AREAS}}" = as.character(cfg$ICES_AREAS),
    "{{WORKING_GROUP}}" = as.character(cfg$WORKING_GROUP),
    "{{ASSESSMENT_YEAR}}" = as.character(cfg$ASSESSMENT_YEAR),
    "{{ADVICE_YEAR}}" = as.character(cfg$ADVICE_YEAR %||% (as.numeric(cfg$ASSESSMENT_YEAR) + 1))
  )
  if (layout == "iceland") tokens <- c(tokens, .iceland_tokens(cfg))

  text_ext <- c("qmd", "rmd", "r", "md", "yaml", "yml", "css", "tex", "lua")
  files <- list.files(target, recursive = TRUE, full.names = TRUE, all.files = TRUE)
  files <- files[tolower(tools::file_ext(files)) %in% text_ext]
  for (f in files) {
    txt <- tryCatch({
      s <- readChar(f, file.info(f)$size, useBytes = TRUE)
      Encoding(s) <- "UTF-8"
      s
    }, error = function(e) NULL)
    if (is.null(txt)) next
    new <- txt
    for (tok in names(tokens)) new <- gsub(tok, tokens[[tok]], new, fixed = TRUE)
    if (!identical(new, txt)) writeBin(charToRaw(enc2utf8(new)), f)
  }
  msg("Stamped identity tokens")

  # Model version: YYYY.MM.DD.N (R/version.R), one line
  writeLines(paste0(format(Sys.Date(), "%Y.%m.%d"), ".0"), file.path(target, "VERSION"))

  left <- character()
  for (f in files) {
    if (!file.exists(f)) next
    txt <- tryCatch(paste(readLines(f, warn = FALSE, encoding = "UTF-8"), collapse = "\n"), error = function(e) "")
    if (grepl("\\{\\{[A-Z_]+\\}\\}", txt)) left <- c(left, f)
  }
  if (length(left)) warning("Leftover placeholders in:\n  ", paste(left, collapse = "\n  ")) else msg("No leftover placeholders.")

  message("\nScaffolded '", cfg$PROJECT_TITLE, "' (", layout, " layout) at: ", normalizePath(target))
  message("Next:")
  message("  1. cd into the project and run: git init   (local only until you choose a remote)")
  message("  2. Record the questionnaire answers in ai/memory/scaffold-interview.md")
  if (layout == "imr") {
    message("  3. Write the data-loop (R/data_loop_", cfg$MODEL$DATA_LOOP %||% "custom", ".R) and run it: reload_data <- TRUE")
    message("  4. Build and fit: source('_RUN_THE_MODEL.R')   (gadget-build-model, gadget-fit-model)")
  } else {
    message("  3. Edit the mfdb queries in 00-setup/setup-*-data.R and run once with read_data <- TRUE")
    message("  4. Build and fit: source('00-setup/setup.R')")
  }
  invisible(target)
}
