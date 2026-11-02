# 05 - Compare each election with the candidate's next election.
#
# A "pair" = two consecutive elections of the same candidate (1st and 2nd,
# 2nd and 3rd, ...). For each pair the script measures:
#   - how many supporters came back (Jaccard overlap of the two supporter sets)
#     and how many would come back by chance;
#   - how the supporters are spread over the communities found in 04
#     (effective number of communities, Jensen-Shannon divergence);
#   - the average network position of the supporters (strength, PageRank,
#     eigenvector centrality, local clustering).
# It also writes a table that checks each outcome against wiki-Elec.
#
# Input : data/processed/votes.rds, attempts_analysis.rds, network_objects.rds
# Output: data/processed/attempt_pairs.rds
#         output/results/attempt_pairs.csv, outcome_validation.csv

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
if (!all(file.exists(file.path(DIR_PROCESSED,
                               c("votes.rds", "attempts_analysis.rds", "network_objects.rds")))))
  stop("Run R/run_data_prep.R and R/04_build_networks.R first.", call. = FALSE)

# --- helper functions ---------------------------------------------------------
# a / b, or NA when b is 0 or missing.
ratio <- function(a, b) if (!is.na(b) && b > 0) a / b else NA_real_

# Effective number of communities = exp(Shannon entropy) of the community
# labels. Supporters split evenly over 3 communities give 3; most of them in
# one community give close to 1.
effective_communities <- function(labels) {
  if (length(labels) == 0L) return(NA_real_)
  p <- as.numeric(table(labels)) / length(labels)
  exp(-sum(p * log(p)))
}

# Jensen-Shannon divergence between two community mixes (log base 2, so 0 to 1):
# 0 = same mix, 1 = no community in common.
js_divergence <- function(a, b) {
  if (length(a) == 0L || length(b) == 0L) return(NA_real_)
  lev <- union(a, b)
  p <- as.numeric(table(factor(a, levels = lev))) / length(a)
  q <- as.numeric(table(factor(b, levels = lev))) / length(b)
  m <- (p + q) / 2
  half_kl <- function(x) 0.5 * sum(x[x > 0] * log2(x[x > 0] / m[x > 0]))
  half_kl(p) + half_kl(q)
}

# Network summary of a group of supporters in one yearly network. Supporters
# who are not in the network (no edges yet, or no network for that year) count
# as their own "unclassified" community and get 0 for every measure.
support_network_stats <- function(voters, snapshot) {
  if (length(voters) == 0L) {
    return(list(effective_communities = 0, unclassified_supporters = 0L,
                known_community_share = NA_real_, mean_weighted_degree = 0,
                mean_pagerank = 0, mean_eigenvector = 0, mean_local_clustering = 0,
                community_bridge_exposure = 0, community_labels = character()))
  }
  lookup <- function(values, keys) {
    x <- if (is.null(snapshot)) rep(0, length(keys)) else unname(values[keys])
    x[is.na(x)] <- 0
    x
  }
  memb <- if (is.null(snapshot)) rep(NA_integer_, length(voters))
          else unname(snapshot$membership[voters])
  labels <- ifelse(is.na(memb), "unclassified", as.character(memb))
  list(
    effective_communities = effective_communities(labels),
    unclassified_supporters = sum(is.na(memb)),
    known_community_share = mean(!is.na(memb)),
    mean_weighted_degree = mean(lookup(snapshot$weighted_degree, voters)),
    mean_pagerank = mean(lookup(snapshot$pagerank, voters)),
    mean_eigenvector = mean(lookup(snapshot$eigenvector, voters)),
    mean_local_clustering = mean(lookup(snapshot$local_clustering, voters)),
    community_bridge_exposure =
      mean(lookup(snapshot$community_bridge_exposure, as.character(memb))),
    community_labels = labels
  )
}

# --- data -----------------------------------------------------------------------
votes     <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
attempts  <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
snapshots <- readRDS(file.path(DIR_PROCESSED, "network_objects.rds"))$snapshots

# Same votes as in 04. Votes with no date get the opening date of their election.
votes <- network_votes(votes, attempts)
votes$time <- votes$dat
no_date <- is.na(votes$time)
votes$time[no_date] <- attempts$opened_at[match(votes$attempt_id[no_date], attempts$attempt_id)]

# Shorter names, and elections sorted by candidate and attempt number.
attempts$attempt_number <- attempts$attempt_no
attempts$start_date <- attempts$opened_at
attempts$end_date <- attempts$closed_at
attempts$year <- attempts$year_from_date
attempts$outcome <- attempts$outcome_analysis
attempts <- attempts[order(attempts$candidate, attempts$attempt_number), ]

