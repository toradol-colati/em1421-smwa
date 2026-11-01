# 07 - Report figures.
#
# Input : data/processed/attempt_pairs.rds
#         data/processed/network_objects.rds
#         data/processed/model_objects.rds
# Output: output/figures/fig1_covoting_network.png
#         output/figures/fig2_supporter_overlap.png
#         output/figures/fig3_community_diversity.png
#         output/figures/fig4_model_coefficients.png
# Packages: igraph, ggplot2

local_lib <- file.path(getwd(), ".Rlib")
if (dir.exists(local_lib)) {
  .libPaths(c(local_lib, .libPaths()))
}

suppressPackageStartupMessages({
  library(igraph)
  library(ggplot2)
})

source(file.path("R", "00_paths.R"))
dir.create(DIR_FIGURES, showWarnings = FALSE, recursive = TRUE)

required <- file.path(
  DIR_PROCESSED,
  c("attempt_pairs.rds", "network_objects.rds", "model_objects.rds")
)
if (any(!file.exists(required))) {
  stop(
    "Run R/04_build_networks.R, R/05_measure_change.R and R/06_model_outcome.R first.",
    call. = FALSE
  )
}

pairs <- readRDS(file.path(DIR_PROCESSED, "attempt_pairs.rds"))
pairs <- pairs[!pairs$fragment_pair, ]   # fragments: see 05_measure_change.R
network_objects <- readRDS(file.path(DIR_PROCESSED, "network_objects.rds"))
model_objects <- readRDS(file.path(DIR_PROCESSED, "model_objects.rds"))

network_summary <- do.call(
  rbind,
  lapply(network_objects$snapshots, `[[`, "summary")
)

latest_snapshot <- network_objects$snapshots[[
  length(network_objects$snapshots)
]]
graph_membership <- latest_snapshot$membership
community_sizes <- table(
  graph_membership[!is.na(graph_membership)]
)
community_ids <- as.integer(names(community_sizes))
angles <- seq(0, 2 * pi, length.out = length(community_ids) + 1)[
  seq_along(community_ids)
]
coordinates <- data.frame(
  community = community_ids,
  x = cos(angles),
  y = sin(angles),
  size = as.integer(community_sizes)
)

cross_summary <- latest_snapshot$community_edges
cross_summary <- merge(
  cross_summary,
  coordinates[, c("community", "x", "y")],
  by.x = "lower",
  by.y = "community"
)
names(cross_summary)[names(cross_summary) == "x"] <- "x_from"
names(cross_summary)[names(cross_summary) == "y"] <- "y_from"
cross_summary <- merge(
  cross_summary,
  coordinates[, c("community", "x", "y")],
  by.x = "upper",
  by.y = "community"
)
names(cross_summary)[names(cross_summary) == "x"] <- "x_to"
names(cross_summary)[names(cross_summary) == "y"] <- "y_to"
png(
  file.path(DIR_FIGURES, "fig1_covoting_network.png"),
  width = 1800,
  height = 850,
  res = 180
)
layout(matrix(c(1, 2), nrow = 1), widths = c(1.15, 1))
par(mar = c(2, 2, 4, 1))
plot(
  NA,
  xlim = c(-1.35, 1.35),
  ylim = c(-1.35, 1.35),
  asp = 1,
  axes = FALSE,
  xlab = "",
  ylab = "",
  main = "Voter-community network"
)
edge_width <- 0.5 + 3.5 * log1p(cross_summary$weight) /
  max(log1p(cross_summary$weight))
segments(
  cross_summary$x_from,
  cross_summary$y_from,
  cross_summary$x_to,
  cross_summary$y_to,
  col = adjustcolor("#4C78A8", alpha.f = 0.28),
  lwd = edge_width
)
points(
  coordinates$x,
  coordinates$y,
  pch = 21,
  cex = 2.2 + 3.3 * sqrt(coordinates$size / max(coordinates$size)),
  bg = "#F58518",
  col = "white",
  lwd = 1.5
)
text(
  coordinates$x,
  coordinates$y,
  labels = paste0("C", coordinates$community, "\n", coordinates$size),
  cex = 0.78,
  font = 2
)
mtext("Latest cumulative snapshot", side = 1, line = 0.5, cex = 0.8)

par(mar = c(4.5, 4.5, 4, 1))
plot(
  network_summary$cutoff_year,
  network_summary$modularity,
  type = "b",
  pch = 19,
  col = "#E45756",
  ylim = c(
    0,
    max(
      c(network_summary$modularity, network_summary$cross_community_share),
      na.rm = TRUE
    ) * 1.08
  ),
  xlab = "Start of target year",
  ylab = "Network measure",
  main = "Community structure over time"
)
lines(
  network_summary$cutoff_year,
  network_summary$cross_community_share,
  type = "b",
  pch = 17,
  col = "#4C78A8"
)
legend(
  "bottomright",
  legend = c("Modularity", "Cross-community edge share"),
  col = c("#E45756", "#4C78A8"),
  pch = c(19, 17),
  lty = 1,
  bty = "n",
  cex = 0.85
)
mtext(
  "Historical same-direction voter co-voting network",
  outer = TRUE,
  side = 3,
  line = -1.5,
  cex = 1.1,
  font = 2
)
dev.off()

