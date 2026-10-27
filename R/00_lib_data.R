# Shared functions of the data workstream. Sourced by 01, 02, 03 and by the two
# verification scripts. Base R only: no dependencies.

# --- parsers for the two files ------------------------------------------------
FIELDS <- c("SRC", "TGT", "VOT", "RES", "YEA", "DAT", "TXT")

read_rfa <- function(path) {
  stop_if_missing(path)
  lines <- readLines(gzfile(path), warn = FALSE, encoding = "UTF-8")
  keys  <- sub(":.*$", "", lines)
  vals  <- sub("^[A-Z]{3}:", "", lines)
  keep  <- keys %in% FIELDS
  # Sanity check: the discarded lines must be the blank separators only. If any
  # non-empty line is dropped, TXT comments span several lines and the parser
  # would be losing text without noticing.
  dropped_non_empty <- sum(!keep & lines != "")
  if (dropped_non_empty > 0) {
    warning("non-empty lines discarded: ", dropped_non_empty,
            " (multi-line TXT comments?)")
  }
  keys <- keys[keep]; vals <- vals[keep]
  rec  <- cumsum(keys == "SRC")   # every SRC line opens a new record
  n_fields <- table(table(rec))
  if (length(n_fields) != 1L || names(n_fields)[1] != "7") {
    warning("records whose field count is not 7: ",
            paste(names(n_fields), n_fields, sep = "x", collapse = " "))
  }
  out <- as.data.frame(tapply(vals, list(rec, keys), identity),
                       stringsAsFactors = FALSE)
  # NOTE 1 - the spelling of a username is NOT its identity. Three fixes, each
  # forced by a defect measured in the file:
  #  - 43 spellings carry a leading or trailing blank, and 21 of those collide
  #    with the clean form already present: without trimming, distinct names are
  #    11,402 instead of 11,381, the figure published by SNAP;
  #  - one name has a double internal space ("Salvio  giuliano") and collides
  #    with the single-space form, which is already present;
  #  - one name carries an invisible marker at the front (U+200E, LEFT-TO-RIGHT
  #    MARK: "<U+200E>Jetijonez"), which would make it a node of its own.
  # After normalisation the distinct names are 11,380.
  out$SRC <- clean_name(out$SRC)
  out$TGT <- clean_name(out$TGT)
  out$vote_id <- seq_len(nrow(out))
  out[, c("vote_id", FIELDS)]
}

# NOTE 2 - first-letter case variants. On Wikipedia the first letter of a
# username is always capitalised, so "harej" and "Harej" are the same account.
# The SNAP total of 11,381 does NOT merge them; merging brings the count down to
# 11,243. OPEN DECISION (it concerns both roles): merge or not. If they are not
# merged, 8 candidates look like two different people with one attempt each and
# fall outside the repeat-candidate population. This function lists the cases so
# the decision can be made on data rather than by intuition.
capitalise_first <- function(s) {
  ifelse(s == "" | is.na(s), s,
         paste0(toupper(substr(s, 1, 1)), substr(s, 2, nchar(s))))
}

case_variants <- function(d) {
  names_all <- unique(c(d$SRC, d$TGT))
  groups <- split(names_all, capitalise_first(names_all))
  ambiguous <- groups[lengths(groups) > 1]
  if (length(ambiguous) == 0) return(data.frame())
  do.call(rbind, lapply(names(ambiguous), function(nm) {
    spellings <- ambiguous[[nm]]
    data.frame(
      merged_name    = nm,
      spelling       = spellings,
      n_votes_cast   = vapply(spellings, function(f) sum(d$SRC == f), integer(1)),
      n_votes_received = vapply(spellings, function(f) sum(d$TGT == f), integer(1)),
      years_as_candidate = vapply(spellings, function(f) {
        paste(sort(unique(d$YEA[d$TGT == f])), collapse = ";")
      }, character(1)),
      row.names = NULL, stringsAsFactors = FALSE
    )
  }))
}

