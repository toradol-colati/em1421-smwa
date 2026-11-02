# 07 - Make the four figures of the report.
#   Fig 1: the communities of the latest network, and modularity and the share
#          of edges between communities over the years (base R plot);
#   Fig 2: supporter overlap above chance, by earlier and later result;
#   Fig 3: change in the number of supporter communities;
#   Fig 4: odds ratios of the network model (from 06).
#
# Input : data/processed/attempt_pairs.rds, network_objects.rds, model_objects.rds
# Output: output/figures/fig1_covoting_network.png, fig2_supporter_overlap.png,
#         fig3_community_diversity.png, fig4_model_coefficients.png

if (dir.exists(".Rlib")) .libPaths(c(file.path(getwd(), ".Rlib"), .libPaths()))
suppressPackageStartupMessages({ library(igraph); library(ggplot2) })
source(file.path("R", "00_paths.R"))
dir.create(DIR_FIGURES, showWarnings = FALSE, recursive = TRUE)
if (!all(file.exists(file.path(DIR_PROCESSED,
                               c("attempt_pairs.rds", "network_objects.rds", "model_objects.rds")))))
  stop("Run R/04_build_networks.R, R/05_measure_change.R and R/06_model_outcome.R first.",
       call. = FALSE)

pairs <- readRDS(file.path(DIR_PROCESSED, "attempt_pairs.rds"))
pairs <- pairs[pairs$in_chronological, ]   # figures 2-3 use the chronological sample
snapshots <- readRDS(file.path(DIR_PROCESSED, "network_objects.rds"))$snapshots
model_objects <- readRDS(file.path(DIR_PROCESSED, "model_objects.rds"))
network_summary <- do.call(rbind, lapply(snapshots, `[[`, "summary"))

# --- Figure 1 -------------------------------------------------------------------
# Left: the latest network shrunk to one circle per community, placed evenly on
# a circle (size = number of voters), with lines between communities whose
# width grows with their total edge weight (log scale).
latest <- snapshots[[length(snapshots)]]
sizes <- table(latest$membership[!is.na(latest$membership)])
angles <- seq(0, 2 * pi, length.out = length(sizes) + 1)[seq_along(sizes)]
nodes <- data.frame(community = as.integer(names(sizes)), x = cos(angles),
                    y = sin(angles), size = as.integer(sizes))
links <- latest$community_edges
from <- match(links$lower, nodes$community); to <- match(links$upper, nodes$community)

png(file.path(DIR_FIGURES, "fig1_covoting_network.png"), width = 1800, height = 850, res = 180)
layout(matrix(c(1, 2), nrow = 1), widths = c(1.15, 1))
par(mar = c(2, 2, 4, 1))
plot(NA, xlim = c(-1.35, 1.35), ylim = c(-1.35, 1.35), asp = 1, axes = FALSE,
     xlab = "", ylab = "", main = "Voter-community network")
segments(nodes$x[from], nodes$y[from], nodes$x[to], nodes$y[to],
         col = adjustcolor("#4C78A8", alpha.f = 0.28),
         lwd = 0.5 + 3.5 * log1p(links$weight) / max(log1p(links$weight)))
points(nodes$x, nodes$y, pch = 21, bg = "#F58518", col = "white", lwd = 1.5,
       cex = 2.2 + 3.3 * sqrt(nodes$size / max(nodes$size)))
text(nodes$x, nodes$y, labels = paste0("C", nodes$community, "\n", nodes$size),
     cex = 0.78, font = 2)
mtext("Latest cumulative snapshot", side = 1, line = 0.5, cex = 0.8)

# Right: modularity and cross-community edge share over the years.
par(mar = c(4.5, 4.5, 4, 1))
with(network_summary, {
  plot(cutoff_year, modularity, type = "b", pch = 19, col = "#E45756",
       ylim = c(0, max(c(modularity, cross_community_share), na.rm = TRUE) * 1.08),
       xlab = "Start of target year", ylab = "Network measure",
       main = "Community structure over time")
  lines(cutoff_year, cross_community_share, type = "b", pch = 17, col = "#4C78A8")
})
legend("bottomright", legend = c("Modularity", "Cross-community edge share"),
       col = c("#E45756", "#4C78A8"), pch = c(19, 17), lty = 1, bty = "n", cex = 0.85)
