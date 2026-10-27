# 04 - Network construction (igraph).  [SKELETON - network workstream]
# Input : data/processed/votes.rds, data/processed/attempts_validated.rds
# Output: data/processed/net_*.rds
#
# OPEN DECISIONS. Each network needs four explicit choices - node, edge,
# direction, weight - plus a time window:
#   - voting network: voter -> candidate, support and opposition kept apart,
#     neutral votes (vot = 0) to be handled, window = everything up to the
#     opening of attempt t+1;
#   - voter-voter co-voting network: what creates an edge and with what weight.
#     The projection is dense; extracting a backbone against a null model is an
#     option, but note that it is outside the course syllabus;
#   - community detection algorithm;
#   - the network on which brokerage is measured, and which measure.
#
# Known constraints, measured: 10,394 voters and 3,468 candidates in votes.rds,
# 2,512 users are both. Self-votes are loops: see the self_vote column.
