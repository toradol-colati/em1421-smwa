# Repeat Requests for Adminship on Wikipedia: Coalition Change, Network Structure, and Later Success

Mihretab Worku Morka and Umberto Toraldo

EM1421 Social Media and Web Analytics, Ca' Foscari University of Venice, 31 October 2026

## Abstract

Repeat Requests for Adminship (RfAs) let an online community reconsider the same candidate and therefore provide a direct view of coalition change. We analyse 198,275 votes from the Stanford SNAP wiki-RfA dataset, covering 2003 to May 2013. After reconciling identities, dates and outcomes, we reconstruct 4,081 attempts and study 609 consecutive pairs among 490 repeat candidates. Directed edges capture votes; a separate historical co-voting network connects users who repeatedly took the same side. Prior success is associated with much lower returning-supporter overlap (median 0.000 versus 0.044) and greater community reshuffling (0.311 versus 0.098), but not with broader coalitions. The network is clustered, has short paths and fragments rapidly when weak ties are removed. A network-augmented logistic model does not improve grouped cross-validation over vote share and timing (AUC 0.715 versus 0.716). Repeat RfAs are therefore characterised more by coalition rebuilding than by consolidation, while network position adds interpretation but not material forecasting value.

## 1. Introduction

Wikipedia administrators receive maintenance powers, so a Request for Adminship is a public evaluation of trust as well as a technical appointment. Editors explain their records, supporters and opponents justify their votes, and earlier conduct becomes evidence. Prior work shows that promotion depends on contribution history and social context. Burke and Kraut (2008) focus on the interpretation of prior activity, while Leskovec, Huttenlocher and Kleinberg (2010) show that the process is embedded in a wider social network. Picot-Clemente, Bothorel and Jullien (2015) compare revisions with social interactions and show that neither dimension can be reduced to the other.

Research on RfAs has mostly compared different candidates at a single point or modelled one election outcome. A candidate who applies several times offers a focused alternative. The same person is observed before and after rejection or promotion, so changes in supporters, opponents and community position can be described without comparing unlike people. This distinguishes two stories that cross-sectional data cannot separate: a candidate may consolidate a coalition, or repeatedly rebuild support with a changing group of voters.

The project asks: among repeat RfA candidates, how do changes in voter-community composition, support-coalition overlap and network position differ between previously rejected and previously successful candidates, and how are these changes associated with the next outcome? We answer in three steps. First, we reconstruct repeat attempts and compare consecutive pairs. Second, we measure coalition continuity, community reshuffling and network position in historical voter networks. Third, we test whether those measures improve prediction of the later result. The design is observational. We report associations rather than causal effects, and we retain a negative predictive result rather than interpreting network position as necessary for promotion.

## 2. Data and validation

The primary source is the Stanford SNAP wiki-RfA file (West et al., 2014), a compressed plain-text collection of 198,275 vote records from 2003 to May 2013. Each record identifies a voter, candidate, vote direction, election result, year, timestamp and optional comment. The companion wiki-Elec file contains 2,794 separated elections through January 2008 and validates our reconstructed attempts. Both are third-party reconstructions, so they contain missing dates, duplicate rows and occasional disagreements.

Because wiki-RfA has no election identifier, we reconstruct attempts from vote timestamps. A new attempt begins when the recorded result changes or when more than seven days pass without a vote. We normalise whitespace and first-letter username variants, remove 1,661 voter-less records and reconcile repeated and undated votes. The final table contains 195,252 votes and 4,081 attempts. It includes 490 repeat candidates and 621 consecutive pairs, of which 609 have valid outcomes: 555 follow a rejection and 54 follow a success. After excluding attempts with fewer than five votes from the inferential model, 528 pairs from 424 candidates remain.

Voter-set matching links 2,175 reconstructed attempts to wiki-Elec. Outcomes agree in 2,163 cases, or 99.45%, and the 12 high-confidence disagreements are excluded from outcome analysis. Repeating the reconstruction with a gap-only rule produces 4,063 attempts rather than 4,081. Matching is also stable between four and 21 days. These checks do not make the reconstruction error-free, but they bound its main uncertainty and show that the exact threshold is not driving the findings.

