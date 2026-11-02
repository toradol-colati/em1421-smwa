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
# Lecture 3, "Strong and Weak Ties" (section "General Approaches to Graph
# Partitioning"), points the way. It classifies partitioning methods as
# divisive and agglomerative, presents Girvan-Newman as the divisive example,
# and states that it "works well for networks of moderate size (few thousands
# nodes)" while beyond that recomputing betweenness at each step is expensive -
# citing as the alternatives either approximating betweenness or using
# agglomerative methods. Louvain is the standard agglomerative method, so this
# is not a departure from the syllabus but the remedy the syllabus names.
#
# Output: output/results/community_method_check.csv
# Expected running time: about 30 minutes, nearly all of it Girvan-Newman
# (two variants, each stopped after GN_TIMEOUT_S on a snapshot).

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


# Girvan-Newman in a separate R process, killed after `timeout_s` seconds.
# setTimeLimit() inside this process does not reliably interrupt igraph's C
# code: on the 2006 snapshot the time-limit error escaped tryCatch and stopped
# the whole pipeline. Returns the membership vector, or NULL on timeout.
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

  # Two ways to give Girvan-Newman the edges, both valid. In edge betweenness
  # igraph reads weights as edge LENGTHS, so co-vote counts must never be
  # passed as they are: that makes the strongest ties the longest.
  #   - "unweighted": weights = NA, as in the course lab ("Networks in R":
  #     edge_betweenness(net, directed=T, weights=NA));
  #   - "inverse weight": length = 1 / co-vote count, so strong ties are short.
  # Both partitions are scored with the same weighted modularity as Louvain.
  variants <- list(unweighted = NA, `inverse weight` = 1 / E(g)$weight)
  for (variant in names(variants)) {
    t0 <- Sys.time()
    gn <- run_gn_with_timeout(g, variants[[variant]], GN_TIMEOUT_S)
    t_gn <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

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

out <- do.call(rbind, rows)
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
write.csv(out, file.path("output", "results", "community_method_check.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwritten: output/results/community_method_check.csv\n")
cat("For reference, the largest snapshot in the analysis has 6,228 nodes and\n")
cat("771,356 edges, 11.6 times the edges of the 2006 snapshot.\n")
