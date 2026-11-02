# 01 - Read the two raw files into tables.
# Input : data/raw/wiki-RfA.txt.gz, data/raw/wikiElec.ElecBs3.txt.gz
# Output: data/processed/votes_raw.rds, data/processed/elec_raw.rds,
#         data/processed/username_case_variants.csv
# Packages: none (base R).
#
# The reading functions are in R/00_lib_data.R, so the check script
# R/99_verify_data.R can use the same ones.
# This script only reads the files and cleans the spelling of usernames.
# Removing duplicates and building elections happens in step 02.

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

votes_raw <- read_rfa(FILE_RFA)
dir.create(DIR_PROCESSED, showWarnings = FALSE, recursive = TRUE)
saveRDS(votes_raw, file.path(DIR_PROCESSED, "votes_raw.rds"))

elec <- read_elec(FILE_ELEC)
saveRDS(elec, file.path(DIR_PROCESSED, "elec_raw.rds"))

cv <- case_variants(votes_raw)
write.csv(cv, file.path(DIR_PROCESSED, "username_case_variants.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# Check our counts against the totals published by SNAP.
# check() prints a count, the expected value, and OK or MISMATCH.
check <- function(label, got, expected) {
  cat(label, got, " (expected ", expected, ")",
      if (got == expected) " OK" else " MISMATCH", "\n", sep = "")
}
users <- c(votes_raw$SRC, votes_raw$TGT)
cat("--- wiki-RfA ---\n")
check("votes: ", nrow(votes_raw), 198275)
# SNAP reports 11,381 users. We expect 11,380 because our cleaning merges two
# spellings that SNAP counts separately: one name with a double space inside
# and one with an invisible character (see NOTE 1 in 00_lib_data.R).
check("distinct users: ", length(unique(users)), 11380)
# SNAP reports 189,004 voter-candidate pairs, counted before cleaning. After
# cleaning we get 189,001, because a few pairs were written in two spellings.
check("voter-candidate pairs: ", nrow(unique(votes_raw[, c("SRC", "TGT")])), 189001)

# On Wikipedia the first letter of a username is always a capital, so names
# that differ only in the first letter (iMatthew / IMatthew) are one person.
# The key case is a candidate whose votes are split across two spellings:
# without merging, one election would look like two candidates.
is_candidate <- cv$n_votes_received > 0
cat("users after merging the first letter: ", length(unique(capitalise_first(users))), "\n",
    "name groups differing only in the first letter: ", length(unique(cv$merged_name)), "\n",
    "  of which the person is a candidate: ", length(unique(cv$merged_name[is_candidate])), "\n",
    "  of which the candidate appears under two spellings: ",
    length(unique(cv$merged_name[ave(is_candidate, cv$merged_name, FUN = sum) > 1])), "\n",
    sep = "")

el <- elec$elections
cat("\n--- wiki-Elec ---\n")
check("elections: ", nrow(el), 2794)
# SNAP gives only rounded figures for promotions and rejections (about 1200 /
# 1500). The closing time (field T) is not reliable; see step 03.
cat("votes: ", nrow(elec$votes), "\n",
    "promotions: ", sum(el$outcome == 1), "   rejections: ", sum(el$outcome == 0), "\n",
    "declared closing times from ", format(min(el$closed_at), "%Y-%m-%d"),
    " to ", format(max(el$closed_at), "%Y-%m-%d"), "\n",
    "distinct candidates: ", length(unique(el$candidate)),
    "   with more than one election: ", sum(table(el$candidate) > 1), "\n",
    "missing closing times: ", sum(is.na(el$closed_at)), "\n", sep = "")
