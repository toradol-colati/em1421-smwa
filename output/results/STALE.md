# Results not yet regenerated on this branch

The code on `claude/review-fixes` changed, but R could not be run when the
fixes were made. Until `Rscript R/00_run_all.R` is run, the files below do NOT
correspond to the code, and some numbers in `report/report_source.md` will not
match them. The numbers in the report come from the checks in `review/`.

| File | Script | Why it is stale |
|---|---|---|
| `attempt_pairs.csv`, `outcome_validation.csv` | 05 | new `fragment_pair` column; UTF-8 usernames |
| `group_comparison.csv`, `model_*.csv`, `sample_flow.csv`, `analysis_summary.txt` | 06 | fragment pairs now excluded |
| `coalition_overlap_null.csv` | 93 | computed on 29 Oct data with mismatched attempt ids (see `review/check_attempt_ids.py`); fragments now excluded |
| `recruitment_curve.csv` | 94 | same data problem; eligibility and baseline fixed |
| `network_description.csv` | 96 | 2004 and 2005 average path length used weights as lengths |
| `community_method_check.csv` | 97 | Girvan-Newman weights; two variants now |
| `output/figures/fig2-4` and `report/*.pdf` | 07, PDF | built from the stale tables |

Not affected: `network_summary.csv` (04), `weak_ties_*.csv` (95),
`degree_distribution.csv` (96), `fig1_covoting_network.png`.

Delete this file after the full run.
