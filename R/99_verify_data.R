# 99 - Independent verification of the claims made in docs/DATA.md.
# Recomputes every figure STARTING FROM THE RAW FILES, without using any
# intermediate output, and compares it with what is stated. Prints OK or MISMATCH.
# It is there for anyone who wants to check the work rather than trust it.
# Input : data/raw/*.gz    Output: data/processed/99_verification.txt

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

ko <- 0L; log_lines <- character(0)
chk <- function(label, got, expected, tol = 0) {
  verdict <- if (is.na(got) || is.na(expected)) "?" else
             if (abs(got - expected) <= tol) "OK" else { ko <<- ko + 1L; "MISMATCH" }
  s <- sprintf("%-62s %12s  expected %12s  %s", label,
               format(got, big.mark = " "), format(expected, big.mark = " "), verdict)
  log_lines <<- c(log_lines, s); cat(s, "\n", sep = "")
}
sect <- function(t) { s <- paste0("\n== ", t, " =="); log_lines <<- c(log_lines, s); cat(s, "\n") }

# ---------------------------------------------------------------- wiki-RfA --
sect("wiki-RfA: parsed independently of the pipeline parser")
L <- readLines(gzfile(FILE_RFA), warn = FALSE, encoding = "UTF-8")
k <- sub(":.*$", "", L); v <- sub("^[A-Z]{3}:", "", L)
keep <- k %in% c("SRC","TGT","VOT","RES","YEA","DAT","TXT")
chk("total lines in the file", length(L), 1586200)
chk("discarded lines that are NOT blank separators", sum(!keep & L != ""), 0)
rec <- cumsum(k[keep] == "SRC")
chk("records (= votes)", max(rec), 198275)
chk("records whose field count is not 7", sum(table(rec) != 7), 0)
D <- as.data.frame(tapply(v[keep], list(rec, k[keep]), identity), stringsAsFactors = FALSE)

sect("wiki-RfA: user identity")
all_names_raw <- c(D$SRC, D$TGT)
chk("distinct users WITHOUT trimming", length(unique(all_names_raw)), 11402)
chk("distinct users WITH trimming (SNAP total)", length(unique(trimws(all_names_raw))), 11381)
chk("distinct users after full normalisation", length(unique(clean_name(all_names_raw))), 11380)
con_sp <- unique(all_names_raw)[unique(all_names_raw) != trimws(unique(all_names_raw))]
chk("spellings with a leading or trailing blank", length(con_sp), 43)
chk("  of which collide with the clean form already present", sum(trimws(con_sp) %in% all_names_raw), 21)
chk("  reduction in distinct names", length(unique(all_names_raw)) - length(unique(trimws(all_names_raw))), 21)
chk("voter-candidate pairs WITHOUT trimming (SNAP total)",
    nrow(unique(D[, c("SRC","TGT")])), 189004)
# Dt: the same data with usernames normalised the way read_rfa() does. D stays
# raw, so that both stages can be checked.
Dt <- D; Dt$SRC <- clean_name(D$SRC); Dt$TGT <- clean_name(D$TGT)
chk("voter-candidate pairs after normalisation", nrow(unique(Dt[, c("SRC","TGT")])), 189001)
chk("distinct voters, normalised (empty node included)", length(unique(Dt$SRC)), 10416)
chk("distinct candidates", length(unique(Dt$TGT)), 3497)
chk("users who are BOTH voters AND candidates", length(intersect(unique(Dt$SRC), unique(Dt$TGT))), 2533)
chk("candidates who never voted", length(setdiff(unique(Dt$TGT), unique(Dt$SRC))), 964, tol = 5)
cap <- function(s) ifelse(s == "", s, paste0(toupper(substr(s,1,1)), substr(s,2,nchar(s))))
chk("users after merging the first letter", length(unique(cap(clean_name(all_names_raw)))), 11243)
gr <- split(unique(trimws(all_names_raw)), cap(unique(trimws(all_names_raw))))
chk("groups of spellings differing only in first-letter case", sum(lengths(gr) > 1), 137)
chk("  of which the person is a candidate under some spelling",
    sum(vapply(gr, function(f) length(f) > 1 && any(f %in% Dt$TGT), TRUE)), 90)
