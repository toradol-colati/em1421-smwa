# 94 - How coalitions grow: the T(k) curve of lecture 4, applied to RfA.
#
#   Rscript R/94_recruitment_curve.R
#
# WHY THIS EXISTS
# The research question asks how support coalitions change between one attempt
# and the next. The course supplies a procedure for exactly that shape of
# question: Kossinets and Watts take two snapshots, count how many contacts a
# pair already shares in the first, and measure the fraction that form a link
# by the second, then plot that fraction T(k) against a deliberately simple
# baseline in which each shared contact acts independently,
# T_baseline(k) = 1 - (1 - p)^k. The real curve bending above or below that
# line is the result.
#
# TRANSPOSED HERE
#   For a candidate with consecutive attempts t and t+1:
#     - S_t is the set of voters who SUPPORTED the candidate at attempt t;
#     - for a voter v who did NOT vote at t, k is how many of v's co-voters
#       belong to S_t;
#     - T(k) is the fraction of such voters who support the candidate at t+1.
#   This is the course's focal closure: the attempt is a focus in Feld's sense,
#   and the question is whether the coalition recruits through the existing
#   coalition's own neighbourhood.
#
# THE DESIGN POINT THAT MAKES IT MEANINGFUL
# The co-voting network is built only from attempts in years STRICTLY BEFORE
# the year of attempt t. It therefore shares no vote with S_t, and none with
# the outcome at t+1. Without that separation the relation would be partly
# mechanical: two voters would count as co-voters because both supported this
# candidate at t, which is the very thing being predicted.
#
# BASELINE
# p is estimated from the single-contact rate, p_hat = T(1), and the curve
# 1 - (1 - p_hat)^k is reported next to the observed one. Above the line means
# contacts reinforce each other; below means diminishing returns, which is what
# the course found for focal closure as opposed to triadic closure.
#
# Output: output/results/recruitment_curve.csv

suppressPackageStartupMessages({library(igraph); library(Matrix)})
source(file.path("R", "00_paths.R"))

K_MAX <- 12   # k values reported separately; above this they are pooled

votes <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
pairs <- readRDS(file.path(DIR_PROCESSED, "attempt_pairs.rds"))

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
  has_tie <- diff(A@p) > 0
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
p_hat <- observed[2]                              # T(1)
baseline <- 1 - (1 - p_hat) ^ (0:K_MAX)

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
cat(sprintf("p estimated from T(1): %.5f\n\n", p_hat))
print(format(out, digits = 4), row.names = FALSE)

dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
write.csv(out, file.path("output", "results", "recruitment_curve.csv"), row.names = FALSE)
cat("\nwritten: output/results/recruitment_curve.csv\n")
