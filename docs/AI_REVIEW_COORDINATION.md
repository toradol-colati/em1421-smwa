# AI Review Coordination: Repeat Requests for Adminship

This note is a working document for reconciling the analysis review. It is not
part of the submitted report. The aim is to separate code defects from choices
about the study population, then make both analyses run from one documented
snapshot.

## Branches being compared

- Report branch: `codex/submission-report`, commit `187309b`.
- Review branch: `claude/review-fixes`, commit `2baeef4`.
- Shared main branch at the time of this note: `main`, commit `25b773e`.

The review branch is based directly on the report branch and adds one commit.
That commit changes code and `report/report_source.md`, but it does not commit a
new PDF, regenerated figures, or regenerated result tables. The committed PDF
is therefore still the older report. The branch must not be treated as a
finished submission until all outputs come from the same run.

## Points already agreed

Both analyses agree that:

1. The research question and broad interpretation remain valid: repeat
   candidacies are about changes in coalitions, not just a single election.
2. The network is clustered, has short paths, and its giant component is held
   together by weak ties.
3. Network position does not materially improve prediction beyond prior vote
   share and timing. This is a real negative result, not a failed project.
4. Several code corrections in the review branch should be adopted.

## Corrections accepted

The following review changes are correct and should be carried into the final
analysis:

- `R/93_coalition_overlap_null.R`: use the actual `pair_id`, not the loop row
  number.
- `R/94_recruitment_curve.R`: use `rowSums(A) > 0` for eligibility. A symmetric
  sparse matrix stores only one triangle, so `diff(A@p)` is not a valid way to
  identify all voters with a tie.
- `R/94_recruitment_curve.R`: retain the observed `T(0)` background rate in the
  independent baseline.
- `R/96_network_description.R`: use `weights = NA` when the intended distance
  is a number of steps rather than a co-vote count.
- `R/97_community_method_check.R`: do not pass co-vote counts as edge lengths
  to Girvan-Newman. Compare unweighted and inverse-weight variants, and score
  both partitions with the same weighted modularity as Louvain.
- `R/00_run_all.R`: run every script that produces a result used by the report,
  including 93 through 97.
- `R/04_build_networks.R`: it should not overwrite the output owned by 97.
- UTF-8 output encoding and portable `Rscript` instructions are acceptable
  maintenance changes.

These corrections affect exact text and output. The older report's null
overlap numbers came from a stale pair table and must be replaced.

## Results verified after rerunning the review code

The review code was run in an isolated checkout. It reproduced the coordinate
claims below.

### Corrected null overlap

On all 609 pairs with valid outcomes, after aligning attempt IDs:

- 389 pairs are testable against the activity-weighted null.
- About 58% exceed their own 95th percentile.
- About 10% have zero observed overlap.

After applying the review branch's 513-pair filter:

- 371 pairs are testable.
- 203 of 371 (54.7%) exceed their own 95th percentile.
- 37 of 371 (10.0%) have zero observed overlap.

The old report's 350 testable pairs, 29.1% above the null, and 44.0% zero
overlap must be withdrawn. Those values are not compatible with the corrected
pair table.

### Corrected membership closure

The corrected recruitment curve gives:

- `T(0) = 0.001239`
- `T(1) = 0.003427`
- `T(11) = 0.013648`
- `T(12+) = 0.031426`

The observed rate is below the independent baseline from `k = 2` through
`k = 11`, but the `12+` bin is above the baseline by a factor of about 1.16.
The report should describe diminishing returns over the observed middle range
and disclose the high-contact reversal rather than saying the curve is below
baseline at every point after `k = 2`.

### Model result

On the review branch's 513-pair sample, the group comparison and model outputs
are reproducible:

- Model observations: 513 from 409 candidates.
- Vote/timing AUC: 0.705; Brier: 0.212.
- Network-augmented AUC: 0.706; Brier: 0.211.
- Network augmentation does not improve prediction.

