"""Port of R/93_coalition_overlap_null.R on the current processed data.
Monte Carlo (B = 200 per pair); numbers differ from R only by random draws."""
import sys

import numpy as np
import pandas as pd

sys.path.insert(0, "review")
from rds import read_rds  # noqa: E402

B = 200
DATA = sys.argv[1] if len(sys.argv) > 1 else "data/processed"   # e.g. an old checkout
votes = read_rds(f"{DATA}/votes.rds")
attempts = read_rds(f"{DATA}/attempts_analysis.rds")
pairs = read_rds(f"{DATA}/attempt_pairs.rds")
pairs["fragment_pair"] = (pairs.previous_short_attempt.astype(bool) | pairs.next_short_attempt.astype(bool)
                          | (pairs.days_between < 0))

v2 = votes[votes.attempt_id.notna() & ~votes.self_vote.astype(bool)].copy()
v2["year"] = v2.attempt_id.map(attempts.set_index("attempt_id").year_from_date)
sup = v2[v2.vot == 1].groupby("attempt_id").src.apply(lambda s: set(s.unique())).to_dict()
act = v2.groupby(["year", "src"]).size()

rng = np.random.default_rng(93)
rows = []
for _, r in pairs.iterrows():
    sp_, sn = sup.get(r.previous_attempt_id, set()), sup.get(r.next_attempt_id, set())
    if len(sp_) < 3 or len(sn) < 3:
        continue
    pool = act.loc[int(r.next_attempt_year)]
    pool = pool[pool.index != r.candidate]
    if len(pool) <= len(sn):
        continue
    obs = len(sp_ & sn) / len(sp_ | sn)
    names = pool.index.values; prob = pool.values / pool.values.sum()
    nulls = np.empty(B)
    for b in range(B):
        d = set(rng.choice(names, size=len(sn), replace=False, p=prob))
        nulls[b] = len(sp_ & d) / len(sp_ | d)
    rows.append(dict(pair_id=int(r.pair_id), previous_outcome=int(r.previous_outcome),
                     next_outcome=int(r.next_outcome), fragment=bool(r.fragment_pair), observed=obs,
                     null_mean=nulls.mean(), above_p95=obs > np.quantile(nulls, 0.95)))
out = pd.DataFrame(rows)
if len(sys.argv) == 1:
    out.to_csv("review/null93_current.csv", index=False)


def rep(o, lab):
    print(f"  {lab:34s} n = {len(o):3d}  above own 95th percentile {o.above_p95.mean():6.1%}  "
          f"overlap exactly 0 {(o.observed == 0).mean():6.1%}  median observed {o.observed.median():.3f}  "
          f"median null {o.null_mean.median():.3f}")


rep(out, f"all pairs ({DATA})")
k = out[~out.fragment]
rep(k, "without fragment pairs")
for o, lab in ((-1, "  previously rejected"), (1, "  previously successful")):
    rep(k[k.previous_outcome == o], lab)
for o, lab in ((-1, "  next rejected"), (1, "  next successful")):
    rep(k[k.next_outcome == o], lab)
