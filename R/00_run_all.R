# 00 - Complete project runner.
#
# Run from the repository root:
#   Rscript R/00_run_all.R
#
# Runs every step that produces a number, table or figure used in the report.
# The two slowest steps are 96_network_description.R (about 10 minutes,
# average path length) and 97_community_method_check.R (about 15 minutes,
# Girvan-Newman, stopped after 10 minutes on a snapshot).

steps <- c(
  "R/run_data_prep.R",              # 01-03: votes, attempts, validation
  "R/04_build_networks.R",          # co-voting snapshots, Louvain communities
  "R/05_measure_change.R",          # consecutive pairs, coalition measures
  "R/06_model_outcome.R",           # group comparisons, outcome models
  "R/07_figures.R",                 # Figures 1-4
  "R/93_coalition_overlap_null.R",  # supporter overlap against a random baseline
  "R/94_recruitment_curve.R",       # membership closure, T(k)
  "R/95_weak_ties.R",               # strength of weak ties
  "R/96_network_description.R",     # clustering, path length, giant component
  "R/97_community_method_check.R"   # Girvan-Newman vs Louvain
)

for (step in steps) {
  if (!file.exists(step)) {
    stop("Missing pipeline step: ", step, call. = FALSE)
  }
  cat("\n===== Running ", step, " =====\n", sep = "")
  # local = new.env(): each step runs in its own environment, so objects left
  # by one script cannot change the next one.
  source(step, echo = FALSE, chdir = FALSE, local = new.env())
}

cat("\nProject pipeline completed successfully.\n")