## 3. Network construction and methods

We use two complementary networks. In the voting network, nodes are voters and candidates; a signed edge runs from voter to candidate and records support or opposition. In the co-voting network, an undirected edge joins two voters when they chose the same side in at least two historical attempts, weighted by the number of agreements. This is a projection of a voter-attempt affiliation network onto voters, in the sense of Feld (1981): an RfA is a focus that brings a temporary group together. It measures shared electoral behaviour, not friendship, trust or personal influence. Neutral votes and self-votes are excluded.

Network snapshots are cumulative and use only attempts before the target year, so a relation created by the predicted attempt cannot enter its predictors. Communities are detected with weighted Louvain modularity maximisation (Blondel et al., 2008). The course introduces Girvan-Newman as a divisive method for moderate-size graphs, but its betweenness recomputation becomes prohibitive here. On the 2005 snapshot, Girvan-Newman returned 247 communities with modularity 0.018 in 197.6 seconds; Louvain returned three communities with modularity 0.213 in 0.01 seconds. On the 2006 snapshot, Girvan-Newman did not finish within 600 seconds. Louvain is therefore practical, although its partition remains exploratory.

For each candidate we compute supporter overlap, returning and new supporters, the effective number of supporter communities, Jensen-Shannon divergence between the previous and current community mixes, weighted degree, PageRank, eigenvector centrality, local clustering and community bridge exposure. Comparisons between previously rejected and previously successful candidates use two-sided Mann-Whitney-Wilcoxon tests, Cliff's delta for effect size and Benjamini-Hochberg control across metrics. The 54 pairs after prior success are treated cautiously because the groups are unbalanced.

Every structural claim is compared with a baseline. Clustering is tested against 20 degree-preserving rewirings, and path length against log(n)/log(mean degree). Coalition overlap is tested against activity-weighted random supporter sets of the same size. Following Granovetter (1973), neighbourhood overlap is measured across tie-strength bins and the giant component is tracked while edges are removed weakest-first and strongest-first. Following Kossinets and Watts (2006), recruitment T(k) measures support in the next attempt among voters with k prior co-voters who supported the candidate.

The outcome model compares a vote-share and timing model with the same model plus prior supporter-community breadth and mean supporter weighted degree. Logistic regression is evaluated with five-fold cross-validation grouped by candidate, so all attempts by one person remain in the same fold. AUC and Brier score are reported. Only variables from before the later attempt are predictors. Current-attempt overlap and community breadth are used descriptively, never as predictors of that same attempt.

## 4. Results

### 4.1 Network structure

The final cumulative co-voting snapshot contains 6,228 voters and 771,356 edges. Figure 1 summarises its community structure and its cumulative evolution. Its giant component includes every voter, and the mean degree is 247.7. This density is partly a consequence of projecting repeated participation onto voters. The informative result is therefore the comparison with a null. Global transitivity is 0.357, compared with 0.252 in degree-preserving rewiring, a ratio of 1.42. Across snapshots the ratio ranges from 1.09 to 1.42. Average path length is 2.18, while the deliberately simple random-graph expectation is 1.58. The observed path is longer than that benchmark yet short in absolute terms. The network combines local clustering with short separation.

[[FIGURE:output/figures/fig1_covoting_network.png|Figure 1. Historical same-direction co-voting network. The left panel aggregates the final snapshot into detected communities; node size is community size and edges show cross-community co-voting. The right panel traces modularity and the cross-community edge share over cumulative snapshots.]]

Louvain finds between three and seven communities across snapshots. Modularity rises from 0.185 in the 2004 snapshot to 0.411 in 2013, while the share of cross-community edges falls from 0.506 to 0.274. The later network is therefore more modular, although the partition should not be read as a definitive map of ideological camps.

Coalitions are much less persistent than this dense background might suggest. Of 609 consecutive pairs, 350 meet the minimum supporter-set and activity-pool requirements for the activity-weighted null test. Observed supporter overlap exceeds the pair's own 95th percentile in 102 cases, or 29.1%, and is exactly zero in 154 cases, or 44.0%. A returning core exists, but it is modest and absent from many pairs.

