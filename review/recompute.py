"""
Recompute the results affected by the review fixes, from the project's own
processed data (data/processed/*.rds), without R.

Each part first REPRODUCES the published number with the original rule, to show
the Python port matches the R code, then applies the fix.

Run from the repository root:  python recompute.py
"""
import json
import sys
import time
from itertools import combinations

import networkx as nx
import numpy as np
import pandas as pd
import scipy.sparse as sp
from scipy.stats import mannwhitneyu, norm

sys.path.insert(0, "review")
from rds import read_rds  # noqa: E402

RESULTS = {}
votes = read_rds("data/processed/votes.rds")
attempts = read_rds("data/processed/attempts_analysis.rds")
pairs_all = read_rds("data/processed/attempt_pairs.rds")
pairs_all["fragment_pair"] = (pairs_all.previous_short_attempt.astype(bool)
                              | pairs_all.next_short_attempt.astype(bool)
                              | (pairs_all.days_between < 0))
pairs = pairs_all[~pairs_all.fragment_pair].copy()


def section(t):
    print("\n" + "=" * 72 + "\n" + t + "\n" + "=" * 72)


# --------------------------------------------------------------------------
section("1. Sample after removing fragment pairs")
for o, lab in ((-1, "previously rejected"), (1, "previously successful")):
    m = pairs_all.previous_outcome == o
    print(f"  {lab:22s}: {m.sum():3d} pairs, fragments {int((m & pairs_all.fragment_pair).sum()):3d}, "
          f"kept {int((m & ~pairs_all.fragment_pair).sum()):3d}")
print(f"  total kept: {len(pairs)} of {len(pairs_all)}; candidates: {pairs.candidate.nunique()}")
print(f"  next-attempt successes among kept pairs: {int((pairs.next_outcome == 1).sum())}")
RESULTS["sample"] = dict(
    all=len(pairs_all), fragments=int(pairs_all.fragment_pair.sum()), kept=len(pairs),
    kept_rejected=int((pairs.previous_outcome == -1).sum()),
    kept_success=int((pairs.previous_outcome == 1).sum()),
    candidates=int(pairs.candidate.nunique()),
    next_success=int((pairs.next_outcome == 1).sum()))

# --------------------------------------------------------------------------
section("2. Group comparisons (Mann-Whitney-Wilcoxon, Cliff's delta, BH)")
METRICS = ["supporter_jaccard", "jaccard_excess", "new_support_share",
           "returning_support_share", "previous_support_effective_communities",
           "current_support_effective_communities", "community_breadth_change",
           "community_mix_js", "previous_supporter_mean_weighted_degree",
           "previous_supporter_mean_pagerank", "previous_supporter_mean_eigenvector",
           "previous_supporter_mean_local_clustering",
           "previous_community_bridge_exposure"]


def bh(p):
    p = np.asarray(p, float); n = len(p); o = np.argsort(p)[::-1]
    adj = np.minimum.accumulate(p[o] * n / np.arange(n, 0, -1))
    out = np.empty(n); out[o] = np.minimum(adj, 1); return out


def compare(df, by):
    rows = []
    for m in METRICS:
        f = df.loc[df[by] != 1, m].astype(float).dropna().values
        s = df.loc[df[by] == 1, m].astype(float).dropna().values
        p = mannwhitneyu(f, s, alternative="two-sided", method="asymptotic",
                         use_continuity=True).pvalue
        cd = np.mean(np.sign(s[:, None] - f[None, :]))
        rows.append(dict(metric=m, failure_n=len(f), failure_median=np.median(f),
                         success_n=len(s), success_median=np.median(s),
                         cliffs_delta=cd, p=p))
    r = pd.DataFrame(rows); r["p_bh"] = bh(r.p); return r


pub = pd.read_csv("output/results/group_comparison.csv")
chk = compare(pairs_all, "previous_outcome")
pp = pub[pub.comparison == "Previous attempt outcome"].reset_index(drop=True)
ok = np.allclose(chk.p_bh, pp.wilcoxon_p_adjusted, rtol=1e-6) and \
    np.allclose(chk.cliffs_delta, pp.cliffs_delta_success_vs_failure)
print(f"  reproduces published group_comparison.csv on all 609 pairs: {ok}")

