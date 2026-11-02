# 95 - The strength of weak ties (Lecture 3, Granovetter; Onnela et al.).
#
#   Rscript R/95_weak_ties.R
#
# Tie strength = the number of elections in which two voters took the same side.
#
# Test 1 - neighborhood overlap against tie strength.
#   Neighborhood overlap of an edge A-B = (voters linked to both A and B) /
#   (voters linked to A or B). It is 0 when the edge is a local bridge.
#   Granovetter's idea: strong ties sit inside tight groups (high overlap),
#   weak ties connect different groups (low overlap).
#   Baseline: the same network with the weights shuffled at random.
#   For speed, a random sample of EDGE_SAMPLE edges is used.
#
# Test 2 - which ties hold the network together.
#   As in Onnela et al., edges are removed in steps of 2%, weakest first and
#   then strongest first, and the size of the giant component is recorded.
#   This test uses all edges and has no shuffled baseline. Many edges have the
#   minimum weight (2), so the order among them is arbitrary.
#
# Output: output/results/weak_ties_overlap.csv
#         output/results/weak_ties_percolation.csv

suppressPackageStartupMessages({library(igraph); library(Matrix)})
source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

SNAPSHOTS    <- c(2008, 2013)   # a mid-sized and the final snapshot
EDGE_SAMPLE  <- 60000           # edges sampled for the overlap test
N_BINS       <- 20              # strength percentile bins
STEP         <- 0.02            # removal step for the percolation test

attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
v2 <- network_votes(readRDS(file.path(DIR_PROCESSED, "votes.rds")), attempts)
all_voters <- sort(unique(v2$src))
build_snapshot <- function(cutoff_year) covoting_graph(v2, cutoff_year, all_voters)  # as in 04

# Neighborhood overlap of each edge A-B: shared neighbours of A and B divided
# by all neighbours of A or B (not counting A and B themselves).
overlap_of_edges <- function(g, edge_ids) {
  nb <- adjacent_vertices(g, V(g))
  ends_m <- ends(g, E(g)[edge_ids], names = FALSE)
  vapply(seq_len(nrow(ends_m)), function(r) {
    a <- nb[[ends_m[r, 1]]]; b <- nb[[ends_m[r, 2]]]
    a <- setdiff(as.integer(a), ends_m[r, 2])
    b <- setdiff(as.integer(b), ends_m[r, 1])
    u <- length(union(a, b))
    if (u == 0) NA_real_ else length(intersect(a, b)) / u
  }, 0)
}

overlap_rows <- list(); perc_rows <- list()
for (cut in SNAPSHOTS) {
  g <- build_snapshot(cut)
  m <- ecount(g)
  cat(sprintf("\n=== snapshot %d: %d nodes, %d edges ===\n", cut, vcount(g), m))

  # the same graph with degrees kept and weights reshuffled: the baseline
  set.seed(1421 + cut)
  g_null <- g
  E(g_null)$weight <- sample(E(g)$weight)

  # ---- TEST 1: neighborhood overlap against tie strength ----
  # Sort the sampled edges by weight into N_BINS equal groups (bin 1 = weakest
  # 5%, bin 20 = strongest 5%) and take the mean overlap in each group. Done
  # on the real network and on the shuffled one. Spearman rho = rank
  # correlation of weight and overlap.
  for (lab in c("observed", "weights reshuffled")) {
    gg <- if (lab == "observed") g else g_null
    set.seed(95 + cut)
    ids <- if (m > EDGE_SAMPLE) sort(sample.int(m, EDGE_SAMPLE)) else seq_len(m)
    ov <- overlap_of_edges(gg, ids)
    w <- E(gg)$weight[ids]
    bin <- cut(rank(w, ties.method = "average") / length(w),
               breaks = seq(0, 1, length.out = N_BINS + 1),
               include.lowest = TRUE, labels = FALSE)
    agg <- tapply(ov, bin, function(x) mean(x, na.rm = TRUE))
    wm  <- tapply(w, bin, median)
    nn  <- tapply(ov, bin, function(x) sum(!is.na(x)))
    overlap_rows[[length(overlap_rows) + 1]] <- data.frame(
      cutoff_year = cut, series = lab,
      strength_percentile_bin = as.integer(names(agg)),
      median_strength = as.numeric(wm),
      mean_overlap = as.numeric(agg), n_edges = as.integer(nn),
      stringsAsFactors = FALSE)
    rho <- suppressWarnings(cor(w, ov, method = "spearman", use = "complete.obs"))
    cat(sprintf("  overlap vs strength [%s]: bin 1 = %.3f, bin %d = %.3f, Spearman rho = %.3f\n",
                lab, agg[1], N_BINS, agg[length(agg)], rho))
  }

  # ---- TEST 2: remove edges and watch the giant component ----
  # Remove 0%, 2%, 4%, ... up to 90% of the edges, weakest first and then
  # strongest first, and record the size of the largest component as a share
  # of its starting size. If removing weak ties breaks the network faster,
  # weak ties are the bridges between groups (Onnela et al.).
  n0 <- max(components(g)$csize)
  for (ordering in c("weakest first", "strongest first")) {
    ord <- order(E(g)$weight, decreasing = (ordering == "strongest first"))
    fracs <- seq(0, 0.9, by = STEP)
    gc <- vapply(fracs, function(f) {
      k <- floor(f * m)
      gg <- if (k == 0) g else delete_edges(g, E(g)[ord[seq_len(k)]])
      max(components(gg)$csize) / n0
    }, 0)
    perc_rows[[length(perc_rows) + 1]] <- data.frame(
      cutoff_year = cut, removal_order = ordering,
      fraction_removed = fracs, giant_component_share = gc,
      stringsAsFactors = FALSE)
    half <- fracs[which(gc < 0.5)[1]]
    cat(sprintf("  percolation [%-15s]: giant component falls below half after %s of edges\n",
                ordering, ifelse(is.na(half), "more than 90%", sprintf("%.0f%%", 100 * half))))
  }
}

# Save both tables.
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
write.csv(do.call(rbind, overlap_rows),
          file.path("output", "results", "weak_ties_overlap.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(do.call(rbind, perc_rows),
          file.path("output", "results", "weak_ties_percolation.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwritten: output/results/weak_ties_overlap.csv and weak_ties_percolation.csv\n")
