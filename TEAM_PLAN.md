# EM1421 Project Handoff

## Context

The proposal question is approved. The project uses the two SNAP files `wiki-RfA.txt.gz` and `wikiElec.ElecBs3.txt.gz`. The final deliverable is a PDF report plus all R code and data needed to reproduce the analysis.

Team:

- Umberto Toraldo, data member
- Mihretab Worku Morka, network member

## What the repository contains now

```text
em1421-smwa/
  README.md
  CLAUDE.md
  TEAM_PLAN.md
  docs/
  data/raw/
  data/processed/
  R/00_paths.R
  R/01_read_raw.R
  R/02_build_attempts.R
  R/03_validate_outcomes.R
  R/04_build_networks.R
  R/05_measure_change.R
  R/06_model_outcome.R
  R/07_figures.R
  output/figures/
  report/
```

Umberto has created the repository structure, added the course materials and project notes, written the approved-question documentation and added the numbered R workflow.

Current implementation status:

- `R/00_paths.R` works.
- `R/01_read_raw.R` runs, but its parsed columns are nested list columns and the result is not usable.
- `R/02` to `R/07` contain only comments.
- The two SNAP data files are not committed.
- There are no cleaned datasets, network results, figures or report draft.

## What should change before submission

- Consolidate the eight script skeletons into two working scripts.
- Put the two raw SNAP files in `data/raw/`.
- Generate reproducible cleaned data and results.
- Write the literature notes and report in Markdown, then export the report as PDF.
- Include the contribution paragraph inside the report.
- Keep only the report, code, required data and a short execution README in the final Moodle ZIP.

The course PDFs, the unrelated `Exam guidelines.pptx`, `CLAUDE.md` and the long internal context notes are working resources, not final submission files.

## Proposed deliverable

```text
EM1421_Submission/
  report.pdf
  README.txt
  data/
    wiki-RfA.txt.gz
    wikiElec.ElecBs3.txt.gz
  R/
    01_prepare_data.R
    02_analysis.R
  output/
    results/
    figures/
```

`01_prepare_data.R` handles both raw files and creates clean vote and attempt tables.

`02_analysis.R` builds the network features, performs the outcome analysis and produces the four report figures or tables.

## Work division

### 1. Umberto - data workstream

1. Fix the RfA parser and implement the `wikiElec` parser.
2. Normalise usernames, define the duplicate rule, reconstruct candidate attempts and validate their outcomes.
3. Deliver the raw data, clean `votes` and `attempts` tables, an audit of ambiguous records and a short data handoff note.

Primary file: `R/01_prepare_data.R`.

### 2. Mihretab - network workstream

1. Define and build the voter-to-candidate network and the voter-to-voter co-voting network.
2. Calculate voter communities, supporter overlap, community diversity, centrality and brokerage; compare consecutive attempts.
3. Run the leakage-safe outcome analysis and produce the numerical results and four figures or tables for the report.

Primary file: `R/02_analysis.R`.

Only information available before attempt \(t+1\) may predict the outcome of \(t+1\). Measures using votes from \(t+1\) are descriptive comparisons only.

### 3. Joint workstream

1. Agree on the vote and attempt table schemas and on the definitions of both networks before coding is finalised.
2. Maintain `report/literature.md` with references linked to specific claims, then write `report/report.md` and export the final PDF.
3. Interpret results, write limitations, prepare the contribution paragraph, test the final package and submit.

## Immediate next step

Umberto fixes the data parser and freezes the two table schemas. Mihretab can then implement the network analysis against a small agreed example table while the full dataset is being validated.

## Required report items

- Approved research question and motivation
- Data source, collection period, filtering and final sample
- Network methods and statistical analysis
- Results with uncertainty and comparison points
- Interpretation, limitations and biases
- At least five scientific references
- No more than four captioned and referenced figures or tables
- Paragraph describing each member's contribution
- PDF length between 12,000 and 20,000 characters, including spaces
