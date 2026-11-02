# Toolbox: functions shared by several scripts. The data functions (used by
# 01, 02, 03, 99, 99b) need only base R; the network functions at the end
# (used by 04, 05, 94-97) need igraph and Matrix.

# --- parsers for the two files ------------------------------------------------
FIELDS <- c("SRC", "TGT", "VOT", "RES", "YEA", "DAT", "TXT")

read_rfa <- function(path) {
  stop_if_missing(path)
  lines <- readLines(gzfile(path), warn = FALSE, encoding = "UTF-8")
  keys  <- sub(":.*$", "", lines)
  vals  <- sub("^[A-Z]{3}:", "", lines)
  keep  <- keys %in% FIELDS
  # Safety check: the only lines we skip should be the blank lines between
  # records. If a non-empty line is skipped, some text would be lost.
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
  # NOTE 1 - clean the spelling of usernames, because the file has three
  # problems:
  #  - 43 names have a space at the start or end (21 of them then look like a
  #    different person from the clean spelling);
  #  - one name has a double space inside ("Salvio  giuliano");
  #  - one name starts with an invisible character ("<U+200E>Jetijonez").
  # After cleaning there are 11,380 distinct names (SNAP reports 11,381).
  out$SRC <- clean_name(out$SRC)
  out$TGT <- clean_name(out$TGT)
  out$vote_id <- seq_len(nrow(out))
  out[, c("vote_id", FIELDS)]
}

# NOTE 2 - names that differ only in the first letter. On Wikipedia the first
# letter of a username is always a capital, so "harej" and "Harej" are the same
# person. Merging them brings the number of names from 11,381 to 11,243.
# Without merging, 8 candidates would look like two different people, each with
# one election. case_variants() lists all such names so the choice can be
# checked (the setting is MERGE_FIRST_LETTER in 00_paths.R).
capitalise_first <- function(s) {
  ifelse(s == "" | is.na(s), s,
         paste0(toupper(substr(s, 1, 1)), substr(s, 2, nchar(s))))
}

