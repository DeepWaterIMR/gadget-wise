## -----------------------------------------------------------------------------
##
## Model versioning
##
## The model version is YYYY.MM.DD.N: the date of the model update and a running
## number for that day starting from 0 (e.g. 2026.10.14.0, 2026.10.14.1). It is
## stored in the VERSION file at the project root. Bump it with bump_version()
## when committing a change that alters model results, and describe the change
## in NEWS.md.
##
## -----------------------------------------------------------------------------

#' @title Read the model version
#' @param path Path to the VERSION file
#' @return Version string, or NA if the VERSION file is missing

model_version <- function(path = "VERSION") {
  if (!file.exists(path)) return(NA_character_)
  # NB: Also reads the "version: x" form wise-writing writes
  trimws(sub("^version:", "", readLines(path, n = 1, warn = FALSE)))
}

#' @title Git commit of the working copy, with a "-dirty" suffix for uncommitted changes to tracked files
#' @return Short commit hash, or NA if git is not available

model_git_commit <- function() {
  commit <- tryCatch(
    system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE, stderr = FALSE),
    error = function(e) character(0), warning = function(w) character(0)
  )
  if (length(commit) == 0) return(NA_character_)
  dirty <- tryCatch(
    system2("git", c("status", "--porcelain", "--untracked-files=no"), stdout = TRUE, stderr = FALSE),
    error = function(e) character(0), warning = function(w) character(0)
  )
  paste0(commit, if (length(dirty) > 0) "-dirty")
}

#' @title Bump the model version
#' @description Increments the running number if the version is already from \code{date}, otherwise starts \code{date} from 0
#' @param path Path to the VERSION file
#' @param date Date of the model update
#' @return The new version string, invisibly

bump_version <- function(path = "VERSION", date = Sys.Date()) {
  today <- format(as.Date(date), "%Y.%m.%d")
  old <- model_version(path)
  n <- if (!is.na(old) && startsWith(old, paste0(today, "."))) {
    as.integer(sub(".*\\.", "", old)) + 1L
  } else {
    0L
  }
  new <- paste0(today, ".", n)
  writeLines(new, path)
  message("Model version: ", old, " -> ", new, ". Remember to describe the change in NEWS.md")
  invisible(new)
}

#' @title Model version label for figure captions and output files
#' @return E.g. "Model version 2026.10.14.1 (9c65fa8)"

model_version_label <- function() {
  paste0("Model version ", model_version(), " (", model_git_commit(), ")")
}
