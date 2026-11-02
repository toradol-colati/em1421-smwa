# run_data_prep.R - Runs the data part of the project with one command:
#
#   Rscript R/run_data_prep.R      (from the project folder)
#
# It runs three steps in order:
#   01_read_raw.R           read both SNAP files
#   02_build_attempts.R     rebuild the elections; write votes.rds and attempts.rds
#   03_validate_outcomes.R  check them against wiki-Elec; write attempts_validated.rds
#
# Why a separate runner instead of three source() calls:
#  1. It deletes the old outputs first, so files from a previous run can never
#     be mistaken for new results.
#  2. It stops at the first error and says which step failed. Files the failed
#     step had already written are moved to data/processed/failed_run_<time>/.
#  3. Each step runs in its own environment, so an object left over from one
#     step cannot be used by accident in the next.
#  4. At the end it checks that every expected output file exists.
#  5. Warnings are printed when they happen, next to the line that caused them.
#
# It takes a few minutes, mostly in step 03 (3 rules x 17 thresholds).

options(warn = 1)   # print warnings immediately
t_start <- Sys.time()
source(file.path("R", "00_paths.R"))

STEPS <- c("01_read_raw.R", "02_build_attempts.R", "03_validate_outcomes.R")

EXPECTED <- c(
  "votes_raw.rds", "elec_raw.rds", "username_case_variants.csv",
  "votes.rds", "attempts.rds", "records_without_voter.csv",
  "02_log.txt", "attempts_validated.rds", "03_match_wikielec.csv",
  "03_threshold_sweep.csv", "03_log.txt", "attempts_analysis.rds",
  "data_preparation_summary.txt"
)

dir.create(DIR_PROCESSED, showWarnings = FALSE, recursive = TRUE)

# --- 1. clear the outputs of the chain ---------------------------------------
old <- file.path(DIR_PROCESSED, EXPECTED)
removed <- sum(file.remove(old[file.exists(old)]))
cat(sprintf("Cleared %d output file(s) from a previous run.\n", removed))

# --- 2. run the steps --------------------------------------------------------
for (i in seq_along(STEPS)) {
  step <- STEPS[i]
  cat(sprintf("\n=============== STEP %d of %d: %s ===============\n",
              i, length(STEPS), step))
  t0 <- Sys.time()
  # Run the script in its own clean environment. If it fails, catch the
  # error instead of crashing, so we can clean up below.
  ok <- tryCatch({
    sys.source(file.path("R", step), envir = new.env(parent = globalenv()))
    TRUE
  }, error = function(e) {
    cat(sprintf("\nSTEP FAILED: %s\n  %s\n", step, conditionMessage(e)))
    FALSE
  })
  if (!ok) {
    # Move aside whatever this aborted run had already written. A step can fail
    # after producing some of its outputs, and those files are not results.
    left <- file.path(DIR_PROCESSED, EXPECTED)
    left <- left[file.exists(left)]
    if (length(left) > 0) {
      quarantine <- file.path(DIR_PROCESSED,
                              format(Sys.time(), "failed_run_%Y%m%d_%H%M%S"))
      dir.create(quarantine, showWarnings = FALSE, recursive = TRUE)
      file.rename(left, file.path(quarantine, basename(left)))
      cat(sprintf("\nMoved %d partial output file(s) into %s/\n",
                  length(left), quarantine))
    }
    cat("\nStopped. Fix the error and run this script again.\n")
    quit(status = 1, save = "no")
  }
  cat(sprintf("--- %s finished in %.1f s ---\n", step,
              as.numeric(difftime(Sys.time(), t0, units = "secs"))))
}

# All three steps worked: read their results for the last step.
v <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
a <- readRDS(file.path(DIR_PROCESSED, "attempts_validated.rds"))

# --- 3. create the analysis table used by stages 04-07 ----------------------
# For the 12 elections where our result disagrees with wiki-Elec, the result
# is set to NA so they are left out of the outcome analysis.
outcome_mismatch <- !is.na(a$elec_matched) &
  a$elec_matched &
  !is.na(a$outcome_agrees) &
  !a$outcome_agrees
a$outcome_analysis <- a$outcome
a$outcome_analysis[outcome_mismatch] <- NA_integer_
a$year_analysis <- a$year_from_date
saveRDS(a, file.path(DIR_PROCESSED, "attempts_analysis.rds"))

# Short text summary of the main counts.
repeat_counts <- table(a$candidate)
summary_lines <- c(
  paste("Validated vote rows:", nrow(v)),
  paste("Attempts:", nrow(a)),
  paste("Repeat candidates:", sum(repeat_counts >= 2L)),
  paste("Consecutive attempt pairs:", sum(repeat_counts[repeat_counts >= 2L] - 1L)),
  paste("Externally matched attempts:", sum(a$elec_matched)),
  paste(
    "Outcome disagreements excluded from outcome analysis:",
    sum(outcome_mismatch)
  ),
  paste("Self-votes retained in votes table:", sum(v$self_vote)),
  paste("Neutral votes retained in votes table:", sum(v$vot == 0L))
)
# Names that differ only in the first letter are merged (see 00_lib_data.R).
# Self-votes and neutral votes stay in the votes table; the network scripts
# (04 onward) leave them out.
writeLines(
  summary_lines,
  file.path(DIR_PROCESSED, "data_preparation_summary.txt")
)

# --- 4. check that everything expected is on disk ---------------------------
missing <- EXPECTED[!file.exists(file.path(DIR_PROCESSED, EXPECTED))]
if (length(missing) > 0) {
  cat("\nINCOMPLETE RUN. These expected outputs are missing:\n  ",
      paste(missing, collapse = "\n  "), "\n", sep = "")
  quit(status = 1, save = "no")
}

av <- readRDS(file.path(DIR_PROCESSED, "attempts_validated.rds"))
cat(sprintf("\n=============== DONE in %.1f min ===============\n",
            as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
cat(sprintf("votes.rds              %7d validated votes\n", nrow(v)))
cat(sprintf("attempts.rds           %7d attempts, %d repeat candidates\n",
            nrow(a), sum(table(a$candidate) > 1)))
cat(sprintf("attempts_validated.rds %7d attempts with an external match\n",
            sum(av$elec_matched)))
# The tables are described in docs/DATA.md. Optional extra checks:
#   Rscript R/99_verify_data.R      recomputes the numbers from the raw files
#   Rscript R/99b_verify_output.R   checks the tables are consistent
