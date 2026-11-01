# 05 - Coalition and network change between consecutive attempts.
#
# Input : data/processed/votes.rds
#         data/processed/attempts_analysis.rds
#         data/processed/network_objects.rds
# Output: data/processed/attempt_pairs.rds
#         output/results/attempt_pairs.csv
#         output/results/outcome_validation.csv
# Packages: base R

source(file.path("R", "00_paths.R"))
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)

required <- file.path(
  DIR_PROCESSED,
  c("votes.rds", "attempts_analysis.rds", "network_objects.rds")
)
if (any(!file.exists(required))) {
  stop("Run R/01_prepare_data.R and R/04_build_networks.R first.", call. = FALSE)
}

assert_condition <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
}

community_entropy <- function(values) {
  values <- values[!is.na(values)]
  if (length(values) == 0L) {
    return(NA_real_)
  }
  frequencies <- as.numeric(table(values)) / length(values)
  -sum(frequencies * log(frequencies))
}

effective_communities <- function(values) {
  entropy <- community_entropy(values)
  if (is.na(entropy)) NA_real_ else exp(entropy)
}

js_divergence <- function(values_previous, values_current) {
  if (length(values_previous) == 0L || length(values_current) == 0L) {
    return(NA_real_)
  }
  categories <- union(values_previous, values_current)
  previous_distribution <- as.numeric(table(
    factor(values_previous, levels = categories)
  )) / length(values_previous)
  current_distribution <- as.numeric(table(
    factor(values_current, levels = categories)
  )) / length(values_current)
  midpoint <- (previous_distribution + current_distribution) / 2
  term <- function(distribution) {
    positive <- distribution > 0
    0.5 * sum(
      distribution[positive] *
        log2(distribution[positive] / midpoint[positive])
    )
  }
  term(previous_distribution) + term(current_distribution)
}

support_network_stats <- function(voters, snapshot) {
  n_supporters <- length(voters)
  if (n_supporters == 0L) {
    return(list(
      effective_communities = 0,
      unclassified_supporters = 0L,
      known_community_share = NA_real_,
      mean_weighted_degree = 0,
      mean_pagerank = 0,
      mean_eigenvector = 0,
      mean_local_clustering = 0,
      community_bridge_exposure = 0,
      community_labels = character()
    ))
  }

  if (is.null(snapshot)) {
    memberships <- rep(NA_integer_, n_supporters)
    degrees <- rep(0, n_supporters)
    pageranks <- rep(0, n_supporters)
    eigenvectors <- rep(0, n_supporters)
    local_clustering <- rep(0, n_supporters)
    bridge_exposure <- rep(0, n_supporters)
  } else {
    memberships <- unname(snapshot$membership[voters])
    degrees <- unname(snapshot$weighted_degree[voters])
    pageranks <- unname(snapshot$pagerank[voters])
    eigenvectors <- unname(snapshot$eigenvector[voters])
    local_clustering <- unname(snapshot$local_clustering[voters])
    bridge_exposure <- unname(
      snapshot$community_bridge_exposure[as.character(memberships)]
    )
    degrees[is.na(degrees)] <- 0
    pageranks[is.na(pageranks)] <- 0
    eigenvectors[is.na(eigenvectors)] <- 0
    local_clustering[is.na(local_clustering)] <- 0
    bridge_exposure[is.na(bridge_exposure)] <- 0
  }

  unclassified <- is.na(memberships)
  community_labels <- as.character(memberships)
  community_labels[unclassified] <- "unclassified"

  list(
    effective_communities = effective_communities(community_labels),
    unclassified_supporters = sum(unclassified),
    known_community_share = mean(!unclassified),
    mean_weighted_degree = mean(degrees),
    mean_pagerank = mean(pageranks),
    mean_eigenvector = mean(eigenvectors),
    mean_local_clustering = mean(local_clustering),
    community_bridge_exposure = mean(bridge_exposure),
    community_labels = community_labels
  )
}

votes <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
network_objects <- readRDS(file.path(DIR_PROCESSED, "network_objects.rds"))
snapshots <- network_objects$snapshots

votes <- votes[
  !is.na(votes$attempt_id) &
    votes$vot %in% c(-1L, 1L) &
    !votes$self_vote,
]
attempt_index <- match(votes$attempt_id, attempts$attempt_id)
votes$voter <- votes$src
votes$candidate <- votes$tgt
votes$vote <- votes$vot
votes$year <- attempts$year_from_date[attempt_index]
votes$vote_time <- votes$dat
votes$vote_time_effective <- votes$dat
missing_vote_time <- is.na(votes$vote_time_effective)
votes$vote_time_effective[missing_vote_time] <-
  attempts$opened_at[attempt_index[missing_vote_time]]

