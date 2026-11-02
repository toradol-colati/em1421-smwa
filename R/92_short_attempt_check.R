# 92 - Which short attempts are real early-closed requests?
#
#   Rscript R/92_short_attempt_check.R
#
# An attempt with fewer than 5 votes (flag_short) can be a real request that
# was closed early, or one request split in two by the date-based
# reconstruction (for example a late vote counted as a new attempt). This
# script reports the evidence for each, so the choice of population in
# 05_measure_change.R can be judged from the data:
#   - short attempts by recorded outcome, and how many match a wiki-Elec
#     election by voter set (independent confirmation that they were real);
#   - short-attempt pairs by previous outcome: how many of their short attempts
#     match wiki-Elec, how often the next attempt succeeds, and the median
#     number of days between the two attempts.
#
# Output: output/results/short_attempt_check.csv

source(file.path("R", "00_paths.R"))

attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
pairs <- readRDS(file.path(DIR_PROCESSED, "attempt_pairs.rds"))
matched <- attempts$elec_matched %in% TRUE
short <- attempts$flag_short %in% TRUE

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

clean <- pairs[pairs$in_strict, ]
for (o in c(-1L, 1L)) {
  g <- clean[clean$previous_outcome == o, ]
  rows[[length(rows) + 1]] <- data.frame(
    table = "strict pairs", group = ifelse(o == 1L, "after success", "after rejection"),
    n = nrow(g), short_attempts = 0L, matched_to_wiki_elec = NA_integer_, one_vote = NA_integer_,
    one_vote_matched = NA_integer_, next_success = sum(g$next_outcome == 1L),
    median_days_between = median(g$days_between))
}

out <- do.call(rbind, rows)
print(out, row.names = FALSE)
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
write.csv(out, file.path("output", "results", "short_attempt_check.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwritten: output/results/short_attempt_check.csv\n")
