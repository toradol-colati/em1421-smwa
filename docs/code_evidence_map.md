# Code-to-course evidence map

This document separates methods copied conceptually from the course from
project-specific extensions. Not every line of data-engineering code comes from
a lecture; parsers, data cleaning and validation are implementation choices
required by the SNAP file formats.

## Data preparation

| Code section | What it does | Source or justification |
|---|---|---|
| `R/00_lib_data.R` `read_rfa()` | Parses seven-field vote records | SNAP `wiki-RfA` format and observed file audit |
| `clean_name()` and `norm_user()` | Removes invisible characters, whitespace defects and underscore/space differences | Empirical identity audit; Wikipedia titles treat underscores and spaces as equivalent |
| `parse_dat()` | Parses full and abbreviated month names without depending on locale | Data audit found 7,080 dates that a full-month parser would lose |
| `reconstruct_attempts()` | Groups by candidate/outcome and a time gap, with a gap-only sensitivity rule | Published precedent plus validation against `wiki-Elec` |
| `R/03_validate_outcomes.R` | Compares reconstructed voter sets with independent elections using Jaccard overlap | The neighborhood-overlap idea is taught in the network-context lecture |
| `R/run_data_prep.R` | Runs the ordered data stages and creates `attempts_analysis.rds` | Project no-leakage and data-quality requirements |

## Network construction

Implemented in `R/04_build_networks.R`.

| Code section | What it does | Source or justification |
|---|---|---|
| Voter and candidate are different node types | Represents voting as an affiliation structure | Bipartite-network lecture, Networks in R b |
| `build_covoting_snapshot()` | Projects voters through shared same-direction candidate votes | Taught bipartite projection, extended with signed same-direction separation and a two-event threshold |
| Undirected weighted graph | Two voters have one symmetric repeated co-voting tie | Graph definitions and weighted-network material |
| Excluding neutral and self-votes | Keeps only genuine signed voter-candidate edges | Project-specific inclusion decision; self-votes are retained in the audit table |

Every project-specific choice should be justified in one sentence: what the
node is, what the edge is, why it is undirected, what the weight means and why
the threshold is used.

## Network measures

| Code section | What it measures | Course/source status |
|---|---|---|
| `strength()` / `weighted_degree` | Repeated co-voting embeddedness | Degree and weighted-network material; direct extension |
| `page_rank()` | Connection to well-connected voters | PageRank is mentioned in the citation-network lecture |
| `eigen_centrality()` | Weighted centrality among important neighbours | Eigenvector centrality is demonstrated in the citation-network lecture |
| `transitivity()` | Triadic closure at graph and voter level | Clustering coefficient/transitivity is taught in the ties and Networks-in-R lectures |
| `edge_density()` | Share of possible co-voting edges present | Graph density is demonstrated in Networks in R a |
| `cluster_louvain()` | Modularity-based community partitioning | **Extension:** the course demonstrates Girvan-Newman, but also discusses agglomerative methods for large networks |
| `cluster_edge_betweenness()` | Girvan-Newman sensitivity check | Directly taught graph-partitioning method |
| `community_bridge_exposure` | Number of other communities reached by a voter's community | **Custom community-level extension**, not a local bridge or Burt structural-hole measure |

## Coalition changes

Implemented in `R/05_measure_change.R`.

| Code section | Definition | Explanation |
|---|---|---|
| `supporter_jaccard` | Intersection divided by union of supporter sets | Same neighborhood-overlap logic taught in the network-context lecture |
| `jaccard_excess` | Observed overlap minus random-mixing expectation | Generic null-comparison logic; the exact voter-pool expectation is a project extension |
| `effective_communities` | `exp(Shannon entropy)` over community labels | One community means homogeneous support; larger values mean broader coalition breadth |
| `community_mix_js` | Jensen-Shannon divergence between community distributions | Measures reshuffling beyond individual voter overlap; project extension |
| `returning_support_share` | Returning supporters divided by current supporters | Directly tied to the research question |
| `new_support_share` | New supporters divided by current supporters | Directly tied to the research question |

`community_mix_js` compares how support is distributed across communities, not
whether the same exact voters returned. It therefore complements rather than
replaces Jaccard overlap.

## Statistical analysis

Implemented in `R/06_model_outcome.R`.

| Code section | What it does | Status |
|---|---|---|
| Wilcoxon tests and Cliff's delta | Compare skewed metric distributions without assuming normality | Project statistics extension |
| Benjamini-Hochberg adjustment | Controls false discovery across metric families | Project statistics extension |
| Logistic regression | Models a binary next-attempt outcome | Project statistics extension |
| Candidate-grouped five-fold CV | Keeps repeated attempts by one candidate in one fold | Prevents dependence between training and test rows; motivated by the bias/train-test lecture |
| AUC and Brier score | Measures discrimination and probability accuracy | Project extension with prevalence baseline |
| Vote-only versus network-augmented model | Tests whether network measures add predictive information | Direct response to the course warning: if structure answers the question, the network adds nothing |

The model deliberately excludes current-attempt coalition variables. This
follows the project no-leakage rule.

Figure generation is isolated in `R/07_figures.R`.

## Important distinctions for the oral discussion

- Co-voting is a behavioural affiliation, not measured friendship or social
  influence.
- PageRank and eigenvector centrality answer related but not identical
  questions.
- Modularity partitions are exploratory when the graph is dense and method
  sensitive.
- The network result describes coalition composition; it does not establish
  causality or superior forecasting.

## Course files used

- `docs/2-EM1421.pdf`: graph definitions, degree, weighted networks, paths and
  connectivity.
- `docs/5-EM1421a.pdf`: igraph operations, degree, transitivity, centrality,
  betweenness, hubs and authorities.
- `docs/5-EM1421b.pdf`: bipartite networks, projections, layouts and edge
  filtering.
- `docs/6-EM1421.pdf`: PageRank, eigenvector centrality, betweenness and
  community detection.
- `docs/3-EM1421.pdf`: triadic closure, weak ties, embeddedness, structural
  holes and Girvan-Newman.
- `docs/4-EM1421.pdf`: homophily, random mixing, bipartite affiliation networks
  and selection versus influence.
- `docs/11. Social Data - Biases, methodological pitfalls, and ethical
  boundaries.pdf`: data quality, evaluation, train/test composition and
  limitations.
