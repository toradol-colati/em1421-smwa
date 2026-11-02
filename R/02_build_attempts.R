# 02 - Attempt reconstruction: one row per (candidate, attempt).
# Input : data/processed/votes_raw.rds
# Output: data/processed/votes.rds              one row per validated vote
#         data/processed/attempts.rds           one row per attempt
#         data/processed/records_without_voter.csv
#         data/processed/02_log.txt             every quantity, for the report
# Packages: none (base R).
#
# PRINCIPLE: do not filter, flag. Every problematic row stays in the table with
# a flag column, so whoever analyses decides what to exclude, not whoever
# cleans. Only two kinds of row are dropped, and both are counted in the log:
# the voter-less phantom records, which are not votes at all, and the undated
# votes that cannot be attributed to a single attempt.
#
# The threshold is a PARAMETER, not an assumption: 03_validate_outcomes.R picks
# it by comparing the reconstruction against the real elections of wiki-Elec.
# The value set here is the published precedent (Kolczynska) and the nominal
# length of an RfA.

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

MODE               <- "res_then_gap"  # grouping rule, see 00_lib_data.R
                                      # variants (harej/Harej). FALSE keeps the
                                      # SNAP convention of 11,381 nodes.

log_lines <- character(0)
note <- function(...) {
  s <- paste0(...)
  log_lines <<- c(log_lines, s)
  cat(s, "\n", sep = "")
}

# --- 1. raw votes, columns renamed in lowercase ------------------------------
raw <- readRDS(file.path(DIR_PROCESSED, "votes_raw.rds"))
d <- data.frame(
  vote_id = raw$vote_id,
  src = raw$SRC, tgt = raw$TGT,
  vot = as.integer(raw$VOT), res = as.integer(raw$RES),
  yea = as.integer(raw$YEA),
  stringsAsFactors = FALSE
)
d$self_vote <- d$src == d$tgt
note("incoming records: ", nrow(d))

if (MERGE_FIRST_LETTER) {
  d$src <- capitalise_first(d$src); d$tgt <- capitalise_first(d$tgt)
  note("usernames: first letter merged -> distinct nodes: ",
       length(unique(c(d$src, d$tgt))))
} else {
  note("usernames: SNAP spelling kept -> distinct nodes: ",
       length(unique(c(d$src, d$tgt))))
}
d$self_vote <- d$src == d$tgt

# --- 2. dates ----------------------------------------------------------------
dd <- parse_dat(raw$DAT)
d$dat <- dd
d$dat_missing <- is.na(d$dat)
note("records with an empty DAT field: ", attr(dd, "n_empty"),
     sprintf("  (%.2f%% of all records)", 100 * attr(dd, "n_empty") / nrow(d)))
note("DAT present but not interpretable: ", attr(dd, "n_unparsed"),
     "  (unrecognised format: ", attr(dd, "n_bad_format"),
     " | impossible value, e.g. hour 31: ", attr(dd, "n_impossible"), ")")

# --- 3. phantom records, with no voter ---------------------------------------
# 1,661 records have SRC empty, and ALL of them also have TXT and DAT empty:
# they are phantom records of the file, not votes. They touch 926 candidates,
# concentrated in 2006 (800 of them). Left in the table they would become a
# SINGLE NODE with 1,661 outgoing edges towards 926 candidates: a hub that does
# not exist, which would distort every centrality measure and the whole
# co-voting projection. They cannot be "flagged": a vote with no voter is not an
# edge. They are removed and written out separately so that nothing disappears
# silently.
no_voter <- d[d$src == "", ]
write.csv(no_voter[, c("vote_id", "tgt", "vot", "res", "yea")],
          file.path(DIR_PROCESSED, "records_without_voter.csv"), row.names = FALSE, fileEncoding = "UTF-8")
note("phantom records with an empty SRC, removed: ", nrow(no_voter),
     " of ", nrow(d), sprintf("  (%.2f%%)", 100 * nrow(no_voter) / nrow(d)))
note("  candidates touched: ", length(unique(no_voter$tgt)),
     " | listed in records_without_voter.csv")
d <- d[d$src != "", ]
note("votes with an identifiable voter: ", nrow(d))

# --- 4. self-votes -----------------------------------------------------------
note("self-votes (the candidate voting in their own RfA): ", sum(d$src == d$tgt),
     "  -> kept in the table, flagged by the self_vote column")

# --- 5. where the undated votes fall -----------------------------------------
undated <- d[d$dat_missing, ]
note("undated votes, among those with a voter: ", nrow(undated))
note("candidates touched by undated votes: ", length(unique(undated$tgt)))
note("  of which with a single YEA among their undated votes: ",
     sum(tapply(undated$yea, undated$tgt, function(x) length(unique(x))) == 1))

# --- 6. fully identical rows -------------------------------------------------
row_keys <- paste(d$src, d$tgt, d$vot, d$res, d$yea, format(d$dat), sep = "\r")
note("fully identical rows (same voter, candidate, vote, outcome, year, date): ",
     sum(duplicated(row_keys)))

