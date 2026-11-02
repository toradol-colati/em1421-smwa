# Repeat Requests for Adminship on Wikipedia: Coalition Change, Network Structure, and Later Success

Mihretab Worku Morka and Umberto Toraldo

EM1421 Social Media and Web Analytics, Ca' Foscari University of Venice, November 2026

## Abstract

Repeat Requests for Adminship (RfAs) let an online community judge the same candidate more than once, which gives a direct view of how a support coalition changes. We analyse 198,275 votes from the Stanford SNAP wiki-RfA dataset (2003 to May 2013), reconstruct 4,081 attempts and study 609 consecutive pairs from 490 repeat candidates, reporting every comparison in three named samples. Voters are linked in a co-voting network, the projection of a voter-attempt affiliation network. Coalitions persist beyond chance: in 54% of testable pairs the returning supporters exceed a random draw of active voters. This persistence is rarer after a previous success (23% against 56% of pairs) and more common before a successful attempt (62% against 46%), and after a success the supporter community mix changes far more (median divergence 0.311 against 0.103). These results hold in all three samples; whether earlier coalitions of previously successful candidates were broader or more central depends on how short attempts are treated. The network shows triadic closure, short paths and a giant component held together by weak ties, and recruitment through the previous coalition follows membership closure with diminishing returns. Network measures do not improve grouped cross-validated prediction over vote share and timing (AUC 0.698 against 0.697).

## 1. Introduction

Wikipedia administrators receive maintenance powers, so a Request for Adminship is a public evaluation of trust as well as a technical appointment. Editors explain their records, supporters and opponents justify their votes, and earlier conduct becomes evidence. Prior work shows that promotion depends on contribution history and social context. Burke and Kraut (2008) focus on the interpretation of prior activity, while Leskovec, Huttenlocher and Kleinberg (2010) show that the process is embedded in a wider social network. Picot-Clemente, Bothorel and Jullien (2015) compare revisions with social interactions and show that neither dimension can be reduced to the other.

Research on RfAs has mostly compared different candidates at a single point or modelled one election outcome. A candidate who applies several times offers a focused alternative: the same person is observed before and after rejection or promotion, so changes in supporters and in their position in the network can be described without comparing unlike people. This separates two stories that cross-sectional data cannot: a candidate may consolidate a coalition, or rebuild support with a changing group of voters.

The project asks: among repeat RfA candidates, how do changes in voter-community composition, support-coalition overlap and network position differ between previously rejected and previously successful candidates, and how are these changes associated with the next outcome? We reconstruct repeat attempts, measure coalition continuity and network position in historical co-voting networks, and test whether those measures improve prediction of the later result. The design is observational, so we report associations, not causal effects.

## 2. Data and validation

The primary source is the Stanford SNAP wiki-RfA file (West et al., 2014; snap.stanford.edu/data/wiki-RfA.html, retrieved October 2026): 198,275 vote records from 2003 to May 2013, each with voter, candidate, vote direction, result, year, timestamp and optional comment. The companion wiki-Elec file contains 2,794 elections through January 2008 and validates our reconstruction. Both are third-party reconstructions with missing dates and duplicate rows.

Because wiki-RfA has no election identifier, attempts are reconstructed from vote timestamps: a new attempt begins when the recorded result changes or more than seven days pass without a vote. After normalising usernames, removing 1,661 voter-less records and reconciling repeated and undated votes, the table has 195,252 votes and 4,081 attempts, with 490 repeat candidates and 609 consecutive pairs with valid outcomes. Voter-set matching links 2,175 attempts to wiki-Elec; outcomes agree in 2,163 (99.45%), and the 12 disagreements are excluded.

Two kinds of pair need a decision. In 17 pairs the second attempt starts before the first ends, so they are not consecutive requests. In 79 further pairs one attempt has fewer than five votes. Short attempts recorded as rejections are often real early-closed requests: 66 of 241 match a wiki-Elec election. None of the 56 short attempts recorded as successes does, and the 25 short pairs that follow a success are all followed by a second success a median of 16 days later, a pattern consistent with one promotion split in two. Every comparison is therefore reported for three samples: all 609 valid pairs; the chronological sample of 592 pairs (main descriptive results), which drops the 17 overlapping pairs; and the strict sample of 513 pairs from 409 candidates, which also drops short attempts and is used for the outcome model. Only 27 pairs follow a success in the strict sample, against 52 in the chronological one.

