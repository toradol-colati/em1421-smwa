# 06 - Descriptive comparisons and outcome models.
#
# Input : data/processed/attempt_pairs.rds
#         data/processed/attempts_analysis.rds
#         data/processed/network_objects.rds
# Output: output/results/group_comparison.csv
#         output/results/model_data.csv
#         output/results/model_formula.txt
#         output/results/model_coefficients.csv
#         output/results/model_performance.csv
#         output/results/model_performance_sensitivity.csv
#         output/results/sample_flow.csv
#         output/results/analysis_summary.txt
#         data/processed/model_objects.rds
# Packages: base R

set.seed(1421)
source(file.path("R", "00_paths.R"))
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)

required <- file.path(
  DIR_PROCESSED,
  c("attempt_pairs.rds", "attempts_analysis.rds", "network_objects.rds")
)
if (any(!file.exists(required))) {
  stop("Run R/01_prepare_data.R, R/04_build_networks.R and R/05_measure_change.R first.",
       call. = FALSE)
}

assert_condition <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
}

pairs <- readRDS(file.path(DIR_PROCESSED, "attempt_pairs.rds"))
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
network_objects <- readRDS(file.path(DIR_PROCESSED, "network_objects.rds"))

# Three populations of pairs are defined in 05_measure_change.R. Descriptive
# comparisons are reported for all three; the outcome model uses the strict
# sample (at least 5 votes in both attempts) with the others as sensitivity.
pairs_all <- pairs
samples <- list(
  "All valid outcomes" = pairs_all,
  "Chronological" = pairs_all[pairs_all$in_chronological, ],
  "Strict" = pairs_all[pairs_all$in_strict, ]
)

cliff_delta <- function(failure_values, success_values) {
  failure_values <- failure_values[is.finite(failure_values)]
  success_values <- success_values[is.finite(success_values)]
  if (length(failure_values) == 0L || length(success_values) == 0L) {
    return(NA_real_)
  }
  mean(sign(outer(success_values, failure_values, "-")))
}

