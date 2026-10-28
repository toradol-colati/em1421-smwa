# EM1421 - canonical data preparation
#
# Run from the repository root:
#   Rscript R/01_prepare_data.R
#
# The three numbered data steps are run in order. This wrapper creates the
# analysis-ready tables used by R/04_build_networks.R through R/07_figures.R.

required_files <- file.path(
  "data",
  "raw",
  c("wiki-RfA.txt.gz", "wikiElec.ElecBs3.txt.gz")
)
if (any(!file.exists(required_files))) {
  stop(
    "Missing raw data. See data/raw/README.md.",
    call. = FALSE
  )
}

source(file.path("R", "01_read_raw.R"))
source(file.path("R", "02_build_attempts.R"))
source(file.path("R", "03_validate_outcomes.R"))

votes <- readRDS(file.path("data", "processed", "votes.rds"))
attempts <- readRDS(
  file.path("data", "processed", "attempts_validated.rds")
)

# A high-confidence disagreement with the independent election file is kept
# visible but excluded from outcome analysis.
outcome_mismatch <- !is.na(attempts$elec_matched) &
  attempts$elec_matched &
  !is.na(attempts$outcome_agrees) &
  !attempts$outcome_agrees
attempts$outcome_analysis <- attempts$outcome
attempts$outcome_analysis[outcome_mismatch] <- NA_integer_
attempts$year_analysis <- attempts$year_from_date

saveRDS(
  attempts,
  file.path("data", "processed", "attempts_analysis.rds")
)

repeat_counts <- table(attempts$candidate)
summary_lines <- c(
  paste("Validated vote rows:", nrow(votes)),
  paste("Attempts:", nrow(attempts)),
  paste("Repeat candidates:", sum(repeat_counts >= 2L)),
  paste("Consecutive attempt pairs:", sum(repeat_counts[repeat_counts >= 2L] - 1L)),
  paste("Externally matched attempts:", sum(attempts$elec_matched)),
  paste(
    "Outcome disagreements excluded from outcome analysis:",
    sum(outcome_mismatch)
  ),
  paste("Self-votes retained in votes table:", sum(votes$self_vote)),
  paste("Neutral votes retained in votes table:", sum(votes$vot == 0L)),
  "First-letter username variants are merged.",
  "Network analysis excludes self-votes and neutral votes."
)
writeLines(
  summary_lines,
  file.path("data", "processed", "data_preparation_summary.txt")
)
cat(paste(summary_lines, collapse = "\n"), "\n")