mtext("Historical same-direction voter co-voting network", outer = TRUE,
      side = 3, line = -1.5, cex = 1.1, font = 2)
dev.off()

# --- Figures 2 and 3 --------------------------------------------------------------
# Same layout: one box per group, every pair as a point, dashed line at 0.
pair_boxplot <- function(data, y) {
  ggplot(data, aes(x = previous_group, y = .data[[y]], fill = next_group)) +
    geom_hline(yintercept = 0, linetype = 2, color = "gray45") +
    geom_boxplot(position = position_dodge(width = 0.72), width = 0.62,
                 outlier.shape = NA, alpha = 0.55, linewidth = 0.35) +
    geom_point(position = position_jitterdodge(jitter.width = 0.16, dodge.width = 0.72),
               size = 0.9, alpha = 0.45, stroke = 0) +
    scale_fill_manual(values = c("Next: rejected" = "#9ECAE1", "Next: successful" = "#F4A582")) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "top")
}
save_png <- function(plot, name) ggsave(file.path(DIR_FIGURES, name), plot,
                                        width = 8, height = 5, dpi = 300)

# Figure 2: overlap minus chance (jaccard_excess from 05). 0 = exactly what
# chance predicts. The y axis is stretched near 0 (pseudo-log) because most
# values are small.
d2 <- pairs[!is.na(pairs$supporter_jaccard) & !is.na(pairs$jaccard_excess), ]
n_prior <- table(d2$previous_group)
save_png(pair_boxplot(d2, "jaccard_excess") +
  scale_x_discrete(labels = c(paste0("Previously rejected\n(n = ", n_prior[1], ")"),
                              paste0("Previously successful\n(n = ", n_prior[2], ")"))) +
  scale_y_continuous(trans = scales::pseudo_log_trans(sigma = 0.01),
                     breaks = c(-0.01, 0, 0.01, 0.05, 0.10, 0.25, 0.50, 1.00)) +
  labs(x = "Outcome of previous request",
       y = "Observed supporter overlap minus random expectation", fill = NULL,
       title = "Supporter overlap above random expectation",
       subtitle = sprintf("Each point is a pair of consecutive requests (chronological sample, %d pairs)",
                          nrow(d2))),
  "fig2_supporter_overlap.png")

# Figure 3: change in the effective number of supporter communities from the
# earlier to the later election. Above 0 = support spread over more communities.
save_png(pair_boxplot(pairs[!is.na(pairs$community_breadth_change), ],
                      "community_breadth_change") +
  labs(x = "Outcome of previous request", y = "Change in effective supporter communities",
       fill = NULL, title = "Change in the breadth of a candidate's voter coalition"),
  "fig3_community_diversity.png")

# --- Figure 4 -------------------------------------------------------------------
# Odds ratios with 95% intervals of the network model (without the intercept).
# 1 = no effect; log scale on x. The subtitle gives the cross-validated AUC.
coefs <- model_objects$coefficient_table
coefs <- coefs[coefs$model == "Network-augmented" & coefs$term != "(Intercept)", ]
coefs$term_label <- factor(coefs$term_label, levels = rev(coefs$term_label))
auc <- setNames(model_objects$performance$auc, model_objects$performance$model)
save_png(ggplot(coefs, aes(x = odds_ratio, y = term_label)) +
  geom_vline(xintercept = 1, linetype = 2, color = "gray45") +
  geom_errorbar(aes(xmin = confidence_low, xmax = confidence_high), orientation = "y",
                width = 0.18, color = "#176B87", linewidth = 0.6) +
  geom_point(size = 2.1, color = "#176B87") +
  scale_x_log10() +
  labs(x = "Odds ratio for success at the next request (95% CI)", y = NULL,
       title = "Network-augmented pre-request model",
       subtitle = sprintf("Grouped CV AUC %.3f without network measures; %.3f with them",
                          auc[["Vote shares and timing"]], auc[["Network-augmented"]])) +
  theme_minimal(base_size = 11),
  "fig4_model_coefficients.png")
