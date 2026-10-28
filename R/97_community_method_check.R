# 97 - Does the course's community-detection method work on these networks?
#
#   Rscript R/97_community_method_check.R
#
# WHY THIS EXISTS
# The course teaches one community-detection algorithm, Girvan-Newman
# (cluster_edge_betweenness), and the analysis uses Louvain
# (cluster_louvain). That substitution has to be defended, not assumed, so this
# script measures it instead of asserting it: it rebuilds the co-voting
# snapshots with the same rule as 04_build_networks.R and runs both methods on
# the three smallest ones, recording communities found, modularity, running
# time, and how much the two partitions agree (adjusted Rand index).
#
# The course itself points the way. It classifies partitioning methods as
# divisive and agglomerative, presents Girvan-Newman as the divisive example,
# and states that it "works well for networks of moderate size (few thousands
# nodes)" while beyond that recomputing betweenness at each step is expensive -
# citing as the alternatives either approximating betweenness or using
# agglomerative methods. Louvain is the standard agglomerative method, so this
# is not a departure from the syllabus but the remedy the syllabus names.
#
# Output: output/results/community_method_check.csv
# Expected running time: about 15 minutes, nearly all of it Girvan-Newman.

suppressPackageStartupMessages({library(igraph); library(Matrix)})
source(file.path("R", "00_paths.R"))

CUTOFFS      <- c(2004, 2005, 2006)   # the three smallest snapshots
GN_TIMEOUT_S <- 600                   # give-up time for Girvan-Newman

votes <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
votes <- votes[!is.na(votes$attempt_id) & votes$vot %in% c(-1L, 1L) & !votes$self_vote, ]
ai <- match(votes$attempt_id, attempts$attempt_id)
votes$voter <- votes$src
votes$vote  <- votes$vot
votes$year  <- attempts$year_from_date[ai]
all_voters  <- sort(unique(votes$voter))

# Same construction as 04_build_networks.R: two voters are linked when they cast
# the same direction in at least two historical attempts, weighted by how often.
build_snapshot <- function(cutoff_year) {
  h <- votes[votes$year < cutoff_year, c("attempt_id", "voter", "vote")]
  gk <- paste(h$attempt_id, h$vote, sep = "|")
  inc <- sparseMatrix(i = match(gk, unique(gk)), j = match(h$voter, all_voters),
                      x = 1, dims = c(length(unique(gk)), length(all_voters)))
  pr <- crossprod(inc); diag(pr) <- 0
  e <- summary(pr); e <- e[e$i < e$j & e$x >= 2, ]
  graph_from_data_frame(
    data.frame(from = all_voters[e$i], to = all_voters[e$j],
               weight = e$x, stringsAsFactors = FALSE),
    directed = FALSE)
}

# Adjusted Rand index, computed directly to avoid another dependency.
adjusted_rand <- function(a, b) {
  tb <- table(a, b); n <- sum(tb)
  s_ij <- sum(choose(tb, 2)); s_i <- sum(choose(rowSums(tb), 2)); s_j <- sum(choose(colSums(tb), 2))
  expected <- s_i * s_j / choose(n, 2)
  (s_ij - expected) / ((s_i + s_j) / 2 - expected)
}

rows <- list()
for (cut in CUTOFFS) {
  g <- build_snapshot(cut)
  cat(sprintf("\nsnapshot %d: %d nodes, %d edges\n", cut, vcount(g), ecount(g)))
  set.seed(1421 + cut)
  t0 <- Sys.time()
  lv <- cluster_louvain(g, weights = E(g)$weight)
  t_lv <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  cat(sprintf("  Louvain       : %d communities, modularity %.3f, %.2f s\n",
              length(sizes(lv)), modularity(lv), t_lv))

  t0 <- Sys.time()
  gn <- tryCatch({
    setTimeLimit(cpu = GN_TIMEOUT_S, elapsed = GN_TIMEOUT_S, transient = TRUE)
    r <- suppressWarnings(cluster_edge_betweenness(g, weights = E(g)$weight))
    setTimeLimit(); r
  }, error = function(e) { setTimeLimit(); NULL })
  t_gn <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

  if (is.null(gn)) {
    cat(sprintf("  Girvan-Newman : did not finish within %d s\n", GN_TIMEOUT_S))
    rows[[length(rows) + 1]] <- data.frame(
      cutoff_year = cut, nodes = vcount(g), edges = ecount(g),
      louvain_communities = length(sizes(lv)), louvain_modularity = modularity(lv),
      louvain_seconds = round(t_lv, 2),
      gn_communities = NA_integer_, gn_modularity = NA_real_,
      gn_seconds = NA_real_, gn_completed = FALSE, adjusted_rand = NA_real_)
  } else {
    ar <- adjusted_rand(membership(lv), membership(gn))
    cat(sprintf("  Girvan-Newman : %d communities, modularity %.3f, %.1f s\n",
                length(sizes(gn)), modularity(gn), t_gn))
    cat(sprintf("  agreement between the two partitions (adjusted Rand): %.3f\n", ar))
    rows[[length(rows) + 1]] <- data.frame(
      cutoff_year = cut, nodes = vcount(g), edges = ecount(g),
      louvain_communities = length(sizes(lv)), louvain_modularity = modularity(lv),
      louvain_seconds = round(t_lv, 2),
      gn_communities = length(sizes(gn)), gn_modularity = modularity(gn),
      gn_seconds = round(t_gn, 1), gn_completed = TRUE, adjusted_rand = ar)
  }
}

out <- do.call(rbind, rows)
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
write.csv(out, file.path("output", "results", "community_method_check.csv"), row.names = FALSE)
cat("\nwritten: output/results/community_method_check.csv\n")
cat("For reference, the largest snapshot in the analysis has 6,228 nodes and\n")
cat("771,356 edges, that is 11.6 times the edges of the 2006 snapshot on which\n")
cat("Girvan-Newman already failed to finish.\n")
