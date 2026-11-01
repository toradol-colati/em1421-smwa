# Repeat Requests for Adminship on Wikipedia: Coalition Change, Network Structure, and Later Success

Mihretab Worku Morka and Umberto Toraldo

EM1421 Social Media and Web Analytics, Ca' Foscari University of Venice, 31 October 2026

## Abstract

Repeat Requests for Adminship (RfAs) let an online community judge the same candidate more than once, which gives a direct view of how a support coalition changes. We analyse 198,275 votes from the Stanford SNAP wiki-RfA dataset (2003 to May 2013). After reconciling identities, dates and outcomes, we reconstruct 4,081 attempts and study 513 consecutive pairs from 409 repeat candidates, once fragments of a single request are removed. Voters are linked in a co-voting network, the projection of a voter-attempt affiliation network. Coalitions persist beyond chance: in 54% of testable pairs the returning supporters exceed what a random draw of active voters gives. Persistence is stronger before a successful attempt (61% versus 47%) and weaker after a previous success (26% versus 56%), when the supporter community mix also changes far more (median divergence 0.402 versus 0.106). The network shows triadic closure, short paths and a giant component held together by weak ties. Recruitment through the previous coalition follows membership closure with diminishing returns. A network-augmented logistic model does not improve grouped cross-validation over vote share and timing (AUC 0.706 versus 0.705).

## 1. Introduction

Wikipedia administrators receive maintenance powers, so a Request for Adminship is a public evaluation of trust as well as a technical appointment. Editors explain their records, supporters and opponents justify their votes, and earlier conduct becomes evidence. Prior work shows that promotion depends on contribution history and social context. Burke and Kraut (2008) focus on the interpretation of prior activity, while Leskovec, Huttenlocher and Kleinberg (2010) show that the process is embedded in a wider social network. Picot-Clemente, Bothorel and Jullien (2015) compare revisions with social interactions and show that neither dimension can be reduced to the other.

Research on RfAs has mostly compared different candidates at a single point or modelled one election outcome. A candidate who applies several times offers a focused alternative: the same person is observed before and after rejection or promotion, so changes in supporters and in their position in the network can be described without comparing unlike people. This separates two stories that cross-sectional data cannot: a candidate may consolidate a coalition, or rebuild support with a changing group of voters.

The project asks: among repeat RfA candidates, how do changes in voter-community composition, support-coalition overlap and network position differ between previously rejected and previously successful candidates, and how are these changes associated with the next outcome? We answer in three steps: we reconstruct repeat attempts, we measure coalition continuity and network position in historical co-voting networks, and we test whether those measures improve prediction of the later result. The design is observational, so we report associations, not causal effects.

## 2. Data and validation

The primary source is the Stanford SNAP wiki-RfA file (West et al., 2014; snap.stanford.edu/data/wiki-RfA.html, retrieved October 2026), a plain-text collection of 198,275 vote records from 2003 to May 2013. Each record gives a voter, candidate, vote direction, election result, year, timestamp and optional comment. The companion wiki-Elec file contains 2,794 elections through January 2008 and validates our reconstruction. Both are third-party reconstructions with missing dates, duplicate rows and occasional disagreements.

Because wiki-RfA has no election identifier, we reconstruct attempts from vote timestamps: a new attempt begins when the recorded result changes or when more than seven days pass without a vote. We normalise first-letter username variants, remove 1,661 voter-less records and reconcile repeated and undated votes. The final table has 195,252 votes and 4,081 attempts, with 490 repeat candidates and 609 consecutive pairs with valid outcomes.

Inferred boundaries can split one request into pieces: a late vote becomes a separate one-vote "attempt", or two "attempts" overlap in time. Such a piece has zero overlap with any coalition whatever the voters do, so we exclude every pair in which either attempt has fewer than five votes or the second starts before the first ends. This removes 96 pairs, 27 of them among the 54 that follow a success. The analysis uses 513 pairs from 409 candidates: 486 follow a rejection and 27 follow a success.

Voter-set matching links 2,175 reconstructed attempts to wiki-Elec. Outcomes agree in 2,163 cases (99.45%), and the 12 disagreements are excluded. A gap-only rule gives 4,063 attempts rather than 4,081, and matching is stable for thresholds between four and 21 days.

## 3. Network construction and methods

