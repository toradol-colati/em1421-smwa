# EM1421 — Repeat Requests for Adminship

Group project for **EM1421 Social Media and Web Analytics**, Ca' Foscari University of Venice,
academic year 2026/2027. Instructor: Pierluigi Zama Ramirez.

**Research question (the approved wording; it must not be rewritten without writing to the
instructor first):**
> Among repeat Requests for Adminship candidates, how do changes in voter-community
> composition, support-coalition overlap and network position differ between previously
> rejected and previously successful candidates, and how are these changes associated with the
> next outcome?

Data: SNAP **wiki-RfA** (Wikipedia RfA votes, 2003 – May 2013) as the primary source, SNAP
**wiki-Elec** (elections up to January 2008) to validate outcomes. The whole analysis is in R
(igraph, ggplot2). Results are described as associations, not causal effects.

Team of two. **Umberto Toraldo** (GitHub `toradol-colati`) is the **data member**: preparing
both SNAP datasets, cleaning the records, reconstructing candidate attempts, validating the
outcomes, and delivering analysis-ready vote-level and attempt-level tables. **Mihretab Worku
Morka** (GitHub `mihretabworku`) is the **network member**: building the voter and co-voting
networks, measuring communities, support overlap, centrality and brokerage, running the outcome
analysis and producing the report figures. Jointly: the data and network definitions, the
literature, interpretation, the report and the final submission package.

Deadline stated in the brief: **2 November 2026, 09:00 CET** (report PDF, code and data, plus a
confirmation email to the instructor).

---

## Start here

| # | File | Why |
|---|---|---|
| 1 | [docs/DATA.md](docs/DATA.md) | **The data workstream, complete.** What the raw data are and where they come from, the eleven defects found and how each was fixed, the delivered tables column by column, what is still open, the two verification rounds, the substantive analysis of the results, and all the R code in an appendix. Everything the network workstream needs in order to start. |
| 2 | [docs/EM1421_RfA_contesto_nuova_chat.md](docs/EM1421_RfA_contesto_nuova_chat.md) | Project background: state of play, figures, verified literature, open problems and the decisions still to be taken (§11). In Italian. |
| 3 | [CLAUDE.md](CLAUDE.md) | What changed after that document. In Italian; it also instructs Claude Code. |
| 4 | [docs/MATERIALE_CORSO.md](docs/MATERIALE_CORSO.md) | All the course slides summarised: definitions, formulas, igraph functions, and where the material constrains our method choices. In Italian. §11 and §12 are the ones to read before writing analysis code. |
| 5 | [docs/CODICE.md](docs/CODICE.md) | What code we are allowed to write beyond the slides, and the repository conventions. In Italian. |
| 6 | [docs/EM1421_group_project_brief.pdf](docs/EM1421_group_project_brief.pdf) · [docs/writing_your_project.txt](docs/writing_your_project.txt) · [docs/EM1421_projectsInstructions.txt](docs/EM1421_projectsInstructions.txt) | The approved brief, the criteria the instructor marks against, and the formal rules (max 4 figures, 12,000–20,000 characters, no code in the report, at least 5 scientific references, a paragraph on each member's contribution). |

The rest of `docs/` holds the original slides and papers, kept for reference.

## Repository layout

```
CLAUDE.md                 working notes and instructions
README.md                 this file
R/                        numbered scripts, to be run in order
  run_data_prep.R         one command that runs 01, 02 and 03 in order
  00_paths.R              shared paths and the missing-file check
  00_lib_data.R           shared functions: parsers, name normalisation, dates,
                          attempt reconstruction, deduplication, attempt table
  01_read_raw.R           read both SNAP files, no substantive cleaning
  02_build_attempts.R     reconstruct attempts, produce votes.rds and attempts.rds
  03_validate_outcomes.R  validate against wiki-Elec, choose the threshold
  04_build_networks.R     voting network and co-voting projection    [SKELETON]
  05_measure_change.R     measures of change from t to t+1           [SKELETON]
  06_model_outcome.R      outcome of the next attempt                [SKELETON]
  07_figures.R            the report figures                         [SKELETON]
  98_generate_appendix.R  regenerates the code appendix of docs/DATA.md
  99_verify_data.R        round 1: every claim recomputed from the raw files
  99b_verify_output.R     round 2: internal invariants of the tables
data/raw/                 the SNAP files as downloaded, with checksums
data/processed/           derived tables and logs, produced by the scripts
output/figures/           figures
report/                   the report PDF and its sources
docs/                     brief, instructions, slides, papers, documentation
```

The scripts marked `[SKELETON]` contain no code yet: only a header with inputs, outputs and the
decisions still open for that step. They belong to the network workstream.

## Running everything

The two SNAP files are in the repository, so no download is needed. From the repository root,
one command runs the whole data workstream:

```bash
Rscript R/run_data_prep.R
```

It takes about three minutes and prints a summary at the end. The three steps stay separate
files, because they are three different jobs and because a failure in one must never be
mistaken for a result of another; the wrapper only orchestrates them. It also guarantees four
things that plain `source()` calls do not:

- the outputs of the chain are **deleted before anything starts**, so a stale file from an
  earlier run cannot be picked up by a later step;
- it **stops at the first error**, names the step that failed and exits non-zero;
- whatever the failed step had already written is **moved into
  `data/processed/failed_run_<timestamp>/`** — still available for debugging, but no longer
  where a result is expected, so it cannot be mistaken for one;
- at the end it **checks every expected output exists**, so a partial success cannot pass for
  a complete run.

The three steps can still be run one at a time, which is what you want while developing:

```bash
Rscript R/01_read_raw.R
Rscript R/02_build_attempts.R
Rscript R/03_validate_outcomes.R
```

Optionally, the two verification rounds:

```bash
Rscript R/99_verify_data.R
Rscript R/99b_verify_output.R
```

Base R only; nothing else is required for the data workstream. `igraph` and `ggplot2` will be
needed for the network workstream. The scripts install nothing and make no network calls, so
the instructor can run them as they are.

## Conventions

- `data/raw/` is **read-only** for the scripts. Every script writes only to `data/processed/`
  or `output/`.
- **Do not filter, flag.** Problematic rows stay in the tables with a flag column, so whoever
  analyses decides what to exclude and the number of exclusions is available for the report.
- No variable observed **during** attempt t+1 may enter as a predictor of the outcome of t+1.
  The t+1 coalition variables are for descriptive comparison only, against a null model. This
  is the brief's "no leakage" rule.
- Thresholds and parameters are named constants at the top of each script, never numbers buried
  in the code.
- The report contains no code and no description of the code.

## Status

**Done — data workstream.** `data/processed/votes.rds` (195,271 validated votes) and
`data/processed/attempts.rds` (4,082 attempts, 484 repeat candidates) are ready, documented in
`docs/DATA.md`, validated against wiki-Elec at 99.45% outcome agreement on 2,177 matched
elections, and covered by two verification rounds that both pass.

**Next, together:** agree on the open decisions in `docs/DATA.md` §14 — first-letter case
variants above all, because they change both the study population and the node identities — and
settle the definitions of the two networks: node, edge, direction, weight, time window.

**Then — network workstream.** Scripts 04 to 07.