by_prev = compare(pairs, "previous_outcome")
by_next = compare(pairs, "next_outcome")
pd.set_option("display.width", 160)
for lab, r in (("grouped by PREVIOUS result (rejected vs successful)", by_prev),
               ("grouped by NEXT result (rejected vs successful)", by_next)):
    print(f"\n  {lab}")
    print(r.assign(failure_median=r.failure_median.round(4), success_median=r.success_median.round(4),
                   cliffs_delta=r.cliffs_delta.round(3), p_bh=r.p_bh.map(lambda x: f"{x:.3g}"))
          [["metric", "failure_n", "failure_median", "success_n", "success_median", "cliffs_delta", "p_bh"]]
          .to_string(index=False))
RESULTS["by_prev"] = by_prev.to_dict("records")
RESULTS["by_next"] = by_next.to_dict("records")

# --------------------------------------------------------------------------
section("3. Outcome models (logistic regression, candidate-grouped 5-fold CV)")


def build_model_frame(df):
    cols = ["next_success", "previous_outcome", "previous_support_share", "previous_supporters",
            "previous_support_effective_communities", "previous_supporter_mean_weighted_degree",
            "days_between", "next_attempt_year"]
    d = df.dropna(subset=cols).copy()
    d["previous_success"] = (d.previous_outcome == 1).astype(float)
    d["previous_support_share_10"] = d.previous_support_share * 10
    d["log2_previous_supporters"] = np.log2(1 + d.previous_supporters.astype(float))
    d["log2_previous_supporter_weighted_degree"] = np.log2(1 + d.previous_supporter_mean_weighted_degree)
    d["log2_days_between"] = np.log2(1 + np.maximum(d.days_between, 0))
    return d


BASE = ["previous_success", "previous_support_share_10", "log2_previous_supporters",
        "log2_days_between", "year_centered"]
NET = BASE + ["previous_support_effective_communities", "log2_previous_supporter_weighted_degree"]


def glm_logit(X, y):
    X = np.column_stack([np.ones(len(X)), X]); b = np.zeros(X.shape[1])
    for _ in range(100):
        mu = 1 / (1 + np.exp(-X @ b)); W = mu * (1 - mu)
        H = X.T @ (X * W[:, None]); step = np.linalg.solve(H, X.T @ (y - mu)); b += step
        if np.max(np.abs(step)) < 1e-10: break
    se = np.sqrt(np.diag(np.linalg.inv(H)))
    return b, se


def auc(y, p):
    r = pd.Series(p).rank().values; npos = (y == 1).sum(); nneg = (y == 0).sum()
    return (r[y == 1].sum() - npos * (npos + 1) / 2) / (npos * nneg)


def evaluate(d, terms):
    pred = np.full(len(d), np.nan); base = np.full(len(d), np.nan)
    for f in range(1, 6):
        tr, te = d.fold != f, d.fold == f
        b, _ = glm_logit(d.loc[tr, terms].values.astype(float), d.loc[tr, "next_success"].values.astype(float))
        pred[te.values] = 1 / (1 + np.exp(-(b[0] + d.loc[te, terms].values.astype(float) @ b[1:])))
        base[te.values] = d.loc[tr, "next_success"].mean()
    y = d.next_success.values.astype(float)
    return auc(y, pred), np.mean((pred - y) ** 2), np.mean((base - y) ** 2)


mall = build_model_frame(pairs_all)
year_min = mall.next_attempt_year.min()   # R centres on the full complete-case sample
for d in (mall,):
    d["year_centered"] = d.next_attempt_year - year_min
# reproduce: the published model sample (short attempts excluded). Folds are
# taken from the published model_data.csv by ROW (its candidate names are
# corrupted for non-ASCII usernames, so matching by name would lose rows).
old = mall[~(mall.previous_short_attempt.astype(bool) | mall.next_short_attempt.astype(bool))].copy()
md = pd.read_csv("output/results/model_data.csv")
assert len(md) == len(old) and np.allclose(md.next_success, old.next_success)
old["fold"] = md.fold.values
folds = old.groupby("candidate").fold.first()
mall["fold"] = mall.candidate.map(folds)
b_old, _ = glm_logit(old[NET].values.astype(float), old.next_success.values.astype(float))
pub_c = pd.read_csv("output/results/model_coefficients.csv")
pub_net = pub_c[pub_c.model == "Network-augmented"].estimate.values
a_b, br_b, br0 = evaluate(old, BASE); a_n, br_n, _ = evaluate(old, NET)
print(f"  reproduces published model: n = {len(old)}, coefficients match: "
      f"{np.allclose(b_old, pub_net, atol=1e-6)}, AUC {a_b:.3f} / {a_n:.3f} (published 0.716 / 0.715)")

