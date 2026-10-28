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

The immutable raw files are in `data/raw/`. Generated data are written to
`data/processed/` and are not committed.

## Repository layout

```text
R/
  00_run_all.R               execute the complete pipeline
  00_paths.R                 shared paths and configuration
  00_lib_data.R              parsers, normalisation and attempt helpers
  01_prepare_data.R          single data-preparation entry point
  01_read_raw.R              read the two SNAP files
  02_build_attempts.R        reconstruct candidate attempts
  03_validate_outcomes.R     validate attempts and outcomes
  04_build_networks.R        build historical co-voting networks
  05_measure_change.R        measure coalition and network change
  06_model_outcome.R         descriptive tests and outcome models
  07_figures.R               generate the four report figures
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

```powershell
$rscript = "C:\Program Files\R\R-4.5.2\bin\Rscript.exe"

& $rscript R\00_run_all.R
```

`00_run_all.R` executes the decomposed pipeline in order:

```text
01_prepare_data.R
04_build_networks.R
05_measure_change.R
06_model_outcome.R
07_figures.R
```

The individual stages remain separately runnable for inspection and debugging.

Optional verification:

```powershell
& $rscript R\99_verify_data.R
& $rscript R\99b_verify_output.R
```

`01_prepare_data.R` runs the internal data steps in order. The four analysis
scripts are intentionally separate so each stage can be inspected and rerun.

## Final data counts

| Quantity | Final value |
|---|---:|
| Validated vote records | 195,252 |
| Reconstructed attempts | 4,081 |
| Repeat candidates | 490 |
| All consecutive attempt pairs | 621 |
| Pairs with valid outcomes | 609 |
| Pairs after prior rejection | 555 |
| Pairs after prior success | 54 |
| Successful next attempts | 251 |
| Attempts matched to `wiki-Elec` | 2,175 |
| Validated outcome agreements | 2,163 (99.45%) |
| Reliable modelling pairs | 528 |

The final reconstruction:

- merges first-letter username variants;
- removes 1,661 voter-less phantom records;
- recovers abbreviated and misspelled month names;
- attributes 6,975 undated votes only where attribution is unambiguous;
- retains ambiguous and conflicting source information in diagnostic files;
- excludes 12 high-confidence outcome disagreements from outcome analysis.

## Network construction

Two voters are connected when they cast the same support/oppose direction in at
least two historical candidate attempts. The graph is undirected and weighted
by repeated co-voting. Neutral votes and self-votes are excluded from the signed
co-voting network.

Communities are detected with weighted Louvain. The course's Girvan-Newman
method is retained as a sensitivity check on the first tractable snapshot.
Community results are treated as exploratory because dense graphs are sensitive
to detection method and threshold.

The analysis measures supporter overlap, new and returning supporters,
effective community breadth, community-mix change, weighted degree, PageRank,
eigenvector centrality, local clustering and community-level bridge exposure.

## Outcome modelling

The model compares:

1. a vote-share/timing model;
2. a model augmented with network position.

Both use candidate-grouped five-fold cross-validation and only variables
available before the next attempt. The final sample contains 528 reliable pairs
from 424 candidates.

| Model | AUC | Brier |
|---|---:|---:|
| Prevalence only | 0.500 | 0.244 |
| Vote shares and timing | 0.716 | 0.210 |
| Network-augmented | 0.715 | 0.209 |

Network measures do not materially improve held-out prediction. They are
therefore interpreted as descriptive measures of coalition composition rather
than evidence of superior forecasting. The comparison is repeated with and
without very short attempts.

## Documentation

- `docs/DATA.md`: final data definitions, counts and limitations.
- `docs/code_evidence_map.md`: code-to-course correspondence and clearly marked
  project extensions.

The report must not contain code. Generated data, results and figures must be
recreated by the scripts and are excluded from Git.
