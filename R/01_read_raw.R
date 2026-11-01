# 01 - Read the two raw files. No substantive cleaning here.
# Input : data/raw/wiki-RfA.txt.gz, data/raw/wikiElec.ElecBs3.txt.gz
# Output: data/processed/votes_raw.rds, data/processed/elec_raw.rds,
#         data/processed/username_case_variants.csv
# Packages: none (base R).
#
# The two parsers live in R/00_lib_data.R so the independent verification
# (R/99_verify_data.R) can use them too.
# This script only turns the text formats into tables and normalises username
# spelling (see NOTE 1 in the library). It does not deduplicate and decides
# nothing substantive: that is step 02.

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

votes_raw <- read_rfa(FILE_RFA)
dir.create(DIR_PROCESSED, showWarnings = FALSE, recursive = TRUE)
saveRDS(votes_raw, file.path(DIR_PROCESSED, "votes_raw.rds"))

elec <- read_elec(FILE_ELEC)
saveRDS(elec, file.path(DIR_PROCESSED, "elec_raw.rds"))

cv <- case_variants(votes_raw)
write.csv(cv, file.path(DIR_PROCESSED, "username_case_variants.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# Control counts against the totals published by SNAP.
n_votes  <- nrow(votes_raw)
n_users  <- length(unique(c(votes_raw$SRC, votes_raw$TGT)))
cat("--- wiki-RfA ---\n")
cat("votes:                 ", n_votes, " (SNAP: 198275)",
    if (n_votes == 198275) " OK" else " MISMATCH", "\n", sep = "")
cat("distinct users:        ", n_users,
    " (expected 11380; SNAP reports 11381 because it does not merge one double",
    " internal space and one invisible character, see NOTE 1)",
    if (n_users == 11380) " OK" else " MISMATCH", "\n", sep = "")
# NOTE - distinct pairs are 189,001 after normalisation and 189,004 without it:
# a couple of pairs appear under two spellings. The SNAP totals are therefore
# not consistent with each other: 11,381 users is a post-trim count, 189,004
# pairs is a pre-trim one. This belongs in the data section of the report.
cat("voter-candidate pairs: ", nrow(unique(votes_raw[, c("SRC", "TGT")])),
    " (SNAP: 189004, pre-normalisation)\n", sep = "")
cat("users after merging the first letter: ",
    length(unique(capitalise_first(c(votes_raw$SRC, votes_raw$TGT)))), "\n", sep = "")
cat("spelling groups differing only in the first letter: ",
    length(unique(cv$merged_name)),
    " (listed in data/processed/username_case_variants.csv)\n", sep = "")
cat("  of which the person is a candidate under at least one spelling: ",
    length(unique(cv$merged_name[cv$n_votes_received > 0])), "\n", sep = "")
cat("  of which the CANDIDATE appears under two spellings: ",
    length(unique(cv$merged_name[ave(cv$n_votes_received > 0, cv$merged_name,
                                     FUN = sum) > 1])),
    "  <- destructive for attempt reconstruction\n", sep = "")

cat("\n--- wiki-Elec ---\n")
cat("elections: ", nrow(elec$elections), " (SNAP: 2794)",
    if (nrow(elec$elections) == 2794) " OK" else " MISMATCH", "\n", sep = "")
cat("votes: ", nrow(elec$votes), "\n", sep = "")
cat("promotions: ", sum(elec$elections$outcome == 1),
    "   rejections: ", sum(elec$elections$outcome == 0),
    "   (SNAP: about 1200 / 1500)\n", sep = "")
cat("declared closing times from ", format(min(elec$elections$closed_at), "%Y-%m-%d"),
    " to ", format(max(elec$elections$closed_at), "%Y-%m-%d"),
    "  -- but field T is unreliable, see 03\n", sep = "")
cat("distinct candidates: ", length(unique(elec$elections$candidate)),
    "   with more than one election: ",
    sum(table(elec$elections$candidate) > 1), "\n", sep = "")
cat("missing closing times: ", sum(is.na(elec$elections$closed_at)), "\n", sep = "")