new = mall[~mall.fragment_pair].copy()
missing = new.fold.isna().sum()
print(f"  new sample: {len(new)} pairs from {new.candidate.nunique()} candidates (folds missing: {missing})")
a_b, br_b, br0 = evaluate(new, BASE); a_n, br_n, _ = evaluate(new, NET)
print(f"  prevalence-only Brier {br0:.3f}")
print(f"  vote shares and timing : AUC {a_b:.3f}  Brier {br_b:.3f}")
print(f"  network-augmented      : AUC {a_n:.3f}  Brier {br_n:.3f}")
a_ab, _, _ = evaluate(mall, BASE); a_an, _, _ = evaluate(mall, NET)
print(f"  all 609 complete pairs : AUC {a_ab:.3f} / {a_an:.3f}")
LAB = {"previous_success": "Prior success vs prior rejection",
       "previous_support_share_10": "Prior support share (per 10 pp)",
       "log2_previous_supporters": "Prior supporters (per doubling)",
       "log2_days_between": "Days between attempts (per doubling)",
       "year_centered": "Calendar year",
       "previous_support_effective_communities": "Prior effective supporter communities",
       "log2_previous_supporter_weighted_degree": "Supporter weighted degree (per doubling)"}
coef = []
for name, terms in (("Vote shares and timing", BASE), ("Network-augmented", NET)):
    b, se = glm_logit(new[terms].values.astype(float), new.next_success.values.astype(float))
    for t, bi, si in zip(["(Intercept)"] + terms, b, se):
        coef.append(dict(model=name, term=t, odds_ratio=np.exp(bi), lo=np.exp(bi - 1.96 * si),
                         hi=np.exp(bi + 1.96 * si), p=2 * norm.sf(abs(bi / si))))
coef = pd.DataFrame(coef)
print("\n  network-augmented model, odds ratios (95% Wald CI):")
for _, r in coef[coef.model == "Network-augmented"].iloc[1:].iterrows():
    print(f"    {LAB[r.term]:42s} {r.odds_ratio:5.2f}  ({r.lo:.2f} to {r.hi:.2f})  p = {r.p:.3g}")
RESULTS["model"] = dict(n=len(new), candidates=int(new.candidate.nunique()), auc_base=a_b, auc_net=a_n,
                        brier_base=br_b, brier_net=br_n, brier_prev=br0, auc_all_base=a_ab,
                        auc_all_net=a_an, coef=coef.to_dict("records"))

# --------------------------------------------------------------------------
section("4. Membership closure T(k) with the corrected baseline")
from tk import tk as tk_port, K_MAX
# The published recruitment_curve.csv was produced on 29 Oct, before the data
# were regenerated (31 Oct), and with an eligibility rule that depends on the
# alphabetical order of usernames (see the fix in R/94). Its reproduction is
# checked separately in check_tk_reproduction.py; here the corrected rule runs
# on the current data.
r_all = tk_port(pairs_all, votes, attempts, "full")
r = tk_port(pairs, votes, attempts, "full")
obs, n, hits, used = r["observed"], r["eligible"], r["recruited"], r["used"]

p0 = obs[0]; p = 1 - (1 - obs[1]) / (1 - p0)
base = 1 - (1 - p0) * (1 - p) ** np.arange(K_MAX + 1)
old_base = 1 - (1 - obs[1]) ** np.arange(K_MAX + 1)
print(f"  all pairs, corrected eligibility: T(0..2) = {np.round(r_all['observed'][:3], 5)}")
print(f"  without fragment pairs: pairs used {used}; T(0) = {p0:.5f}, per-connection p = {p:.5f}")
print("   k   eligible  supported  T(k)      corrected baseline  ratio   (old baseline ratio)")
rc = []
for k in range(K_MAX + 1):
    lab = f"{k}" if k < K_MAX else f"{K_MAX}+"
    ob = obs[k] / old_base[k] if old_base[k] > 0 else float("nan")
    print(f"  {lab:>3s}  {int(n[k]):8d}  {int(hits[k]):8d}   {obs[k]:.5f}   {base[k]:.5f}           {obs[k] / base[k]:5.2f}   ({ob:.2f})")
    rc.append(dict(k=lab, eligible=int(n[k]), recruited=int(hits[k]), observed=obs[k], baseline=base[k],
                   ratio=obs[k] / base[k]))
