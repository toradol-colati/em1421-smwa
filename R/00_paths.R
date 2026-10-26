# Percorsi e utilità comuni. Da eseguire dalla radice del repo (source(), non standalone).

DIR_RAW       <- file.path("data", "raw")
DIR_PROCESSED <- file.path("data", "processed")
DIR_FIGURES   <- file.path("output", "figures")

FILE_RFA  <- file.path(DIR_RAW, "wiki-RfA.txt.gz")
FILE_ELEC <- file.path(DIR_RAW, "wikiElec.ElecBs3.txt.gz")

stop_if_missing <- function(path) {
  if (!file.exists(path)) {
    stop("File assente: ", path, ". Vedi data/raw/README.md per il download.", call. = FALSE)
  }
  invisible(TRUE)
}