Nodes are voters. Two voters are joined by an undirected edge when they took the same side (support or oppose) in at least two historical attempts, and the edge weight, its strength, is the number of such agreements. This is the projection of the bipartite affiliation network of voters and attempts: each attempt is a focus in the sense of Feld (1981) that brings a temporary group together. The edge records shared electoral behaviour, not friendship or influence. Neutral votes and self-votes are excluded. Snapshots are cumulative and use only attempts before the target year, so a tie created by the predicted attempt cannot enter its predictors.

Communities are detected with weighted Louvain modularity maximisation (Blondel et al., 2008), an agglomerative method. Girvan-Newman, the divisive method based on edge betweenness, suits networks of moderate size because betweenness is recomputed after every removal; our largest snapshot has 6,228 voters and 771,356 edges. On the 2004 snapshot, with tie strength entered as closeness, Girvan-Newman reaches modularity 0.093 against 0.185 for Louvain; on the 2006 snapshot (66,698 edges) it does not finish within ten minutes. Partitions are treated as exploratory.

Supporter overlap between consecutive attempts is the neighborhood overlap of the two attempts in the affiliation network: supporters of both divided by supporters of either. We also measure returning and new supporters, the effective number of supporter communities, the Jensen-Shannon divergence between the previous and current community mixes, and the supporters' mean weighted degree, PageRank, eigenvector centrality, local clustering coefficient and community bridge exposure. Groups are compared with two-sided Mann-Whitney-Wilcoxon tests, Cliff's delta and Benjamini-Hochberg adjustment.

Every structural claim has a baseline. The clustering coefficient is compared with 20 degree-preserving rewirings and the average path length with log(n)/log(mean degree). Overlap is compared, as in a homophily test, with random supporter sets of the same size drawn from voters active that year in proportion to their activity (200 draws per pair). Following Granovetter (1973) and Onnela et al. (2007), neighborhood overlap of a random sample of 60,000 edges is measured across tie-strength percentiles against a weight-reshuffled graph, and the giant component is tracked as edges are removed weakest-first and strongest-first. Following Kossinets and Watts (2006), membership closure T(k) is the share of voters with k co-voting ties into the previous coalition who support the candidate at the next attempt; the baseline lets each tie add an independent probability p on top of the rate at k = 0.

The outcome model compares vote share and timing with the same model plus prior supporter-community breadth and supporter weighted degree. Logistic regression is evaluated with five-fold cross-validation grouped by candidate, and only variables from before the later attempt are predictors.

## 4. Results

### 4.1 Network structure

The final snapshot has 6,228 voters and 771,356 edges, all in one giant component, with mean degree 247.7; this density partly follows from the projection, so comparison with a baseline is what matters. Global transitivity is 0.357 against 0.252 after rewiring (ratio 1.42; 1.09 to 1.42 across snapshots), evidence of triadic closure beyond the degree sequence. The average path length is 2.18, a small world. Louvain finds three to seven communities; modularity rises from 0.185 in 2004 to 0.411 in 2013, and the cross-community edge share falls from 0.506 to 0.274, most of it in the final year (0.371 to 0.274), so the partition should not be read as a map of stable camps.

[[FIGURE:output/figures/fig1_covoting_network.png|Figure 1. Historical same-direction co-voting network. The left panel aggregates the final snapshot into detected communities; node size is community size and edges show cross-community co-voting. The right panel traces modularity and the cross-community edge share over cumulative snapshots.]]

Tie strength follows the strength of weak ties. In 2008, mean neighborhood overlap rises from 0.195 in the weakest bin to 0.424 in the strongest, while the reshuffled graph stays near 0.256; in 2013 the values are 0.181, 0.398 and about 0.237. Strong ties sit inside closed groups, and weak ties behave as "almost" local bridges (Easley & Kleinberg, 2010). Removing weak ties first shrinks the giant component steadily to below half after 78% of edges are removed; removing strong ties first leaves over 90% of it connected after 90% removal. The breakdown is gradual, not the abrupt collapse Onnela et al. report.

Coalitions persist beyond chance. Of 371 pairs testable against the random baseline, 54% exceed their own 95th percentile and only 10% have zero overlap. Membership closure is clear but sublinear: the support rate rises from 0.0012 with no tie into the previous coalition to 0.0034 with one tie and 0.0137 with eleven. From k = 2 to 11 it stays below the independent baseline (ratios 0.54 to 0.87), so each additional tie adds less: the diminishing returns that Easley and Kleinberg (2010) describe for membership closure.

### 4.2 Previous outcome and coalition change

