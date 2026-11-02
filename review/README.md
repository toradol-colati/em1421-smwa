# Review checks (Python)

**Superseded by the R run.** All numbers in the report now come from
`Rscript R/00_run_all.R` (log: `output/logs/run_all_log.txt`). These Python
checks were written before R was available. The R run reproduced their counts
exactly (371 null-testable strict pairs, the full T(k) table, path lengths 1.92
and 1.99, Girvan-Newman 0.093 and 0.017 on 2004). The model AUC differs (Python
0.705, R 0.697) because R assigns cross-validation folds at random, while the
Python check reused the earlier folds; the R value is the reported one.

These scripts recompute, from the project's own `data/processed/*.rds`, the
results changed by the fixes on this branch. They exist because R was not
available when the fixes were made. They are evidence, not part of the
pipeline: the R scripts remain the source of the final results.

Each check first reproduces a published number with the original rule, then
applies the fix.

Run from the repository root (Python 3 with numpy, pandas, scipy, networkx):

```bash
python review/check_attempt_ids.py   # why 93 and 94 outputs are stale
python review/null93.py              # script 93 on current data
python review/recompute.py           # everything else
```

| Check | Reproduces the published value | Fixed result |
|---|---|---|
| Group comparisons (06) | exactly, all 26 tests | `recompute_output.txt` §2 |
| Outcome model and CV (06) | exactly (AUC 0.716 / 0.715) | §3 |
| Overlap null (93) | exactly on the 29 Oct data (350 pairs, 29.1%, 44.0%) | `null93_output.txt`: 371 pairs, 53.9%, 10.0% |
| Membership closure T(k) (94) | within 0.01% (R's locale-dependent name sort) | §4 |
| Path length 2004, 2005 (96) | exactly (4.510, 4.536 with weights as lengths) | §6: 1.919, 1.990 |
| Girvan-Newman 2004 (97) | n/a | §7 |

Files: `rds.py` reads `.rds` files without R; `tk.py` ports script 94;
`null93.py` ports script 93 (Monte Carlo: counts are exact, percentages vary
slightly with the random draws); `recompute.py` covers the rest.

The number of pairs testable in the null test (371) does not depend on the
random draws, so `Rscript R/93_coalition_overlap_null.R` must report exactly
371. Filtering the stale `coalition_overlap_null.csv` instead gives 296, which
is not a valid result.
