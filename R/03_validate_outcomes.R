# 03 - Check our elections against wiki-Elec, and test the 7-day threshold.
# Input : data/processed/votes_raw.rds, data/processed/elec_raw.rds,
#         data/processed/votes.rds, data/processed/attempts.rds
# Output: data/processed/03_threshold_sweep.csv, data/processed/03_match_wikielec.csv,
#         data/processed/attempts_validated.rds, data/processed/03_log.txt
# Packages: none (base R).
#
# How an election in wiki-Elec is matched to one of our elections:
# by who voted, not by date. Two elections of the same person have different
# voters, so the voter overlap (Jaccard) tells them apart.
#
# Dates cannot be used: the closing time (field T) in wiki-Elec is wrong by a
# median of 102 days compared with the election's own last vote, and in 54% of
# elections by more than 30 days. An earlier version of this script matched by
# date and wrongly found that only 36% of elections matched (the true figure is
# 78%).

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

# Settings: the thresholds (days) and the three grouping rules to test, and
# the minimum voter overlap to call two elections the same.
GRID           <- c(1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 18, 21, 28, 35, 45, 60)
MODES          <- c("res_then_gap", "gap_then_res", "gap_only")
J_MIN          <- 0.5   # minimum voter overlap to call it the same election
CHOSEN_THRESHOLD <- THRESHOLD_DAYS

log_lines <- character(0)
# note() prints a line and also saves it to data/processed/03_log.txt
note <- function(...) { s <- paste0(...); log_lines <<- c(log_lines, s); cat(s, "\n", sep = "") }
# Jaccard overlap of two voter lists.
jac <- function(x, y) length(intersect(x, y)) / length(union(x, y))

# For each wiki-Elec election, find the election of the same candidate with
# the most similar voter list. set_at = voters of each of our elections,
# per = our election ids for each candidate. Returns the best Jaccard and the
# id of the best election (NA when the candidate is not in our data).
best_match <- function(set_at, per) {
  best <- rep(NA_real_, nrow(ele)); bid <- rep(NA_integer_, nrow(ele))
  for (r in seq_len(nrow(ele))) {
    ids <- per[[ele$cand_k[r]]]; if (is.null(ids)) next
    s <- set_el[[as.character(ele$election_id[r])]]
    jj <- vapply(ids, function(k) jac(s, set_at[[as.character(k)]]), 0)
    best[r] <- max(jj); bid[r] <- ids[which.max(jj)]
  }
  list(best = best, bid = bid)
}

# Read the raw wiki-RfA votes and the wiki-Elec file (from 01), with the
# same cleaning of names and dates as in 02.
raw  <- readRDS(file.path(DIR_PROCESSED, "votes_raw.rds"))
elec <- readRDS(file.path(DIR_PROCESSED, "elec_raw.rds"))
d <- data.frame(src = raw$SRC, tgt = raw$TGT,
                vot = as.integer(raw$VOT), res = as.integer(raw$RES),
                yea = as.integer(raw$YEA), dat = parse_dat(raw$DAT),
                stringsAsFactors = FALSE)
if (MERGE_FIRST_LETTER) {
  d$src <- capitalise_first(d$src)
  d$tgt <- capitalise_first(d$tgt)
}

# wiki-Elec: the voter list of each election, the candidate, and the date
# of the last vote (votes dated after 2008 are ignored as errors).
ev <- elec$votes; ev$voter_k <- norm_user(ev$voter)
set_el <- split(ev$voter_k, ev$election_id)
ele <- elec$elections
ele$cand_k <- norm_user(ele$candidate)
ele$last_vote <- as.POSIXct(vapply(
  split(as.numeric(ev$dat), ev$election_id)[as.character(ele$election_id)],
  function(x) max(x[x < as.numeric(as.POSIXct("2009-01-01", tz = "UTC"))]), 0),
  origin = "1970-01-01", tz = "UTC")

# --- check: how far the closing time T is from the last vote -------------------
# This is why matching below uses voters, not dates.
dT <- as.numeric(difftime(ele$closed_at, ele$last_vote, units = "days"))
note("wiki-Elec: ", nrow(ele), " elections, declared closing times from ",
     format(min(ele$closed_at), "%Y-%m-%d"), " to ",
     format(max(ele$closed_at), "%Y-%m-%d"),
     "; earliest last vote: ", format(min(ele$last_vote), "%Y-%m-%d"))