# --- 7. reconstruction -------------------------------------------------------
v <- reconstruct_attempts(d, THRESHOLD_DAYS, MODE)
note("rule: ", MODE, "; threshold: ", THRESHOLD_DAYS, " days")
note("dated votes used in the reconstruction: ", nrow(v))
note("attempts reconstructed: ", length(unique(v$attempt_id)))
note("candidates with at least one attempt: ", length(unique(v$tgt)))

# --- 8. deduplication within the attempt -------------------------------------
v <- dedup_votes(v)
note("votes removed because the same voter appears more than once in the same ",
     "attempt (most recent kept): ", attr(v, "n_rows_removed"))
note("validated votes: ", nrow(v))

# --- 9. attribution of the undated votes -------------------------------------
# They are attached only where the attribution is unambiguous: the candidate has
# a single attempt with that year and that outcome. The rest stay out, counted.
# A provisional attempt table, built on dated votes only, is needed just to know
# which (candidate, year, outcome) keys are unique.
a <- build_attempts(v)
a$key <- paste(a$candidate, a$yea, a$outcome)
unique_keys <- a$key[!duplicated(a$key) & !(a$key %in% a$key[duplicated(a$key)])]
undated$key <- paste(undated$tgt, undated$yea, undated$res)
undated$attempt_id <- a$attempt_id[match(undated$key, a$key)]
undated$attempt_id[!(undated$key %in% unique_keys)] <- NA_integer_
note("undated votes attributed unambiguously: ", sum(!is.na(undated$attempt_id)),
     " of ", nrow(undated))
note("undated votes that cannot be attributed (dropped): ",
     sum(is.na(undated$attempt_id)))
a$key <- NULL

# --- 10. attempt table, built on the COMPLETE vote table ---------------------
# ORDER MATTERS: the per-attempt counts (n_votes, n_support, ..., support_share)
# must be computed AFTER the attributed undated votes are put back, otherwise
# attempts.rds and votes.rds disagree and support_share silently excludes
# thousands of votes. That was a bug, caught by the invariant checks in
# R/99b_verify_output.R.
v$dat_imputed <- FALSE
if (any(!is.na(undated$attempt_id))) {
  extra <- undated[!is.na(undated$attempt_id), ]
  extra$attempt_no  <- a$attempt_no[match(extra$attempt_id, a$attempt_id)]
  extra$dat_imputed <- TRUE
  extra$key <- NULL
  common_cols <- intersect(names(v), names(extra))
  v <- rbind(v[, common_cols], extra[, common_cols])
}
# Second deduplication: within one attempt a voter may hold both a dated vote
# and an undated one that was attributed to them. The DATED vote is kept,
# because it can be checked. The first deduplication (step 8) could not see
# these, because the undated votes only enter here: another bug caught by the
# invariant checks.
v <- v[order(v$attempt_id, v$src, v$dat_imputed, v$dat, method = "radix"), ]
dup_second <- duplicated(v[, c("attempt_id", "src")])
note("votes removed in the second deduplication (same voter, one dated and one ",
     "imputed within the same attempt): ", sum(dup_second))
v <- v[!dup_second, ]
v <- v[order(v$attempt_id, v$src, method = "radix"), ]

a_dated <- a
a <- build_attempts(v)
a$n_votes_dated   <- a_dated$n_votes[match(a$attempt_id, a_dated$attempt_id)]
a$n_votes_imputed <- a$n_votes - a$n_votes_dated

# the previous outcome has to be recomputed on the final table
repeats <- table(a$candidate)
a$prev_outcome <- NA_integer_
for (cand in names(repeats)[repeats > 1]) {
  i <- which(a$candidate == cand); i <- i[order(a$attempt_no[i])]
  a$prev_outcome[i[-1]] <- a$outcome[i[-length(i)]]
}
note("attempts: ", nrow(a))
note("repeat candidates (2+ attempts): ", sum(repeats > 1),
     "   (the project brief states 414)")
note("  of which with 3+ attempts: ", sum(repeats > 2))
note("consecutive attempt pairs: ", sum(repeats[repeats > 1] - 1))
note("flagged attempts: few votes (<5): ", sum(a$flag_short),
     " | duration >14 days: ", sum(a$flag_long),
     " | same candidate/year/outcome: ", sum(a$flag_year_clash))
note("  preceded by a rejection: ", sum(a$prev_outcome == -1, na.rm = TRUE),
     " | preceded by a success: ", sum(a$prev_outcome == 1, na.rm = TRUE))

saveRDS(v, file.path(DIR_PROCESSED, "votes.rds"))
saveRDS(a, file.path(DIR_PROCESSED, "attempts.rds"))
writeLines(log_lines, file.path(DIR_PROCESSED, "02_log.txt"))
note("written: votes.rds (", nrow(v), " rows), attempts.rds (", nrow(a), " rows)")
