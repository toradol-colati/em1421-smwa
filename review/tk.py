"""Port of R/94_recruitment_curve.R (T(k), membership closure)."""
import numpy as np
import pandas as pd
import scipy.sparse as sp

K_MAX = 12


def prepare(votes, attempts):
    v2 = votes[votes.attempt_id.notna() & votes.vot.isin([-1, 1]) & ~votes.self_vote.astype(bool)].copy()
    yr = attempts.set_index("attempt_id").year_from_date
    v2["year"] = v2.attempt_id.map(yr).astype(int)
    all_voters = np.array(sorted(v2.src.unique()))
    vid = {v: i for i, v in enumerate(all_voters)}
    v2["voter_id"] = v2.src.map(vid)
    return v2, vid, len(all_voters), yr.to_dict()


def tk(pairs, votes, attempts, tie_rule="full"):
    v2, vid, n_v, ayear = prepare(votes, attempts)
    cache = {}

    def adjacency_before(y):
        if y in cache:
            return cache[y]
        h = v2[v2.year < y]
        if len(h) == 0:
            cache[y] = None
            return None
        gk = h.attempt_id.astype(str) + "|" + h.vot.astype(str)
        codes, _ = pd.factorize(gk)
        inc = sp.csr_matrix((np.ones(len(h)), (codes, h.voter_id.values)), shape=(codes.max() + 1, n_v))
        pr = (inc.T @ inc).tocsr()
        pr.data[pr.data < 2] = 0
        pr.setdiag(0)
        pr.eliminate_zeros()
        pr.data[:] = 1
        cache[y] = pr
        return pr

    sup = v2[v2.vot == 1].groupby("attempt_id").voter_id.apply(np.array).to_dict()
    allv = v2.groupby("attempt_id").voter_id.apply(np.array).to_dict()
    hits = np.zeros(K_MAX + 1); n = np.zeros(K_MAX + 1); used = 0
    for _, r in pairs.iterrows():
        A = adjacency_before(int(ayear[r.previous_attempt_id]))
        if A is None:
            continue
        s_prev = sup.get(r.previous_attempt_id, np.array([], int))
        if len(s_prev) == 0:
            continue
        s = np.zeros(n_v); s[s_prev] = 1
        k_all = A @ s
        if tie_rule == "full":
            has_tie = np.diff(A.indptr) > 0
        else:  # R dsCMatrix stores the upper triangle: column j holds rows i <= j
            has_tie = np.diff(sp.triu(A).tocsc().indptr) > 0
        excl = set(allv.get(r.previous_attempt_id, []))
        if r.candidate in vid:
            excl.add(vid[r.candidate])
        elig = np.array([i for i in np.flatnonzero(has_tie) if i not in excl], dtype=int)
        if len(elig) == 0:
            continue
        y = np.isin(elig, sup.get(r.next_attempt_id, np.array([], int))).astype(int)
        k = np.minimum(k_all[elig], K_MAX).astype(int)
        np.add.at(hits, k, y); np.add.at(n, k, 1); used += 1
    return dict(observed=hits / n, eligible=n, recruited=hits, used=used)
