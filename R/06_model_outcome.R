# 06 - Compare groups of pairs and predict the outcome of the next election.
#
# Part 1 - comparisons. Pairs are split by the result of the earlier election
#   (and, separately, by the result of the later one), and every measure from
#   05 is compared between the two groups: Wilcoxon test, with p-values
#   adjusted for many tests (Benjamini-Hochberg), and Cliff's delta as effect
#   size. Done for all three samples.
# Part 2 - logistic regression for "is the next election a success?" on the
#   strict sample, with two models:
#     base model   : earlier result, earlier vote share, number of earlier
#                    supporters, days between the elections, year;
#     network model: the same plus community spread and weighted degree of
#                    the earlier supporters.
#   Both are tested with 5-fold cross-validation (AUC and Brier score) to see
#   whether the network measures help prediction.
#
# Input : data/processed/attempt_pairs.rds, attempts_analysis.rds, network_objects.rds
# Output: output/results/group_comparison.csv, model_data.csv, model_formula.txt,
#         model_coefficients.csv, model_performance.csv,
#         model_performance_sensitivity.csv, sample_flow.csv, analysis_summary.txt
#         data/processed/model_objects.rds

source(file.path("R", "00_paths.R"))
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)
if (!all(file.exists(file.path(DIR_PROCESSED,
                               c("attempt_pairs.rds", "attempts_analysis.rds", "network_objects.rds")))))
  stop("Run R/run_data_prep.R, R/04_build_networks.R and R/05_measure_change.R first.",
       call. = FALSE)
save_csv <- function(x, name) write.csv(x, file.path("output", "results", name),
                                        row.names = FALSE, fileEncoding = "UTF-8")

pairs           <- readRDS(file.path(DIR_PROCESSED, "attempt_pairs.rds"))
attempts        <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
network_objects <- readRDS(file.path(DIR_PROCESSED, "network_objects.rds"))

# The three samples are defined in 05. Comparisons are reported for all
# three; the model uses the strict sample, the other two are a robustness check.
samples <- list("All valid outcomes" = pairs,
                "Chronological" = pairs[pairs$in_chronological, ],
                "Strict" = pairs[pairs$in_strict, ])

# --- Part 1: group comparisons ------------------------------------------------
# Cliff's delta: take one success and one failure at random; delta =
# P(success value is larger) - P(failure value is larger). Between -1 and 1;
# 0 = no difference. It does not assume a normal distribution.
cliff_delta <- function(fail, succ) {
  fail <- fail[is.finite(fail)]; succ <- succ[is.finite(succ)]
  if (length(fail) == 0L || length(succ) == 0L) return(NA_real_)
  mean(sign(outer(succ, fail, "-")))
}

metrics <- c("supporter_jaccard", "jaccard_excess", "new_support_share",
             "returning_support_share", "previous_support_effective_communities",
             "current_support_effective_communities", "community_breadth_change",
             "community_mix_js", "previous_supporter_mean_weighted_degree",
             "previous_supporter_mean_pagerank", "previous_supporter_mean_eigenvector",
             "previous_supporter_mean_local_clustering", "previous_community_bridge_exposure")

# For every measure: n, mean, median, difference, Cliff's delta and Wilcoxon
# p-value. 13 measures are tested at once, so the p-values are adjusted (BH).
compare_groups <- function(data, success, label) {
  out <- do.call(rbind, lapply(metrics, function(m) {
    f <- data[[m]][!success]; s <- data[[m]][success]
    test <- tryCatch(wilcox.test(f, s, exact = FALSE), error = function(e) NULL)
    data.frame(comparison = label, metric = m,
               failure_n = sum(!is.na(f)), failure_mean = mean(f, na.rm = TRUE),
               failure_median = median(f, na.rm = TRUE),
               success_n = sum(!is.na(s)), success_mean = mean(s, na.rm = TRUE),
               success_median = median(s, na.rm = TRUE),
               difference_success_minus_failure = mean(s, na.rm = TRUE) - mean(f, na.rm = TRUE),
               cliffs_delta_success_vs_failure = cliff_delta(f, s),
               wilcoxon_p = if (is.null(test)) NA_real_ else test$p.value)
  }))
  out$wilcoxon_p_adjusted <- p.adjust(out$wilcoxon_p, method = "BH")
  out
}

# Each sample, grouped by the earlier result and then by the later result.
group_comparison <- do.call(rbind, lapply(names(samples), function(label) {
  d <- samples[[label]]
  cbind(sample = label, sample_pairs = nrow(d),
        rbind(compare_groups(d, d$previous_outcome == 1L, "Previous attempt outcome"),
              compare_groups(d, d$next_outcome == 1L, "Next attempt outcome")))
}))
save_csv(group_comparison, "group_comparison.csv")

# --- Part 2: outcome model ----------------------------------------------------
# Model data: drop pairs with a missing value, then rescale some predictors
# so the odds ratios are easy to read:
#   vote share x 10    -> effect per 10 percentage points;
#   log2(1 + x)        -> effect per doubling (supporters, degree, days);
#   year - first year  -> year starts at 0.
model_columns <- c("next_success", "previous_outcome", "previous_support_share",
                   "previous_supporters", "previous_support_effective_communities",
                   "previous_supporter_mean_weighted_degree", "days_between",
                   "next_attempt_year")
