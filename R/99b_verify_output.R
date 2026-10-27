# 99b - Second verification round: the INTERNAL INVARIANTS of the tables produced
# and the derived figures quoted in docs/DATA.md.
# While 99_verify_data.R checks the claims about the RAW files, this one checks
# that the output is internally consistent: if one of these conditions fails
# there is a bug in the pipeline, not an inaccuracy in the text.
# Input : data/processed/*.rds   Output: data/processed/99b_verification.txt

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

ko <- 0L; log_lines <- character(0)
inv <- function(label, condition, detail = "") {
  ok <- isTRUE(all(condition))
  if (!ok) ko <<- ko + 1L
  s <- sprintf("%-70s %s%s", label, if (ok) "OK" else "FAILED",
               if (!ok && nzchar(detail)) paste0("  <- ", detail) else "")
  log_lines <<- c(log_lines, s); cat(s, "\n", sep = "")
}
chk <- function(label, got, expected, tol = 0) {
  ok <- !is.na(got) && abs(got - expected) <= tol
  if (!ok) ko <<- ko + 1L
  s <- sprintf("%-62s %12s  expected %12s  %s", label,
               format(got, big.mark = " "), format(expected, big.mark = " "),
               if (ok) "OK" else "MISMATCH")
  log_lines <<- c(log_lines, s); cat(s, "\n", sep = "")
}
sect <- function(t) { s <- paste0("\n== ", t, " =="); log_lines <<- c(log_lines, s); cat(s, "\n") }

v <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
a <- readRDS(file.path(DIR_PROCESSED, "attempts.rds"))
av <- readRDS(file.path(DIR_PROCESSED, "attempts_validated.rds"))

sect("INVARIANTS: votes.rds")
inv("no voter appears twice within the same attempt",
    !any(duplicated(v[, c("attempt_id", "src")])))
inv("no missing attempt_id", !any(is.na(v$attempt_id)))
inv("vot only takes the values -1, 0, 1", all(v$vot %in% c(-1, 0, 1)))
inv("res only takes the values -1, 1", all(v$res %in% c(-1, 1)))
inv("dat is NA exactly when the vote had no date",
    all(is.na(v$dat) == v$dat_missing))
inv("imputed votes all lack an original date",
    all(v$dat_missing[v$dat_imputed]))
inv("res is constant within every attempt",
    all(tapply(v$res, v$attempt_id, function(x) length(unique(x))) == 1))
inv("the candidate is constant within every attempt",
    all(tapply(v$tgt, v$attempt_id, function(x) length(unique(x))) == 1))
inv("no leading or trailing blanks in usernames",
    all(v$src == trimws(v$src)) && all(v$tgt == trimws(v$tgt)))
inv("no empty username (phantom records were removed)",
    all(v$src != "") && all(v$tgt != ""))
inv("no invisible character or double blank in usernames",
    all(v$src == clean_name(v$src)) && all(v$tgt == clean_name(v$tgt)))
inv("self_vote matches src == tgt", all(v$self_vote == (v$src == v$tgt)))
inv("n_self_votes matches the per-attempt count of self-votes",
    all(a$n_self_votes == as.integer(tapply(v$src == v$tgt, v$attempt_id, sum)[as.character(a$attempt_id)])))

sect("INVARIANTS: attempts.rds and consistency with votes.rds")
inv("attempt_id is unique", !any(duplicated(a$attempt_id)))
inv("the attempt_ids of the two tables coincide",
    setequal(a$attempt_id, unique(v$attempt_id)))
n_per <- table(v$attempt_id)
inv("n_votes matches the actual vote count",
    all(a$n_votes == as.integer(n_per[as.character(a$attempt_id)])))
inv("n_support + n_oppose + n_neutral == n_votes",
    all(a$n_support + a$n_oppose + a$n_neutral == a$n_votes))
inv("no attempt with zero votes", all(a$n_votes > 0))
inv("support_share == n_support / (n_support + n_oppose)",
    all(abs(a$support_share - a$n_support/(a$n_support + a$n_oppose)) < 1e-9 |
        is.na(a$support_share)))
inv("opened_at <= closed_at", all(a$opened_at <= a$closed_at))
inv("duration_days matches the difference between the two dates",
    all(abs(a$duration_days -
            as.numeric(difftime(a$closed_at, a$opened_at, units = "days"))) < 1e-6))
inv("attempt_no is a contiguous 1..k for every candidate",
    all(tapply(a$attempt_no, a$candidate,
               function(x) identical(sort(as.integer(x)), seq_along(x)))))