chk("  of which the CANDIDATE appears under two spellings",
    sum(lengths(split(unique(Dt$TGT), cap(unique(Dt$TGT)))) > 1), 8)

sect("wiki-RfA: fields")
chk("support votes (VOT=1)",  sum(D$VOT ==  "1"), 144451)
chk("oppose votes (VOT=-1)",   sum(D$VOT == "-1"),  41176)
chk("neutral votes (VOT=0)",      sum(D$VOT ==  "0"),  12648)
chk("rejected outcome (RES=-1)",  sum(D$RES == "-1"),  74987)
chk("approved outcome (RES=1)",  sum(D$RES ==  "1"), 123288)
chk("empty DAT", sum(D$DAT == ""), 9367)
dt <- parse_dat(D$DAT)
chk("DAT with an unrecognised format", attr(dt, "n_bad_format"), 0)
chk("DAT with an impossible value (hour 31)", attr(dt, "n_impossible"), 1)
mm <- sub("^.*, [0-9]{1,2} ([A-Za-z]+) [0-9]{4}$", "\\1", D$DAT[D$DAT != ""])
abbr <- c("Jan","Feb","Mar","Apr","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
chk("votes with an abbreviated month (May excluded: identical in both forms)", sum(mm %in% abbr), 7077)
chk("  votes whose month is 'May'", sum(mm == "May"), 18603)
chk("votes with the month misspelled in the source", sum(mm %in% c("Janry","Julu","Mya")), 3)
chk("dates a %B parser would lose", sum(mm %in% abbr) + sum(mm %in% c("Janry","Julu","Mya")), 7080)
ya <- as.integer(format(dt, "%Y"))
chk("votes whose date year differs from YEA",
    sum(ya != as.integer(D$YEA), na.rm = TRUE), 1875)
chk("votes dated 2003", sum(ya == 2003, na.rm = TRUE), 155)
chk("votes dated 2013", sum(ya == 2013, na.rm = TRUE), 3348)
ch <- paste(D$SRC, D$TGT, D$VOT, D$RES, D$YEA, D$DAT, sep = "\r")
chk("fully identical rows", sum(duplicated(ch)), 595)
chk("empty comments", sum(D$TXT == ""), 7190)
chk("median comment length", median(nchar(D$TXT)), 98)
chk("maximum comment length", max(nchar(D$TXT)), 7610)
chk("comments starting with a bold marker", sum(startsWith(D$TXT, "'''")), 162939)
chk("votes cast per voter: median", median(table(Dt$SRC)), 3)
chk("votes cast per voter: maximum, phantom records EXCLUDED", max(table(Dt$SRC[Dt$SRC != ""])), 1232)
chk("votes received per candidate: median", median(table(Dt$TGT)), 41)
chk("votes received per candidate: maximum", max(table(Dt$TGT)), 987)

# --------------------------------------------------------------- wiki-Elec --
sect("wiki-Elec: format defects")
raw_b <- readLines(gzfile(FILE_ELEC), warn = FALSE, skipNul = TRUE)
chk("lines read by readLines()", length(raw_b), 128016)
chk("lines where readLines() LEAVES a CR", sum(grepl("\r", raw_b, fixed = TRUE)), 0)
con <- gzfile(FILE_ELEC, open = "rb"); bb <- readBin(con, "raw", 3e6); close(con)
chk("CRLF byte pairs in the first 3 MB of the file", 
    sum(bb[-length(bb)] == as.raw(13) & bb[-1] == as.raw(10)), 83859)
chk("lines that are not valid UTF-8",
    sum(is.na(iconv(raw_b, from = "UTF-8", to = "UTF-8"))), 19)
E <- read_elec(FILE_ELEC)
chk("elections", nrow(E$elections), 2794)
chk("votes", nrow(E$votes), 114040)
chk("distinct voters", length(unique(E$votes$voter)), 6210)
chk("promotions", sum(E$elections$outcome == 1), 1248)
chk("rejections", sum(E$elections$outcome == 0), 1546)
chk("distinct candidates", length(unique(E$elections$candidate)), 2391)
chk("nominator = UNKNOWN", sum(E$elections$nominator == "UNKNOWN"), 2117)
chk("declared self-nominations", sum(E$elections$nominator == E$elections$candidate), 85)
chk("votes per election: median", median(table(E$votes$election_id)), 34)
chk("votes per election: maximum", max(table(E$votes$election_id)), 370)
chk("support votes", sum(E$votes$vot == 1), 83962)
chk("oppose votes",   sum(E$votes$vot == -1), 23118)
chk("neutral votes",     sum(E$votes$vot == 0), 6960)
chk("missing closing times", sum(is.na(E$elections$closed_at)), 0)
yv <- as.integer(format(E$votes$dat, "%Y"))
chk("votes with an impossible year (>2008)", sum(yv > 2008), 11)
cat("  declared closing times from", format(min(E$elections$closed_at)),
    "to", format(max(E$elections$closed_at)), "\n")
cat("  votes (plausible years) from", format(min(E$votes$dat[yv <= 2008])),
    "to", format(max(E$votes$dat[yv <= 2008])), "\n")
chk("elections closed before September 2004",
    sum(E$elections$closed_at < as.POSIXct("2004-09-01", tz = "UTC")), 0)
chk("elections closed in 2007", sum(format(E$elections$closed_at, "%Y") == "2007"), 2180)

sect("wiki-Elec: the T field is unreliable")
ul <- vapply(split(as.numeric(E$votes$dat), E$votes$election_id)[
               as.character(E$elections$election_id)],
             function(x) max(x[x < as.numeric(as.POSIXct("2009-01-01", tz="UTC"))]), 0)
dT <- as.numeric(difftime(E$elections$closed_at,
                          as.POSIXct(ul, origin="1970-01-01", tz="UTC"), units="days"))
chk("gap T - last vote: median (days)", round(median(dT)), 102, tol = 1)
chk("elections with T more than 30 days later", sum(dT > 30), 1512)
chk("elections with T more than 180 days later", sum(dT > 180), 1217)
chk("minimum gap (T before the last vote)", round(min(dT)), -188, tol = 1)

sect("spellings across the two files")
chk("wiki-Elec: candidates with an underscore", sum(grepl("_", unique(E$elections$candidate))), 408)
chk("wiki-Elec: candidates with a space",    sum(grepl(" ",  unique(E$elections$candidate))), 0)
chk("wiki-RfA: candidates with an underscore", sum(grepl("_", unique(Dt$TGT))), 0)
chk("wiki-RfA: candidates with a space",     sum(grepl(" ",  unique(Dt$TGT))), 606)
ec <- unique(E$elections$candidate); rc <- unique(tolower(Dt$TGT))
chk("wiki-Elec candidates found in wiki-RfA, direct match (%)",
    round(100*mean(ec %in% rc), 1), 74.9, tol = 0.2)
chk("wiki-Elec candidates found after normalisation (%)",
    round(100*mean(norm_user(ec) %in% norm_user(rc)), 1), 89.8, tol = 0.2)

# ---------------------------------------- igiene: le trappole classiche -----
# This section does not verify claims: it actively looks for the category of
# "basic" problems that are easy to miss. Each line is a defect that, if
# present and untreated, produces phantom nodes, invented edges or wrong
# counts. The expected values are the ones measured and handled; if they
# change, something in the data or in the code has changed and needs a look.
sect("HYGIENE: the classic traps")
uu_raw <- unique(c(D$SRC, D$TGT))            # original spelling in the file
uu     <- unique(c(Dt$SRC, Dt$TGT))          # after clean_name()
chk("empty names among the nodes (phantom records still present here)", sum(uu == ""), 1)
chk("PHANTOM RECORDS: votes with an empty SRC", sum(Dt$SRC == ""), 1661)
chk("  of these, how many also have an empty TXT", sum(Dt$SRC == "" & Dt$TXT == ""), 1661)
chk("  candidates that exist ONLY through phantom records",
    length(setdiff(unique(Dt$TGT[Dt$SRC == ""]), unique(Dt$TGT[Dt$SRC != ""]))), 6)
chk("names with multiple internal blanks, BEFORE cleaning", sum(grepl("  ", uu_raw)), 1)
chk("  and after cleaning", sum(grepl("  ", uu)), 0)
chk("names with invisible characters, BEFORE cleaning",
    sum(grepl("[\u200b-\u200f\ufeff]", uu_raw)), 1)
chk("  and after cleaning", sum(grepl("[\u200b-\u200f\ufeff]", uu)), 0)
chk("names with a tab or newline", sum(grepl("[\t\r\n]", uu)), 0)
chk("names with a non-breaking space U+00A0", sum(grepl("\u00a0", uu)), 0)
chk("names with HTML entities", sum(grepl("&[a-z]+;|&#[0-9]+;", uu)), 0)
chk("names with an underscore (wiki-RfA uses none)", sum(grepl("_", uu)), 0)
chk("non-ASCII names (legitimate)", sum(grepl("[^\x01-\x7f]", uu, perl = TRUE)), 78)
chk("SELF-VOTES: the candidate votes in their own RfA", sum(Dt$SRC == Dt$TGT), 103)
chk("votes with an empty TGT", sum(Dt$TGT == ""), 0)
chk("VOT outside {-1,0,1}", sum(!(D$VOT %in% c("-1","0","1"))), 0)
chk("RES outside {-1,1}", sum(!(D$RES %in% c("-1","1"))), 0)
chk("YEA outside 2003-2013", sum(!(as.integer(D$YEA) %in% 2003:2013)), 0)
chk("dates before 2003", sum(dt < as.POSIXct("2003-01-01", tz = "UTC"), na.rm = TRUE), 0)
chk("dates after May 2013 (declared end of coverage)",
    sum(dt > as.POSIXct("2013-05-31 23:59", tz = "UTC"), na.rm = TRUE), 75)

sect("HYGIENE: wiki-Elec")
chk("duplicate voters within the same election",
    sum(duplicated(paste(E$votes$election_id, E$votes$voter))), 0)
chk("elections with no votes at all", nrow(E$elections) - length(unique(E$votes$election_id)), 0)
chk("elections with a single vote", sum(table(E$votes$election_id) == 1), 97)
chk("the candidate votes in their own election",
    sum(norm_user(E$votes$voter) == norm_user(
      E$elections$candidate[match(E$votes$election_id, E$elections$election_id)])), 72)
chk("empty usernames among the voters", sum(E$votes$voter == "" | is.na(E$votes$voter)), 0)
chk("two elections with the same candidate and closing time",
    sum(duplicated(paste(E$elections$candidate, E$elections$closed_at))), 0)

# ------------------------------------------------ assunzioni del metodo -----
sect("ASSUMPTION: RES is a property of the election, not of the vote")
# For each matched wiki-Elec election, do the corresponding wiki-RfA votes all
# carry the same RES? If not, grouping by RES would be wrong.
Dt$dat <- dt; Dt$kc <- norm_user(Dt$TGT); Dt$kv <- norm_user(Dt$SRC)
ev <- E$votes; ev$kv <- norm_user(ev$voter)
ele <- E$elections; ele$kc <- norm_user(ele$candidate)
set_el <- split(ev$kv, ev$election_id)
res_mixed <- 0L; examined <- 0L
idx_c <- split(seq_len(nrow(Dt)), Dt$kc)
for (r in seq_len(nrow(ele))) {
  ii <- idx_c[[ele$kc[r]]]; if (is.null(ii)) next
  s <- set_el[[as.character(ele$election_id[r])]]
  jj <- ii[Dt$kv[ii] %in% s]
  if (length(jj) < 10) next
  examined <- examined + 1L
  if (length(unique(Dt$RES[jj])) > 1) res_mixed <- res_mixed + 1L
}
cat(sprintf("  elections examined (>=10 voters found again): %d\n", examined))
cat(sprintf("  of which RES is NOT constant across their wiki-RfA votes: %d (%.1f%%)\n",
            res_mixed, 100*res_mixed/examined))
cat("  NB: a high value here would invalidate grouping by (candidate, RES).\n")
log_lines <- c(log_lines,
  sprintf("  elections examined: %d | RES not constant: %d (%.1f%%)",
          examined, res_mixed, 100*res_mixed/examined))

sect("RESULT")
cat(if (ko == 0) "Every verified claim matches.\n" else
    sprintf("%d claims DO NOT match.\n", ko))
log_lines <- c(log_lines, if (ko == 0) "Every claim matches." else
               sprintf("%d claims DO NOT match.", ko))
writeLines(log_lines, file.path(DIR_PROCESSED, "99_verification.txt"))
