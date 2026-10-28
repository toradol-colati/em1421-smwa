# run_data_prep.R - One command that runs the whole data workstream.
#
#   Rscript R/run_data_prep.R
#
# Run it from the repository root. It executes the three steps in order:
#   01_read_raw.R        parse both SNAP files
#   02_build_attempts.R  reconstruct attempts, write votes.rds and attempts.rds
#   03_validate_outcomes.R  validate against wiki-Elec, write attempts_validated.rds
#
# WHY A WRAPPER AND NOT ONE BIG SCRIPT
# The three steps stay separate files because they are three different jobs and
# because a failure in one must not be mistaken for a result of another. This
# file only orchestrates them; it contains no analysis.
#
# WHAT THIS WRAPPER GUARANTEES, which plain source() calls do not:
#  1. STALE OUTPUTS CANNOT SURVIVE A FAILURE. The outputs of the whole chain are
#     deleted before anything starts. Without this, a step that fails leaves the
#     previous run's .rds on disk, and the next step - or the next person -
#     silently works on data that does not correspond to the current code. That
#     is exactly the "one part fails and misleads the other part" problem.
#  2. IT STOPS AT THE FIRST ERROR, naming the step that failed, and exits with a
#     non-zero status so a shell or CI notices. Any output the failed step had
#     already written is moved aside into data/processed/failed_run_<time>/, so
#     it stays available for debugging but cannot be mistaken for a result: a
#     step that dies after writing some of its files is the worst case, and it
#     is the one this handles.
#  3. EACH STEP RUNS IN ITS OWN ENVIRONMENT. Steps 02 and 03 use several
#     variables with the same names (a, v, d, raw, note, log_lines). They never
#     pass anything to each other in memory - they communicate only through
#     files - but isolating them means a leftover object can never be mistaken
#     for a fresh one.
#  4. IT CHECKS THE EXPECTED OUTPUTS EXIST at the end, so a partial success
#     cannot pass for a complete run.
#  5. Warnings are printed as they happen rather than collected at the end, so
#     the line that produced them is visible.
#
# Expected total time: a few minutes, almost all of it in step 03, which sweeps
# 2 rules x 17 thresholds over the whole dataset.

options(warn = 1)
t_start <- Sys.time()
source(file.path("R", "00_paths.R"))

STEPS <- c("01_read_raw.R", "02_build_attempts.R", "03_validate_outcomes.R")

EXPECTED <- c("votes_raw.rds", "elec_raw.rds", "username_case_variants.csv",
              "votes.rds", "attempts.rds", "records_without_voter.csv",
              "02_log.txt", "attempts_validated.rds", "03_match_wikielec.csv",
              "03_threshold_sweep.csv", "03_log.txt")

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
    cat("\nThe chain stopped here. Nothing downstream was run, and no file from\n",
        "this run is left where a result is expected, so nothing can be mistaken\n",
        "for one. Fix the error and run this script again.\n", sep = "")
    quit(status = 1, save = "no")
  }
  cat(sprintf("--- %s finished in %.1f s ---\n", step,
              as.numeric(difftime(Sys.time(), t0, units = "secs"))))
}

# --- 3. check that everything expected is on disk ----------------------------
missing <- EXPECTED[!file.exists(file.path(DIR_PROCESSED, EXPECTED))]
if (length(missing) > 0) {
  cat("\nINCOMPLETE RUN. These expected outputs are missing:\n  ",
      paste(missing, collapse = "\n  "), "\n", sep = "")
  quit(status = 1, save = "no")
}

v <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
a <- readRDS(file.path(DIR_PROCESSED, "attempts.rds"))
av <- readRDS(file.path(DIR_PROCESSED, "attempts_validated.rds"))
cat(sprintf("\n=============== DONE in %.1f min ===============\n",
            as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
cat(sprintf("votes.rds              %7d validated votes\n", nrow(v)))
cat(sprintf("attempts.rds           %7d attempts, %d repeat candidates\n",
            nrow(a), sum(table(a$candidate) > 1)))
cat(sprintf("attempts_validated.rds %7d attempts with an external match\n",
            sum(av$elec_matched)))
cat("\nFull documentation of what these tables contain: docs/DATA.md\n")
cat("Optional verification rounds:\n")
cat("  Rscript R/99_verify_data.R      claims recomputed from the raw files\n")
cat("  Rscript R/99b_verify_output.R   internal invariants of the tables\n")