compare_groups <- function(data, group, comparison_label) {
  metrics <- c(
    "supporter_jaccard",
    "jaccard_excess",
    "new_support_share",
    "returning_support_share",
    "previous_support_effective_communities",
    "current_support_effective_communities",
    "community_breadth_change",
    "community_mix_js",
    "previous_supporter_mean_weighted_degree",
    "previous_supporter_mean_pagerank",
    "previous_supporter_mean_eigenvector",
    "previous_supporter_mean_local_clustering",
    "previous_community_bridge_exposure"
  )

  rows <- lapply(metrics, function(metric) {
    failure_values <- data[[metric]][group == "failure"]
    success_values <- data[[metric]][group == "success"]
    test <- tryCatch(
      wilcox.test(failure_values, success_values, exact = FALSE),
      error = function(e) NULL
    )
    data.frame(
      comparison = comparison_label,
      metric = metric,
      failure_n = sum(!is.na(failure_values)),
      failure_mean = mean(failure_values, na.rm = TRUE),
      failure_median = median(failure_values, na.rm = TRUE),
      success_n = sum(!is.na(success_values)),
      success_mean = mean(success_values, na.rm = TRUE),
      success_median = median(success_values, na.rm = TRUE),
      difference_success_minus_failure =
        mean(success_values, na.rm = TRUE) -
        mean(failure_values, na.rm = TRUE),
      cliffs_delta_success_vs_failure =
        cliff_delta(failure_values, success_values),
      wilcoxon_p = if (is.null(test)) NA_real_ else test$p.value,
      stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, rows)
  result$wilcoxon_p_adjusted <- p.adjust(result$wilcoxon_p, method = "BH")
  result
}

group_comparison <- do.call(rbind, lapply(names(samples), function(label) {
  d <- samples[[label]]
  out <- rbind(
    compare_groups(
      d,
      ifelse(d$previous_outcome == 1L, "success", "failure"),
      "Previous attempt outcome"
    ),
    compare_groups(
      d,
      ifelse(d$next_outcome == 1L, "success", "failure"),
      "Next attempt outcome"
    )
  )
  cbind(sample = label, sample_pairs = nrow(d), out)
}))
write.csv(
  group_comparison,
  file.path("output", "results", "group_comparison.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)

model_columns <- c(
  "next_success",
  "previous_outcome",
  "previous_support_share",
  "previous_supporters",
  "previous_support_effective_communities",
  "previous_supporter_mean_weighted_degree",
  "days_between",
  "next_attempt_year"
)
model_data_all <- pairs_all[complete.cases(pairs_all[, model_columns]), ]
model_data_all$previous_success <-
  as.integer(model_data_all$previous_outcome == 1L)
model_data_all$previous_support_share_10 <-
  model_data_all$previous_support_share * 10
model_data_all$log2_previous_supporters <-
  log2(1 + model_data_all$previous_supporters)
model_data_all$log2_previous_supporter_weighted_degree <-
  log2(1 + model_data_all$previous_supporter_mean_weighted_degree)
model_data_all$log2_days_between <-
  log2(1 + pmax(model_data_all$days_between, 0))
model_data_all$year_centered <- model_data_all$next_attempt_year -
  min(model_data_all$next_attempt_year)
model_data <- model_data_all[model_data_all$in_strict, ]

base_model_formula <- next_success ~
  previous_success +
  previous_support_share_10 +
  log2_previous_supporters +
  log2_days_between +
  year_centered

network_model_formula <- update(
  base_model_formula,
  . ~ . +
    previous_support_effective_communities +
    log2_previous_supporter_weighted_degree
)

fit_base <- glm(
  base_model_formula,
  data = model_data,
  family = binomial(),
  control = glm.control(maxit = 100)
)
fit_network <- glm(
  network_model_formula,
  data = model_data,
  family = binomial(),
  control = glm.control(maxit = 100)
)

tidy_glm <- function(fit, model_label) {
  fit_coefficients <- coef(summary(fit))
  confidence_intervals <- confint.default(fit)
  data.frame(
    model = model_label,
    term = rownames(fit_coefficients),
    estimate = fit_coefficients[, "Estimate"],
    standard_error = fit_coefficients[, "Std. Error"],
    p_value = fit_coefficients[, "Pr(>|z|)"],
    odds_ratio = exp(fit_coefficients[, "Estimate"]),
    confidence_low = exp(confidence_intervals[, 1]),
    confidence_high = exp(confidence_intervals[, 2]),
    stringsAsFactors = FALSE
  )
}

coefficient_table <- rbind(
  tidy_glm(fit_base, "Vote shares and timing"),
  tidy_glm(fit_network, "Network-augmented")
)
coefficient_labels <- c(
  "(Intercept)" = "Intercept",
  previous_success = "Prior success vs prior rejection",
  previous_support_share_10 = "Prior support share (per 10 pp)",
  log2_previous_supporters = "Prior supporters (per doubling)",
  previous_support_effective_communities =
    "Prior effective supporter communities",
  log2_previous_supporter_weighted_degree =
    "Supporter weighted degree (per doubling)",
  log2_days_between = "Days between attempts (per doubling)",
  year_centered = "Calendar year"
)
coefficient_table$term_label <- unname(coefficient_labels[
  coefficient_table$term
])
write.csv(
  coefficient_table,
  file.path("output", "results", "model_coefficients.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)

auc_value <- function(actual, probability) {
  actual <- as.integer(actual)
  positive <- sum(actual == 1L)
  negative <- sum(actual == 0L)
  if (positive == 0L || negative == 0L) {
    return(NA_real_)
  }
  ranks <- rank(probability, ties.method = "average")
  (sum(ranks[actual == 1L]) - positive * (positive + 1) / 2) /
    (positive * negative)
}

candidate_outcomes <- aggregate(
  previous_success ~ candidate,
  data = model_data_all,
  FUN = max
)
candidate_outcomes$fold <- NA_integer_
set.seed(1421)
for (stratum in c(0L, 1L)) {
  candidate_ids <- candidate_outcomes$candidate[
    candidate_outcomes$previous_success == stratum
  ]
  candidate_ids <- sample(candidate_ids)
  candidate_outcomes$fold[
    candidate_outcomes$candidate %in% candidate_ids
  ] <- rep(seq_len(5), length.out = length(candidate_ids))
}
fold_lookup <- setNames(candidate_outcomes$fold, candidate_outcomes$candidate)
model_data_all$fold <- unname(fold_lookup[model_data_all$candidate])
model_data$fold <- unname(fold_lookup[model_data$candidate])

evaluate_model <- function(data, formula) {
  fold_predictions <- rep(NA_real_, nrow(data))
  baseline_predictions <- rep(NA_real_, nrow(data))
  for (fold in seq_len(5)) {
    train <- data[data$fold != fold, ]
    test <- data[data$fold == fold, ]
    if (nrow(test) == 0L) {
      next
    }
    fold_fit <- glm(
      formula,
      data = train,
      family = binomial(),
      control = glm.control(maxit = 100)
    )
    fold_predictions[data$fold == fold] <-
      predict(fold_fit, newdata = test, type = "response")
    baseline_predictions[data$fold == fold] <- mean(train$next_success)
  }
  list(prediction = fold_predictions, baseline = baseline_predictions)
}

base_evaluation <- evaluate_model(model_data, base_model_formula)
network_evaluation <- evaluate_model(model_data, network_model_formula)

base_terms <- all.vars(base_model_formula)
assert_condition(
  !any(grepl("^current_", base_terms)),
  "Leakage detected: the outcome model contains a current-attempt variable."
)
assert_condition(
  !anyNA(model_data$fold),
  "Cross-validation folds are missing for at least one modelling row."
)
assert_condition(
  all(tapply(
    model_data$fold,
    model_data$candidate,
    function(x) length(unique(x)) == 1L
  )),
  "At least one candidate appears in more than one cross-validation fold."
)

model_export_columns <- c(
  "candidate", "fold", "next_success", "previous_outcome",
  "previous_success", "previous_support_share_10",
  "log2_previous_supporters", "previous_support_effective_communities",
  "log2_previous_supporter_weighted_degree", "log2_days_between",
  "year_centered"
)
write.csv(
  model_data[, model_export_columns],
  file.path("output", "results", "model_data.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
writeLines(
  c(
    paste("Base model:", paste(deparse(base_model_formula), collapse = " ")),
    paste("Network model:",
          paste(deparse(network_model_formula), collapse = " "))
  ),
  file.path("output", "results", "model_formula.txt")
)

performance <- data.frame(
  model = c("Prevalence only", "Vote shares and timing", "Network-augmented"),
  auc = c(
    0.5,
    auc_value(model_data$next_success, base_evaluation$prediction),
    auc_value(model_data$next_success, network_evaluation$prediction)
  ),
  brier_score = c(
    mean((base_evaluation$baseline - model_data$next_success)^2),
    mean((base_evaluation$prediction - model_data$next_success)^2),
    mean((network_evaluation$prediction - model_data$next_success)^2)
  ),
  observations = nrow(model_data),
  candidates = length(unique(model_data$candidate)),
  stringsAsFactors = FALSE
)
write.csv(
  performance,
  file.path("output", "results", "model_performance.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)

sensitivity_sets <- list(
  "Strict" = model_data,
  "Chronological" = model_data_all[model_data_all$in_chronological, ],
  "All valid outcomes" = model_data_all
)
performance_sensitivity <- do.call(rbind, lapply(names(sensitivity_sets), function(label) {
  d <- sensitivity_sets[[label]]
  eb <- evaluate_model(d, base_model_formula)
  en <- evaluate_model(d, network_model_formula)
  data.frame(
    sample = label,
    model = c("Vote shares and timing", "Network-augmented"),
    observations = nrow(d),
    auc = c(auc_value(d$next_success, eb$prediction),
            auc_value(d$next_success, en$prediction)),
    brier_score = c(mean((eb$prediction - d$next_success)^2),
                    mean((en$prediction - d$next_success)^2)),
    stringsAsFactors = FALSE
  )
}))
write.csv(
  performance_sensitivity,
  file.path("output", "results", "model_performance_sensitivity.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)

all_pair_count <- sum(pmax(table(attempts$candidate) - 1L, 0L))
sample_flow <- data.frame(
  stage = c(
    "Reconstructed attempts", "Repeat candidates",
    "All consecutive attempt pairs", "Pairs with valid outcomes",
    "Negative-interval pairs", "Short-attempt pairs (not negative-interval)",
    "Chronological sample", "Strict sample", "Pairs used in outcome models"
  ),
  count = c(
    nrow(attempts), sum(table(attempts$candidate) >= 2L),
    all_pair_count, nrow(pairs_all), sum(pairs_all$negative_interval),
    sum(pairs_all$short_attempt_pair & !pairs_all$negative_interval),
    sum(pairs_all$in_chronological), sum(pairs_all$in_strict), nrow(model_data)
  ),
  stringsAsFactors = FALSE
)
write.csv(
  sample_flow,
  file.path("output", "results", "sample_flow.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)

summary_lines <- c(
  paste("All consecutive attempt pairs:", all_pair_count),
  paste("Pairs with valid outcomes:", nrow(pairs_all)),
  paste("Chronological sample:", sum(pairs_all$in_chronological),
        "| strict sample:", sum(pairs_all$in_strict)),
  paste("Pairs after prior success (all / chronological / strict):",
        sum(pairs_all$previous_outcome == 1L), "/",
        sum(pairs_all$previous_outcome == 1L & pairs_all$in_chronological), "/",
        sum(pairs_all$previous_outcome == 1L & pairs_all$in_strict)),
  paste(
    "Attempts matched to wikiElec by voter set:",
    sum(attempts$elec_matched, na.rm = TRUE)
  ),
  paste(
    "Validated outcome agreements:",
    sum(attempts$elec_matched & attempts$outcome_agrees, na.rm = TRUE),
    "of",
    sum(attempts$elec_matched, na.rm = TRUE)
  ),
  paste("Network snapshots:", length(network_objects$snapshots)),
  paste("Model observations:", nrow(model_data)),
  paste("Model candidates:", length(unique(model_data$candidate))),
  sprintf("Vote/timing model AUC: %.3f",
          performance$auc[performance$model == "Vote shares and timing"]),
  sprintf("Network-augmented model AUC: %.3f",
          performance$auc[performance$model == "Network-augmented"]),
  sprintf("Vote/timing model Brier score: %.3f",
          performance$brier_score[performance$model == "Vote shares and timing"]),
  sprintf("Network-augmented model Brier score: %.3f",
          performance$brier_score[performance$model == "Network-augmented"]),
  sprintf("Prevalence-only Brier score: %.3f",
          performance$brier_score[performance$model == "Prevalence only"]),
  "Network snapshots use same-direction co-voting before the target year.",
  "Louvain is the main method; Girvan-Newman is compared on the three smallest snapshots in 97_community_method_check.R.",
  "Network measures showed no material improvement in held-out prediction; AUC and Brier differences were negligible and mixed.",
  "Model predictors use only information available before the next attempt.",
  "All estimates describe association, not a causal effect."
)
writeLines(
  summary_lines,
  file.path("output", "results", "analysis_summary.txt")
)

saveRDS(
  list(
    network_objects = network_objects,
    model_base = fit_base,
    model_network = fit_network,
    folds = fold_lookup,
    performance = performance,
    performance_sensitivity = performance_sensitivity,
    group_comparison = group_comparison,
    coefficient_table = coefficient_table
  ),
  file.path(DIR_PROCESSED, "model_objects.rds")
)

cat("Model observations:", nrow(model_data), "\n")
