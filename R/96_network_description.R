# 96 - Structural description of the two networks, against baselines.
#
#   Rscript R/96_network_description.R
#
# WHY THIS EXISTS
# The analysis computes per-node measures and feeds them to a model, but it
# never says what the networks ARE. The course spends two lectures on exactly
# that vocabulary - size, degree and its distribution, density and sparsity,
# connected components and the giant component, shortest paths, average path
# length and diameter, the small-world phenomenon, the clustering coefficient
# and triadic closure - and the instructor's criterion 04 asks for the node,
# edge, direction and weight to be stated before any metric, while criterion 07
# asks every result to carry a comparison point.
#
# A density of 0.09 or a transitivity of 0.45 on their own are not results.
# This script therefore reports each structural quantity NEXT TO the value a
# comparable random graph would give:
#   - observed clustering against a DEGREE-PRESERVING rewiring of the same
#     graph, which keeps every node's degree and destroys everything else, so
#     the excess is attributable to triadic closure rather than to degree;
#   - observed average path length against the small-world expectation for a
#     random graph of the same size and mean degree, log(N) / log(<k>).
#
# Output: output/results/network_description.csv
#         output/results/degree_distribution.csv
# Runtime: about 10 minutes, almost all of it average path length.

suppressPackageStartupMessages({library(igraph); library(Matrix)})
source(file.path("R", "00_paths.R"))

NULL_REPLICATES <- 20     # rewirings per snapshot for the clustering baseline
PATH_SAMPLE     <- 1000   # source nodes sampled for average path length

votes <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))

# ---------------------------------------------------------------- 1. voting --
# Node: a user. Edge: a vote, directed from voter to candidate. Signed by `vot`
# (support, oppose; neutral votes carry no direction of sentiment). Unweighted
# per attempt; a repeat candidate can receive several votes from one voter
# across attempts, so parallel edges exist and are collapsed with a weight.
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
print(t(voting))

# Degree distribution of the voting network: the course's p_k.
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
# Node: a voter. Edge: the two voters cast the same direction in at least two
# historical attempts. Undirected, weighted by how many attempts they agreed on.
# This is the projection onto voters of the bipartite affiliation network of
# voters and attempts - the attempt is a focus in Feld's sense - so it is dense
# by construction and must be read against a baseline.
v2 <- votes[!is.na(votes$attempt_id) & votes$vot %in% c(-1L, 1L) & !votes$self_vote, ]
ai <- match(v2$attempt_id, attempts$attempt_id)
v2$year <- attempts$year_from_date[ai]
all_voters <- sort(unique(v2$src))

build_snapshot <- function(cutoff_year) {
  h <- v2[v2$year < cutoff_year, c("attempt_id", "src", "vot")]
  if (nrow(h) == 0L) return(NULL)
  gk <- paste(h$attempt_id, h$vot, sep = "|")
  inc <- sparseMatrix(i = match(gk, unique(gk)), j = match(h$src, all_voters),
                      x = 1, dims = c(length(unique(gk)), length(all_voters)))
  pr <- crossprod(inc); diag(pr) <- 0
  e <- summary(pr); e <- e[e$i < e$j & e$x >= 2, ]
  if (nrow(e) == 0L) return(NULL)
  graph_from_data_frame(
    data.frame(from = all_voters[e$i], to = all_voters[e$j], weight = e$x,
               stringsAsFactors = FALSE), directed = FALSE)
}

cutoffs <- sort(unique(v2$year)); cutoffs <- cutoffs[cutoffs > min(cutoffs)]
rows <- list()
for (cut in cutoffs) {
  g <- build_snapshot(cut)
  if (is.null(g) || vcount(g) < 10) next
  n <- vcount(g); m <- ecount(g); k_mean <- 2 * m / n
  comp <- components(g)
  tr_obs <- transitivity(g, type = "global")

  # degree-preserving null: same degree sequence, everything else destroyed
  set.seed(1421 + cut)
  tr_null <- vapply(seq_len(NULL_REPLICATES), function(i)
    transitivity(rewire(g, keeping_degseq(loops = FALSE, niter = m)),
                 type = "global"), 0)

  # average path length on the giant component; sampled when the graph is large
  gc <- induced_subgraph(g, which(comp$membership == which.max(comp$csize)))
  t0 <- Sys.time()
  if (vcount(gc) > PATH_SAMPLE) {
    src <- sample(V(gc), PATH_SAMPLE)
    dmat <- distances(gc, v = src, weights = NA)
    dmat <- dmat[is.finite(dmat) & dmat > 0]
    d_mean <- mean(dmat); d_max <- max(dmat)
  } else {
    d_mean <- mean_distance(gc, directed = FALSE)
    d_max <- diameter(gc, directed = FALSE, weights = NA)
  }
  t_path <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

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

out <- do.call(rbind, rows)
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
write.csv(out, file.path("output", "results", "network_description.csv"), row.names = FALSE)

# degree distribution of the last co-voting snapshot as well
g_last <- build_snapshot(max(cutoffs))
d_last <- degree(g_last)
dd <- rbind(dd, data.frame(
  network = "co-voting (last snapshot)", direction = "undirected",
  quantile = c("min","q25","median","mean","q75","q90","q99","max"),
  value = c(min(d_last), quantile(d_last, .25), median(d_last), mean(d_last),
            quantile(d_last, .75), quantile(d_last, .9), quantile(d_last, .99),
            max(d_last))))
write.csv(dd, file.path("output", "results", "degree_distribution.csv"), row.names = FALSE)
cat("\nwritten: output/results/network_description.csv and degree_distribution.csv\n")