md <- pairs[complete.cases(pairs[, model_columns]), ]
md$previous_success <- as.integer(md$previous_outcome == 1L)
md$previous_support_share_10 <- md$previous_support_share * 10
md$log2_previous_supporters <- log2(1 + md$previous_supporters)
md$log2_previous_supporter_weighted_degree <- log2(1 + md$previous_supporter_mean_weighted_degree)
md$log2_days_between <- log2(1 + pmax(md$days_between, 0))
md$year_centered <- md$next_attempt_year - min(md$next_attempt_year)

# Base model: only information known before the next election.
# Network model: the same plus two network measures of the earlier supporters.
base_model_formula <- next_success ~ previous_success + previous_support_share_10 +
  log2_previous_supporters + log2_days_between + year_centered
network_model_formula <- update(base_model_formula, . ~ . +
  previous_support_effective_communities + log2_previous_supporter_weighted_degree)
fit <- function(formula, data) glm(formula, data = data, family = binomial(),
                                   control = glm.control(maxit = 100))

# Cross-validation folds. All pairs of one candidate go to the SAME fold, so
# the model is never tested on a candidate it was trained on. Candidates with
# and without a prior success are split evenly over the 5 folds.
cand <- aggregate(previous_success ~ candidate, data = md, FUN = max)
cand$fold <- NA_integer_
set.seed(1421)
for (stratum in c(0L, 1L)) {
  ids <- sample(cand$candidate[cand$previous_success == stratum])
  cand$fold[cand$candidate %in% ids] <- rep(seq_len(5), length.out = length(ids))
}
fold_lookup <- setNames(cand$fold, cand$candidate)
md$fold <- unname(fold_lookup[md$candidate])
model_data <- md[md$in_strict, ]           # the model uses the strict sample

fit_base    <- fit(base_model_formula, model_data)
fit_network <- fit(network_model_formula, model_data)

# Coefficient table: estimate, p-value, odds ratio and 95% interval.
tidy_glm <- function(model, label) {
  co <- coef(summary(model)); ci <- confint.default(model)
  data.frame(model = label, term = rownames(co), estimate = co[, "Estimate"],
             standard_error = co[, "Std. Error"], p_value = co[, "Pr(>|z|)"],
             odds_ratio = exp(co[, "Estimate"]),
             confidence_low = exp(ci[, 1]), confidence_high = exp(ci[, 2]))
}
coefficient_table <- rbind(tidy_glm(fit_base, "Vote shares and timing"),
                           tidy_glm(fit_network, "Network-augmented"))
coefficient_labels <- c(                    # readable names for Figure 4
  "(Intercept)" = "Intercept",
  previous_success = "Prior success vs prior rejection",
  previous_support_share_10 = "Prior support share (per 10 pp)",
  log2_previous_supporters = "Prior supporters (per doubling)",
  previous_support_effective_communities = "Prior effective supporter communities",
  log2_previous_supporter_weighted_degree = "Supporter weighted degree (per doubling)",
  log2_days_between = "Days between attempts (per doubling)",
  year_centered = "Calendar year")
coefficient_table$term_label <- unname(coefficient_labels[coefficient_table$term])
save_csv(coefficient_table, "model_coefficients.csv")

# AUC: the chance that a random success gets a higher predicted probability
# than a random failure (0.5 = guessing, 1 = perfect). Computed from ranks.
auc_value <- function(y, p) {
  pos <- sum(y == 1L); neg <- sum(y == 0L)
  if (pos == 0L || neg == 0L) return(NA_real_)
  (sum(rank(p)[y == 1L]) - pos * (pos + 1) / 2) / (pos * neg)
}
brier <- function(y, p) mean((p - y)^2)  # mean squared error of the probability

# 5-fold cross-validation: fit on 4 folds, predict the 5th, repeat. The
# "baseline" prediction is the success rate of the training folds.
cross_validate <- function(data, formula) {
  pred <- base <- rep(NA_real_, nrow(data))
  for (k in seq_len(5)) {
    test <- data$fold == k
    if (!any(test)) next
    pred[test] <- predict(fit(formula, data[!test, ]), newdata = data[test, ], type = "response")
    base[test] <- mean(data$next_success[!test])
  }
  list(prediction = pred, baseline = base)
}
cv_base    <- cross_validate(model_data, base_model_formula)
cv_network <- cross_validate(model_data, network_model_formula)

# Checks: no information from the later election is used as a predictor,
# every row has a fold, and no candidate is split across folds.
stopifnot(
  "A predictor comes from the later election." = !any(grepl("^current_", all.vars(base_model_formula))),
  "A row has no fold." = !anyNA(model_data$fold),
  "A candidate is in two folds." =
    all(tapply(model_data$fold, model_data$candidate, function(x) length(unique(x)) == 1L)))