plot_pairs <- pairs[
  !is.na(pairs$supporter_jaccard) & !is.na(pairs$jaccard_excess),
]
prior_counts <- table(plot_pairs$previous_group)
p2 <- ggplot(
  plot_pairs,
  aes(x = previous_group, y = jaccard_excess, fill = next_group)
) +
  geom_hline(yintercept = 0, linetype = 2, color = "gray45") +
  geom_boxplot(
    position = position_dodge(width = 0.72),
    width = 0.62,
    outlier.shape = NA,
    alpha = 0.55,
    linewidth = 0.35
  ) +
  geom_point(
    position = position_jitterdodge(jitter.width = 0.16, dodge.width = 0.72),
    size = 0.9,
    alpha = 0.45,
    stroke = 0
  ) +
  scale_x_discrete(
    labels = c(
      paste0("Previously rejected\n(n = ", prior_counts[1], ")"),
      paste0("Previously successful\n(n = ", prior_counts[2], ")")
    )
  ) +
  scale_fill_manual(
    values = c("Next: rejected" = "#9ECAE1",
               "Next: successful" = "#F4A582")
  ) +
  scale_y_continuous(
    trans = scales::pseudo_log_trans(sigma = 0.01),
    breaks = c(-0.01, 0, 0.01, 0.05, 0.10, 0.25, 0.50, 1.00)
  ) +
  labs(
    x = "Outcome of previous request",
    y = "Observed supporter overlap minus random expectation",
    fill = NULL,
    title = "Repeat support is uncommon, but rises before later success",
    subtitle = "Each point is a pair of consecutive requests"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top")
ggsave(
  file.path(DIR_FIGURES, "fig2_supporter_overlap.png"),
  p2,
  width = 8,
  height = 5,
  dpi = 300
)

p3_data <- pairs[!is.na(pairs$community_breadth_change), ]
p3 <- ggplot(
  p3_data,
  aes(x = previous_group, y = community_breadth_change, fill = next_group)
) +
  geom_hline(yintercept = 0, linetype = 2, color = "gray45") +
  geom_boxplot(
    position = position_dodge(width = 0.72),
    width = 0.62,
    outlier.shape = NA,
    alpha = 0.55,
    linewidth = 0.35
  ) +
  geom_point(
    position = position_jitterdodge(jitter.width = 0.16, dodge.width = 0.72),
    size = 0.9,
    alpha = 0.45,
    stroke = 0
  ) +
  scale_fill_manual(
    values = c("Next: rejected" = "#9ECAE1",
               "Next: successful" = "#F4A582")
  ) +
  labs(
    x = "Outcome of previous request",
    y = "Change in effective supporter communities",
    fill = NULL,
    title = "Change in the breadth of a candidate's voter coalition"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top")
ggsave(
  file.path(DIR_FIGURES, "fig3_community_diversity.png"),
  p3,
  width = 8,
  height = 5,
  dpi = 300
)

coefficient_table <- model_objects$coefficient_table
plot_coefficients <- coefficient_table[
  coefficient_table$model == "Network-augmented" &
    coefficient_table$term != "(Intercept)",
]
plot_coefficients$term_label <- factor(
  plot_coefficients$term_label,
  levels = rev(plot_coefficients$term_label)
)
p4 <- ggplot(
  plot_coefficients,
  aes(x = odds_ratio, y = term_label)
) +
  geom_vline(xintercept = 1, linetype = 2, color = "gray45") +
  geom_errorbar(
    aes(xmin = confidence_low, xmax = confidence_high),
    orientation = "y",
    width = 0.18,
    color = "#176B87",
    linewidth = 0.6
  ) +
  geom_point(size = 2.1, color = "#176B87") +
  scale_x_log10() +
  labs(
    x = "Odds ratio for success at the next request (95% CI)",
    y = NULL,
    title = "Network-augmented pre-request model",
    subtitle = sprintf(
      "Grouped CV AUC %.3f without network measures; %.3f with them",
      model_objects$performance$auc[
        model_objects$performance$model == "Vote shares and timing"
      ],
      model_objects$performance$auc[
        model_objects$performance$model == "Network-augmented"
      ]
    )
  ) +
  theme_minimal(base_size = 11)
ggsave(
  file.path(DIR_FIGURES, "fig4_model_coefficients.png"),
  p4,
  width = 8,
  height = 5,
  dpi = 300
)
