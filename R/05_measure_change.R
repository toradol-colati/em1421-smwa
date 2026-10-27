# 05 - Measuring the change between attempt t and attempt t+1.  [SKELETON]
# Input : data/processed/net_*.rds, data/processed/attempts_validated.rds
# Output: data/processed/features.rds
#
# Two blocks, to be kept strictly apart:
#   - PREDICTIVE: only variables known before attempt t+1 opens (outcome and
#     support share at t, the candidate's network position up to that point,
#     votes the candidate cast in other RfAs between attempts, time elapsed,
#     year).
#   - DESCRIPTIVE: shared supporters, new supporters, community diversity.
#     These use the votes of t+1, so they never enter the model; they are
#     compared against a null model that holds the number of voters fixed.
#
# Mandatory check before any regression: the correlation between in-degree or
# centrality before t+1 and the number of voters or support share at t.
