# 02 - Rebuild the elections ("attempts"): one row per candidate and attempt.
# Input : data/processed/votes_raw.rds
# Output: data/processed/votes.rds              one row per validated vote
#         data/processed/attempts.rds           one row per attempt
#         data/processed/records_without_voter.csv
#         data/processed/02_log.txt             every quantity, for the report
# Packages: none (base R).
#
# Rule: flag problems instead of deleting rows. Problem rows stay in the table
# with a flag column, so the analysis decides what to exclude. Only two kinds
# of row are removed, and both are counted in the log: records with no voter
# (not real votes) and undated votes that cannot be placed in one election.
#
# The 7-day threshold is set in 00_paths.R. Script 03 tests other values
# against the real elections of wiki-Elec. Seven days is the length of an RfA.

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

MODE <- "res_then_gap"  # grouping rule, see reconstruct_attempts() in 00_lib_data.R

# note() prints a line and also saves it to data/processed/02_log.txt
log_lines <- character(0)
note <- function(...) { s <- paste0(...); log_lines <<- c(log_lines, s); cat(s, "\n", sep = "") }

# --- 1. raw votes, with lowercase column names ------------------------------
raw <- readRDS(file.path(DIR_PROCESSED, "votes_raw.rds"))
d <- data.frame(
  vote_id = raw$vote_id,
  src = raw$SRC, tgt = raw$TGT,
  vot = as.integer(raw$VOT), res = as.integer(raw$RES),
  yea = as.integer(raw$YEA),
  stringsAsFactors = FALSE
)
note("incoming records: ", nrow(d))

# Merge names that differ only in the first letter (setting in 00_paths.R).
if (MERGE_FIRST_LETTER) {
  d$src <- capitalise_first(d$src); d$tgt <- capitalise_first(d$tgt)
}
note("usernames: ", if (MERGE_FIRST_LETTER) "first letter merged" else "SNAP spelling kept",
     " -> distinct nodes: ", length(unique(c(d$src, d$tgt))))
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

# --- 3. records with no voter -----------------------------------------------
# 1,661 records have no voter, no comment and no date: they are not real votes.
# Kept, they would become one fake voter with 1,661 votes and distort every
# network measure. They are removed, and saved to records_without_voter.csv so
# nothing disappears without a trace.
no_voter <- d[d$src == "", ]
write.csv(no_voter[, c("vote_id", "tgt", "vot", "res", "yea")],
          file.path(DIR_PROCESSED, "records_without_voter.csv"), row.names = FALSE, fileEncoding = "UTF-8")
note("phantom records with an empty SRC, removed: ", nrow(no_voter),
     " of ", nrow(d), sprintf("  (%.2f%%)", 100 * nrow(no_voter) / nrow(d)))
note("  candidates touched: ", length(unique(no_voter$tgt)))
d <- d[d$src != "", ]
note("votes with an identifiable voter: ", nrow(d))

# --- 4. self-votes -----------------------------------------------------------
# A self-vote is the candidate voting in their own election. They stay in the
# table, marked in the self_vote column, and are left out of the networks.
note("self-votes: ", sum(d$src == d$tgt))

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
# If a voter appears twice in one election, their most recent vote is kept.
note("votes removed as duplicates: ", attr(v, "n_rows_removed"))
note("validated votes: ", nrow(v))

# --- 9. place the undated votes ----------------------------------------------
# An undated vote is added to an election only when there is exactly one
# possible election: the candidate has one attempt with that year and that
# result. The others are left out and counted. A first attempt table, built
# from dated votes only, tells us which (candidate, year, result) are unique.
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

# --- 10. final attempt table, built from all placed votes ---------------------
# The counts per election (n_votes, n_support, support_share, ...) must be
# computed after the undated votes are added back. Otherwise attempts.rds and
# votes.rds would disagree. (This was a real bug, found by R/99b_verify_output.R.)
v$dat_imputed <- FALSE
if (any(!is.na(undated$attempt_id))) {
  extra <- undated[!is.na(undated$attempt_id), ]
  extra$attempt_no  <- a$attempt_no[match(extra$attempt_id, a$attempt_id)]
  extra$dat_imputed <- TRUE
  extra$key <- NULL
  common_cols <- intersect(names(v), names(extra))
  v <- rbind(v[, common_cols], extra[, common_cols])
}
# Second duplicate check: a voter may now have both a dated vote and an undated
# one in the same election. We keep the dated one, because its date can be
# checked. Step 8 could not catch these, because undated votes are added here.
v <- v[order(v$attempt_id, v$src, v$dat_imputed, v$dat, method = "radix"), ]
dup_second <- duplicated(v[, c("attempt_id", "src")])
note("votes removed in the second duplicate check: ", sum(dup_second))
v <- v[!dup_second, ]
v <- v[order(v$attempt_id, v$src, method = "radix"), ]

a_dated <- a
a <- build_attempts(v)
a$n_votes_dated   <- a_dated$n_votes[match(a$attempt_id, a_dated$attempt_id)]
a$n_votes_imputed <- a$n_votes - a$n_votes_dated

# result of each candidate's previous election, from the final table
repeats <- table(a$candidate)
a$prev_outcome <- NA_integer_
for (cand in names(repeats)[repeats > 1]) {
  i <- which(a$candidate == cand); i <- i[order(a$attempt_no[i])]
  a$prev_outcome[i[-1]] <- a$outcome[i[-length(i)]]
}
note("attempts: ", nrow(a))
# The project brief said 414; the cleaned data give a different number.
note("repeat candidates (2+ attempts): ", sum(repeats > 1))
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
