# 03 - Validation of the reconstruction against wiki-Elec, and choice of the
#      separation threshold.
# Input : data/processed/votes_raw.rds, data/processed/elec_raw.rds,
#         data/processed/votes.rds, data/processed/attempts.rds
# Output: data/processed/03_threshold_sweep.csv, data/processed/03_match_wikielec.csv,
#         data/processed/attempts_validated.rds, data/processed/03_log.txt
# Packages: none (base R).
#
# HOW A REAL ELECTION IS MATCHED TO A RECONSTRUCTED ATTEMPT
# By voter set, not by date. Two elections of the same person have very
# different voter sets, so the overlap (Jaccard) tells them apart, and the
# criterion does not depend on any date field.
#
# The first version of this script matched by proximity between the declared
# closing time T of wiki-Elec and the last vote of the attempt. That is WRONG,
# because T is unreliable: the difference between T and the last vote OF THE
# SAME ELECTION, inside wiki-Elec itself, has a median of 102 days, and 54% of
# elections have T more than 30 days after their own last vote (1,217 more than
# 180 days; some have T BEFORE their own last vote). The same is visible in the
# fact that 78% of elections are declared closed in 2007 while the votes are
# spread over 2005-2007. Consequences of that error, all corrected here: the
# measured coverage was 36% instead of 78%, 23 under-splits appeared instead of
# 1, and the wrong conclusion was drawn that wiki-RfA did not contain the
# elections of wiki-Elec.

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

GRID           <- c(1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 18, 21, 28, 35, 45, 60)
MODES          <- c("res_then_gap", "gap_then_res", "gap_only")
J_MIN          <- 0.5   # minimum voter overlap to call it the same election
CHOSEN_THRESHOLD <- THRESHOLD_DAYS

log_lines <- character(0)
note <- function(...) { s <- paste0(...); log_lines <<- c(log_lines, s); cat(s, "\n", sep = "") }
jac <- function(x, y) length(intersect(x, y)) / length(union(x, y))

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

ev <- elec$votes; ev$voter_k <- norm_user(ev$voter)
set_el <- split(ev$voter_k, ev$election_id)
ele <- elec$elections
ele$cand_k <- norm_user(ele$candidate)
ele$last_vote <- as.POSIXct(vapply(
  split(as.numeric(ev$dat), ev$election_id)[as.character(ele$election_id)],
  function(x) max(x[x < as.numeric(as.POSIXct("2009-01-01", tz = "UTC"))]), 0),
  origin = "1970-01-01", tz = "UTC")

# --- diagnostic: the T field is unreliable -----------------------------------
dT <- as.numeric(difftime(ele$closed_at, ele$last_vote, units = "days"))
note("wiki-Elec: ", nrow(ele), " elections, declared closing times from ",
     format(min(ele$closed_at), "%Y-%m-%d"), " to ",
     format(max(ele$closed_at), "%Y-%m-%d"),
     ". Earliest last-vote of an election: ",
     format(min(ele$last_vote), "%Y-%m-%d"), ".")
note("Field T (closing time) is UNRELIABLE: the gap between T and the last vote")
note("  of the same election has a median of ", round(median(dT), 1),
     " days; it exceeds 30 days in ", sprintf("%.0f%%", 100 * mean(dT > 30)),
     " of cases; it exceeds 180 days in ", sum(dT > 180),
     " elections; the minimum is ", round(min(dT), 1),
     " days (T before the last vote).")
note("  This is why matching uses VOTER SETS, not dates.\n")

# --- evaluate one rule and one threshold -------------------------------------
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
  per <- split(info$attempt_id, info$cand_k)
  best <- rep(NA_real_, nrow(ele)); bid <- rep(NA_integer_, nrow(ele))
  for (r in seq_len(nrow(ele))) {
    ids <- per[[ele$cand_k[r]]]; if (is.null(ids)) next
    s <- set_el[[as.character(ele$election_id[r])]]
    jj <- vapply(ids, function(k) jac(s, set_at[[as.character(k)]]), 0)
    best[r] <- max(jj); bid[r] <- ids[which.max(jj)]
  }
  ok <- !is.na(best) & best > J_MIN
  mo <- info$outcome[match(bid[ok], info$attempt_id)]
  # Agreement on the NUMBER of attempts per candidate is computed only on
  # candidates whose wiki-Elec elections are ALL matched. Computing it on every
  # candidate inflates the figure with accidental agreement: a candidate whose
  # correct election is missing from wiki-RfA, but who has another one, scores
  # "1 against 1" and counts as agreeing.
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

note("sweep: ", length(MODES), " rules x ", length(GRID), " thresholds...")
res <- do.call(rbind, lapply(MODES, function(m)
  do.call(rbind, lapply(GRID, function(s) evaluate(m, s)))))
