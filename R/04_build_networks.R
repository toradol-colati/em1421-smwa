# 04 - Build one co-voting network of voters per year (Lab 5b projection).
#
# For each year Y the network uses only elections BEFORE Y, so it shows what
# the voting community looked like when a candidate in year Y ran again.
#   Node  : a voter.
#   Edge  : two voters voted the same way in at least two earlier elections.
#   Weight: the number of elections in which they agreed.
# On each network the script finds communities (Louvain) and node measures
# (strength, PageRank, eigenvector centrality, local clustering; Lecture 6).
#
# Input : data/processed/votes.rds, attempts_analysis.rds
# Output: data/processed/network_objects.rds
#         output/results/network_summary.csv

if (dir.exists(".Rlib")) .libPaths(c(file.path(getwd(), ".Rlib"), .libPaths()))
suppressPackageStartupMessages({ library(igraph); library(Matrix) })
source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
if (!all(file.exists(file.path(DIR_PROCESSED, c("votes.rds", "attempts_analysis.rds")))))
  stop("Run R/run_data_prep.R before R/04_build_networks.R.", call. = FALSE)

votes    <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))

votes <- network_votes(votes, attempts)    # support/oppose votes, no self-votes, with year
all_voters <- sort(unique(votes$src))

build_covoting_snapshot <- function(cutoff_year) {
  graph <- covoting_graph(votes, cutoff_year, all_voters)   # see 00_lib_data.R
  if (is.null(graph)) return(NULL)
  h <- votes[votes$year < cutoff_year, ]                     # the earlier votes
  w <- E(graph)$weight

  # Communities (Louvain; 97 compares it with Girvan-Newman). The seed is set
  # right before, so the result is the same on every run.
  set.seed(1421 + cutoff_year)
  communities <- cluster_louvain(graph, weights = w)
  memb <- as.numeric(membership(communities))   # plain numbers, one per node

  # Node measures, stored for ALL voters: voters with no edge get community NA
  # and 0 for every measure. If eigenvector centrality fails, everyone gets 0.
  for_all_voters <- function(x, empty) {
    out <- setNames(rep(empty, length(all_voters)), all_voters)
    out[V(graph)$name] <- x
    out
  }
  # (Same order of calls as before: igraph uses R's random numbers.)
  degree_all <- for_all_voters(strength(graph, weights = w), 0)
  pagerank <- page_rank(graph, directed = FALSE, weights = w)$vector
  eigenvector <- tryCatch(eigen_centrality(graph, directed = FALSE, weights = w)$vector,
                          error = function(e) rep(0, vcount(graph)))
  clustering <- transitivity(graph, type = "local", weights = NA)
  clustering[is.na(clustering)] <- 0      # voters with fewer than 2 neighbours

  # Edges between communities. For each community: how many other
  # communities it touches, and the total edge weight between each pair.
  el <- as_edgelist(graph, names = FALSE)
  from_c <- memb[el[, 1]]; to_c <- memb[el[, 2]]
  cross <- from_c != to_c
  touches <- unique(rbind(cbind(from_c, to_c), cbind(to_c, from_c))[c(cross, cross), , drop = FALSE])
  bridge_exposure <- setNames(tabulate(touches[, 1], nbins = max(memb)),
                              paste(seq_len(max(memb))))   # names "1", "2", ...
  cross_edges <- data.frame(lower = pmin(from_c, to_c)[cross],
                            upper = pmax(from_c, to_c)[cross], weight = w[cross])
  community_edges <- if (any(cross)) {
    aggregate(weight ~ lower + upper, data = cross_edges, FUN = sum)
  } else {
    data.frame(lower = integer(), upper = integer(), weight = numeric())
  }

  list(
    summary = data.frame(
      cutoff_year = cutoff_year,
      historical_votes = nrow(h),
      eligible_voters = length(unique(h$src)),
      network_voters = vcount(graph),
      covoting_edges = ecount(graph),
      communities_nonempty = length(unique(memb)),
      modularity = modularity(communities),
      cross_community_edges = sum(cross),
      cross_community_share = sum(cross) / ecount(graph),
      mean_weighted_degree = mean(degree_all[degree_all > 0]),
      density = edge_density(graph),
      global_transitivity = transitivity(graph, type = "global", weights = NA)),
    membership = for_all_voters(memb, NA_integer_),
    weighted_degree = degree_all,
    pagerank = for_all_voters(pagerank, 0),
    eigenvector = for_all_voters(eigenvector, 0),
    local_clustering = for_all_voters(clustering, 0),
    community_bridge_exposure = bridge_exposure,
    community_edges = community_edges
  )
}

# One network per year in which an election starts (the first year has no
# earlier votes and is skipped).
years <- sort(unique(attempts$year_from_date))
snapshots <- Filter(Negate(is.null), setNames(lapply(years, build_covoting_snapshot), paste(years)))
if (length(snapshots) == 0L) stop("No co-voting network could be built.", call. = FALSE)

write.csv(do.call(rbind, lapply(snapshots, `[[`, "summary")),
          file.path("output", "results", "network_summary.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
saveRDS(list(snapshots = snapshots), file.path(DIR_PROCESSED, "network_objects.rds"))