# Table that compares each outcome with wiki-Elec, for the appendix.
outcome_validation <- attempts[, c(
  "attempt_id", "candidate", "attempt_number", "start_date", "end_date",
  "year", "outcome", "outcome_analysis", "elec_matched", "elec_outcome",
  "elec_jaccard", "outcome_agrees")]
outcome_validation$validation_status <- ifelse(
  outcome_validation$elec_matched,
  ifelse(outcome_validation$outcome_agrees, "validated", "outcome_mismatch"),
  "not_matched_in_companion_file")
outcome_validation$rfa_success <- as.integer(outcome_validation$outcome == 1L)
outcome_validation$wiki_success <- as.integer(outcome_validation$elec_outcome == 1L)
write.csv(outcome_validation, file.path("output", "results", "outcome_validation.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")

# Lookup tables for the loop:
#   votes_of   : for each election, the vote (+1 / -1) of each voter;
#   first_vote : for each user, the time of their first vote (the chance
#                baseline needs everyone who had voted before an election);
#   cast_times : for each user, the times of all the votes they cast.
votes_of   <- split(setNames(votes$vot, votes$src), votes$attempt_id)
first_vote <- sapply(split(as.numeric(votes$time), votes$src), min)
cast_times <- split(votes$time, votes$src)

# --- one row per pair -------------------------------------------------------------
pair_rows <- list()
for (rows in split(seq_len(nrow(attempts)), attempts$candidate)) {
  if (length(rows) < 2L) next
  for (i in seq_len(length(rows) - 1L)) {
    prev <- attempts[rows[i], ]
    curr <- attempts[rows[i + 1L], ]
    if (is.na(prev$outcome_analysis) || is.na(curr$outcome_analysis)) next
    v_prev <- votes_of[[as.character(prev$attempt_id)]]
    v_curr <- votes_of[[as.character(curr$attempt_id)]]
    if (is.null(v_prev) || is.null(v_curr)) next

    # Who supported / opposed each time, and how they moved.
    sup_prev <- names(v_prev)[v_prev == 1];  opp_prev <- names(v_prev)[v_prev == -1]
    sup_curr <- names(v_curr)[v_curr == 1];  opp_curr <- names(v_curr)[v_curr == -1]
    returning <- intersect(sup_prev, sup_curr)          # supported both times
    new_sup   <- setdiff(sup_curr, sup_prev)            # supported only the 2nd time
    converted <- intersect(opp_prev, sup_curr)          # opposed, then supported
    jaccard   <- ratio(length(returning), length(union(sup_prev, sup_curr)))

    # Chance baseline: if the 2nd election's supporters were a random draw from
    # everyone who had voted before it started, the expected number of
    # returning supporters is (size 1 x size 2) / pool. (93 tests this properly.)
    pool <- sum(first_vote < as.numeric(curr$start_date))
    exp_shared <- if (pool > 0L) length(sup_prev) * length(sup_curr) / pool else NA_real_
    exp_jaccard <- ratio(exp_shared, length(sup_prev) + length(sup_curr) - exp_shared)

    # Network position. Both supporter groups are placed in the SAME network
    # (votes before the year of the 2nd election), so any change is a change
    # in who supports, not a change in the network.
    snap <- snapshots[[as.character(curr$year)]]
    np <- support_network_stats(sup_prev, snap)
    nc <- support_network_stats(sup_curr, snap)

    # Votes the candidate cast on other elections between their own two.
    t <- cast_times[[prev$candidate]]
    outgoing <- if (is.null(t)) 0L else sum(t > prev$end_date & t < curr$start_date, na.rm = TRUE)

    pair_rows[[length(pair_rows) + 1L]] <- data.frame(
      pair_id = length(pair_rows) + 1L,
      candidate = prev$candidate,
      previous_attempt_id = prev$attempt_id,
      next_attempt_id = curr$attempt_id,
      previous_attempt_number = prev$attempt_number,
      next_attempt_year = curr$year,
      previous_outcome = prev$outcome_analysis,
      next_outcome = curr$outcome_analysis,
      previous_short_attempt = prev$flag_short,
      next_short_attempt = curr$flag_short,
      previous_year_clash = prev$flag_year_clash,
      next_year_clash = curr$flag_year_clash,
      days_between = as.numeric(difftime(curr$start_date, prev$end_date, units = "days")),
      previous_supporters = length(sup_prev),
      previous_opponents = length(opp_prev),
      current_supporters = length(sup_curr),
      current_opponents = length(opp_curr),
      previous_support_share = ratio(length(sup_prev), length(sup_prev) + length(opp_prev)),
      returning_supporters = length(returning),
      new_supporters = length(new_sup),
      converted_opposition = length(converted),
      supporter_jaccard = jaccard,
      null_expected_jaccard = exp_jaccard,
      jaccard_excess = jaccard - exp_jaccard,
      returning_support_share = ratio(length(returning), length(sup_curr)),
      new_support_share = ratio(length(new_sup), length(sup_curr)),
      previous_support_effective_communities = np$effective_communities,
      current_support_effective_communities = nc$effective_communities,
      community_breadth_change = nc$effective_communities - np$effective_communities,
      community_mix_js = js_divergence(np$community_labels, nc$community_labels),
      previous_unclassified_supporters = np$unclassified_supporters,
      current_unclassified_supporters = nc$unclassified_supporters,
      previous_known_community_share = np$known_community_share,
      current_known_community_share = nc$known_community_share,
      previous_supporter_mean_weighted_degree = np$mean_weighted_degree,
      current_supporter_mean_weighted_degree = nc$mean_weighted_degree,
      previous_supporter_mean_pagerank = np$mean_pagerank,
      current_supporter_mean_pagerank = nc$mean_pagerank,
      previous_supporter_mean_eigenvector = np$mean_eigenvector,
      current_supporter_mean_eigenvector = nc$mean_eigenvector,
      previous_supporter_mean_local_clustering = np$mean_local_clustering,
      current_supporter_mean_local_clustering = nc$mean_local_clustering,
      previous_community_bridge_exposure = np$community_bridge_exposure,
      current_community_bridge_exposure = nc$community_bridge_exposure,
      outgoing_votes_between_attempts = outgoing
    )
  }
}

pairs <- do.call(rbind, pair_rows)
rownames(pairs) <- NULL
pairs$previous_group <- factor(
  ifelse(pairs$previous_outcome == 1L, "Previously successful", "Previously rejected"),
  levels = c("Previously rejected", "Previously successful"))
pairs$next_group <- factor(
  ifelse(pairs$next_outcome == 1L, "Next: successful", "Next: rejected"),
  levels = c("Next: rejected", "Next: successful"))
pairs$next_success <- as.integer(pairs$next_outcome == 1L)

# Three samples of pairs. Scripts 06, 07, 93 and 94 report results for each.
#   negative_interval : the second election starts before the first one ends,
#                       so they are not two separate elections (17 pairs).
#   short_attempt_pair: one of the two elections has fewer than 5 votes. It
#                       may be real (closed early) or a piece of a split
#                       election; with so few votes, overlap is near 0 anyway.
#   samples: "all" (609 pairs), "chronological" (without negative_interval,
#            592) and "strict" (also without short_attempt_pair, 513; used
#            for the model). Evidence in 92_short_attempt_check.R.
pairs$negative_interval <- (pairs$days_between < 0) %in% TRUE
pairs$short_attempt_pair <- (pairs$previous_short_attempt | pairs$next_short_attempt) %in% TRUE
pairs$in_chronological <- !pairs$negative_interval
pairs$in_strict <- !pairs$negative_interval & !pairs$short_attempt_pair

# Sanity checks: unique IDs, shares between 0 and 1, no negative values.
in_0_1 <- function(x) all(is.na(x) | (x >= -1e-12 & x <= 1 + 1e-12))
stopifnot(
  "Pair IDs are not unique." = !anyDuplicated(pairs$pair_id),
  "Supporter Jaccard outside [0, 1]." = in_0_1(pairs$supporter_jaccard),
  "New-supporter share outside [0, 1]." = in_0_1(pairs$new_support_share),
  "Returning-supporter share outside [0, 1]." = in_0_1(pairs$returning_support_share),
  "Jensen-Shannon divergence outside [0, 1]." = in_0_1(pairs$community_mix_js),
  "Negative effective-community value." =
    all(pairs$previous_support_effective_communities >= 0,
        pairs$current_support_effective_communities >= 0)
)

saveRDS(pairs, file.path(DIR_PROCESSED, "attempt_pairs.rds"))
write.csv(pairs, file.path("output", "results", "attempt_pairs.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
cat("Attempt pairs written:", nrow(pairs), "\n")
