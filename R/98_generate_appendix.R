# 98 - Regenerates the code appendix of docs/DATA_FULL.md from the real files in R/.
# Run it after every change to the scripts, so that the code shown in the
# document cannot drift from the code that actually runs. It rewrites only the
# region between the two markers and leaves the rest of the document untouched.
FILES <- c("R/00_run_all.R", "R/run_data_prep.R",
           "R/00_paths.R", "R/00_lib_data.R", "R/01_read_raw.R",
           "R/02_build_attempts.R", "R/03_validate_outcomes.R",
           "R/04_build_networks.R", "R/05_measure_change.R",
           "R/06_model_outcome.R", "R/07_figures.R",
           "R/99_verify_data.R", "R/99b_verify_output.R",
           "R/98_generate_appendix.R")
doc <- "docs/DATA_FULL.md"
text_lines <- readLines(doc, warn = FALSE)
i <- grep("^<!-- GENERATED APPENDIX START -->$", text_lines)
j <- grep("^<!-- GENERATED APPENDIX END -->$", text_lines)
stopifnot(length(i) == 1, length(j) == 1, j > i)
# Four-backtick fences: this very file contains three-backtick sequences in its
# own strings, and a three-backtick fence would be closed by them, breaking the
# last block of the appendix.
blocks <- unlist(lapply(FILES, function(f) {
  c(paste0("### `", f, "`"), "",
    "````r", readLines(f, warn = FALSE), "````", "")
}))
out <- c(text_lines[seq_len(i)], "", blocks, text_lines[j:length(text_lines)])
writeLines(out, doc)
cat("appendix regenerated:", length(blocks), "lines from", length(FILES), "files\n")