Tie strength has the structure associated with Granovetter's argument. In 2008, mean neighbourhood overlap rises from 0.195 in the weakest edge bin to 0.424 in the strongest, while a weight-reshuffled baseline remains near 0.256. In 2013 the corresponding values are 0.181, 0.398 and about 0.235 to 0.240. Strong co-voting ties sit inside closed groups. Yet weak ties hold the graph together: removing the weakest edges first makes the giant component fall below half after 78% have been removed, whereas removing the strongest edges first leaves more than 90% of the giant component at 90% removal.

Recruitment through the previous coalition is positive but sublinear. The support rate among eligible voters rises from 0.00286 with no prior coalition contact to 0.01717 with 12 or more. From k = 2 onward it remains below the independent-contact baseline 1 - (1 - p)^k, with observed-to-baseline ratios around 0.38 to 0.71. Additional coalition neighbours are associated with recruitment, but their marginal contribution declines rather than reinforces one another.

### 4.2 Previous outcome and coalition change

The previous result is associated with how the next coalition is assembled. After a rejection, median supporter overlap is 0.044; after a success it is 0.000 (Cliff's delta = -0.374, BH-adjusted p < 0.001). Excess overlap relative to the active-voter expectation falls from a median of 0.042 to approximately zero (delta = -0.539, p < 0.001). The median share of returning supporters in the later attempt is 0.074 after rejection and 0.000 after success, while the new-supporter share is 0.926 and 1.000 respectively. Figure 2 shows the pair-level distributions behind these summaries.

[[FIGURE:output/figures/fig2_supporter_overlap.png|Figure 2. Pair-level supporter overlap relative to an active-voter expectation, grouped by the previous result and coloured by the later result. Each point is one consecutive pair; boxes show medians and interquartile ranges.]]

Figure 3 shows that the difference is not simply a broader coalition. The effective number of supporter communities is 1.65 in both groups (BH-adjusted p = 0.737), and the change in coalition breadth is also statistically indistinguishable (p = 0.700). What differs is reshuffling: Jensen-Shannon divergence between the previous and current community mixes is 0.098 after rejection and 0.311 after success (delta = 0.299, p = 0.001). Most position measures do not separate the groups; mean supporter PageRank is slightly higher after prior success, but weighted degree, local clustering and bridge exposure do not show a coherent advantage.

[[FIGURE:output/figures/fig3_community_diversity.png|Figure 3. Change in the effective number of supporter communities between consecutive requests, grouped by the previous result and coloured by the later result.]]

### 4.3 Later outcome and prediction

Descriptively, successful later attempts contain more continuity and broader support than rejected later attempts. Median supporter overlap is 0.067 versus 0.017, returning-support share is 0.085 versus 0.036, and the effective number of supporter communities is 2.46 versus 1.89. These variables describe the same attempt whose outcome is being compared, so they cannot be used to forecast its outcome without leakage.

The pre-attempt models show why the distinction matters. The prevalence-only Brier score is 0.244. Vote share and timing improve discrimination to AUC 0.716 and Brier 0.210. Adding prior community breadth and supporter weighted degree leaves performance essentially unchanged: AUC 0.715 and Brier 0.209. With all 609 complete pairs, the corresponding AUCs are 0.754 and 0.753. Figure 4 reports the fitted odds ratios. Prior support share has an odds ratio of 1.55 per ten percentage points (95% CI 1.26 to 1.91). Effective supporter communities have an odds ratio of 1.30, but the interval includes no association (0.93 to 1.80), while weighted degree is neutral (0.99, 0.93 to 1.07). The coefficient for prior success is conditional on the other terms, not a marginal success rate.

[[FIGURE:output/figures/fig4_model_coefficients.png|Figure 4. Odds ratios and 95% confidence intervals from the network-augmented logistic model. The subtitle reports grouped cross-validated AUC for the model without and with network measures.]]

## 5. Discussion

The results answer the research question in two parts. Candidates who return after promotion do not bring back a stable coalition: overlap is lower and the community mix changes more than after rejection, consistent with a newly assembled support base. After rejection there is more persistence, but median overlap is only 0.044. Across both groups, the dominant pattern is coalition rebuilding.

Successful attempts contain more returning supporters and broader community representation, but those features are observed in the attempt itself. Prior network position does not materially improve prediction once vote share and timing are known. This negative result suggests that RfA outcomes are not a simple function of proximity to central voters. The network describes the environment in which support is mobilised, but does not replace direct support, prior evaluation and timing.

The network findings add context. Dense clusters and short paths coexist with weak bridges; recruitment through existing supporters is positive but subject to diminishing returns. This is consistent with support spreading across groups rather than cascading through one closed circle. It also fits prior evidence that promotion combines contribution quality with social interpretation: being connected may make support visible, but connection alone does not determine approval (Burke & Kraut, 2008; Picot-Clemente et al., 2015).

## 6. Limitations

The study is observational. A coalition change may follow from campaigning, changed voter behaviour or selection into a later attempt, and the data cannot identify a causal effect. Co-voting is a behavioural proxy, not friendship, trust or influence. Neutral votes and comments are not used in the network or outcome model, so the rationale behind votes is absent.

The 54 pairs after prior success are few and unbalanced relative to 555 after rejection, limiting precision and making the conditional coefficient specification-sensitive. External validation ends in January 2008, so later outcomes lack a second source. Attempt boundaries are inferred, although the gap-only analysis and 99.45% agreement bound this risk. Louvain partitions are exploratory, and the data end in 2013, so conclusions describe that period rather than the present platform.

## 7. Conclusion

Repeat RfAs show coalition turnover rather than cumulative consolidation. After prior success, candidates are especially likely to return with a reshuffled supporter base, but there is no evidence that their coalitions are broader. Successful later attempts contain more returning support and wider community representation, while prior network position does not materially improve prediction beyond vote share and timing. The network analysis is therefore explanatory: it shows how supporters are connected, how weak ties hold the wider structure together, and how recruitment operates through diminishing returns. It does not justify treating centrality as a substitute for direct electoral support.

## Author contributions

Umberto Toraldo led data preparation, identity cleanup, attempt reconstruction and external outcome validation. Mihretab Worku Morka led network construction, coalition measures, statistical modelling and figures. Both authors jointly developed the research question, reviewed the literature, interpreted the results and wrote the report. Both will present the project and answer questions in the oral discussion.

## References

Blondel, V. D., Guillaume, J.-L., Lambiotte, R., & Lefebvre, E. (2008). Fast unfolding of communities in large networks. Journal of Statistical Mechanics: Theory and Experiment, 2008(10), P10008. https://doi.org/10.1088/1742-5468/2008/10/P10008

Burke, M., & Kraut, R. (2008). Mopping up: Modeling Wikipedia promotion decisions. In Proceedings of the 2008 ACM Conference on Computer Supported Cooperative Work (pp. 27-36). ACM. https://doi.org/10.1145/1460563.1460571

Feld, S. L. (1981). The focused organization of social ties. American Journal of Sociology, 86(5), 1015-1035. https://doi.org/10.1086/227352

Granovetter, M. S. (1973). The strength of weak ties. American Journal of Sociology, 78(6), 1360-1380. https://doi.org/10.1086/225469

Kossinets, G., & Watts, D. J. (2006). Empirical analysis of an evolving social network. Science, 311(5757), 88-90. https://doi.org/10.1126/science.1116869

Leskovec, J., Huttenlocher, D., & Kleinberg, J. (2010). Governance in social media: A case study of the Wikipedia promotion process. Proceedings of the International AAAI Conference on Web and Social Media, 4(1), 98-105. https://doi.org/10.1609/icwsm.v4i1.14013

Picot-Clemente, R., Bothorel, C., & Jullien, N. (2015). Social interactions vs revisions, what is important for promotion in Wikipedia? In Proceedings of the 2015 IEEE/ACM International Conference on Advances in Social Networks Analysis and Mining (pp. 888-893). ACM. https://doi.org/10.1145/2808797.2810063

West, R., Paskov, H. S., Leskovec, J., & Potts, C. (2014). Exploiting social network structure for person-to-person sentiment analysis. Transactions of the Association for Computational Linguistics, 2, 297-310. https://doi.org/10.1162/tacl_a_00184