write.csv(res, file.path(DIR_PROCESSED, "03_threshold_sweep.csv"), row.names = FALSE)
pr <- res
for (cc in c("matched_share", "median_jaccard", "outcome_agreement", "count_agreement"))
  pr[[cc]] <- round(pr[[cc]], 4)
print(pr, row.names = FALSE)

rtg <- res[res$mode == "res_then_gap", ]
g <- function(s, col) rtg[[col]][rtg$threshold == s]
note("\nCHOICE OF THE THRESHOLD")
note("  matched elections: ", g(4, "matched"), " at 4 days, ", g(7, "matched"),
     " at 7, ", g(21, "matched"), " at 21, ", g(60, "matched"), " at 60.")
note("  exact attempt count: ", sprintf("%.1f%%", 100 * g(4, "count_agreement")),
     " at 4 days, ", sprintf("%.1f%%", 100 * g(7, "count_agreement")), " at 7, ",
     sprintf("%.1f%%", 100 * g(60, "count_agreement")), " at 60.")
note("  Both measures are flat between 4 and 21 days: the choice is NOT driven")
note("  by the data, and that flatness is itself the robustness result. 7 days")
note("  is kept, the value of the published precedent (Kolczynska) and the")
note("  nominal length of an RfA.")
note("  Discarded rule (gap_then_res): at 7 days it produces ",
     res$fragments_lt5[res$mode == "gap_then_res" & res$threshold == 7],
     " attempts with fewer than 5 votes against ", g(7, "fragments_lt5"), ".")

# --- final pass --------------------------------------------------------------
note("\n--- VALIDATION with res_then_gap and a ", CHOSEN_THRESHOLD, "-day threshold ---")
v <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
a <- readRDS(file.path(DIR_PROCESSED, "attempts.rds"))
v$src_k <- norm_user(v$src); set_at <- split(v$src_k, v$attempt_id)
a$cand_k <- norm_user(a$candidate); per <- split(a$attempt_id, a$cand_k)
best <- rep(NA_real_, nrow(ele)); bid <- rep(NA_integer_, nrow(ele))
for (r in seq_len(nrow(ele))) {
  ids <- per[[ele$cand_k[r]]]; if (is.null(ids)) next
  s <- set_el[[as.character(ele$election_id[r])]]
  jj <- vapply(ids, function(k) jac(s, set_at[[as.character(k)]]), 0)
  best[r] <- max(jj); bid[r] <- ids[which.max(jj)]
}
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
missing_from_me <- mapply(function(r, k)
  length(setdiff(set_el[[as.character(r)]], set_at[[as.character(k)]])),
  ele$election_id[ok], ele$my_attempt[ok])
missing_from_them <- mapply(function(r, k)
  length(setdiff(set_at[[as.character(k)]], set_el[[as.character(r)]])),
  ele$election_id[ok], ele$my_attempt[ok])
note("disagreement on individual voters (medians): wiki-Elec holds ",
     median(missing_from_me), " that we do not, we hold ", median(missing_from_them),
     " that it does not,")
note("  out of a median of ",
     median(lengths(set_el)[as.character(ele$election_id[ok])]),
     " voters per election. Similar sizes (identical in ",
     sum(lengths(set_el)[as.character(ele$election_id[ok])] ==
           a$n_votes[match(ele$my_attempt[ok], a$attempt_id)]),
     " elections), different lists.")

a$elec_matched  <- a$attempt_id %in% ele$my_attempt[ok]
a$elec_outcome  <- ele$outcome[match(a$attempt_id, ele$my_attempt)]
a$elec_jaccard  <- ele$jaccard[match(a$attempt_id, ele$my_attempt)]
a$outcome_agrees <- ifelse(a$elec_matched, (a$outcome == 1) == (a$elec_outcome == 1), NA)
saveRDS(a, file.path(DIR_PROCESSED, "attempts_validated.rds"))
write.csv(ele[, c("election_id", "candidate", "outcome", "closed_at", "last_vote",
                  "jaccard", "my_attempt")],
          file.path(DIR_PROCESSED, "03_match_wikielec.csv"), row.names = FALSE)
note("LIMIT: the validation covers ", sum(a$elec_matched), " attempts of ", nrow(a),
     sprintf(" (%.0f%%)", 100 * mean(a$elec_matched)),
     ". Outside the period covered by wiki-Elec, that is from 2008 to 2013,",
     " no validation exists.")
note("written: attempts_validated.rds, 03_match_wikielec.csv")
writeLines(log_lines, file.path(DIR_PROCESSED, "03_log.txt"))
