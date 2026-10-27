# data/raw

The SNAP files exactly as downloaded, compressed, unmodified. No script writes here.

| File | Source | Expected size | Coverage |
|---|---|---|---|
| `wiki-RfA.txt.gz` | https://snap.stanford.edu/data/wiki-RfA.html | 14,970,777 bytes | 2003 – May 2013 |
| `wikiElec.ElecBs3.txt.gz` | https://snap.stanford.edu/data/wiki-Elec.html | 1,090,375 bytes | 2,794 elections, votes from March 2004 to January 2008 |

Both files are committed, so nothing needs downloading to run the code. They are well under
GitHub's 100 MB per-file limit, and the submission requires the data together with the code.
Checksums are in `SHA256SUMS.txt`; verify them with:

```bash
shasum -a 256 -c SHA256SUMS.txt
```

If the files ever need to be fetched again:

```bash
curl -L -o data/raw/wiki-RfA.txt.gz https://snap.stanford.edu/data/wiki-RfA.txt.gz
curl -L -o data/raw/wikiElec.ElecBs3.txt.gz https://snap.stanford.edu/data/wikiElec.ElecBs3.txt.gz
```

Check the size afterwards: if it is much smaller than expected, what was downloaded is an
error page.

Data citations:
- wiki-RfA: West, R., Paskov, H. S., Leskovec, J. & Potts, C. (2014). *Exploiting Social
  Network Structure for Person-to-Person Sentiment Analysis*. TACL 2: 297–310.
- wiki-Elec: Leskovec, J., Huttenlocher, D. & Kleinberg, J. (2010). *Signed Networks in Social
  Media* (CHI) and *Predicting Positive and Negative Links in Online Social Networks* (WWW).

A warning that matters for anyone using these files: the two are **two separate third-party
reconstructions**, made at different times and for different papers. They largely describe the
same elections but disagree on roughly a fifth of the voters of each one, and the `T` field of
wiki-Elec is not a reliable closing time. See `docs/DATA.md` §6 and §7(i).
