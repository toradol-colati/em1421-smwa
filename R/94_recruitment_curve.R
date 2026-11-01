# 94 - Membership closure in repeat RfAs: the T(k) curve.
#
#   Rscript R/94_recruitment_curve.R
#
# WHY THIS EXISTS
# Lecture 4, "Networks in their Surrounding Contexts", section "Tracking Link
# Formation: Membership Closure", asks: "What is the probability that a person
# becomes involved with a particular focus as a function of the number of
# friends who are already involved in it?" Its Wikipedia example plots the
# "probability a person edits a Wikipedia article as a function of the number
# of prior editors with whom they have communicated".
#
# TRANSPOSED HERE
#   The focus is a candidate's support coalition. For consecutive attempts t
#   and t+1 of the same candidate:
#     - S_t is the set of voters who SUPPORTED the candidate at attempt t;
#     - for a voter v who did NOT vote at t, k is the number of v's co-voters
#       (historical co-voting network) who belong to S_t;
#     - T(k) is the fraction of such voters who support the candidate at t+1.
#
# THE DESIGN POINT THAT MAKES IT MEANINGFUL
# The co-voting network is built only from attempts in years STRICTLY BEFORE
# the year of attempt t. It therefore shares no vote with S_t, and none with
# the outcome at t+1. Without that separation the relation would be partly
# mechanical: two voters would count as co-voters because both supported this
# candidate at t, which is the very thing being predicted.
#
# BASELINE
# The lecture compares T(k) with "an intentionally simplified baseline model"
# in which each connection gives "an independent probability p", so
# T_baseline(k) = 1 - (1 - p)^k. That form assumes T(0) is close to 0 ("T(0) is
# very close to 0" in the Kossinets-Watts data). Here T(0) is not 0, so the
# baseline below keeps the background rate T(0) and adds an independent p per
# connection (see the computation at the end of the script). Observed above the
# baseline means connections reinforce each other; below means the
# "diminishing returns" the lecture reports for focal closure.
#
# Output: output/results/recruitment_curve.csv

suppressPackageStartupMessages({library(igraph); library(Matrix)})
source(file.path("R", "00_paths.R"))

K_MAX <- 12   # k values reported separately; above this they are pooled

votes <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
pairs <- readRDS(file.path(DIR_PROCESSED, "attempt_pairs.rds"))
pairs <- pairs[!pairs$fragment_pair, ]   # fragments: see 05_measure_change.R

v2 <- votes[!is.na(votes$attempt_id) & votes$vot %in% c(-1L, 1L) & !votes$self_vote, ]
ai <- match(v2$attempt_id, attempts$attempt_id)
v2$year <- attempts$year_from_date[ai]
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

supporters_of <- function(attempt_id) {
  v2$voter_id[v2$attempt_id == attempt_id & v2$vot == 1L]
}
voters_of <- function(attempt_id) {
  v2$voter_id[v2$attempt_id == attempt_id]
}

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
  k_all <- as.numeric(A %*% s_vec)              # co-voters of v who supported at t

  # eligible: voters with at least one co-voting tie before t, who did NOT vote
  # at t, and who are not the candidate
  # rowSums, not diff(A@p): crossprod() returns a symmetric matrix that stores
  # only its upper triangle, so diff(A@p) would count only co-voters with an
  # alphabetically earlier username and drop about 7% of eligible voters.
  has_tie <- Matrix::rowSums(A) > 0
  excluded <- unique(c(voters_of(prev_id), match(pairs$candidate[r], all_voters)))
  elig <- which(has_tie)
  elig <- elig[!(elig %in% excluded)]
  if (length(elig) == 0L) next

  sup_next <- supporters_of(next_id)
  y_vec <- as.integer(elig %in% sup_next)
  k_vec <- pmin(k_all[elig], K_MAX + 1)

  for (kk in 0:(K_MAX + 1)) {
    sel <- k_vec == kk
    if (!any(sel)) next
    idx <- min(kk, K_MAX) + 1
    k_hits[idx] <- k_hits[idx] + sum(y_vec[sel])
    k_n[idx]    <- k_n[idx] + sum(sel)
  }
  used_pairs <- used_pairs + 1L
}

k_labels <- c(as.character(0:(K_MAX - 1)), paste0(K_MAX, "+"))
observed <- k_hits / k_n
# Baseline. Lecture 4 ("Networks in their Surrounding Contexts") compares T(k)
# with 1 - (1 - p)^k, where each of the k connections independently produces
# the event with probability p. That form assumes T(0) is close to 0, as in the
# Kossinets-Watts data. Here voters with no connection into the coalition still
# support the candidate (T(0) > 0), so the baseline keeps that background rate
# p0 and lets each connection add an independent chance p on top of it:
#   T_baseline(k) = 1 - (1 - p0) * (1 - p)^k,   with p fitted so that the
#   baseline equals the observed T(1).
p0    <- observed[1]                                # T(0)
p_hat <- 1 - (1 - observed[2]) / (1 - p0)           # per-connection effect
baseline <- 1 - (1 - p0) * (1 - p_hat) ^ (0:K_MAX)

out <- data.frame(
  k = k_labels,
  eligible_voters = as.integer(k_n),
  recruited = as.integer(k_hits),
  observed_rate = observed,
  independent_baseline = baseline,
  ratio_observed_to_baseline = observed / baseline,
  stringsAsFactors = FALSE
)

cat(sprintf("pairs used: %d of %d\n", used_pairs, nrow(pairs)))
cat(sprintf("background rate T(0): %.5f   per-connection p: %.5f\n\n", p0, p_hat))
print(format(out, digits = 4), row.names = FALSE)

dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
write.csv(out, file.path("output", "results", "recruitment_curve.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwritten: output/results/recruitment_curve.csv\n")
