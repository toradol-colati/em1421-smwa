# 04 - Historical signed voter co-voting networks.
#
# Input : data/processed/votes.rds
#         data/processed/attempts_analysis.rds
# Output: data/processed/network_objects.rds
#         output/results/network_summary.csv
#         output/results/community_method_check.csv
# Packages: igraph, Matrix

set.seed(1421)

local_lib <- file.path(getwd(), ".Rlib")
if (dir.exists(local_lib)) {
  .libPaths(c(local_lib, .libPaths()))
}

suppressPackageStartupMessages({
  library(igraph)
  library(Matrix)
})

source(file.path("R", "00_paths.R"))
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)

required <- file.path(
  DIR_PROCESSED,
  c("votes.rds", "attempts_analysis.rds")
)
if (any(!file.exists(required))) {
  stop("Run R/01_prepare_data.R before R/04_build_networks.R.", call. = FALSE)
}

assert_condition <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
}

votes <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))

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

build_covoting_snapshot <- function(cutoff_year, all_voters) {
  history <- votes[
    votes$year < cutoff_year,
    c("attempt_id", "voter", "vote"),
  ]
  if (nrow(history) == 0L) {
    return(NULL)
  }

  group_key <- paste(history$attempt_id, history$vote, sep = "|")
  group_id <- match(group_key, unique(group_key))
  voter_id <- match(history$voter, all_voters)
  incidence <- sparseMatrix(
    i = group_id,
    j = voter_id,
    x = 1,
    dims = c(length(unique(group_key)), length(all_voters))
  )
  projection <- crossprod(incidence)
  diag(projection) <- 0
  entries <- summary(projection)

  # A link requires agreement in at least two historical attempts.
  entries <- entries[entries$i < entries$j & entries$x >= 2, ]
  assert_condition(
    all(entries$x >= 2),
    "Covoting network contains an edge below the two-event threshold."
  )
  if (nrow(entries) == 0L) {
    return(NULL)
  }

  edge_table <- data.frame(
    from = all_voters[entries$i],
    to = all_voters[entries$j],
    weight = entries$x,
    stringsAsFactors = FALSE
  )
  graph <- graph_from_data_frame(edge_table, directed = FALSE)

  set.seed(1421 + cutoff_year)
  communities <- cluster_louvain(graph, weights = E(graph)$weight)
  graph_membership <- membership(communities)
  graph_degree <- strength(graph, mode = "all", weights = E(graph)$weight)
  graph_pagerank <- page_rank(
    graph,
    directed = FALSE,
    weights = E(graph)$weight
  )$vector
  graph_eigenvector <- tryCatch(
    eigen_centrality(
      graph,
      directed = FALSE,
      weights = E(graph)$weight
    )$vector,
    error = function(e) rep(0, vcount(graph))
  )
  graph_local_clustering <- transitivity(
    graph,
    type = "local",
    weights = NA
  )
  graph_local_clustering[is.na(graph_local_clustering)] <- 0

  membership_all <- rep(NA_integer_, length(all_voters))
  names(membership_all) <- all_voters
  degree_all <- rep(0, length(all_voters))
  names(degree_all) <- all_voters
  pagerank_all <- rep(0, length(all_voters))
  names(pagerank_all) <- all_voters
  eigenvector_all <- rep(0, length(all_voters))
  names(eigenvector_all) <- all_voters
  local_clustering_all <- rep(0, length(all_voters))
  names(local_clustering_all) <- all_voters
  membership_all[V(graph)$name] <- graph_membership
  degree_all[V(graph)$name] <- graph_degree
  pagerank_all[V(graph)$name] <- graph_pagerank
  eigenvector_all[V(graph)$name] <- graph_eigenvector
  local_clustering_all[V(graph)$name] <- graph_local_clustering

  edge_vertices <- ends(graph, E(graph), names = TRUE)
  from_community <- membership_all[edge_vertices[, 1]]
  to_community <- membership_all[edge_vertices[, 2]]
  cross <- from_community != to_community

  max_community <- max(membership_all, na.rm = TRUE)
  community_bridge_exposure <- rep(0L, max_community)
  names(community_bridge_exposure) <- as.character(seq_len(max_community))
  if (any(cross)) {
    long_cross <- rbind(
      data.frame(community = from_community[cross],
                 other = to_community[cross]),
      data.frame(community = to_community[cross],
                 other = from_community[cross])
    )
    bridge_counts <- tapply(
      long_cross$other,
      long_cross$community,
      function(x) length(unique(x))
    )
    community_bridge_exposure[names(bridge_counts)] <-
      as.integer(bridge_counts)
  }
  cross_edges <- data.frame(
    lower = pmin(from_community[cross], to_community[cross]),
    upper = pmax(from_community[cross], to_community[cross]),
    weight = E(graph)$weight[cross],
    stringsAsFactors = FALSE
  )
  community_edge_summary <- if (nrow(cross_edges) == 0L) {
    data.frame(lower = integer(), upper = integer(), weight = numeric())
  } else {
    aggregate(
      cross_edges$weight,
      by = list(lower = cross_edges$lower, upper = cross_edges$upper),
      FUN = sum
    ) |>
      setNames(c("lower", "upper", "weight"))
  }

  summary_row <- data.frame(
    cutoff_year = cutoff_year,
    historical_votes = nrow(history),
    eligible_voters = length(unique(history$voter)),
    network_voters = vcount(graph),
    covoting_edges = ecount(graph),
    communities_nonempty = length(unique(na.omit(membership_all))),
    modularity = modularity(communities),
    cross_community_edges = sum(cross),
    cross_community_share = sum(cross) / ecount(graph),
    mean_weighted_degree = mean(degree_all[degree_all > 0]),
    density = edge_density(graph, loops = FALSE),
    global_transitivity = transitivity(graph, type = "global", weights = NA),
    stringsAsFactors = FALSE
  )

  list(
    graph = graph,
    membership = membership_all,
    weighted_degree = degree_all,
    pagerank = pagerank_all,
    eigenvector = eigenvector_all,
    local_clustering = local_clustering_all,
    community_bridge_exposure = community_bridge_exposure,
    community_edges = community_edge_summary,
    summary = summary_row
  )
}

