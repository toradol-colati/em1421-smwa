# 94 - Membership closure: are voters recruited through the old coalition?
#
#   Rscript R/94_recruitment_curve.R
#
# Lecture 4 ("Networks in their Surrounding Contexts", membership closure) asks
# how likely a person is to join a group as a function of how many of their
# friends are already in it. Here the group is a candidate's supporters.
#
# For two consecutive elections t and t+1 of the same candidate:
#   - S_t = the voters who supported the candidate at t;
#   - for each voter who did not vote at t, k = how many of their co-voters
#     are in S_t;
#   - T(k) = the share of these voters who support the candidate at t+1.
#
# The co-voting network uses only elections from years before t, so the
# election being studied cannot create its own connections.
#
# Baseline: as in Lecture 4, each connection is assumed to act independently.
# Observed above the baseline means connections reinforce each other; below
# means "diminishing returns" (see the formula at the end of the script).
#
# Output: output/results/recruitment_curve.csv

suppressPackageStartupMessages({library(igraph); library(Matrix)})
source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

K_MAX <- 12   # k values reported separately; above this they are pooled

# Read data.
votes <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
pairs <- readRDS(file.path(DIR_PROCESSED, "attempt_pairs.rds"))
pairs_all <- pairs   # populations: see 05_measure_change.R

# Real votes only (support or oppose, no self-votes), with year and a number
# for each voter so voters can be used as matrix rows.
v2 <- network_votes(votes, attempts)       # as in 04
v2$candidate <- v2$tgt
all_voters <- sort(unique(v2$src))
n_v <- length(all_voters)
v2$voter_id <- match(v2$src, all_voters)

# Binary co-voting adjacency from attempts strictly before `cutoff_year`.
adjacency_before <- local({
  cache <- list()
  function(cutoff_year) {
    key <- as.character(cutoff_year)
    if (!is.null(cache[[key]])) return(cache[[key]])
    h <- v2[v2$year < cutoff_year, ]
    if (nrow(h) == 0L) return(NULL)
    gk <- paste(h$attempt_id, h$vot, sep = "|")
    inc <- sparseMatrix(i = match(gk, unique(gk)), j = h$voter_id, x = 1,
                        dims = c(length(unique(gk)), n_v))
    pr <- crossprod(inc)
    pr@x[pr@x < 2] <- 0        # a link needs agreement in at least two attempts
    pr <- drop0(pr); diag(pr) <- 0
    a <- drop0(pr); a@x[] <- 1
    cache[[key]] <<- a
    a
  }
})

# Voter numbers of the supporters / of everyone who voted in one election.
supporters_of <- function(attempt_id) {
  v2$voter_id[v2$attempt_id == attempt_id & v2$vot == 1L]
}
voters_of <- function(attempt_id) {
  v2$voter_id[v2$attempt_id == attempt_id]
}

# T(k) curve for a set of pairs. For each pair:
#   - network = voters' co-voting ties before the year of the FIRST election;
#   - k = how many of a voter's network neighbours supported the first election;
#   - the voter counts as "recruited" if they support the SECOND election.
# Only voters who did not vote in the first election are counted, so we look
# at new people joining. T(k) = recruited / eligible voters with that k.
tk_curve <- function(pairs) {
  k_hits <- numeric(K_MAX + 1); k_n <- numeric(K_MAX + 1)
  used_pairs <- 0L
  for (r in seq_len(nrow(pairs))) {
    prev_id <- pairs$previous_attempt_id[r]
    next_id <- pairs$next_attempt_id[r]
    y_prev <- attempts$year_from_date[match(prev_id, attempts$attempt_id)]
    A <- adjacency_before(y_prev)
    if (is.null(A)) next

    s_prev <- supporters_of(prev_id)
    if (length(s_prev) == 0L) next
    s_vec <- numeric(n_v); s_vec[s_prev] <- 1
    k_all <- as.numeric(A %*% s_vec)              # for each voter: neighbours who supported the first election              # co-voters of v who supported at t

    # eligible: voters with at least one co-voting tie before t, who did NOT vote
    # at t, and who are not the candidate
    # rowSums() counts all co-voters. (diff(A@p) would miss about 7% of voters,
    # because this matrix type stores only half of the symmetric matrix.)
    has_tie <- Matrix::rowSums(A) > 0
    excluded <- unique(c(voters_of(prev_id), match(pairs$candidate[r], all_voters)))
    elig <- which(has_tie)
    elig <- elig[!(elig %in% excluded)]
    if (length(elig) == 0L) next

    # Outcome (1 = supports the second election) and k, with k above K_MAX
    # put in one "12+" group.
    sup_next <- supporters_of(next_id)
    y_vec <- as.integer(elig %in% sup_next)
    k_vec <- pmin(k_all[elig], K_MAX + 1)

    # Add this pair's counts to the totals for each k.
    for (kk in 0:(K_MAX + 1)) {
      sel <- k_vec == kk
      if (!any(sel)) next
      idx <- min(kk, K_MAX) + 1
      k_hits[idx] <- k_hits[idx] + sum(y_vec[sel])
      k_n[idx]    <- k_n[idx] + sum(sel)
    }
    used_pairs <- used_pairs + 1L
  }
  list(hits = k_hits, n = k_n, used = used_pairs)
}

# Run the curve on each sample and compare it with the baseline.
curves <- list()
for (smp in c("all", "chronological", "strict")) {
  d <- switch(smp, all = pairs_all,
              chronological = pairs_all[pairs_all$in_chronological, ],
              strict = pairs_all[pairs_all$in_strict, ])
  tk <- tk_curve(d)
  k_hits <- tk$hits; k_n <- tk$n
  k_labels <- c(as.character(0:(K_MAX - 1)), paste0(K_MAX, "+"))
  observed <- k_hits / k_n
  # Baseline. Lecture 4 uses 1 - (1 - p)^k, which assumes T(0) is about 0.
  # Here voters with no connection still sometimes support the candidate
  # (T(0) > 0), so we keep that background rate p0 and let each connection add
  # an independent chance p:  T_baseline(k) = 1 - (1 - p0) * (1 - p)^k,
  # with p chosen so the baseline equals the observed T(1).
  p0    <- observed[1]                                # T(0)
  p_hat <- 1 - (1 - observed[2]) / (1 - p0)           # per-connection effect
  baseline <- 1 - (1 - p0) * (1 - p_hat) ^ (0:K_MAX)

  out <- data.frame(
    sample = smp,
    k = k_labels,
    eligible_voters = as.integer(k_n),
    recruited = as.integer(k_hits),
    observed_rate = observed,
    independent_baseline = baseline,
    ratio_observed_to_baseline = observed / baseline,
    stringsAsFactors = FALSE
  )

  cat(sprintf("\n--- sample: %s ---\npairs used: %d of %d\n", smp, tk$used, nrow(d)))
  cat(sprintf("background rate T(0): %.5f   per-connection p: %.5f\n\n", p0, p_hat))
  print(format(out, digits = 4), row.names = FALSE)
  curves[[smp]] <- out
}
out <- do.call(rbind, curves)

dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
write.csv(out, file.path("output", "results", "recruitment_curve.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwritten: output/results/recruitment_curve.csv\n")
