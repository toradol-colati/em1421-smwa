# 92 - Short elections (fewer than 5 votes): real or pieces of a split?
#
#   Rscript R/92_short_attempt_check.R
#
# A short election can be a real request that was closed early, or a piece of
# one election that our 7-day rule split in two (for example a late vote).
# This script collects the evidence used to define the three samples in 05:
#   - short elections by result, and how many match a wiki-Elec election
#     (which confirms they really happened);
#   - pairs that contain a short election: how many of those elections match
#     wiki-Elec, how often the next election succeeds, and the median number
#     of days between the two.
#
# Output: output/results/short_attempt_check.csv

source(file.path("R", "00_paths.R"))

# Read the elections and pairs; mark which elections matched wiki-Elec and
# which are short (fewer than 5 votes).
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
pairs <- readRDS(file.path(DIR_PROCESSED, "attempt_pairs.rds"))
matched <- attempts$elec_matched %in% TRUE
short <- attempts$flag_short %in% TRUE

# Table 1 - short elections, split by recorded result: how many match a
# wiki-Elec election, and how many have just one vote.
rows <- list()
for (o in c(-1L, 1L)) {
  sel <- short & attempts$outcome == o
  rows[[length(rows) + 1]] <- data.frame(
    table = "short attempts", group = ifelse(o == 1L, "recorded success", "recorded rejection"),
    n = sum(sel), short_attempts = sum(sel), matched_to_wiki_elec = sum(sel & matched),
    one_vote = sum(sel & attempts$n_votes == 1L),
    one_vote_matched = sum(sel & matched & attempts$n_votes == 1L),
    next_success = NA_integer_, median_days_between = NA_real_)
}

# Table 2 - pairs that contain a short election (overlapping pairs left
# out), split by the earlier result: how many short elections match
# wiki-Elec, how often the next election is a success, and the median gap.
# A short "success" followed days later by another success looks like one
# election that was split in two.
sp <- pairs[pairs$short_attempt_pair & !pairs$negative_interval, ]
for (o in c(-1L, 1L)) {
  g <- sp[sp$previous_outcome == o, ]
  ids <- c(g$previous_attempt_id[g$previous_short_attempt],
           g$next_attempt_id[g$next_short_attempt])
  m <- attempts$elec_matched[match(ids, attempts$attempt_id)] %in% TRUE
  rows[[length(rows) + 1]] <- data.frame(
    table = "short-attempt pairs", group = ifelse(o == 1L, "after success", "after rejection"),
    n = nrow(g), short_attempts = length(ids), matched_to_wiki_elec = sum(m), one_vote = NA_integer_,
    one_vote_matched = NA_integer_, next_success = sum(g$next_outcome == 1L),
    median_days_between = median(g$days_between))
}

# Table 3 - the strict sample, for comparison.
clean <- pairs[pairs$in_strict, ]
for (o in c(-1L, 1L)) {
  g <- clean[clean$previous_outcome == o, ]
  rows[[length(rows) + 1]] <- data.frame(
    table = "strict pairs", group = ifelse(o == 1L, "after success", "after rejection"),
    n = nrow(g), short_attempts = 0L, matched_to_wiki_elec = NA_integer_, one_vote = NA_integer_,
    one_vote_matched = NA_integer_, next_success = sum(g$next_outcome == 1L),
    median_days_between = median(g$days_between))
}

# Print the three tables and save them.
out <- do.call(rbind, rows)
print(out, row.names = FALSE)
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
write.csv(out, file.path("output", "results", "short_attempt_check.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwritten: output/results/short_attempt_check.csv\n")
