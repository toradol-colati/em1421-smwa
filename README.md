# EM1421 - Repeat Requests for Adminship

Group project for **EM1421 Social Media and Web Analytics**, Ca' Foscari
University of Venice, academic year 2026/2027.

## Research question

Among repeat Requests for Adminship candidates, how do changes in
voter-community composition, support-coalition overlap and network position
differ between previously rejected and previously successful candidates, and
how are these changes associated with the next outcome?

The project is observational. Results are interpreted as associations, not
causal effects.

## Team

- **Umberto Toraldo**: data preparation, identity cleanup, attempt
  reconstruction and external validation.
- **Mihretab Worku Morka**: network construction, coalition measures,
  statistical models and figures.
- **Joint work**: research question, literature, interpretation, report and
  final oral discussion.

## Data

- `wiki-RfA.txt.gz`: primary SNAP vote data, 2003-May 2013.
- `wikiElec.ElecBs3.txt.gz`: independent election data through January 2008,
  used to validate attempt boundaries and outcomes.

The immutable raw files are in `data/raw/`. The validated processed data are
written to `data/processed/`, and the final tables and figures are included in
this branch so the submitted results can be inspected directly.

## Repository layout

```text
R/
  00_run_all.R               execute the complete pipeline
  00_paths.R                 shared paths and configuration
  00_lib_data.R              parsers, normalisation and attempt helpers
  run_data_prep.R            single data-preparation entry point
  01_read_raw.R              read the two SNAP files
  02_build_attempts.R        reconstruct candidate attempts
  03_validate_outcomes.R     validate attempts and outcomes
  04_build_networks.R        build historical co-voting networks
  05_measure_change.R        measure coalition and network change
  06_model_outcome.R         descriptive tests and outcome models
  07_figures.R               generate the four report figures
  93_coalition_overlap_null.R supporter overlap against a random baseline
  94_recruitment_curve.R     membership closure, T(k)
  95_weak_ties.R             strength of weak ties: neighborhood overlap, giant component
  96_network_description.R   clustering coefficient, average path length, giant component
  97_community_method_check.R Girvan-Newman compared with Louvain
  92_short_attempt_check.R   which short attempts match wiki-Elec
  98_generate_appendix.R     copies the code into docs/DATA_FULL.md
  99_verify_data.R           optional raw-data verification
  99b_verify_output.R        optional output-invariant verification

data/raw/                     immutable source data
data/processed/               generated data and intermediate objects
output/results/               generated tables and numerical results
output/figures/               generated report figures
report/                       final report
docs/                         brief, course references and method notes
```

## Required R packages

```r
install.packages(c("igraph", "ggplot2", "Matrix"))
```

Data preparation uses base R only.

## Run everything

From the repository root:

```bash
Rscript R/00_run_all.R
```

On Windows, if `Rscript` is not on the PATH, use its full path, for example
`"C:\Program Files\R\R-4.5.2\bin\Rscript.exe" R/00_run_all.R`.

`00_run_all.R` executes the decomposed pipeline in order:

```text
run_data_prep.R
04_build_networks.R
05_measure_change.R
06_model_outcome.R
07_figures.R
92_short_attempt_check.R
93_coalition_overlap_null.R
94_recruitment_curve.R
95_weak_ties.R
96_network_description.R
97_community_method_check.R
```

A full run took about 50 minutes on a laptop, most of it in 97 (Girvan-Newman).
The log of the run that produced the committed outputs is `output/logs/run_all_log.txt`.

The individual stages remain separately runnable for inspection and debugging.

Optional verification:

```bash
Rscript R/99_verify_data.R
Rscript R/99b_verify_output.R
```

`run_data_prep.R` runs the data steps in isolated environments, clears stale
outputs before starting, quarantines partial results after a failure and checks
that every expected data file exists. The four analysis scripts are
intentionally separate so each stage can be inspected and rerun.

To run only the data workstream:

```bash
Rscript R/run_data_prep.R
```

## Final data counts

