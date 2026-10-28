# 00 - Complete project runner.
#
# Run from the repository root:
#   Rscript R/00_run_all.R
#
# This keeps the analysis modular while providing one reproducible entry point.

steps <- c(
  "R/run_data_prep.R",
  "R/04_build_networks.R",
  "R/05_measure_change.R",
  "R/06_model_outcome.R",
  "R/07_figures.R"
)

for (step in steps) {
  if (!file.exists(step)) {
    stop("Missing pipeline step: ", step, call. = FALSE)
  }
  cat("\n===== Running ", step, " =====\n", sep = "")
  source(step, echo = FALSE, chdir = FALSE)
}

cat("\nProject pipeline completed successfully.\n")