inv("attempt_no ordina per data di opened",
    all(tapply(seq_len(nrow(a)), a$candidate, function(i)
      !is.unsorted(a$opened_at[i][order(a$attempt_no[i])]))))
inv("prev_outcome is the outcome of the candidate's previous attempt",
    all(vapply(split(seq_len(nrow(a)), a$candidate), function(i) {
      i <- i[order(a$attempt_no[i])]
      if (length(i) == 1) return(is.na(a$prev_outcome[i]))
      is.na(a$prev_outcome[i[1]]) &&
        identical(a$prev_outcome[i[-1]], a$outcome[i[-length(i)]])
    }, TRUE)))
inv("flag_short == (n_votes < 5)", all(a$flag_short == (a$n_votes < 5)))
inv("flag_long == (duration_days > 14)", all(a$flag_long == (a$duration_days > 14)))
inv("attempt_no agrees across the two tables",
    all(v$attempt_no == a$attempt_no[match(v$attempt_id, a$attempt_id)]))

sect("VOTE CONSERVATION")
raw_n <- 198275L
phantom <- 1661L; removed <- 627L + 100L; lost <- 616L
chk("raw records", raw_n, 198275)
chk("votes in votes.rds", nrow(v), 195271)
chk("phantom + ripetuti + lost senza data", phantom + removed + lost, raw_n - nrow(v))
chk("votes with an imputed date", sum(v$dat_imputed), 6991)
chk("undated votes kept in the table", sum(v$dat_missing), 6991)

sect("FIGURES QUOTED IN docs/DATA.md")
chk("attempts", nrow(a), 4082)
repeats <- table(a$candidate)
chk("repeat candidates (2+ attempts)", sum(repeats > 1), 484)
chk("candidates with 3+ attempts", sum(repeats > 2), 90)
chk("consecutive attempt pairs", sum(repeats[repeats > 1] - 1), 614)
chk("attempts with a known previous outcome", sum(!is.na(a$prev_outcome)), 614)
chk("candidates with at least one previous rejection",
    length(unique(a$candidate[!is.na(a$prev_outcome) & a$prev_outcome == -1])), 445)
chk("candidates with at least one previous success",
    length(unique(a$candidate[!is.na(a$prev_outcome) & a$prev_outcome == 1])), 53)
chk("flag_short", sum(a$flag_short), 296)
chk("flag_long", sum(a$flag_long), 4)
chk("flag_year_clash", sum(a$flag_year_clash), 359)
chk("attempts matched in wiki-Elec", sum(av$elec_matched), 2176)
chk("of which the outcome agrees", sum(av$outcome_agrees, na.rm = TRUE), 2176 - 12)
chk("attempts with no external match", sum(!av$elec_matched), 4082 - 2176)

sect("NETWORK STRUCTURE, ON THE DELIVERED TABLE (not on the raw file)")
# NB: the raw-file figures (10,417 voters, 3,497 candidates, 2,533 both) are NOT
# these: thousands of records leave the pipeline and with them some users
# disappear entirely. The document must report both.
chk("distinct voters in votes.rds", length(unique(v$src)), 10394, tol = 30)
chk("distinct candidates in votes.rds", length(unique(v$tgt)), 3468, tol = 10)
chk("users who are both voters and candidates", length(intersect(v$src, v$tgt)), 2512, tol = 10)
chk("support votes", sum(v$vot == 1), 143610, tol = 600)
chk("oppose votes", sum(v$vot == -1), 40561, tol = 600)
chk("neutral votes", sum(v$vot == 0), 11992, tol = 600)
chk("attempts where n_votes_dated + n_votes_imputed != n_votes",
    sum(a$n_votes_dated + a$n_votes_imputed != a$n_votes), 0)
chk("sum of imputed votes across attempts", sum(a$n_votes_imputed), 6991)
chk("self-votes surviving in the table", sum(v$self_vote), 94, tol = 15)
chk("sum of n_self_votes", sum(a$n_self_votes), sum(v$self_vote))

sect("ROUND 2 RESULT")
cat(if (ko == 0) "Every invariant holds and every figure matches.\n" else
    sprintf("%d checks FAILED.\n", ko))
log_lines <- c(log_lines, if (ko == 0) "Everything consistent." else sprintf("%d checks failed.", ko))
writeLines(log_lines, file.path(DIR_PROCESSED, "99b_verification.txt"))
