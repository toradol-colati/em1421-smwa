# 98 - Rigenera l'appendice di codice in docs/DATI.md dai file veri in R/.
# Da eseguire dopo ogni modifica agli script, cosi il codice nel documento non
# puo divergere da quello che gira. Non tocca il resto del documento.
FILES <- c("R/00_paths.R", "R/00_lib_data.R", "R/01_read_raw.R",
           "R/02_build_attempts.R", "R/03_validate_outcomes.R",
           "R/99_verifica_dati.R", "R/99b_verifica_output.R",
           "R/98_genera_appendice.R")
doc <- "docs/DATI.md"
testo <- readLines(doc, warn = FALSE)
i <- grep("^<!-- INIZIO APPENDICE GENERATA -->$", testo)
j <- grep("^<!-- FINE APPENDICE GENERATA -->$", testo)
stopifnot(length(i) == 1, length(j) == 1, j > i)
blocchi <- unlist(lapply(FILES, function(f) {
  c(paste0("### `", f, "`"), "",
    "````r", readLines(f, warn = FALSE), "````", "")
}))
out <- c(testo[seq_len(i)], "", blocchi, testo[j:length(testo)])
writeLines(out, doc)
cat("appendice rigenerata:", length(blocchi), "righe da", length(FILES), "file\n")