# Table of every name that has more than one spelling of the first letter,
# with how many votes each spelling cast and received.
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
# NOTE 3 - three problems in the wiki-Elec file:
#  (a) names are all lowercase and use "_" where wiki-RfA uses a space
#      ("dream_focus" vs "Dream Focus"); norm_user() below fixes this when the
#      two files are compared;
#  (b) 19 lines contain broken characters (all from one user). They are removed
#      with iconv(sub = ""). Reading the whole file as ISO-8859-1 instead would
#      break the names that are correct (anárion would become anÃ¡rion);
#  (c) lines end with Windows line endings (CRLF); the sub() below removes them
#      just in case (readLines() already does).
read_elec <- function(path) {
  stop_if_missing(path)
  lines <- iconv(readLines(gzfile(path), warn = FALSE, skipNul = TRUE),
                 from = "UTF-8", to = "UTF-8", sub = "")   # (b)
  lines <- sub("\r$", "", lines)                           # (c)
  lines <- lines[!startsWith(lines, "#") & nzchar(lines)]
  # The first letter of each line says what it is (E, T, U, N, V). A new
  # election starts at every "E" line, so cumsum() numbers the elections.
  tag   <- substr(lines, 1, 1)
  block <- cumsum(tag == "E")
  field_rows <- function(t) {
    i <- which(tag == t)
    data.frame(block = block[i], rest = sub("^.\t", "", lines[i]),
               stringsAsFactors = FALSE)
  }
  e <- field_rows("E"); tt <- field_rows("T"); u <- field_rows("U"); n <- field_rows("N")
  # One row per election (outcome, closing time, candidate, nominator).
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
  # One row per vote (election, vote, voter, date).
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
# Clean spelling within one file: remove invisible characters, turn repeated
# spaces into one, and trim spaces at the ends. Letter case is not changed here.
clean_name <- function(x) {
  for (code_point in c(0x200B:0x200F, 0xFEFF)) {
    x <- gsub(intToUtf8(code_point), "", x, fixed = TRUE)
  }
  x <- gsub("[[:space:]]+", " ", x)           # repeated or exotic blanks -> one
  trimws(x)
}

# Make names comparable between the two files: clean them, turn "_" into a
# space, and make everything lowercase (wiki-Elec is all lowercase).
norm_user <- function(x, lower = TRUE) {
  x <- clean_name(gsub("_", " ", x))
  if (lower) tolower(x) else x
}

# --- dates --------------------------------------------------------------------
# NOTE 4 - reading the DAT field ("HH:MM, DD Month YYYY"). Problems in the file:
#  - 7,707 real votes have no date;
#  - 7,077 dates use short month names (Jan, Feb, ...);
#  - 3 months are misspelled ("Janry", "Julu", "Mya");
#  - 1 date has an impossible hour ("31:29, 24 May 2008").
# Month names are translated with our own table, so the result is the same on
# every computer, whatever its language settings.
MONTHS <- c(
  january = 1, february = 2, march = 3, april = 4, may = 5, june = 6,
  july = 7, august = 8, september = 9, october = 10, november = 11, december = 12,
  jan = 1, feb = 2, mar = 3, apr = 4, jun = 6, jul = 7, aug = 8,
  sep = 9, oct = 10, nov = 11, dec = 12,
  janry = 1, julu = 7, mya = 5          # misspellings found in the source
)

parse_dat <- function(x) {
  x <- trimws(x)
  # Split "HH:MM, DD Month YYYY" into its parts and build a date in UTC.
  # Values that do not have this format stay NA.
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
  # Count problems after building the dates: a value like "31:29" has the right
  # format but is still not a real time, so it becomes NA.
  attr(res, "n_bad_format") <- sum(!ok & nzchar(x))
  attr(res, "n_impossible") <- sum(ok & is.na(res))
  attr(res, "n_unparsed")        <- sum(!ok & nzchar(x)) + sum(ok & is.na(res))
  attr(res, "n_empty")              <- sum(!nzchar(x))
  res
}

# NOTE ON SORTING - every order() on usernames uses method = "radix". Without
# it, R sorts names according to the computer's language settings, and the same
# data got different attempt_id numbers on Windows and on macOS. "radix" sorts
# the same way on every computer.

# --- attempt reconstruction ---------------------------------------------------
# Three ways to split a candidate's votes into elections. Script 03 compares
# all three against wiki-Elec.
#
# "res_then_gap" (the one we use): first group the votes by candidate and
#   result (RES), then start a new election when there is a gap of more than
#   threshold_days without votes. Two elections with different results stay
#   apart because of RES, and a single stray vote cannot split an election.
#
# "gap_then_res" (rejected): sort by date, and start a new election when the
#   gap is too long or the result changes. One stray vote with a different
#   result inside an election splits it into pieces (candidate ABCD got four
#   elections in one week).
#
# "gap_only" (sensitivity check): use only the date gap; an election with
#   mixed results gets an unknown result.
#
# We do not use YEA: 1,875 votes have a date in a different year from YEA.
# Undated votes cannot be sorted by date, so they are left out here and added
# later in 02, only when their election is certain.
reconstruct_attempts <- function(d, threshold_days, mode = "res_then_gap") {
  stopifnot(all(c("tgt", "vot", "res", "yea", "dat") %in% names(d)))
  stopifnot(mode %in% c("res_then_gap", "gap_then_res", "gap_only"))
  d <- d[!is.na(d$dat), ]
  if (nrow(d) == 0) return(d)
  if (mode == "res_then_gap") {
    d <- d[order(d$tgt, d$res, d$dat, method = "radix"), ]
    n <- nrow(d)
    group_change <- c(TRUE, d$tgt[-1] != d$tgt[-n] | d$res[-1] != d$res[-n])
  } else if (mode == "gap_then_res") {
    d <- d[order(d$tgt, d$dat, method = "radix"), ]
    n <- nrow(d)
    group_change <- c(TRUE, d$tgt[-1] != d$tgt[-n] | d$res[-1] != d$res[-n])
  } else {
    d <- d[order(d$tgt, d$dat, method = "radix"), ]
    n <- nrow(d)
    group_change <- c(TRUE, d$tgt[-1] != d$tgt[-n])
  }
  # Days since the previous vote. A new election starts when the group changes
  # or the gap is longer than threshold_days; cumsum() then numbers them.
  gap_days <- c(NA_real_, as.numeric(difftime(d$dat[-1], d$dat[-n], units = "days")))
  is_new <- group_change | (!group_change & gap_days > threshold_days)
  is_new[is.na(is_new)] <- TRUE
  d$attempt_id <- cumsum(is_new)
  # running number of the attempt within the candidate, by opening date
  ap <- tapply(as.numeric(d$dat), d$attempt_id, min)
  first_tbl <- data.frame(attempt_id = as.integer(names(ap)), opened = as.numeric(ap))
  first_tbl$tgt <- d$tgt[match(first_tbl$attempt_id, d$attempt_id)]
  first_tbl <- first_tbl[order(first_tbl$tgt, first_tbl$opened, method = "radix"), ]
  first_tbl$attempt_no <- ave(first_tbl$opened, first_tbl$tgt, FUN = seq_along)
  d$attempt_no <- first_tbl$attempt_no[match(d$attempt_id, first_tbl$attempt_id)]
  d
}

# --- deduplication ------------------------------------------------------------
# Remove duplicate votes: if a voter appears more than once in the same
# election (a changed vote or a repeated row), keep their most recent vote.
dedup_votes <- function(d) {
  o <- order(d$attempt_id, d$src, d$dat, method = "radix")
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
  # start and end dates use dated votes only (undated votes have no date)
  a$opened_at    <- as.POSIXct(vapply(spl, function(i) min(as.numeric(v$dat[i]), na.rm = TRUE), 0),
                               origin = "1970-01-01", tz = "UTC")
  a$closed_at    <- as.POSIXct(vapply(spl, function(i) max(as.numeric(v$dat[i]), na.rm = TRUE), 0),
                               origin = "1970-01-01", tz = "UTC")
  a$n_votes      <- vapply(spl, length, 0L)
  a$n_support    <- vapply(spl, function(i) sum(v$vot[i] ==  1), 0L)
  a$n_oppose     <- vapply(spl, function(i) sum(v$vot[i] == -1), 0L)
  a$n_neutral    <- vapply(spl, function(i) sum(v$vot[i] ==  0), 0L)
  # self-votes: the candidate voting in their own election (kept, counted)
  a$n_self_votes <- vapply(spl, function(i) sum(v$src[i] == v$tgt[i]), 0L)
  # support share = support / (support + oppose); neutral votes are not counted
  a$support_share <- ifelse(a$n_support + a$n_oppose > 0,
                            a$n_support / (a$n_support + a$n_oppose), NA_real_)
  a$duration_days <- as.numeric(difftime(a$closed_at, a$opened_at, units = "days"))
  # flags for possible problems (rows are kept, only marked)
  a$flag_short      <- a$n_votes < 5          # very few votes
  a$flag_long       <- a$duration_days > 14   # longer than a normal RfA
  # two elections of the same candidate in the same year with the same result
  # might be one election split in two. The year comes from the first vote's
  # date, not from YEA, which is sometimes wrong.
  a$year_from_date <- as.integer(format(a$opened_at, "%Y"))
  key <- paste(a$candidate, a$year_from_date, a$outcome)
  a$flag_year_clash <- key %in% key[duplicated(key)]
  a[order(a$candidate, a$attempt_no, method = "radix"), ]
}

# --- co-voting networks (used by 04, 05, 94-97) --------------------------------
# Votes used in the network analysis: assigned to an election, support or
# oppose (neutral votes left out), no self-votes; with the year of the election.
network_votes <- function(votes, attempts) {
  v <- votes[!is.na(votes$attempt_id) & votes$vot %in% c(-1L, 1L) & !votes$self_vote, ]
  v$year <- attempts$year_from_date[match(v$attempt_id, attempts$attempt_id)]
  v
}

# Co-voting network built from the votes before cutoff_year (Lab 5b projection).
# Bipartite network: one row per side of an election (supporters of election
# 12, opposers of election 12, ...), one column per voter. crossprod() projects
# it onto voters: cell (A, B) = number of elections in which A and B voted the
# same way (same result as bipartite.projection(), but fast on a large sparse
# matrix). Pairs with 2+ agreements become edges weighted by that number.
# The calling script must load Matrix (library(Matrix)). NULL if no edges.
covoting_graph <- function(votes, cutoff_year, all_voters) {
  h <- votes[votes$year < cutoff_year, ]
  if (nrow(h) == 0L) return(NULL)
  side <- paste(h$attempt_id, h$vot, sep = "|")
  incidence <- Matrix::sparseMatrix(i = match(side, unique(side)),
                                    j = match(h$src, all_voters), x = 1,
                                    dims = c(length(unique(side)), length(all_voters)))
  e <- summary(crossprod(incidence))      # needs library(Matrix) loaded
  e <- e[e$i < e$j & e$x >= 2, ]          # each pair once, 2+ agreements
  if (nrow(e) == 0L) return(NULL)
  igraph::graph_from_data_frame(
    data.frame(from = all_voters[e$i], to = all_voters[e$j], weight = e$x),
    directed = FALSE)
}