# wiki-Elec: blocks, one per election, fields separated by tabs.
#   E <0|1>                                          outcome
#   T <YYYY-MM-DD HH:MM:SS>                          declared closing time
#   U <id> <username>                                candidate
#   N <id> <username>                                nominator (may be missing)
#   V <vote> <id> <YYYY-MM-DD HH:MM:SS> <username>   one vote per line
# NOTE 3 - three traps in this file, all about node identity:
#  (a) usernames are ALL LOWERCASE here, while wiki-RfA keeps the original
#      spelling, and wiki-Elec uses an UNDERSCORE where wiki-RfA uses a SPACE
#      (408 names with an underscore and 0 with a space, against 0 and 606 in
#      wiki-RfA). Normalising the names raises the share of wiki-Elec candidates
#      found again in wiki-RfA from 74.9% to 89.8%: see norm_user() below;
#  (b) the file is UTF-8 but contains corrupt bytes: 19 lines out of 128,016 are
#      not valid UTF-8, and all of them belong to the same user (a truncated
#      sequence, "eivind_f_<c3>yangen"). Without intervention substr() stops
#      with "invalid multibyte string". Invalid bytes are dropped with
#      iconv(sub = ""): converting the whole file from ISO-8859-1, which the
#      success of 'iconv -f ISO-8859-1' would seem to suggest, is WRONG, because
#      it ruins the names that were correct UTF-8 (anarion -> anÃ¡rion);
#  (c) lines end in CRLF. R's readLines() already strips the terminator, so the
#      sub() below is a safety net that does nothing here; it would matter when
#      reading the file with readBin, with scan(sep = "\n"), or on a connection
#      opened in binary mode.
read_elec <- function(path) {
  stop_if_missing(path)
  lines <- iconv(readLines(gzfile(path), warn = FALSE, skipNul = TRUE),
                 from = "UTF-8", to = "UTF-8", sub = "")   # (b)
  lines <- sub("\r$", "", lines)                           # (c)
  lines <- lines[!startsWith(lines, "#") & nzchar(lines)]
  tag   <- substr(lines, 1, 1)
  block <- cumsum(tag == "E")
  field_rows <- function(t) {
    i <- which(tag == t)
    data.frame(block = block[i], rest = sub("^.\t", "", lines[i]),
               stringsAsFactors = FALSE)
  }
  e <- field_rows("E"); tt <- field_rows("T"); u <- field_rows("U"); n <- field_rows("N")
  part_of <- function(x, k) vapply(strsplit(x, "\t", fixed = TRUE),
                                 function(p) if (length(p) >= k) p[k] else NA_character_,
                                 character(1))
  elections <- data.frame(
    election_id = e$block,
    outcome     = as.integer(e$rest),                       # 1 promoted, 0 not
    closed_at   = as.POSIXct(tt$rest[match(e$block, tt$block)],
                             format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    candidate   = trimws(part_of(u$rest[match(e$block, u$block)], 2)),
    nominator   = trimws(part_of(n$rest[match(e$block, n$block)], 2)),
    stringsAsFactors = FALSE
  )
  iv <- which(tag == "V")
  pv <- strsplit(sub("^V\t", "", lines[iv]), "\t", fixed = TRUE)
  elec_votes <- data.frame(
    election_id = block[iv],
    vot   = as.integer(vapply(pv, `[`, character(1), 1)),
    voter = trimws(vapply(pv, function(p) if (length(p) >= 4) p[4] else NA_character_,
                          character(1))),
    dat   = as.POSIXct(vapply(pv, function(p) if (length(p) >= 3) p[3] else NA_character_,
                              character(1)),
                       format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    stringsAsFactors = FALSE
  )
  list(elections = elections, votes = elec_votes)
}

# --- user identity ------------------------------------------------------------
# Spelling normalisation WITHIN a single file: strips invisible characters,
# collapses repeated blanks and trims the edges. It does not touch letter case:
# that is an open decision (MERGE_FIRST_LETTER in 02).
clean_name <- function(x) {
  x <- gsub("[​-‏﻿]", "", x)   # direction marks and similar
  x <- gsub("[[:space:]]+", " ", x)           # repeated or exotic blanks -> one
  trimws(x)
}

# Comparison key ACROSS the two files. Three normalisations, each forced by a
# measured defect, not by generic caution:
#  - clean_name, for the reasons in NOTE 1;
#  - underscore -> space: wiki-Elec writes "dream_focus", wiki-RfA "Dream Focus";
#  - tolower: wiki-Elec is entirely lowercase. On Wikipedia the first letter of a
#    username is always capitalised, so "harej" and "Harej" are the same account:
#    for COMPARING the two files, tolower is correct. Whether to apply it WITHIN
#    wiki-RfA as well, merging 137 groups of spellings, is an open decision (see
#    the documentation): it changes the node count and the study population.
norm_user <- function(x, lower = TRUE) {
  x <- clean_name(gsub("_", " ", x))
  if (lower) tolower(x) else x
}

# --- dates --------------------------------------------------------------------
# NOTE 4 - the DAT field of wiki-RfA has the shape "HH:MM, DD Month YYYY", but:
#  - 9,367 records have DAT empty, and 1,661 of those are the voter-less phantom
#    records removed in 02, so the real figure among actual votes is 7,707;
#  - 7,077 use the abbreviated month (Jan, Feb, ...). "May" is identical in both
#    forms and is therefore not a problem case;
#  - 3 have the month misspelled in the source: "Janry", "Julu", "Mya";
#  - 1 has an impossible value: "31:29, 24 May 2008", hour 31.
# A parser built on format = "%d %B %Y" would depend on LC_TIME (so it would
# give different results on another machine) and would silently turn 7,080 dates
# into NA. Here the month is translated with an explicit, locale-independent
# table.
MONTHS <- c(
  january = 1, february = 2, march = 3, april = 4, may = 5, june = 6,
  july = 7, august = 8, september = 9, october = 10, november = 11, december = 12,
  jan = 1, feb = 2, mar = 3, apr = 4, jun = 6, jul = 7, aug = 8,
  sep = 9, oct = 10, nov = 11, dec = 12,
  janry = 1, julu = 7, mya = 5          # misspellings found in the source
)

parse_dat <- function(x) {
  x <- trimws(x)
  m <- regmatches(x, regexec(
    "^([0-9]{1,2}):([0-9]{2}), ([0-9]{1,2}) ([A-Za-z]+) ([0-9]{4})$", x))
  ok <- lengths(m) == 6L
  out <- rep(NA_real_, length(x))
  if (any(ok)) {
    p <- do.call(rbind, m[ok])
    month_num <- MONTHS[tolower(p[, 5])]
    iso <- sprintf("%s-%02d-%02d %02d:%02d:00",
                   p[, 6], month_num, as.integer(p[, 4]),
                   as.integer(p[, 2]), as.integer(p[, 3]))
    out[ok] <- as.numeric(as.POSIXct(iso, format = "%Y-%m-%d %H:%M:%S", tz = "UTC"))
  }
  res <- as.POSIXct(out, origin = "1970-01-01", tz = "UTC")
  # Careful: passing the format check is not enough. One record reads
  # "31:29, 24 May 2008": hour 31 satisfies the regex but as.POSIXct rejects it
  # and returns NA. The diagnostic must count the NAs produced AFTER the date is
  # built, not just the unrecognised formats, otherwise it reports zero when the
  # true figure is one (it used to).
  attr(res, "n_bad_format") <- sum(!ok & nzchar(x))
  attr(res, "n_impossible") <- sum(ok & is.na(res))
  attr(res, "n_unparsed")        <- sum(!ok & nzchar(x)) + sum(ok & is.na(res))
  attr(res, "n_empty")              <- sum(!nzchar(x))
  res
}

# --- attempt reconstruction ---------------------------------------------------
# Two rules, compared against wiki-Elec in 03 instead of being picked by feel.
#
# "gap_then_res": sort by date within the candidate and open a new attempt when
#   the gap exceeds the threshold or RES changes. DISCARDED after testing: a
#   single vote carrying a different RES, sitting inside an election, splits it
#   in three. It produced 1,420 single-vote attempts concentrated on 95
#   candidates (e.g. ABCD: four attempts in one week with outcomes alternating
#   -1, 1, -1, 1). It is kept implemented because the comparison between the two
#   rules is itself a result.
#
# "res_then_gap": group by (candidate, RES) and, within each group, open a new
#   attempt when the gap exceeds the threshold. The votes of two nearby
#   elections with different outcomes separate through RES, and a stray vote
#   does no damage. This is also the rule of the published precedent
#   (Kolczynska), which groups by candidate, year and outcome. The year is NOT
#   used here: YEA is unreliable, 1,875 votes carry a date in a different year
#   from the declared one, in coherent blocks (e.g. Scienceman123, YEA 2008,
#   votes dated March 2006).
#
# Undated votes cannot be ordered: they stay out and are attached afterwards,
# only where the attribution is unambiguous (see 02).
reconstruct_attempts <- function(d, threshold_days, mode = "res_then_gap") {
  stopifnot(all(c("tgt", "vot", "res", "yea", "dat") %in% names(d)))
  stopifnot(mode %in% c("res_then_gap", "gap_then_res"))
  d <- d[!is.na(d$dat), ]
  if (nrow(d) == 0) return(d)
  if (mode == "res_then_gap") {
    d <- d[order(d$tgt, d$res, d$dat), ]
    n <- nrow(d)
    group_change <- c(TRUE, d$tgt[-1] != d$tgt[-n] | d$res[-1] != d$res[-n])
  } else {
    d <- d[order(d$tgt, d$dat), ]
    n <- nrow(d)
    group_change <- c(TRUE, d$tgt[-1] != d$tgt[-n] | d$res[-1] != d$res[-n])
    group_change[1] <- TRUE
  }
  gap_days <- c(NA_real_, as.numeric(difftime(d$dat[-1], d$dat[-n], units = "days")))
  is_new <- group_change | (!group_change & gap_days > threshold_days)
  is_new[is.na(is_new)] <- TRUE
  d$attempt_id <- cumsum(is_new)
  # running number of the attempt within the candidate, by opening date
  ap <- tapply(as.numeric(d$dat), d$attempt_id, min)
  first_tbl <- data.frame(attempt_id = as.integer(names(ap)), opened = as.numeric(ap))
  first_tbl$tgt <- d$tgt[match(first_tbl$attempt_id, d$attempt_id)]
  first_tbl <- first_tbl[order(first_tbl$tgt, first_tbl$opened), ]
  first_tbl$attempt_no <- ave(first_tbl$opened, first_tbl$tgt, FUN = seq_along)
  d$attempt_no <- first_tbl$attempt_no[match(d$attempt_id, first_tbl$attempt_id)]
  d
}

# --- deduplication ------------------------------------------------------------
# A voter may appear more than once within the same attempt: a changed vote, or
# a duplicated row. Rule: keep that voter's most recent vote in that attempt.
# The most plausible reading is that the voter changed their mind, in which case
# the duplicate is signal rather than noise. Returns the cleaned table and the
# number of rows removed.
dedup_votes <- function(d) {
  o <- order(d$attempt_id, d$src, d$dat)
  d <- d[o, ]
  keep_row <- !duplicated(d[, c("attempt_id", "src")], fromLast = TRUE)
  attr(d, "n_rows_removed") <- sum(!keep_row)
  structure(d[keep_row, ], n_rows_removed = sum(!keep_row))
}

# --- attempt-level table ------------------------------------------------------
build_attempts <- function(v) {
  a <- data.frame(
    attempt_id   = sort(unique(v$attempt_id)),
    stringsAsFactors = FALSE
  )
  idx <- match(a$attempt_id, v$attempt_id)
  a$candidate  <- v$tgt[idx]
  a$attempt_no <- v$attempt_no[idx]
  a$outcome    <- v$res[idx]                       # -1 rejected, 1 approved
  a$yea        <- v$yea[idx]
  spl <- split(seq_len(nrow(v)), v$attempt_id)
  spl <- spl[as.character(a$attempt_id)]
  # opening and closing come from DATED votes only: imputed votes carry no date
  # and must not move the boundaries of the attempt
  a$opened_at    <- as.POSIXct(vapply(spl, function(i) min(as.numeric(v$dat[i]), na.rm = TRUE), 0),
                               origin = "1970-01-01", tz = "UTC")
  a$closed_at    <- as.POSIXct(vapply(spl, function(i) max(as.numeric(v$dat[i]), na.rm = TRUE), 0),
                               origin = "1970-01-01", tz = "UTC")
  a$n_votes      <- vapply(spl, length, 0L)
  a$n_support    <- vapply(spl, function(i) sum(v$vot[i] ==  1), 0L)
  a$n_oppose     <- vapply(spl, function(i) sum(v$vot[i] == -1), 0L)
  a$n_neutral    <- vapply(spl, function(i) sum(v$vot[i] ==  0), 0L)
  # self-votes: the candidate voting in their own RfA. There are 103 in the raw
  # file and they are loops in the voting network; they stay in the table, flagged.
  a$n_self_votes <- vapply(spl, function(i) sum(v$src[i] == v$tgt[i]), 0L)
  # support share over support and oppose votes only: neutrals are left out of
  # the denominator. This is a stated convention, not the only possible one.
  a$support_share <- ifelse(a$n_support + a$n_oppose > 0,
                            a$n_support / (a$n_support + a$n_oppose), NA_real_)
  a$duration_days <- as.numeric(difftime(a$closed_at, a$opened_at, units = "days"))
  # ambiguity flags
  a$flag_short      <- a$n_votes < 5          # few votes: possibly a fragment
  a$flag_long       <- a$duration_days > 14   # longer than a normal RfA
  # two attempts of the same candidate, in the same year, with the same outcome:
  # suspected of being a single attempt split by the threshold. The year is read
  # from the opening DATE, not from YEA: YEA is unreliable (1,875 votes carry a
  # date in a different year), and using it here would contradict the decision
  # not to use it in the reconstruction.
  a$year_from_date <- as.integer(format(a$opened_at, "%Y"))
  key <- paste(a$candidate, a$year_from_date, a$outcome)
  a$flag_year_clash <- key %in% key[duplicated(key)]
  a[order(a$candidate, a$attempt_no), ]
}