| Quantity | Final value |
|---|---:|
| Validated vote records | 195,252 |
| Reconstructed attempts | 4,081 |
| Repeat candidates | 490 |
| All consecutive attempt pairs | 621 |
| Pairs with valid outcomes (all valid sample) | 609 |
| Negative-interval pairs | 17 |
| Chronological sample (main descriptive results) | 592 |
| Strict sample (outcome model) | 513 |
| Pairs after prior success (all / chronological / strict) | 54 / 52 / 27 |
| Attempts matched to `wiki-Elec` | 2,175 |
| Validated outcome agreements | 2,163 (99.45%) |
| Modelling pairs (candidates) | 513 (409) |

The final reconstruction:

- merges first-letter username variants;
- removes 1,661 voter-less phantom records;
- recovers abbreviated and misspelled month names;
- attributes 6,975 undated votes only where attribution is unambiguous;
- retains ambiguous and conflicting source information in diagnostic files;
- excludes 12 high-confidence outcome disagreements from outcome analysis;
- reports every pair comparison for three samples: all 609 valid pairs; the
  chronological sample (592), without pairs whose second attempt starts before
  the first ends; and the strict sample (513), also without attempts of fewer
  than five votes. `R/92_short_attempt_check.R` shows which short attempts
  match wiki-Elec.

## Network construction

Two voters are connected when they cast the same support/oppose direction in at
least two historical candidate attempts. The graph is undirected and weighted
by repeated co-voting. Neutral votes and self-votes are excluded from the co-voting
network.

Communities are detected with weighted Louvain, an *agglomerative* method.
Lecture 3 ("Strong and Weak Ties", General Approaches to Graph Partitioning)
presents Girvan-Newman as the *divisive* example, suited to networks of moderate
size, and names agglomerative methods as the alternative for larger ones.

`R/97_community_method_check.R` compares the two on the three smallest
snapshots. Girvan-Newman is run twice: unweighted, as in the course lab, and
with tie strength entered as closeness (1 / weight). igraph reads edge-betweenness
weights as lengths, so co-vote counts must never be passed unchanged. On the
2004 snapshot, the inverse-weight version reaches modularity 0.093 and the
unweighted one 0.017, against 0.185 for Louvain; on 2005 the unweighted version
returns 85 communities with modularity 0.000, and the other 2005 and 2006 runs do
not finish within ten minutes. Each run is a separate R process with a hard
timeout. Community results are treated as exploratory.

The analysis measures supporter overlap, new and returning supporters,
effective community breadth, community-mix change, weighted degree, PageRank,
eigenvector centrality, local clustering and community-level bridge exposure.

## Outcome modelling

The model compares:

1. a vote-share/timing model;
2. a model augmented with network position.

Both use candidate-grouped five-fold cross-validation and only variables
available before the next attempt. The model sample is the strict sample, 513
pairs from 409 candidates.

| Model | AUC | Brier |
|---|---:|---:|
| Prevalence only | 0.500 | 0.241 |
| Vote shares and timing | 0.697 | 0.215 |
| Network-augmented | 0.698 | 0.215 |

Network measures do not materially improve held-out prediction. They are
therefore interpreted as descriptive measures of coalition composition rather
than evidence of superior forecasting. The comparison is repeated with and
in all three samples (`model_performance_sensitivity.csv`).

## Documentation

- `docs/EM1421_group_project_brief.pdf`: submitted project proposal.
- `docs/EM1421_projectsInstructions.txt`: official project requirements.
- `docs/writing_your_project.txt`: instructor's report-writing guidance.
- `docs/DATA.md`: final data definitions, counts and limitations.
- `report/EM1421_Repeat_RfA_Report.pdf`: submission-ready final report.
- `report/report_source.md`: editable manuscript used to produce the report.
- `report/build_pdf.py`: rebuilds the PDF from the manuscript and figures
  (`python report/build_pdf.py`, needs reportlab).

The processed data, result tables and figures
are included as a validated snapshot and can also be recreated with
`R/00_run_all.R`.
