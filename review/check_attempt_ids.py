"""Show why the committed coalition_overlap_null.csv and recruitment_curve.csv
are stale: in the data they were computed on (commit 4a9a95b, 29 Oct), the
attempt ids in attempt_pairs.rds do not match those in votes.rds.

Run from the repository root:  python review/check_attempt_ids.py
"""
import os
import subprocess
import sys

sys.path.insert(0, "review")
from rds import read_rds  # noqa: E402

OLD = "4a9a95b"
old_dir = os.path.join("review", "_old_data")
os.makedirs(old_dir, exist_ok=True)
for f in ("votes", "attempts_analysis", "attempt_pairs"):
    with open(os.path.join(old_dir, f + ".rds"), "wb") as out:
        out.write(subprocess.check_output(["git", "show", f"{OLD}:data/processed/{f}.rds"]))

for label, d in (("data at 4a9a95b (29 Oct, used by 93 and 94)", old_dir),
                 ("current data", "data/processed")):
    v = read_rds(f"{d}/votes.rds"); p = read_rds(f"{d}/attempt_pairs.rds")
    sup = v[v.vot == 1].groupby("attempt_id").src.nunique()
    ok = (p.previous_attempt_id.map(sup).fillna(0).astype(int) == p.previous_supporters.astype(int)).mean()
    print(f"{label:45s}: pairs whose stored supporter count matches votes.rds by attempt id = {ok:.1%}")
print(f"\nTo reproduce the published null-test numbers (350 pairs, 29.1%, 44.0%):\n"
      f"  python review/null93.py {old_dir}")
