# Data preparation

This repository adopts the independently audited data workstream prepared by
Umberto Toraldo, with the following decisions fixed for the network analysis.

## Run

From the repository root:

```powershell
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" R\run_data_prep.R
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" R\99_verify_data.R
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" R\99b_verify_output.R
```

The first command executes the ordered internal steps with stale-output
protection and creates the analysis tables. The two verification scripts are
optional audit checks.
The validated files in `data/processed/` are committed so the prepared tables
can be inspected directly. They can also be recreated from `data/raw/`.

## Canonical choices

- Usernames are trimmed, internal whitespace is collapsed, invisible direction
  characters are removed, underscores are treated as spaces for cross-file
  matching, and first-letter case variants are merged.
- The 1,661 records with an empty voter are removed as phantom records and
  written separately to `records_without_voter.csv`.
- Votes are grouped into candidate attempts by outcome and then by a seven-day
  gap (`res_then_gap`). The threshold is retained because `wiki-Elec` matching
  is flat between 4 and 21 days and seven days matches the published precedent
  and the nominal RfA length.
- A date-gap-only rule is also evaluated as a sensitivity check. At seven days
  it produces 4,063 attempts versus 4,081 for the main rule; both match 1,947
  elections and agree with the external attempt count for 94.6% of comparable
  candidates.
- Undated votes are assigned only when candidate, year and outcome identify one
  attempt unambiguously.
- When one voter appears more than once in an attempt, the latest dated vote is
  retained.
- Self-votes and neutral votes remain in `votes.rds` for audit, but both are
  excluded from the signed voter co-voting network.
- Attempts with a high-confidence outcome disagreement against `wiki-Elec` are
  retained for provenance but excluded from outcome analysis.
- Attempts with fewer than five votes remain in descriptive summaries but do
  not enter the inferential model.

## Validation

The pipeline produces:

| Quantity | Result |
|---|---:|
| Raw RfA vote records | 198,275 |
| Analysis vote records | 195,252 |
| Reconstructed attempts | 4,081 |
| Repeat candidates | 490 |
| Consecutive attempt pairs | 621 |
| Attempts matched to `wiki-Elec` by voter set | 2,175 |
| Outcome agreements among matched attempts | 2,163 (99.45%) |
| Outcome disagreements excluded from analysis | 12 |

The two verification scripts check the raw-file claims and the internal
consistency of the delivered tables. The raw-data verification covers the file
format, identity cleanup, missing dates, vote and outcome counts, invalid
encoding, and known source defects. The output verification checks vote
conservation, attempt membership, previous outcomes, flags, and network-table
counts.

## Remaining limitations

- External outcome validation covers attempts through January 2008 only.
- `wikiElec` and `wiki-RfA` disagree on part of the voter lists even when they
  match the same elections.
- `RES` is not constant within 15% of high-overlap matched elections. The
  `res_then_gap` rule therefore remains the main reconstruction rule, while its
  sensitivity is visible in `03_threshold_sweep.csv`.
- The exact opening and closing times are inferred from vote dates.
- Co-voting is a behavioural measure, not evidence of friendship or influence.
