# 97 - Girvan-Newman (from the course) compared with Louvain (used in 04).
#
#   Rscript R/97_community_method_check.R
#
# Lecture 3 presents Girvan-Newman as a divisive method that "works well for
# networks of moderate size (few thousands nodes)"; for larger networks it
# names agglomerative methods as the alternative. Louvain is agglomerative.
# This script runs both on the three smallest co-voting networks and records
# the number of communities, modularity, running time and how much the two
# partitions agree (adjusted Rand index).
#
# Output: output/results/community_method_check.csv
# Takes about 30 minutes, mostly Girvan-Newman (stopped after GN_TIMEOUT_S
# seconds on a snapshot).

suppressPackageStartupMessages({library(igraph); library(Matrix)})
source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

CUTOFFS      <- c(2004, 2005, 2006)   # the three smallest snapshots
GN_TIMEOUT_S <- 600                   # give-up time for Girvan-Newman

attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
votes <- network_votes(readRDS(file.path(DIR_PROCESSED, "votes.rds")), attempts)
all_voters <- sort(unique(votes$src))
build_snapshot <- function(cutoff_year) covoting_graph(votes, cutoff_year, all_voters)  # as in 04

# Adjusted Rand index: how similar two community splits are.
# 1 = identical, about 0 = no more similar than random splits.
adjusted_rand <- function(a, b) {
  tb <- table(a, b); n <- sum(tb)
  s_ij <- sum(choose(tb, 2)); s_i <- sum(choose(rowSums(tb), 2)); s_j <- sum(choose(colSums(tb), 2))
  expected <- s_i * s_j / choose(n, 2)
  (s_ij - expected) / ((s_i + s_j) / 2 - expected)
}


# Run Girvan-Newman in a separate R process that is stopped after timeout_s
# seconds. (A time limit inside this process failed on the 2006 network and
# stopped the whole run.) Returns the community of each voter, or NULL.
run_gn_with_timeout <- function(g, weights, timeout_s) {
  graph_file <- tempfile(fileext = ".rds")
  result_file <- tempfile(fileext = ".rds")
  saveRDS(list(graph = g, weights = weights), graph_file)
  code <- sprintf(paste0(
    "suppressPackageStartupMessages(library(igraph));",
    "x <- readRDS('%s');",
    "r <- suppressWarnings(cluster_edge_betweenness(x$graph, weights = x$weights));",
    "saveRDS(as.integer(membership(r)), '%s')"),
    gsub("\\\\", "/", graph_file), gsub("\\\\", "/", result_file))
  rscript <- file.path(R.home("bin"), "Rscript")
  status <- suppressWarnings(system2(rscript, c("-e", shQuote(code)),
                                     timeout = timeout_s, stdout = FALSE, stderr = FALSE))
  on.exit(unlink(c(graph_file, result_file)))
  if (!identical(as.integer(status), 0L) || !file.exists(result_file)) return(NULL)
  readRDS(result_file)
}

# For each of the three networks: run Louvain and time it, then run both
# Girvan-Newman versions and compare.
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

  # Girvan-Newman is run two ways. igraph treats weights as edge lengths here,
  # so co-vote counts cannot be used directly (strong ties would look long):
  #   - "unweighted": weights = NA, as in the course lab (Lab 5a);
  #   - "inverse weight": length = 1 / co-vote count, so strong ties are short.
  # Both results are scored with the same weighted modularity as Louvain.
  variants <- list(unweighted = NA, `inverse weight` = 1 / E(g)$weight)
  for (variant in names(variants)) {
    t0 <- Sys.time()
    gn <- run_gn_with_timeout(g, variants[[variant]], GN_TIMEOUT_S)
    t_gn <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

    # If Girvan-Newman finished: its modularity and its similarity to Louvain.
    done <- !is.null(gn)
    gn_q <- if (done) modularity(g, gn, weights = E(g)$weight) else NA_real_
    ar   <- if (done) adjusted_rand(membership(lv), gn) else NA_real_
    if (done) {
      cat(sprintf("  Girvan-Newman (%s): %d communities, modularity %.3f, %.1f s, adjusted Rand vs Louvain %.3f\n",
                  variant, length(unique(gn)), gn_q, t_gn, ar))
    } else {
      cat(sprintf("  Girvan-Newman (%s): did not finish within %d s\n", variant, GN_TIMEOUT_S))
    }
    rows[[length(rows) + 1]] <- data.frame(
      cutoff_year = cut, nodes = vcount(g), edges = ecount(g),
      louvain_communities = length(sizes(lv)), louvain_modularity = modularity(lv),
      louvain_seconds = round(t_lv, 2),
      gn_variant = variant,
      gn_communities = if (done) length(unique(gn)) else NA_integer_,
      gn_modularity = gn_q,
      gn_seconds = if (done) round(t_gn, 1) else NA_real_,
      gn_completed = done, adjusted_rand = ar)
  }
}

# Save the table.
out <- do.call(rbind, rows)
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
write.csv(out, file.path("output", "results", "community_method_check.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwritten: output/results/community_method_check.csv\n")
# For comparison: the largest network in the analysis (2013) has 6,228 voters
# and 771,356 edges, 11.6 times the edges of the 2006 network.