## 3. Network construction and methods

Nodes are voters. Two voters are joined by an undirected edge when they took the same side in at least two historical attempts, and the edge weight, its strength, counts those agreements. This is the projection of the bipartite affiliation network of voters and attempts: each attempt is a focus (Feld, 1981) that brings a temporary group together. The edge records shared electoral behaviour, not friendship or influence. Neutral votes and self-votes are excluded, and cumulative snapshots use only attempts before the target year, so a tie created by the predicted attempt cannot enter its predictors.

Communities are detected with weighted Louvain modularity maximisation (Blondel et al., 2008), an agglomerative method. Girvan-Newman, the divisive method based on edge betweenness, suits networks of moderate size because betweenness is recomputed after every removal. On the 2004 snapshot it reaches modularity 0.093 with tie strength entered as closeness and 0.017 unweighted, against 0.185 for Louvain; on 2005 the unweighted version returns 85 communities with modularity 0.000 after about four minutes, and the other runs on 2005 and 2006 do not finish within ten minutes. Partitions are treated as exploratory.

Supporter overlap between consecutive attempts is the neighborhood overlap of the two attempts in the affiliation network: supporters of both divided by supporters of either. We also measure returning supporters, the effective number of supporter communities, the Jensen-Shannon divergence between community mixes, and the supporters' mean weighted degree, PageRank, eigenvector centrality, local clustering coefficient and community bridge exposure. Groups are compared with two-sided Mann-Whitney-Wilcoxon tests, Cliff's delta and Benjamini-Hochberg adjustment; shares of pairs above the random baseline are compared with Fisher's exact test.

Every structural claim has a baseline. The clustering coefficient is compared with 20 degree-preserving rewirings and the average path length with log(n)/log(mean degree). Overlap is compared, as in a homophily test, with random supporter sets of the same size drawn from voters active that year in proportion to their activity (200 draws per pair). Following Granovetter (1973) and Onnela et al. (2007), neighborhood overlap of a random sample of 60,000 edges is measured across tie-strength percentiles against a weight-reshuffled graph, and the giant component is tracked as edges are removed weakest-first and strongest-first. Following Kossinets and Watts (2006), membership closure T(k) is the share of voters with k co-voting ties into the previous coalition who support the candidate next time; the baseline lets each tie add an independent probability p on top of the rate at k = 0.

The outcome model compares vote share and timing with the same model plus prior supporter-community breadth and supporter weighted degree, using logistic regression with five-fold cross-validation grouped by candidate and only variables from before the later attempt.

## 4. Results

### 4.1 Network structure

The final snapshot has 6,228 voters and 771,356 edges in one giant component, with mean degree 247.7; this density partly follows from the projection, so baselines matter. Global transitivity is 0.357 against 0.252 after rewiring (ratio 1.42; 1.09 to 1.42 across snapshots), evidence of triadic closure beyond the degree sequence. The average path length is 2.18, a small world. Louvain finds three to six communities; modularity rises from 0.185 in 2004 to 0.413 in 2013, and the cross-community edge share falls from 0.506 to 0.348.

[[FIGURE:output/figures/fig1_covoting_network.png|Figure 1. Historical same-direction co-voting network. The left panel aggregates the final snapshot into detected communities; node size is community size and edges show cross-community co-voting. The right panel traces modularity and the cross-community edge share over cumulative snapshots.]]

Tie strength follows the strength of weak ties. In 2008, mean neighborhood overlap rises from 0.195 in the weakest bin to 0.423 in the strongest, while the reshuffled graph stays near 0.257; in 2013 the values are 0.181, 0.396 and 0.237. Strong ties sit inside closed groups, and weak ties behave as "almost" local bridges (Easley & Kleinberg, 2010). Removing weak ties first shrinks the giant component steadily, to 74% of voters at half the edges and below half after 78%; removing strong ties first leaves 93% connected after 90% removal. The breakdown is gradual rather than the abrupt collapse Onnela et al. report.

