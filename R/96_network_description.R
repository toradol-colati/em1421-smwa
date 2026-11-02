# 96 - Describe the networks and compare them with random baselines.
#
#   Rscript R/96_network_description.R
#
# The terms come from Lectures 2 and 3: size, degree distribution, density,
# connected components and giant component, average path length and diameter,
# small world, clustering coefficient and triadic closure.
#
# A number like a clustering of 0.45 means little alone, so each is shown next
# to what a random network would give:
#   - clustering: compared with the same network rewired at random while every
#     voter keeps the same degree, so any extra clustering comes from triadic
#     closure, not from degree;
#   - average path length: compared with log(N) / log(mean degree), the value
#     for a random network of the same size.
#
# Output: output/results/network_description.csv
#         output/results/degree_distribution.csv
# Takes about 10 minutes, mostly for the average path length.

suppressPackageStartupMessages({library(igraph); library(Matrix)})
source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

NULL_REPLICATES <- 20     # rewirings per snapshot for the clustering baseline
PATH_SAMPLE     <- 1000   # source nodes sampled for average path length

votes <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))

# ---------------------------------------------------------------- 1. voting --
# Node: a user. Edge: one vote, from the voter to the candidate, with its
# sign (+1 support, -1 oppose, 0 neutral). Self-votes are removed. A voter who
# voted on several elections of the same candidate gives several parallel
# edges; they are kept, so edges = votes.
cat("=== voting network (voter -> candidate) ===\n")
vt <- votes[!votes$self_vote, ]
gv <- graph_from_data_frame(
  data.frame(from = vt$src, to = vt$tgt, sign = vt$vot, stringsAsFactors = FALSE),
  directed = TRUE)
voters <- unique(vt$src); candidates <- unique(vt$tgt)
comp <- components(gv, mode = "weak")
voting <- data.frame(
  network = "voting (directed, signed)",
  nodes = vcount(gv), edges = ecount(gv),
  voters = length(voters), candidates = length(candidates),
  both_roles = length(intersect(voters, candidates)),
  density = edge_density(gv, loops = FALSE),
  giant_component_share = max(comp$csize) / vcount(gv),
  components = comp$no,
  reciprocity = reciprocity(gv),
  stringsAsFactors = FALSE
)
# Reciprocity = share of votes that go both ways (A voted on B and B on A).
print(t(voting))

# Degree distribution p_k (Lecture 2) summarised by quantiles.
# In-degree = votes received, out-degree = votes cast.
deg_in  <- degree(gv, mode = "in")
deg_out <- degree(gv, mode = "out")
dd <- rbind(
  data.frame(network = "voting", direction = "in",
             quantile = c("min","q25","median","mean","q75","q90","q99","max"),
             value = c(min(deg_in), quantile(deg_in, .25), median(deg_in),
                       mean(deg_in), quantile(deg_in, .75), quantile(deg_in, .9),
                       quantile(deg_in, .99), max(deg_in))),
  data.frame(network = "voting", direction = "out",
             quantile = c("min","q25","median","mean","q75","q90","q99","max"),
             value = c(min(deg_out), quantile(deg_out, .25), median(deg_out),
                       mean(deg_out), quantile(deg_out, .75), quantile(deg_out, .9),
                       quantile(deg_out, .99), max(deg_out)))
)

# ------------------------------------------------------------- 2. co-voting --
# Node: a voter. Edge: the two voters voted the same way in at least two
# earlier elections. Undirected, weighted by the number of agreements.
# This is the projection of the bipartite network of voters and elections
# (Lab 5b), so it is dense by construction and needs a baseline.
v2 <- network_votes(votes, attempts)       # support/oppose votes, no self-votes, with year
all_voters <- sort(unique(v2$src))
build_snapshot <- function(cutoff_year) covoting_graph(v2, cutoff_year, all_voters)  # as in 04

# One network per year (the first year has no earlier votes). For each:
# size, mean degree, components, and global clustering (transitivity).
cutoffs <- sort(unique(v2$year)); cutoffs <- cutoffs[cutoffs > min(cutoffs)]
rows <- list()
for (cut in cutoffs) {
  g <- build_snapshot(cut)
  if (is.null(g) || vcount(g) < 10) next
  n <- vcount(g); m <- ecount(g); k_mean <- 2 * m / n
  comp <- components(g)
  tr_obs <- transitivity(g, type = "global")

  # Clustering baseline: rewire the edges NULL_REPLICATES times, keeping every
  # voter's degree. If the real clustering is higher, triadic closure is
  # stronger than the degrees alone would give.
  set.seed(1421 + cut)
  tr_null <- vapply(seq_len(NULL_REPLICATES), function(i)
    transitivity(rewire(g, keeping_degseq(loops = FALSE, niter = m)),
                 type = "global"), 0)

  # Average path length on the giant component. For large networks, distances
  # are measured from a random sample of PATH_SAMPLE voters to save time.
  gc <- induced_subgraph(g, which(comp$membership == which.max(comp$csize)))
  t0 <- Sys.time()
  if (vcount(gc) > PATH_SAMPLE) {
    src <- sample(V(gc), PATH_SAMPLE)
    dmat <- distances(gc, v = src, weights = NA)
    dmat <- dmat[is.finite(dmat) & dmat > 0]
    d_mean <- mean(dmat); d_max <- max(dmat)
  } else {
    # weights = NA: path length counts steps, as in Lecture 2 ("Graphs").
    # Without it igraph treats the co-vote counts as edge lengths.
    d_mean <- mean_distance(gc, directed = FALSE, weights = NA)
    d_max <- diameter(gc, directed = FALSE, weights = NA)
  }
  t_path <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

  # One row per year. random_graph_expectation = log(n) / log(mean degree),
  # the path length of a random network of the same size (small-world check).
  rows[[length(rows) + 1]] <- data.frame(
    cutoff_year = cut, nodes = n, edges = m,
    mean_degree = k_mean,
    median_degree = median(degree(g)),
    max_degree = max(degree(g)),
    density = edge_density(g, loops = FALSE),
    components = comp$no,
    giant_component_share = max(comp$csize) / n,
    transitivity_observed = tr_obs,
    transitivity_null_mean = mean(tr_null),
    transitivity_null_sd = sd(tr_null),
    transitivity_ratio = tr_obs / mean(tr_null),
    mean_path_length = d_mean,
    max_path_length = d_max,
    random_graph_expectation = log(n) / log(k_mean),
    path_sampled = vcount(gc) > PATH_SAMPLE,
    stringsAsFactors = FALSE)
  cat(sprintf("%d: n=%5d m=%7d  C=%.3f vs null %.3f (x%.2f)  <d>=%.2f vs random %.2f  [%.0fs]\n",
              cut, n, m, tr_obs, mean(tr_null), tr_obs / mean(tr_null),
              d_mean, log(n) / log(k_mean), t_path))
}

# Save the table.
out <- do.call(rbind, rows)
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
write.csv(out, file.path("output", "results", "network_description.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# Add the degree distribution of the last co-voting network and save.
g_last <- build_snapshot(max(cutoffs))
d_last <- degree(g_last)
dd <- rbind(dd, data.frame(
  network = "co-voting (last snapshot)", direction = "undirected",
  quantile = c("min","q25","median","mean","q75","q90","q99","max"),
  value = c(min(d_last), quantile(d_last, .25), median(d_last), mean(d_last),
            quantile(d_last, .75), quantile(d_last, .9), quantile(d_last, .99),
            max(d_last))))
write.csv(dd, file.path("output", "results", "degree_distribution.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwritten: output/results/network_description.csv and degree_distribution.csv\n")
