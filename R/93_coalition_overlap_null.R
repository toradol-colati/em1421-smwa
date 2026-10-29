# 93 - Does a coalition persist more than chance? Overlap against a null model.
#
#   Rscript R/93_coalition_overlap_null.R
#
# WHY THIS EXISTS
# Supporter overlap between consecutive attempts is already computed, but on
# its own a Jaccard of 0.3 says nothing: criterion 06 asks whether the result
# would appear even with random data, and criterion 07 asks for a comparison
# point. The course supplies the shape of the answer in its homophily test -
# reassign the labels at random, keeping the observed proportions, and see
# whether the observed quantity departs from what chance gives.
#
# THE NULL
# For each consecutive pair, the set of supporters at t+1 is replaced by a
# random set of the SAME SIZE drawn from the voters who were active that year,
# with probability proportional to how often each of them voted that year.
# The activity weighting matters: without it the null is dominated by occasional
# voters, who are unlikely to appear in any coalition, so almost any observed
# overlap looks enormous and the test proves nothing.
#
# Overlap is the Jaccard index between the supporter sets of t and t+1, which
# is the same quantity the course calls neighbourhood overlap.
#
# Output: output/results/coalition_overlap_null.csv  (one row per pair)
#         printed summary, overall and split by the previous outcome

source(file.path("R", "00_paths.R"))

B <- 200   # null replicates per pair

votes <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
pairs <- readRDS(file.path(DIR_PROCESSED, "attempt_pairs.rds"))

v2 <- votes[!is.na(votes$attempt_id) & !votes$self_vote, ]
ai <- match(v2$attempt_id, attempts$attempt_id)
v2$year <- attempts$year_from_date[ai]

supporters_of <- function(id) unique(v2$src[v2$attempt_id == id & v2$vot == 1L])

# voters active in a given year, with their vote counts as weights
activity_by_year <- local({
  tb <- table(v2$year, v2$src)
  function(y) {
    row <- tb[as.character(y), ]
    row[row > 0]
  }
})

jaccard <- function(a, b) {
  u <- length(union(a, b))
  if (u == 0) NA_real_ else length(intersect(a, b)) / u
}

rows <- list()
set.seed(93)
for (r in seq_len(nrow(pairs))) {
  s_prev <- supporters_of(pairs$previous_attempt_id[r])
  s_next <- supporters_of(pairs$next_attempt_id[r])
  if (length(s_prev) < 3L || length(s_next) < 3L) next
  y_next <- pairs$next_attempt_year[r]
  pool <- activity_by_year(y_next)
  pool <- pool[names(pool) != pairs$candidate[r]]
  if (length(pool) <= length(s_next)) next

  obs <- jaccard(s_prev, s_next)
  null_vals <- vapply(seq_len(B), function(i) {
    draw <- sample(names(pool), size = length(s_next), replace = FALSE,
                   prob = as.numeric(pool))
    jaccard(s_prev, draw)
  }, 0)
  rows[[length(rows) + 1]] <- data.frame(
    pair_id = r,
    candidate = pairs$candidate[r],
    previous_outcome = pairs$previous_outcome[r],
    next_outcome = pairs$next_outcome[r],
    n_supporters_prev = length(s_prev),
    n_supporters_next = length(s_next),
    observed_overlap = obs,
    null_mean = mean(null_vals),
    null_p95 = quantile(null_vals, 0.95, names = FALSE),
    ratio = obs / mean(null_vals),
    above_null_p95 = obs > quantile(null_vals, 0.95, names = FALSE),
    stringsAsFactors = FALSE)
}
out <- do.call(rbind, rows)

report <- function(sel, label) {
  o <- out[sel, ]
  fin <- o$null_mean > 0
  cat(sprintf("%-34s n=%3d | observed median %.4f | null median %.4f | ratio median %.1f | zero overlap %2.0f%% | above own p95 %2.0f%%\n",
              label, nrow(o), median(o$observed_overlap), median(o$null_mean),
              median(o$ratio[fin]), 100 * mean(o$observed_overlap == 0),
              100 * mean(o$above_null_p95)))
}

cat(sprintf("pairs tested: %d of %d consecutive pairs\n", nrow(out), nrow(pairs)))
cat("(a pair is tested when both attempts have at least three supporters and the\n")
cat(" pool of voters active that year is larger than the coalition being drawn)\n\n")
report(rep(TRUE, nrow(out)), "all pairs")
report(out$n_supporters_prev >= 30 & out$n_supporters_next >= 30,
       "both coalitions 30+ supporters")
cat("\nby the outcome of the previous attempt:\n")
for (o_val in sort(unique(out$previous_outcome))) {
  report(out$previous_outcome == o_val,
         sprintf("  previous outcome %+d", o_val))
}
cat("\nHow to read this: the Jaccard overlap between the supporter set at t and at\n")
cat("t+1 is small in absolute terms and near zero for a large share of pairs, but\n")
cat("it sits above what an activity-weighted random draw of the same size gives.\n")
cat("Coalitions are largely rebuilt between attempts, with a weak but detectable\n")
cat("core that returns.\n\n")

dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
write.csv(out, file.path("output", "results", "coalition_overlap_null.csv"), row.names = FALSE)
cat("\nwritten: output/results/coalition_overlap_null.csv\n")