attempts$attempt_number <- attempts$attempt_no
attempts$start_date <- attempts$opened_at
attempts$end_date <- attempts$closed_at
attempts$year <- attempts$year_from_date
attempts$n_raw_votes <- attempts$n_votes
attempts$outcome <- attempts$outcome_analysis
attempts <- attempts[order(attempts$candidate, attempts$attempt_number), ]

outcome_validation <- attempts[
  ,
  c(
    "attempt_id", "candidate", "attempt_number", "start_date", "end_date",
    "year", "outcome", "outcome_analysis", "elec_matched", "elec_outcome",
    "elec_jaccard", "outcome_agrees"
  )
]
outcome_validation$validation_status <- ifelse(
  outcome_validation$elec_matched,
  ifelse(outcome_validation$outcome_agrees, "validated", "outcome_mismatch"),
  "not_matched_in_companion_file"
)
outcome_validation$rfa_success <- as.integer(outcome_validation$outcome == 1L)
outcome_validation$wiki_success <- as.integer(outcome_validation$elec_outcome == 1L)
write.csv(
  outcome_validation,
  file.path("output", "results", "outcome_validation.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)

vote_maps <- split(setNames(votes$vote, votes$voter), votes$attempt_id)
attempt_votes <- lapply(vote_maps, function(x) x[!is.na(x)])
outgoing_by_voter <- split(votes$vote_time_effective, votes$voter)
candidate_groups <- split(seq_len(nrow(attempts)), attempts$candidate)
pair_rows <- list()

for (candidate_rows in candidate_groups) {
  if (length(candidate_rows) < 2L) {
    next
  }
  for (i in seq_len(length(candidate_rows) - 1L)) {
    previous <- attempts[candidate_rows[i], ]
    current <- attempts[candidate_rows[i + 1L], ]
    if (is.na(previous$outcome_analysis) || is.na(current$outcome_analysis)) {
      next
    }

    previous_votes <- attempt_votes[[as.character(previous$attempt_id)]]
    current_votes <- attempt_votes[[as.character(current$attempt_id)]]
    if (is.null(previous_votes) || is.null(current_votes)) {
      next
    }

    previous_support <- names(previous_votes)[previous_votes == 1]
    previous_oppose <- names(previous_votes)[previous_votes == -1]
    current_support <- names(current_votes)[current_votes == 1]
    current_oppose <- names(current_votes)[current_votes == -1]
    returning_support <- intersect(previous_support, current_support)
    new_support <- setdiff(current_support, previous_support)
    converted_opposition <- intersect(previous_oppose, current_support)
    supporter_union <- union(previous_support, current_support)

    supporter_jaccard <- if (length(supporter_union) == 0L) {
      NA_real_
    } else {
      length(returning_support) / length(supporter_union)
    }

    active_before <- unique(votes$voter[
      votes$vote_time_effective < current$start_date
    ])
    pool_size <- length(active_before)
    expected_intersection <- if (pool_size > 0L) {
      length(previous_support) * length(current_support) / pool_size
    } else {
      NA_real_
    }
    expected_union <- length(previous_support) + length(current_support) -
      expected_intersection
    expected_jaccard <- if (!is.na(expected_union) && expected_union > 0) {
      expected_intersection / expected_union
    } else {
      NA_real_
    }

    snapshot <- snapshots[[as.character(current$year)]]
    previous_network <- support_network_stats(previous_support, snapshot)
    current_network <- support_network_stats(current_support, snapshot)
    community_mix_change <- js_divergence(
      previous_network$community_labels,
      current_network$community_labels
    )

    previous_total <- length(previous_support) + length(previous_oppose)
    previous_support_share <- if (previous_total > 0L) {
      length(previous_support) / previous_total
    } else {
      NA_real_
    }

    times <- outgoing_by_voter[[previous$candidate]]
    outgoing_between <- if (is.null(times)) {
      0L
    } else {
      sum(times > previous$end_date & times < current$start_date, na.rm = TRUE)
    }

    pair_rows[[length(pair_rows) + 1L]] <- data.frame(
      pair_id = length(pair_rows) + 1L,
      candidate = previous$candidate,
      previous_attempt_id = previous$attempt_id,
      next_attempt_id = current$attempt_id,
      previous_attempt_number = previous$attempt_number,
      next_attempt_year = current$year,
      previous_outcome = previous$outcome_analysis,
      next_outcome = current$outcome_analysis,
      previous_short_attempt = previous$flag_short,
      next_short_attempt = current$flag_short,
      previous_year_clash = previous$flag_year_clash,
      next_year_clash = current$flag_year_clash,
      days_between = as.numeric(difftime(
        current$start_date, previous$end_date, units = "days"
      )),
      previous_supporters = length(previous_support),
      previous_opponents = length(previous_oppose),
      current_supporters = length(current_support),
      current_opponents = length(current_oppose),
      previous_support_share = previous_support_share,
      returning_supporters = length(returning_support),
      new_supporters = length(new_support),
      converted_opposition = length(converted_opposition),
      supporter_jaccard = supporter_jaccard,
      null_expected_jaccard = expected_jaccard,
      jaccard_excess = supporter_jaccard - expected_jaccard,
      returning_support_share = if (length(current_support) > 0L) {
        length(returning_support) / length(current_support)
      } else {
        NA_real_
      },
      new_support_share = if (length(current_support) > 0L) {
        length(new_support) / length(current_support)
      } else {
        NA_real_
      },
      previous_support_effective_communities =
        previous_network$effective_communities,
      current_support_effective_communities =
        current_network$effective_communities,
      community_breadth_change =
        current_network$effective_communities -
        previous_network$effective_communities,
      community_mix_js = community_mix_change,
      previous_unclassified_supporters =
        previous_network$unclassified_supporters,
      current_unclassified_supporters =
        current_network$unclassified_supporters,
      previous_known_community_share =
        previous_network$known_community_share,
      current_known_community_share =
        current_network$known_community_share,
      previous_supporter_mean_weighted_degree =
        previous_network$mean_weighted_degree,
      current_supporter_mean_weighted_degree =
        current_network$mean_weighted_degree,
      previous_supporter_mean_pagerank = previous_network$mean_pagerank,
      current_supporter_mean_pagerank = current_network$mean_pagerank,
      previous_supporter_mean_eigenvector = previous_network$mean_eigenvector,
      current_supporter_mean_eigenvector = current_network$mean_eigenvector,
      previous_supporter_mean_local_clustering =
        previous_network$mean_local_clustering,
      current_supporter_mean_local_clustering =
        current_network$mean_local_clustering,
      previous_community_bridge_exposure =
        previous_network$community_bridge_exposure,
      current_community_bridge_exposure =
        current_network$community_bridge_exposure,
      outgoing_votes_between_attempts = outgoing_between,
      stringsAsFactors = FALSE
    )
  }
}

pairs <- do.call(rbind, pair_rows)
rownames(pairs) <- NULL
pairs$previous_group <- factor(
  ifelse(
    pairs$previous_outcome == 1L,
    "Previously successful",
    "Previously rejected"
  ),
  levels = c("Previously rejected", "Previously successful")
)
pairs$next_group <- factor(
  ifelse(pairs$next_outcome == 1L, "Next: successful", "Next: rejected"),
  levels = c("Next: rejected", "Next: successful")
)
pairs$next_success <- as.integer(pairs$next_outcome == 1L)

# Three named populations of pairs. None is chosen silently: 06, 07, 93 and 94
# report results for each.
#   negative_interval : the second attempt starts before the first ends, so the
#                       two are not consecutive requests (17 pairs).
#   short_attempt_pair: either attempt has fewer than 5 votes (flag_short in
#                       00_lib_data.R). Such an attempt can be a real
#                       early-closed request; with so few recorded votes,
#                       supporter overlap is close to 0 by construction.
#   sample            : "all" (all valid outcomes), "chronological" (excludes
#                       negative_interval) and "strict" (also excludes
#                       short_attempt_pair; the modelling sample).
# 92_short_attempt_check.R shows which short attempts match wiki-Elec.
pairs$negative_interval <- (pairs$days_between < 0) %in% TRUE
pairs$short_attempt_pair <- (pairs$previous_short_attempt |
  pairs$next_short_attempt) %in% TRUE
pairs$in_chronological <- !pairs$negative_interval
pairs$in_strict <- !pairs$negative_interval & !pairs$short_attempt_pair

assert_condition(!anyDuplicated(pairs$pair_id), "Pair IDs are not unique.")
assert_condition(
  all(is.na(pairs$supporter_jaccard) |
        pairs$supporter_jaccard >= 0 & pairs$supporter_jaccard <= 1),
  "Supporter Jaccard values are outside [0, 1]."
)
assert_condition(
  all(is.na(pairs$new_support_share) |
        pairs$new_support_share >= 0 & pairs$new_support_share <= 1),
  "New-supporter shares are outside [0, 1]."
)
assert_condition(
  all(is.na(pairs$returning_support_share) |
        pairs$returning_support_share >= 0 &
          pairs$returning_support_share <= 1),
  "Returning-supporter shares are outside [0, 1]."
)
assert_condition(
  all(pairs$previous_support_effective_communities >= 0),
  "Negative previous effective-community value."
)
assert_condition(
  all(pairs$current_support_effective_communities >= 0),
  "Negative current effective-community value."
)
assert_condition(
  all(is.na(pairs$community_mix_js) |
        pairs$community_mix_js >= -1e-12 &
          pairs$community_mix_js <= 1 + 1e-12),
  "Jensen-Shannon divergence is outside [0, 1]."
)

saveRDS(pairs, file.path(DIR_PROCESSED, "attempt_pairs.rds"))
write.csv(
  pairs,
  file.path("output", "results", "attempt_pairs.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)

cat("Attempt pairs written:", nrow(pairs), "\n")