all_voters <- sort(unique(votes$voter))
target_years <- sort(unique(attempts$year_from_date))
snapshots <- list()
for (target_year in target_years) {
  snapshot <- build_covoting_snapshot(target_year, all_voters)
  if (!is.null(snapshot)) {
    snapshots[[as.character(target_year)]] <- snapshot
  }
}
if (length(snapshots) == 0L) {
  stop("No historical co-voting networks could be built.", call. = FALSE)
}

network_summary <- do.call(rbind, lapply(snapshots, `[[`, "summary"))
write.csv(
  network_summary,
  file.path("output", "results", "network_summary.csv"),
  row.names = FALSE
)

small_graph <- snapshots[[1]]$graph
set.seed(1421)
girvan_newman <- cluster_edge_betweenness(
  small_graph,
  weights = 1 / E(small_graph)$weight,
  directed = FALSE
)
set.seed(1421)
girvan_newman_unweighted <- cluster_edge_betweenness(
  small_graph,
  weights = NA,
  directed = FALSE
)
community_method_check <- data.frame(
  method = c(
    "Weighted Louvain",
    "Weighted Girvan-Newman",
    "Unweighted Girvan-Newman"
  ),
  cutoff_year = network_summary$cutoff_year[1],
  network_voters = vcount(small_graph),
  covoting_edges = ecount(small_graph),
  communities = c(
    network_summary$communities_nonempty[1],
    length(unique(membership(girvan_newman))),
    length(unique(membership(girvan_newman_unweighted)))
  ),
  modularity = c(
    network_summary$modularity[1],
    modularity(girvan_newman),
    modularity(girvan_newman_unweighted)
  ),
  stringsAsFactors = FALSE
)
write.csv(
  community_method_check,
  file.path("output", "results", "community_method_check.csv"),
  row.names = FALSE
)

saveRDS(
  list(
    snapshots = lapply(snapshots, function(x) {
      list(
        summary = x$summary,
        membership = x$membership,
        weighted_degree = x$weighted_degree,
        pagerank = x$pagerank,
        eigenvector = x$eigenvector,
        local_clustering = x$local_clustering,
        community_bridge_exposure = x$community_bridge_exposure,
        community_edges = x$community_edges
      )
    })
  ),
  file.path(DIR_PROCESSED, "network_objects.rds")
)