In the chronological sample, 54% of the 374 testable pairs exceed their own 95th percentile under the random baseline and 11% have zero overlap (54% and 10% in the strict sample). Membership closure is clear but sublinear: the support rate rises from 0.0013 with no tie into the previous coalition to 0.0036 with one and 0.0136 with eleven. From k = 2 to 11 it stays below the independent baseline (ratios 0.52 to 0.84), the diminishing returns that Easley and Kleinberg (2010) describe for membership closure. The pooled 12+ bin reverses this, at 1.12 times the baseline (1.10 to 1.16 across samples).

### 4.2 Previous outcome and coalition change

Three results hold in every sample. After a success, the next coalition is reassembled across communities: the Jensen-Shannon divergence between community mixes is 0.311 against 0.103 (Cliff's delta = 0.29, BH-adjusted p = 0.002; strict sample 0.435 against 0.103). Overlap beyond chance is rarer after a success: 23% of tested pairs against 56% (Fisher p < 0.001; strict 26% against 56%, p = 0.002). Supporter PageRank is somewhat higher after a success (p = 0.035; p < 0.001 in the strict sample). Figure 2 shows the pair-level overlap.

[[FIGURE:output/figures/fig2_supporter_overlap.png|Figure 2. Pair-level supporter overlap relative to an active-voter expectation in the chronological sample, grouped by the previous result and coloured by the later result. Each point is one consecutive pair; boxes show medians and interquartile ranges.]]

Other results are sample-dependent. Lower raw overlap after a success (median 0.000 against 0.042, p < 0.001) holds with all 609 or 592 pairs but not in the strict sample (0.023 against 0.048, p = 0.23). Conversely, broader and more central earlier coalitions after a success appear only in the strict sample: 2.20 against 1.76 effective communities (p = 0.017) and higher eigenvector centrality (delta = 0.55, p < 0.001), with no difference in the other two samples (p > 0.1). The change in coalition breadth (Figure 3) does not separate the groups in any sample (p ≥ 0.75).

[[FIGURE:output/figures/fig3_community_diversity.png|Figure 3. Change in the effective number of supporter communities between consecutive requests in the chronological sample, grouped by the previous result and coloured by the later result.]]

### 4.3 Later outcome and prediction

Grouped by the later result, and in all three samples, successful attempts keep more of the earlier coalition: median overlap 0.059 against 0.016 (delta = 0.28, p < 0.001), overlap beyond chance in 62% against 46% of pairs (p = 0.003), more effective supporter communities (2.48 against 1.92) and less reshuffling (divergence 0.094 against 0.137). These describe the attempt being judged, so they cannot forecast it without leakage.

The pre-attempt models are fitted on the strict sample. The prevalence-only Brier score is 0.241. Vote share and timing reach AUC 0.697 and Brier 0.215; adding prior community breadth and supporter weighted degree gives AUC 0.698 and Brier 0.215. The same comparison gives 0.741 against 0.743 with 592 pairs and 0.751 against 0.752 with 609. Figure 4 reports the odds ratios. Prior support share has 1.53 per ten percentage points (95% CI 1.24 to 1.90); effective supporter communities 1.30, with an interval that includes 1 (0.93 to 1.82); weighted degree 0.99 (0.92 to 1.07). Holding support share fixed, a previous success is associated with much lower odds of success at the next request (0.11, 0.04 to 0.32).

[[FIGURE:output/figures/fig4_model_coefficients.png|Figure 4. Odds ratios and 95% confidence intervals from the network-augmented logistic model on the strict sample (513 pairs). The subtitle reports grouped cross-validated AUC for the model without and with network measures.]]

## 5. Discussion

Repeat candidates do not start from zero: in most pairs a core of supporters returns beyond chance, and that core is larger before success. The previous result changes how the coalition is rebuilt. After a rejection, the coalition is largely carried over; after a success, it is reassembled from a different mix of communities, and returning support beyond chance is rare. Whether these candidates' earlier coalitions were broader or more central cannot be settled with these data, because the answer depends on whether short attempts after a success are treated as real requests. The data also do not say why these candidates returned after promotion.

Network position adds description, not prediction. Once vote share and timing are known, prior community breadth and supporter centrality do not improve held-out prediction in any sample, so outcomes are not a simple function of proximity to central voters. The structure explains how support spreads: triadic closure and strong ties bind voters into groups, weak ties connect the groups, and recruitment through an existing coalition shows the diminishing returns of membership closure except at the highest contact counts. Connection may make support visible, but it does not determine approval (Burke & Kraut, 2008; Picot-Clemente et al., 2015).

## 6. Limitations

The study is observational: a coalition change may reflect campaigning, changed voter behaviour or selection into a later attempt. Co-voting is a behavioural proxy, not friendship or influence, and vote comments are not used. Attempt boundaries are inferred, and the treatment of short attempts changes two comparisons by previous result, overlap and earlier-coalition breadth, in opposite directions; both are therefore reported as sample-dependent. Only 27 to 54 pairs follow a success, which limits precision and makes the prior-success coefficient specification-sensitive. External validation ends in January 2008, Louvain partitions depend on the random seed and are exploratory, and the data end in 2013.

## 7. Conclusion

Repeat RfAs combine continuity and turnover. Most coalitions keep a returning core beyond chance, especially before success, while candidates who return after a success face a reshuffled mix of supporter communities, little returning support beyond chance and lower odds of a second success. The network shows triadic closure, weak ties holding the giant component together, and membership closure with diminishing returns, but prior network position does not improve prediction beyond vote share and timing.

## Author contributions

Umberto Toraldo led data preparation, identity cleanup, attempt reconstruction and external outcome validation. Mihretab Worku Morka led network construction, coalition measures, statistical modelling and figures. Both authors jointly developed the research question, reviewed the literature, interpreted the results and wrote the report.

## References

Blondel, V. D., Guillaume, J.-L., Lambiotte, R., & Lefebvre, E. (2008). Fast unfolding of communities in large networks. Journal of Statistical Mechanics: Theory and Experiment, 2008(10), P10008. https://doi.org/10.1088/1742-5468/2008/10/P10008

Burke, M., & Kraut, R. (2008). Mopping up: Modeling Wikipedia promotion decisions. In Proceedings of the 2008 ACM Conference on Computer Supported Cooperative Work (pp. 27-36). ACM. https://doi.org/10.1145/1460563.1460571

Easley, D., & Kleinberg, J. (2010). Networks, crowds, and markets: Reasoning about a highly connected world. Cambridge University Press.

Feld, S. L. (1981). The focused organization of social ties. American Journal of Sociology, 86(5), 1015-1035. https://doi.org/10.1086/227352

Granovetter, M. S. (1973). The strength of weak ties. American Journal of Sociology, 78(6), 1360-1380. https://doi.org/10.1086/225469

Kossinets, G., & Watts, D. J. (2006). Empirical analysis of an evolving social network. Science, 311(5757), 88-90. https://doi.org/10.1126/science.1116869

Leskovec, J., Huttenlocher, D., & Kleinberg, J. (2010). Governance in social media: A case study of the Wikipedia promotion process. Proceedings of the International AAAI Conference on Web and Social Media, 4(1), 98-105. https://doi.org/10.1609/icwsm.v4i1.14013

Onnela, J.-P., Saramäki, J., Hyvönen, J., Szabó, G., Lazer, D., Kaski, K., Kertész, J., & Barabási, A.-L. (2007). Structure and tie strengths in mobile communication networks. Proceedings of the National Academy of Sciences, 104(18), 7332-7336. https://doi.org/10.1073/pnas.0610245104

Picot-Clemente, R., Bothorel, C., & Jullien, N. (2015). Social interactions vs revisions, what is important for promotion in Wikipedia? In Proceedings of the 2015 IEEE/ACM International Conference on Advances in Social Networks Analysis and Mining (pp. 888-893). ACM. https://doi.org/10.1145/2808797.2810063

West, R., Paskov, H. S., Leskovec, J., & Potts, C. (2014). Exploiting social network structure for person-to-person sentiment analysis. Transactions of the Association for Computational Linguistics, 2, 297-310. https://doi.org/10.1162/tacl_a_00184