note("closing time T minus last vote, median days: ", round(median(dT), 1))
note("  share over 30 days: ", sprintf("%.0f%%", 100 * mean(dT > 30)),
     " | elections over 180 days: ", sum(dT > 180),
     " | minimum days: ", round(min(dT), 1), "\n")

# --- evaluate one rule and one threshold -------------------------------------
# Rebuild the elections with one rule and one threshold, then match each
# wiki-Elec election to the rebuilt election of the same candidate with the
# most similar voter list. Returns: how many match, how well, whether the
# outcomes agree, and how often the number of elections per candidate is the
# same as in wiki-Elec.
evaluate <- function(mode, threshold) {
  v <- reconstruct_attempts(d, threshold, mode)
  v$src_k <- norm_user(v$src)
  set_at <- split(v$src_k, v$attempt_id)
  idx <- match(as.integer(names(set_at)), v$attempt_id)
  outcome_by_attempt <- tapply(v$res, v$attempt_id, function(x) {
    values <- unique(x)
    if (length(values) == 1L) values else NA_integer_
  })
  info <- data.frame(attempt_id = as.integer(names(set_at)),
                     cand_k = norm_user(v$tgt[idx]),
                     outcome = as.integer(outcome_by_attempt[names(set_at)]),
                     n_votes = lengths(set_at), stringsAsFactors = FALSE)
  m <- best_match(set_at, split(info$attempt_id, info$cand_k))
  best <- m$best; bid <- m$bid
  ok <- !is.na(best) & best > J_MIN
  mo <- info$outcome[match(bid[ok], info$attempt_id)]
  # Agreement on the number of elections per candidate is counted only for
  # candidates whose wiki-Elec elections are all matched. Otherwise a candidate
  # with one missing and one extra election would look like "1 against 1" and
  # count as agreeing by accident.
  per_c <- split(seq_len(nrow(ele)), ele$cand_k)
  full <- names(per_c)[vapply(per_c, function(ii) all(ok[ii]), TRUE)]
  n_true <- table(ele$cand_k[ele$cand_k %in% full])
  n_mine <- table(info$cand_k[info$cand_k %in% full])
  common <- intersect(names(n_true), names(n_mine))
  data.frame(mode, threshold,
             n_attempts = nrow(info),
             matched = sum(ok),
             matched_share = mean(ok),
             median_jaccard = median(best[ok]),
             outcome_agreement = mean(
               (mo == 1) == (ele$outcome[ok] == 1),
               na.rm = TRUE
             ),
             under_split = sum(duplicated(bid[ok])),
             comparable_candidates = length(common),
             count_agreement = mean(n_true[common] == n_mine[common]),
             over = sum(n_mine[common] > n_true[common]),
             under = sum(n_mine[common] < n_true[common]),
             fragments_lt5 = sum(info$n_votes < 5),
             stringsAsFactors = FALSE)
}

# Try every rule with every threshold and save the table.
note("sweep: ", length(MODES), " rules x ", length(GRID), " thresholds...")
res <- do.call(rbind, lapply(MODES, function(m)
  do.call(rbind, lapply(GRID, function(s) evaluate(m, s)))))
write.csv(res, file.path(DIR_PROCESSED, "03_threshold_sweep.csv"), row.names = FALSE, fileEncoding = "UTF-8")
pr <- res
for (cc in c("matched_share", "median_jaccard", "outcome_agreement", "count_agreement"))
  pr[[cc]] <- round(pr[[cc]], 4)
print(pr, row.names = FALSE)

rtg <- res[res$mode == "res_then_gap", ]
g <- function(s, col) rtg[[col]][rtg$threshold == s]
# Choice of the threshold. Both measures below are almost flat between 4 and
# 21 days, so the result does not depend on the exact value. We keep 7 days,
# the length of an RfA (Kolczynska's blog post on this dataset also notes that
# voting takes a week).
note("\nCHOICE OF THE THRESHOLD")
note("  matched elections: ", g(4, "matched"), " at 4 days, ", g(7, "matched"),
     " at 7, ", g(21, "matched"), " at 21, ", g(60, "matched"), " at 60")
note("  exact election count: ", sprintf("%.1f%%", 100 * g(4, "count_agreement")),
     " at 4 days, ", sprintf("%.1f%%", 100 * g(7, "count_agreement")), " at 7, ",
     sprintf("%.1f%%", 100 * g(60, "count_agreement")), " at 60")
