# 93 - Do supporters come back more often than chance?
#
#   Rscript R/93_coalition_overlap_null.R
#
# An overlap of, say, 0.3 means nothing on its own: we need to know what chance
# would give. Like the homophily test in Lecture 4, we compare the real value
# with random draws.
#
# For each pair of consecutive elections, the supporters of the second election
# are replaced 200 times by a random group of the same size, drawn from the
# voters active that year. Voters who vote more often are more likely to be
# drawn; otherwise the random groups would be full of rare voters and almost
# any real overlap would look large.
#
# Overlap is the share of supporters in both elections out of supporters in
# either (Jaccard), which Lecture 4 calls neighborhood overlap.
#
# Output: output/results/coalition_overlap_null.csv  (one row per pair)
#         output/results/coalition_overlap_tests.csv (Fisher tests by group)

source(file.path("R", "00_paths.R"))

B <- 200   # random draws per pair

# Read data. Keep votes assigned to an election, without self-votes, and
# add the year of each vote's election.
votes <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
pairs <- readRDS(file.path(DIR_PROCESSED, "attempt_pairs.rds"))

v2 <- votes[!is.na(votes$attempt_id) & !votes$self_vote, ]
ai <- match(v2$attempt_id, attempts$attempt_id)
v2$year <- attempts$year_from_date[ai]

# Supporters (+1 votes) of one election.
supporters_of <- function(id) unique(v2$src[v2$attempt_id == id & v2$vot == 1L])

# Voters active in a given year, with the number of votes they cast as weight
# (very active voters are more likely to show up in any election).
activity_by_year <- local({
  tb <- table(v2$year, v2$src)
  function(y) {
    row <- tb[as.character(y), ]
    row[row > 0]
  }
})

# Jaccard overlap = shared supporters / all supporters of either election.
jaccard <- function(a, b) {
  u <- length(union(a, b))
  if (u == 0) NA_real_ else length(intersect(a, b)) / u
}

# For each pair: keep the real supporters of the first election, and replace
# the supporters of the second election with a random draw of the same size
# from the voters active that year (not the candidate). Repeat B times.
# If the real overlap is above the 95th percentile of the random overlaps,
# the same people came back more than chance would predict.
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
    pair_id = pairs$pair_id[r],
    candidate = pairs$candidate[r],
    previous_outcome = pairs$previous_outcome[r],
    next_outcome = pairs$next_outcome[r],
    in_chronological = pairs$in_chronological[r],
    in_strict = pairs$in_strict[r],
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

# Print one summary line for a group of pairs: median real overlap, median
# random overlap, % with zero overlap, % above their own 95th percentile.
report <- function(sel, label) {
  o <- out[sel, ]
  fin <- o$null_mean > 0
  cat(sprintf("%-34s n=%3d | observed median %.4f | null median %.4f | ratio median %.1f | zero overlap %2.0f%% | above own p95 %2.0f%%\n",
              label, nrow(o), median(o$observed_overlap), median(o$null_mean),
              median(o$ratio[fin]), 100 * mean(o$observed_overlap == 0),
              100 * mean(o$above_null_p95)))
}

cat(sprintf("pairs tested: %d of %d consecutive pairs\n", nrow(out), nrow(pairs)))
# A pair is tested only when both elections have at least 3 supporters and
# there are more active voters that year than supporters to draw.
# Results for each sample, overall and by earlier and later result.
for (smp in c("all", "chronological", "strict")) {
  keep <- switch(smp, all = rep(TRUE, nrow(out)),
                 chronological = out$in_chronological, strict = out$in_strict)
  cat(sprintf("\n--- sample: %s ---\n", smp))
  report(keep, "all pairs")
  for (o_val in c(-1L, 1L)) {
    report(keep & out$previous_outcome == o_val,
           sprintf("  previous outcome %+d", o_val))
  }
  for (o_val in c(-1L, 1L)) {
    report(keep & out$next_outcome == o_val,
           sprintf("  next outcome %+d", o_val))
  }
}
# Fisher's exact test: is the share of pairs above chance different between
# pairs after a success and after a rejection (and, separately, before a
# success and before a rejection)? These are the p-values quoted in the report.
fisher_tests <- do.call(rbind, lapply(c("all", "chronological", "strict"), function(smp) {
  d <- switch(smp, all = out, chronological = out[out$in_chronological, ],
              strict = out[out$in_strict, ])
  do.call(rbind, lapply(c("previous_outcome", "next_outcome"), function(g) {
    success <- d[[g]] == 1L
    data.frame(sample = smp, grouped_by = g,
               above_chance_success = mean(d$above_null_p95[success]),
               above_chance_rejection = mean(d$above_null_p95[!success]),
               fisher_p = fisher.test(table(success, d$above_null_p95))$p.value)
  }))
}))
cat("\nFisher's exact test, share of pairs above chance:\n")
print(fisher_tests, row.names = FALSE, digits = 3)

dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
write.csv(out, file.path("output", "results", "coalition_overlap_null.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(fisher_tests, file.path("output", "results", "coalition_overlap_tests.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwritten: output/results/coalition_overlap_null.csv and coalition_overlap_tests.csv\n")