After a success, the next coalition is reassembled across communities. The Jensen-Shannon divergence between community mixes is 0.402 after success against 0.106 after rejection (Cliff's delta = 0.532, BH-adjusted p < 0.001). Overlap beyond chance is rarer after success (26% against 56% of tested pairs, Fisher p = 0.004), although the median raw overlap (0.023 against 0.048) does not differ significantly with only 27 pairs (p = 0.23). The earlier coalitions of previously successful candidates were broader and more central: 2.16 against 1.75 effective communities (p = 0.007), with higher eigenvector centrality (delta = 0.553), PageRank (0.518) and community bridge exposure (0.391, all p < 0.01). Figure 2 shows the pair-level overlap.

[[FIGURE:output/figures/fig2_supporter_overlap.png|Figure 2. Pair-level supporter overlap relative to an active-voter expectation, grouped by the previous result and coloured by the later result. Each point is one consecutive pair; boxes show medians and interquartile ranges.]]

Figure 3 shows that the change in coalition breadth does not separate the groups (p = 0.595): what differs is the mix, not the number, of communities.

[[FIGURE:output/figures/fig3_community_diversity.png|Figure 3. Change in the effective number of supporter communities between consecutive requests, grouped by the previous result and coloured by the later result.]]

### 4.3 Later outcome and prediction

Grouped by the later result, successful attempts keep more of the earlier coalition: median overlap 0.074 against 0.023 (delta = 0.355, p < 0.001), overlap beyond chance in 61% against 47% of pairs (p = 0.007), more effective supporter communities (2.54 against 1.99) and less reshuffling (divergence 0.088 against 0.137). These describe the attempt being judged, so they cannot forecast it without leakage.

The pre-attempt models show why the distinction matters. The prevalence-only Brier score is 0.241. Vote share and timing reach AUC 0.705 and Brier 0.212; adding prior community breadth and supporter weighted degree gives AUC 0.706 and Brier 0.211. Figure 4 reports the odds ratios. Prior support share has an odds ratio of 1.53 per ten percentage points (95% CI 1.24 to 1.90). Effective supporter communities have 1.27, with an interval that includes 1 (0.91 to 1.77), and weighted degree is neutral (0.99, 0.92 to 1.07). Holding support share fixed, a previous success is associated with much lower odds of success at the next request (0.11, 0.04 to 0.31).

[[FIGURE:output/figures/fig4_model_coefficients.png|Figure 4. Odds ratios and 95% confidence intervals from the network-augmented logistic model. The subtitle reports grouped cross-validated AUC for the model without and with network measures.]]

## 5. Discussion

Repeat candidates do not start from zero: in most pairs a core of supporters returns beyond chance, and that core is larger before success. The previous result changes how the coalition is rebuilt. After a rejection, the coalition is mostly carried over. After a success, it is reassembled from a different mix of communities, even though the earlier coalition was broader and more central. The data do not say why these candidates returned after promotion, and with 27 pairs this group remains small.

Network position adds description, not prediction. Once vote share and timing are known, prior community breadth and supporter centrality do not improve held-out prediction, so outcomes are not a simple function of proximity to central voters. The structure explains how support spreads: triadic closure and strong ties bind voters into groups, weak ties connect the groups, and recruitment through an existing coalition shows the diminishing returns of membership closure. Connection may make support visible, but it does not determine approval (Burke & Kraut, 2008; Picot-Clemente et al., 2015).

## 6. Limitations

The study is observational: a coalition change may reflect campaigning, changed voter behaviour or selection into a later attempt. Co-voting is a behavioural proxy, not friendship or influence, and vote comments are not used. Attempt boundaries are inferred; removing fragments changes the overlap comparison by previous result from significant to not significant, so any residual fragments would bias overlap after success downward. The 27 pairs after success limit precision for that group and make its conditional coefficient specification-sensitive. External validation ends in January 2008. Louvain partitions are exploratory and could inflate the community-mix divergence. The data end in 2013.

## 7. Conclusion

Repeat RfAs combine continuity and turnover. Most coalitions keep a returning core beyond chance, especially before success, while candidates who return after a success face a reshuffled mix of supporter communities and lower odds of a second success. The network shows triadic closure, weak ties holding the giant component together, and membership closure with diminishing returns, but prior network position does not improve prediction beyond vote share and timing.

## Author contributions

Umberto Toraldo led data preparation, identity cleanup, attempt reconstruction and external outcome validation. Mihretab Worku Morka led network construction, coalition measures, statistical modelling and figures. Both authors jointly developed the research question, reviewed the literature, interpreted the results and wrote the report. Both will present the project and answer questions in the oral discussion.

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