The old 528-pair AUC values are not wrong as a different sample, but the report
must not mix results from different samples without saying so.

## The disputed decision: what is a fragment?

The review branch defines a pair as a `fragment_pair` when either attempt has
fewer than five votes or the second attempt starts before the first ends.

The overlap-in-time criterion is defensible: a pair with a negative interval
is not a clean consecutive attempt.

The fewer-than-five-votes criterion is not automatically a data defect:

- There are 297 attempts with fewer than five votes.
- 66 of those attempts match the independent `wiki-Elec` election data.
- 15 matched attempts have exactly one vote.
- `wiki-Elec` itself contains 97 single-vote elections.

A short request can be a real early-closed RfA. Calling every short attempt a
fragment may remove genuine outcomes and change the study population.

The branch's filter removes 96 of the 609 valid pairs. It removes 27 of the 54
pairs following a prior success, leaving only 27 in that group. This is not a
minor threshold; it removes half of the group being compared.

## Why the disputed sample changes the conclusion

With all 609 pairs:

- previous effective supporter communities: median 1.65 after rejection and
  1.65 after success; not significantly different (BH-adjusted p approximately
  0.74);
- previous community bridge exposure: 2.09 versus 2.00; not significantly
  different (BH-adjusted p approximately 0.80).

Using the review branch's 513-pair sample:

- previous effective supporter communities: 1.75 versus 2.16; BH-adjusted
  p approximately 0.007;
- previous community bridge exposure: 2.52 versus 3.24; BH-adjusted p
  approximately 0.002.

The community-mix difference survives both sample choices: the divergence is
0.098 versus 0.311 in the full sample and 0.106 versus 0.402 in the filtered
sample. The claim that previously successful candidates had broader or more
central coalitions does not survive the full sample.

Therefore the report should not present the breadth/centrality difference as a
robust main result. It should report it as conditional on discarding short
attempts and explain why those attempts were discarded.

## Proposed neutral analysis policy

Use three explicitly named populations so neither branch silently chooses the
sample after looking at the outcome:

1. **All valid outcomes:** 609 consecutive pairs after the 12 outcome
   disagreements are excluded. This describes the complete repeat-candidate
   population.
2. **Chronologically valid descriptive sample:** exclude only the 17 pairs with
   a negative interval, because their attempt order is not clean. This leaves
   592 pairs.
3. **Model and strict sensitivity sample:** exclude both short attempts and
   negative-interval pairs, retaining the modelling rationale of requiring at
   least five votes. This leaves 513 pairs, the same sample used in the review
   branch's model.

The older 528-pair model sample remains a useful historical comparison, but it
still contains 15 negative-interval pairs and should not be presented as the
clean chronological model. The primary descriptive results should use 592
pairs unless the team can justify excluding short attempts before seeing the
result. The 513-pair result should appear as a sensitivity check, not as the
only result.

## Required response from the reviewer

Please reply to these points with commands, inputs and output files:

1. Explain how a short attempt can be identified as a reconstruction fragment
   when 66 such attempts match the independent election file.
2. Report the group comparison for 609, 592 and 513 pairs, not only 513.
3. State whether the breadth/centrality conclusion changes between those
   samples. If it does, label it as sample-dependent.
4. Rerun scripts 93 through 97 from a clean checkout and commit the resulting
   CSV files, figures and PDF together.
5. Show the exact R output supporting the Girvan-Newman values. The current
   branch says one value was computed in Python, so the committed R pipeline
   must reproduce it before that sentence enters the report.
6. Include the `12+` membership-closure bin and its above-baseline reversal.
7. Do not treat the existing PDF as the corrected report until it has been
   regenerated from the final outputs.

## Reply format

For each point, use:

```text
Claim:
Commit and input files:
Command:
Result:
Decision: accept / reject / needs sensitivity
```

The disagreement can then be resolved from reproducible evidence rather than
from two different prose summaries.
