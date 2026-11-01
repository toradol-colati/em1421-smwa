# 95 - The strength of weak ties, tested on the co-voting network.
#
#   Rscript R/95_weak_ties.R
#
# WHY THIS EXISTS
# Lecture 3, "Strong and Weak Ties", is built on Granovetter's hypothesis and on the two measurements
# Onnela et al. used to test it on a large network. Both are directly
# computable here, and both yield a statement about RfA rather than a
# coefficient. The co-voting edge has a natural strength - the number of
# attempts in which two voters took the same side - so the course's test
# transfers without adaptation.
#
# TEST 1 - neighbourhood overlap against tie strength.
#   Overlap of an edge A-B is
#     (number of nodes that neighbour both A and B) / (number that neighbour at
#     least one of them), the course's definition, which is 0 exactly when the
#     edge is a local bridge. Granovetter's prediction, confirmed by Onnela on
#     mobile-phone data, is that overlap GROWS with tie strength: strong ties
#     sit inside dense groups, weak ties reach across them.
#
# TEST 2 - which ties hold the network together.
#   Onnela removed edges one at a time, first in decreasing order of strength
#   and then in increasing order, and watched the giant component. Removing the
#   weakest first made it break apart abruptly; removing the strongest first
#   shrank it gradually. That is the sense in which weak ties are the
#   connective tissue. Here the same is done in two per cent steps.
#
# Test 1 has a comparison point: the same graph with the weights reshuffled,
# which keeps the degree sequence and the weight distribution but destroys any
# relation between tie strength and neighborhood overlap. For speed it uses a
# random sample of EDGE_SAMPLE edges. Test 2 uses all edges and has no
# reshuffled comparison; note that many edges share the minimum weight (2), so
# the order of removal among them is arbitrary.
#
# Output: output/results/weak_ties_overlap.csv
#         output/results/weak_ties_percolation.csv

suppressPackageStartupMessages({library(igraph); library(Matrix)})
source(file.path("R", "00_paths.R"))

SNAPSHOTS    <- c(2008, 2013)   # a mid-sized and the final snapshot
EDGE_SAMPLE  <- 60000           # edges sampled for the overlap test
N_BINS       <- 20              # strength percentile bins
STEP         <- 0.02            # removal step for the percolation test

votes <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
v2 <- votes[!is.na(votes$attempt_id) & votes$vot %in% c(-1L, 1L) & !votes$self_vote, ]
ai <- match(v2$attempt_id, attempts$attempt_id)
v2$year <- attempts$year_from_date[ai]
all_voters <- sort(unique(v2$src))

build_snapshot <- function(cutoff_year) {
  h <- v2[v2$year < cutoff_year, c("attempt_id", "src", "vot")]
  gk <- paste(h$attempt_id, h$vot, sep = "|")
  inc <- sparseMatrix(i = match(gk, unique(gk)), j = match(h$src, all_voters),
                      x = 1, dims = c(length(unique(gk)), length(all_voters)))
  pr <- crossprod(inc); diag(pr) <- 0
  e <- summary(pr); e <- e[e$i < e$j & e$x >= 2, ]
  graph_from_data_frame(
    data.frame(from = all_voters[e$i], to = all_voters[e$j], weight = e$x,
               stringsAsFactors = FALSE), directed = FALSE)
}

# Neighbourhood overlap for a sample of edges, from adjacency lists.
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

  # ---- TEST 1 ----
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

  # ---- TEST 2 ----
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

dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
write.csv(do.call(rbind, overlap_rows),
          file.path("output", "results", "weak_ties_overlap.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(do.call(rbind, perc_rows),
          file.path("output", "results", "weak_ties_percolation.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwritten: output/results/weak_ties_overlap.csv and weak_ties_percolation.csv\n")
