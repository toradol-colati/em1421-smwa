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

The long-form record of the method — every defect and how it was handled, the
tables column by column, the decisions and their implications, the verification
rounds and the full code — is in `docs/DATA_FULL.md`.

## Remaining limitations

- External outcome validation covers attempts through January 2008 only.
- `wikiElec` and `wiki-RfA` disagree on part of the voter lists even when they
  match the same elections.
- `RES` is not constant within **2.3%** of matched elections. The figure is measured
  on the candidates who have a single election in `wiki-Elec`, where there is no
  ambiguity about which election is meant; measuring it across all candidates
  returns 15%, which is an artefact, because a candidate with several elections
  shares voters between them and the test then pulls in the other election's
  votes. The exposure is bounded directly: the `gap_only` rule never uses `RES`
  to set boundaries and yields 4,063 attempts against 4,081, so the whole
  question moves 18 attempts out of 4,081. Both rules are in
  `03_threshold_sweep.csv`.
- Attempt ids are assigned over a sorted table, and `order()` sorts usernames by
  the machine's collation locale, so the same data produced different
  `attempt_id` values on different machines (3,763 of 4,081 differed between a
  Windows and a macOS run; the attempts themselves were identical). All seven
  ordering calls now use `method = "radix"`, which sorts by byte and is
  locale-independent. Checked by running the pipeline under `LC_COLLATE=it_IT`
  and `LC_COLLATE=C`: byte-identical output.
- The exact opening and closing times are inferred from vote dates.
- Co-voting is a behavioural measure, not evidence of friendship or influence.