# The other rule (split by date first, then by result) is rejected because it
# creates many tiny pieces: a single stray vote can split an election.
note("  elections with fewer than 5 votes at 7 days: ",
     res$fragments_lt5[res$mode == "gap_then_res" & res$threshold == 7],
     " (rejected rule gap_then_res) vs ", g(7, "fragments_lt5"), " (rule used)")

# --- final pass --------------------------------------------------------------
note("\n--- VALIDATION with res_then_gap and a ", CHOSEN_THRESHOLD, "-day threshold ---")
# Final check on the elections actually built by 02 (same matching as above).
v <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
a <- readRDS(file.path(DIR_PROCESSED, "attempts.rds"))
v$src_k <- norm_user(v$src); set_at <- split(v$src_k, v$attempt_id)
a$cand_k <- norm_user(a$candidate)
m <- best_match(set_at, split(a$attempt_id, a$cand_k))
best <- m$best; bid <- m$bid
ele$jaccard <- best
ele$my_attempt <- ifelse(!is.na(best) & best > J_MIN, bid, NA)
ok <- !is.na(ele$my_attempt)
note("elections matched (Jaccard > ", J_MIN, "): ", sum(ok), " of ", nrow(ele),
     sprintf("  (%.1f%%)", 100 * mean(ok)))
note("  with Jaccard > 0.3: ", sum(best > 0.3, na.rm = TRUE),
     "   candidate absent from wiki-RfA: ", sum(is.na(best)),
     sprintf("  (%.1f%%)", 100 * mean(is.na(best))))
note("  median Jaccard on the matched ones: ", round(median(best[ok]), 3))
mo <- a$outcome[match(ele$my_attempt[ok], a$attempt_id)]
note("OUTCOME AGREEMENT: ",
     sprintf("%.2f%%", 100 * mean((mo == 1) == (ele$outcome[ok] == 1))),
     "  (disagreements: ", sum((mo == 1) != (ele$outcome[ok] == 1)),
     " of ", sum(ok), ")")
note("distinct attempts matched: ", length(unique(ele$my_attempt[ok])), " of ", nrow(a),
     "; attempts absorbing two elections: ", sum(duplicated(ele$my_attempt[ok])))
# For matched elections: voters found only in one of the two files.
missing_from_me <- mapply(function(r, k)
  length(setdiff(set_el[[as.character(r)]], set_at[[as.character(k)]])),
  ele$election_id[ok], ele$my_attempt[ok])
missing_from_them <- mapply(function(r, k)
  length(setdiff(set_at[[as.character(k)]], set_el[[as.character(r)]])),
  ele$election_id[ok], ele$my_attempt[ok])
# The two files were collected separately, so their voter lists for the same
# election are similar in size but not identical.
note("voters only in wiki-Elec (median): ", median(missing_from_me),
     " | voters only in ours (median): ", median(missing_from_them))
note("  median voters per election: ",
     median(lengths(set_el)[as.character(ele$election_id[ok])]),
     " | elections with the same number of voters: ",
     sum(lengths(set_el)[as.character(ele$election_id[ok])] ==
           a$n_votes[match(ele$my_attempt[ok], a$attempt_id)]))

# Add the check results to each election and save.
a$elec_matched  <- a$attempt_id %in% ele$my_attempt[ok]
a$elec_outcome  <- ele$outcome[match(a$attempt_id, ele$my_attempt)]
a$elec_jaccard  <- ele$jaccard[match(a$attempt_id, ele$my_attempt)]
a$outcome_agrees <- ifelse(a$elec_matched, (a$outcome == 1) == (a$elec_outcome == 1), NA)
saveRDS(a, file.path(DIR_PROCESSED, "attempts_validated.rds"))
write.csv(ele[, c("election_id", "candidate", "outcome", "closed_at", "last_vote",
                  "jaccard", "my_attempt")],
          file.path(DIR_PROCESSED, "03_match_wikielec.csv"), row.names = FALSE, fileEncoding = "UTF-8")
# Limit: wiki-Elec ends in January 2008, so later elections cannot be checked.
note("attempts checked against wiki-Elec: ", sum(a$elec_matched), " of ", nrow(a),
     sprintf(" (%.0f%%)", 100 * mean(a$elec_matched)))
note("written: attempts_validated.rds, 03_match_wikielec.csv")
writeLines(log_lines, file.path(DIR_PROCESSED, "03_log.txt"))
