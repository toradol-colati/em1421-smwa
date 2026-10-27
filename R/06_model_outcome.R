# 06 - Outcome of the next attempt.  [SKELETON]
# Input : data/processed/features.rds
# Output: data/processed/model_*.rds
#
# Descriptive comparison by previous outcome, then a parsimonious logistic
# regression. Constraints:
#   - no predictor observed during t+1;
#   - attempt pairs of the same candidate are not independent: keep one pair per
#     candidate, or cluster by candidate;
#   - count the successes at t+1: roughly 10 events per variable;
#   - baseline: first-attempt success rate, or a model with previous outcome and
#     year only;
#   - the year must be controlled for in any case: RfA standards changed over
#     time (success falls from 100% in 2003 to 31% in 2012 in our data).
