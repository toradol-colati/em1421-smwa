# 98 - Rigenera l'appendice di codice in docs/DATA.md dai file veri in R/.
# Da eseguire dopo ogni modifica agli script, cosi il codice nel documento non
# puo divergere da quello che gira. Non tocca il rest del documento.
FILES <- c("R/00_paths.R", "R/00_lib_data.R", "R/01_read_raw.R",
           "R/02_build_attempts.R", "R/03_validate_outcomes.R",
           "R/99_verify_data.R", "R/99b_verify_output.R",
           "R/98_generate_appendix.R")
doc <- "docs/DATA.md"
text_lines <- readLines(doc, warn = FALSE)
i <- grep("^<!-- GENERATED APPENDIX START -->$", text_lines)
j <- grep("^<!-- GENERATED APPENDIX END -->$", text_lines)
stopifnot(length(i) == 1, length(j) == 1, j > i)
blocks <- unlist(lapply(FILES, function(f) {
  c(paste0("### `", f, "`"), "",
    "````r", readLines(f, warn = FALSE), "````", "")
}))
out <- c(text_lines[seq_len(i)], "", blocks, text_lines[j:length(text_lines)])
writeLines(out, doc)
cat("appendix regenerated:", length(blocks), "lines from", length(FILES), "files\n")
