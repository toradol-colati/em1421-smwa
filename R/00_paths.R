# Shared paths and helpers. Sourced by the other scripts; not meant to be run
# on its own. All paths are relative to the repository root, so every script
# must be launched from there.

DIR_RAW       <- file.path("data", "raw")
DIR_PROCESSED <- file.path("data", "processed")
DIR_FIGURES   <- file.path("output", "figures")

FILE_RFA  <- file.path(DIR_RAW, "wiki-RfA.txt.gz")
FILE_ELEC <- file.path(DIR_RAW, "wikiElec.ElecBs3.txt.gz")

THRESHOLD_DAYS <- 7
MERGE_FIRST_LETTER <- TRUE

stop_if_missing <- function(path) {
  if (!file.exists(path)) {
    stop("Missing file: ", path, ". See data/raw/README.md for how to get it.",
         call. = FALSE)
  }
  invisible(TRUE)
}