RESULTS["recruitment"] = dict(p0=p0, p=p, used=used, rows=rc)

# --------------------------------------------------------------------------
section("5. STALE FILE ONLY - coalition_overlap_null.csv as committed (29 Oct data; see null93.py for the rerun)")
nul = pd.read_csv("output/results/coalition_overlap_null.csv")
print(f"  published: {len(nul)} pairs tested, above 95th percentile {int(nul.above_null_p95.sum())}, "
      f"overlap exactly 0: {int((nul.observed_overlap == 0).sum())}")
keep = set(pairs.pair_id.astype(int))
nk = nul[nul.pair_id.isin(keep)]
print(f"  stale file filtered for fragments (NOT a valid result): {len(nk)} pairs, above 95th percentile {int(nk.above_null_p95.sum())} "
      f"({nk.above_null_p95.mean():.1%}), overlap exactly 0: {int((nk.observed_overlap == 0).sum())} "
      f"({(nk.observed_overlap == 0).mean():.1%})")
RESULTS["overlap_null"] = dict(n=len(nk), above=int(nk.above_null_p95.sum()),
                               zero=int((nk.observed_overlap == 0).sum()))

# --------------------------------------------------------------------------
section("6. Average path length, unweighted (2004 and 2005 snapshots)")


def snapshot(cut):
    h = v2[v2.year < cut]
    gk = h.attempt_id.astype(str) + "|" + h.vot.astype(str)
    codes, _ = pd.factorize(gk)
    inc = sp.csr_matrix((np.ones(len(h)), (codes, h.voter_id.values)), shape=(codes.max() + 1, n_v))
    pr = sp.triu(inc.T @ inc, k=1).tocoo()
    m = pr.data >= 2
    G = nx.Graph()
    G.add_weighted_edges_from(zip(pr.row[m], pr.col[m], pr.data[m]))
    return G


from tk import prepare
v2, vid, n_v, _ = prepare(votes, attempts)
pub_nd = pd.read_csv("output/results/network_description.csv").set_index("cutoff_year")
RESULTS["paths"] = {}
for cut in (2004, 2005):
    G = snapshot(cut)
    gc = G.subgraph(max(nx.connected_components(G), key=len))
    unw = nx.average_shortest_path_length(gc)
    wtd = nx.average_shortest_path_length(gc, weight="weight")
    print(f"  {cut}: {G.number_of_nodes()} nodes, {G.number_of_edges()} edges "
          f"(published {pub_nd.loc[cut, 'nodes']}, {pub_nd.loc[cut, 'edges']}); "
          f"diameter {nx.diameter(gc)}; mean path unweighted {unw:.3f}, "
          f"with weights as lengths {wtd:.3f} (published {pub_nd.loc[cut, 'mean_path_length']:.3f})")
    RESULTS["paths"][cut] = dict(unweighted=unw, weighted=wtd, diameter=nx.diameter(gc))

# --------------------------------------------------------------------------
section("7. Girvan-Newman on the 2004 snapshot, three ways of entering weights")
G = snapshot(2004)


def gn_best(G, length):
    H = G.copy(); best = (-1, None)
    def mve(Hh):
        eb = nx.edge_betweenness_centrality(Hh, weight=length) if length else nx.edge_betweenness_centrality(Hh)
        return max(eb, key=eb.get)
    if length == "inv":
        for u, v, d in H.edges(data=True): d["inv"] = 1 / d["weight"]
    for comm in nx.community.girvan_newman(H, most_valuable_edge=mve):
        q = nx.community.modularity(G, comm, weight="weight")
        if q > best[0]: best = (q, len(comm))
    return best


RESULTS["gn2004"] = {}
for lab, length in (("weights as lengths (published script)", "weight"), ("unweighted (course lab)", None),
                    ("inverse weight", "inv")):
    q, c = gn_best(G, length)
    print(f"  {lab:40s}: best partition {c} communities, weighted modularity {q:.3f}")
    RESULTS["gn2004"][lab] = dict(q=q, communities=c)
lv = [nx.community.modularity(G, nx.community.louvain_communities(G, weight="weight", seed=s), weight="weight")
      for s in range(20)]
print(f"  Louvain (networkx, 20 seeds)            : modularity {np.mean(lv):.3f} (range {min(lv):.3f}-{max(lv):.3f}); "
      f"published R Louvain 0.185")

json.dump(RESULTS, open("review/results.json", "w"), default=float, indent=1)
print("\nsaved results.json")