save_csv(model_data[, c("candidate", "fold", "next_success", "previous_outcome",
                        "previous_success", "previous_support_share_10",
                        "log2_previous_supporters", "previous_support_effective_communities",
                        "log2_previous_supporter_weighted_degree", "log2_days_between",
                        "year_centered")], "model_data.csv")
writeLines(c(paste("Base model:", paste(deparse(base_model_formula), collapse = " ")),
             paste("Network model:", paste(deparse(network_model_formula), collapse = " "))),
           file.path("output", "results", "model_formula.txt"))

# Prediction quality on the strict sample.
y <- model_data$next_success
performance <- data.frame(
  model = c("Prevalence only", "Vote shares and timing", "Network-augmented"),
  auc = c(0.5, auc_value(y, cv_base$prediction), auc_value(y, cv_network$prediction)),
  brier_score = c(brier(y, cv_base$baseline), brier(y, cv_base$prediction),
                  brier(y, cv_network$prediction)),
  observations = nrow(model_data),
  candidates = length(unique(model_data$candidate)))
save_csv(performance, "model_performance.csv")

# Same cross-validation on the other two samples (robustness check).
sensitivity_sets <- list("Strict" = model_data, "Chronological" = md[md$in_chronological, ],
                         "All valid outcomes" = md)
performance_sensitivity <- do.call(rbind, lapply(names(sensitivity_sets), function(label) {
  d <- sensitivity_sets[[label]]
  pb <- cross_validate(d, base_model_formula)$prediction
  pn <- cross_validate(d, network_model_formula)$prediction
  data.frame(sample = label, model = c("Vote shares and timing", "Network-augmented"),
             observations = nrow(d),
             auc = c(auc_value(d$next_success, pb), auc_value(d$next_success, pn)),
             brier_score = c(brier(d$next_success, pb), brier(d$next_success, pn)))
}))
save_csv(performance_sensitivity, "model_performance_sensitivity.csv")

# Sample flow: how many elections and pairs remain at each step.
per_candidate <- table(attempts$candidate)
all_pair_count <- sum(pmax(per_candidate - 1L, 0L))
save_csv(data.frame(
  stage = c("Reconstructed attempts", "Repeat candidates", "All consecutive attempt pairs",
            "Pairs with valid outcomes", "Negative-interval pairs",
            "Short-attempt pairs (not negative-interval)", "Chronological sample",
            "Strict sample", "Pairs used in outcome models"),
  count = c(nrow(attempts), sum(per_candidate >= 2L), all_pair_count, nrow(pairs),
            sum(pairs$negative_interval), sum(pairs$short_attempt_pair & !pairs$negative_interval),
            sum(pairs$in_chronological), sum(pairs$in_strict), nrow(model_data))),
  "sample_flow.csv")

# Short text summary of the main counts and scores.
perf <- function(model, col) performance[[col]][performance$model == model]
after_success <- pairs$previous_outcome == 1L
writeLines(c(
  paste("All consecutive attempt pairs:", all_pair_count),
  paste("Pairs with valid outcomes:", nrow(pairs)),
  paste("Chronological sample:", sum(pairs$in_chronological),
        "| strict sample:", sum(pairs$in_strict)),
  paste("Pairs after prior success (all / chronological / strict):",
        sum(after_success), "/", sum(after_success & pairs$in_chronological), "/",
        sum(after_success & pairs$in_strict)),
  paste("Attempts matched to wikiElec by voter set:", sum(attempts$elec_matched, na.rm = TRUE)),
  paste("Validated outcome agreements:",
        sum(attempts$elec_matched & attempts$outcome_agrees, na.rm = TRUE), "of",
        sum(attempts$elec_matched, na.rm = TRUE)),
  paste("Network snapshots:", length(network_objects$snapshots)),
  paste("Model observations:", nrow(model_data)),
  paste("Model candidates:", length(unique(model_data$candidate))),
  sprintf("Vote/timing model AUC: %.3f", perf("Vote shares and timing", "auc")),
  sprintf("Network-augmented model AUC: %.3f", perf("Network-augmented", "auc")),
  sprintf("Vote/timing model Brier score: %.3f", perf("Vote shares and timing", "brier_score")),
  sprintf("Network-augmented model Brier score: %.3f", perf("Network-augmented", "brier_score")),
  sprintf("Prevalence-only Brier score: %.3f", perf("Prevalence only", "brier_score"))),
  file.path("output", "results", "analysis_summary.txt"))
# Reading notes: the networks use only votes before the target year; Louvain is
# the main method and 97 compares it with Girvan-Newman; the model predictors
# use only information known before the next election; the estimates show
# association, not cause.

# Save the fitted models and tables for 07.
saveRDS(list(network_objects = network_objects, model_base = fit_base,
             model_network = fit_network, folds = fold_lookup,
             performance = performance, performance_sensitivity = performance_sensitivity,
             group_comparison = group_comparison, coefficient_table = coefficient_table),
        file.path(DIR_PROCESSED, "model_objects.rds"))
cat("Model observations:", nrow(model_data), "\n")
