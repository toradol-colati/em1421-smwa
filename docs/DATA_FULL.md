# Data workstream — complete method documentation

This is the long-form record of how the data were prepared: what the raw material is, every
defect found and how each was handled, the delivered tables column by column, what remains
open, how the work was verified, and the full code. `docs/DATA.md` is the short version that
travels with the submission; this file is the one to read before defending the work.

Status: 28 October 2026. Produced by `R/01_read_raw.R` → `R/02_build_attempts.R` →
`R/03_validate_outcomes.R`, with shared functions in `R/00_lib_data.R`. Base R only, no
dependencies.

**To reproduce everything with one command, from the repository root:**

```bash
Rscript R/run_data_prep.R
```

That wrapper runs the three steps in order. They stay separate files on purpose — they are
three different jobs, and a failure in one must never be mistaken for a result of another — so
the wrapper adds the guarantees that make running them together safe: it clears the chain's
outputs before starting, stops at the first error with a non-zero exit status, moves aside
anything a failed step had already written, and checks at the end that every expected output
exists. The three steps can also be run one at a time.

**Contents**
- [Part I — The raw data](#part-i--the-raw-data)
  - [1. What these data record](#1-what-these-data-record)
  - [2. Provenance: a four-step chain](#2-provenance-a-four-step-chain)
  - [3. Primary file: `wiki-RfA.txt.gz`](#3-primary-file-wiki-rfatxtgz)
  - [4. Validation file: `wikiElec.ElecBs3.txt.gz`](#4-validation-file-wikielecelecbs3txtgz)
  - [5. What the data do NOT contain](#5-what-the-data-do-not-contain)
  - [6. Why the two reconstructions disagree](#6-why-the-two-reconstructions-disagree)
- [Part II — The processing](#part-ii--the-processing)
  - [7. The eleven defects: problem, why it had to be fixed, how, and what would have happened otherwise](#7-the-eleven-defects)
  - [8. Attempt reconstruction](#8-attempt-reconstruction)
  - [9. Choosing the threshold](#9-choosing-the-threshold)
  - [10. Validation](#10-validation)
- [Part III — The output](#part-iii--the-output)
  - [11. The delivered tables, column by column](#11-the-delivered-tables-column-by-column)
  - [12. Structural properties to know before using them](#12-structural-properties-to-know-before-using-them)
- [Part IV — What remains](#part-iv--what-remains)
  - [13. Problems still to be solved](#13-problems-still-to-be-solved)
  - [14. Open questions, to be decided together](#14-open-questions-to-be-decided-together)
  - [15. Problems that remain, as stated limitations](#15-problems-that-remain-as-stated-limitations)
  - [16. Divergence from the figures in the brief](#16-divergence-from-the-figures-in-the-brief)
  - [17. My own errors, found while reviewing the work](#17-my-own-errors-found-while-reviewing-the-work)
  - [17-bis. Decisions taken downstream, and what they imply](#17-bis-decisions-taken-downstream-and-what-they-imply)
  - [18. The independent checks, and the errors they caught](#18-the-independent-checks-and-the-errors-they-caught)
  - [19. Do the results make sense? Substantive analysis](#19-do-the-results-make-sense-substantive-analysis)
  - [20. Appendix: all the R code](#20-appendix-all-the-r-code)

---

# Part I — The raw data

## 1. What these data record

**Wikipedia adminship elections**, the *Requests for Adminship* (RfA).

The generating mechanism: a user is nominated, or nominates themselves, for administrator
rights; a discussion page opens where the community writes **Support**, **Oppose** or
**Neutral** with a comment; after roughly a week a *bureaucrat* closes it and decides whether
to promote.

Two properties follow from that mechanism, and they constrain every interpretation:

1. **This is not a ballot box, it is a discussion.** Votes are public, signed and in
   chronological order: whoever votes sees who has already voted and what they wrote. A
   **normative bias** follows (conformity, herding), and it is not a detail but a threat to
   construct validity: a co-voting edge may reflect conformity to an already visible vote
   rather than affinity between the two voters.
2. **The final decision is not a mechanical count.** The bureaucrat weighs consensus rather
   than applying an arithmetic cut-off. `support_share` is therefore an **indicator** of the
   outcome, not its arithmetic cause.

**A note on sources.** How the closing works, and the roughly seven-day length, are
**background knowledge**, not facts that can be read or checked in the files. If they go into
the report they must be cited from an external source. What the files do contain is: the
votes, their sign, their dates, the outcome, and the comments.

## 2. Provenance: a four-step chain

```
Wikipedia
   └─> RfA pages (public text, editable, archivable, deletable)
         └─> two groups of Stanford researchers
             who scraped them into structured files,
             at two different moments and for two different papers
               └─> SNAP — Stanford Network Analysis Project,
                   Jure Leskovec's network dataset repository
                     └─> us, with SHA-256 checksums in data/raw/SHA256SUMS.txt
```

A consequence to keep in mind throughout: **these are not our data and they are not
Wikipedia's data.** They are **two third-party reconstructions**, made at different times (a
January 2008 dump for one, pages read up to May 2013 for the other) and for different purposes
(signed networks for one, sentiment in comments for the other). That is the structural reason
why they disagree in places, and §6 measures exactly how and by how much.

**Verifiability.** Both files are in `data/raw/`, committed, with their checksums. Expected
sizes: 14,970,777 bytes for wiki-RfA, 1,090,375 for wiki-Elec.

## 3. Primary file: `wiki-RfA.txt.gz`

**Source:** West, R., Paskov, H. S., Leskovec, J. & Potts, C. (2014). *"Exploiting Social
Network Structure for Person-to-Person Sentiment Analysis"*. Transactions of the Association
for Computational Linguistics 2: 297–310.

**Original purpose:** to study the **sentiment** expressed in the comments, not repeat
candidacies. We use it for a different question from theirs, which is exactly what the course
instructions allow: *"you can rely on available datasets, provided that the research question
underlying the analysis is original"*.

**Row unit: the vote, not the election.** Each vote is a record of **seven lines** of the form
`FIELD:value`, and records are separated by a blank line. The first record of the file,
literally:

```
SRC:Steel1943
TGT:BDD
VOT:1
RES:1
YEA:2013
DAT:23:13, 19 April 2013
TXT:'''Support''' as co-nom.
```

| Field | Content | Observed domain |
|---|---|---|
| `SRC` | *source*: the username of **the voter** | 10,417 distinct values |
| `TGT` | *target*: the username of **the candidate** | 3,497 distinct values |
| `VOT` | the **vote**: `-1` oppose, `0` neutral, `1` support | only these three values |
| `RES` | the **outcome of the election**: `-1` rejected, `1` approved. **Repeated identically on every vote of the same election**; it is not an attribute of the vote | 74,987 rows at −1, 123,288 at 1 |
| `YEA` | the declared **opening year** of the election | 2003–2013. **Unreliable**, see §7(g) |
| `DAT` | **date and time of the vote**, format `"HH:MM, DD Month YYYY"` | 9,367 empty, see §7(e) |
| `TXT` | the **comment** attached to the vote, free text | median 98 characters |

**Counts verified on the file** (not taken from the SNAP page, recomputed by us):

| Quantity | Value | Against what SNAP states |
|---|---|---|
| Votes | **198,275** | 198,275, matches |
| Distinct users (voters and candidates together) | **11,381** | 11,381, matches — **but only once trimmed**, §7(a) |
| Distinct voter–candidate pairs | **189,003** | SNAP states 189,004, which is the **pre-trim** count, §7(a) |
| Distinct voters | 10,417 | — |
| Distinct candidates | 3,497 | — |
| Time coverage | **2003 – May 2013** | matches |

**Coverage is partial at both ends:** 155 votes in 2003 and 3,348 in 2013. The full years are
2004–2012. This is why the published precedent (Kołczyńska) drops 2003 and 2013.

**The comments are substantial**, which opens a possibility we do not use: median 98
characters, mean 172, maximum 7,610; only **3.6%** are empty; 162,939 of 198,275 start with a
bold marker such as `'''Support'''`. A textual analysis would be technically possible, but it
is not part of the approved research question.

## 4. Validation file: `wikiElec.ElecBs3.txt.gz`

**Source:** Leskovec, J., Huttenlocher, D. & Kleinberg, J. (2010). *"Signed Networks in Social
Media"* (CHI) and *"Predicting Positive and Negative Links in Online Social Networks"* (WWW).
The header of the file itself points to the first of the two.

**Built from a Wikipedia dump of 3 January 2008**, to study **signed networks**.

**What exactly it is for.** The elections here are **already separated**, while in wiki-RfA
they are not. Three things follow from that single property, so the file serves three
purposes, not one:

1. **Choosing** the rule and the threshold for attempt reconstruction, by comparing our
   reconstructions against elections whose boundaries are known (§9). Not merely validating
   them: choosing.
2. **Validating the outcomes** independently of the primary source (§10).
3. **Measuring the error** of our reconstruction, that is, quantifying how many elections we
   split or merge by mistake. Without a second file that number would not exist and the
   reconstruction would have to be declared unverified.

**Structure: blocks, one per election, fields separated by tabs.** The first block of the
file, literally:

```
E	1
T	2004-09-21 01:15:53
U	30	cjcurrie
N	32	andyl
V	1	3	2004-09-14 16:26:00	ludraman
V	-1	25	2004-09-14 16:53:00	blankfaze
V	1	4	2004-09-14 17:08:00	gzornenplatz
V	0	26	2004-09-14 22:18:00	grunt
...
```

| Line | Content | Notes |
|---|---|---|
| `E` | **outcome**: `1` promoted, `0` not promoted | no missing values |
| `T` | declared **closing time** of the election | **unreliable**, see §7(i) |
| `U` | **candidate**: numeric id and username | 2,391 distinct candidates |
| `N` | **nominator**: numeric id and username | **unusable**: it is literally `UNKNOWN` in **2,117 of 2,794** elections (76%); declared self-nominations: 85 |
| `V` | one **vote** per line: sign, voter id, timestamp, username | 114,040 lines |

**Counts verified on the file:**

| Quantity | Value | Against what SNAP states |
|---|---|---|
| Elections | **2,794** | 2,794, matches |
| Votes | **114,040** | about 100,000, consistent |
| Distinct voters | **6,210** | about 7,000, consistent |
| Promotions / rejections | **1,248 / 1,546** | about 1,200 / 1,500, consistent |
| Votes per election | median **34**, from 1 to 370 | — |
| Vote signs | 83,962 support, 23,118 oppose, 6,960 neutral | — |

**The period.** Yes for what can be checked, but the wording has to be careful, because the
answer depends on *which* field one looks at:

- The **declared closing times** (`T`) run from **17/09/2004 00:41** to **06/01/2008 02:18**,
  with no missing values and no closing time before September 2004. That is measured.
- But the **votes** start earlier: the oldest is **28/03/2004**. An election closing in
  September 2004 contains votes from March 2004, so saying "the file covers from September
  2004" is false if one means votes.
- And above all: `T` is an **unreliable** field (§7(i)), so any statement about the period
  based on `T` is fragile. The solid statement is: **the votes run from 28/03/2004 to
  06/01/2008**, with 11 votes carrying impossible years (2061, 2063, 2064, 2065, 2067, 2070,
  2074, 2086, 2096, 2105) that have to be discarded.

**Either way one correction stands and must be made:** the period is **not 2003–2007**.
Wikipedia has had RfAs since 2003, but this file does not contain them.

## 5. What the data do NOT contain

**(a) No attempt identifier in wiki-RfA.** This is the gap that defines the whole workstream:
198,275 votes and no field saying which of them belong to the same election. Without
reconstructing it the project does not exist, because the approved question is about
**repeat** candidates.

Is reconstructing it from the dates enough? **No, and for three reasons.**
1. Dates alone are not enough: a **grouping rule** is needed. Two elections of the same
   candidate can have votes very close in time, and in the file their votes are interleaved.
   The rule that works groups by (candidate, `RES`) and *then* applies the time gap; the rule
   that looks natural, scanning dates and splitting whenever `RES` changes, produces
   measurable damage (§8).
2. A **threshold** is needed, and it is a free parameter: it has to be chosen, and I chose it
   by comparing the result against the real elections (§9).
3. **4.7% of the records carry no date**, `YEA` is unreliable, and some elections overlap in
   time. The final result agrees with the real elections for 94.6% of comparable candidates,
   not 100%: **a residual error remains, measured but not zero.**

**(b) No candidate attributes.** There is no edit count, no tenure, no areas of work, no use
of edit summaries.

Is that a problem? **Not for feasibility; yes as a limitation, and it must be stated with a
direction.** It is not a problem because our question is about network position, not about the
candidate's merit, and we neither could nor should replicate Burke & Kraut, who used exactly
those attributes. But it is an **unobserved confounder**: if more experienced candidates have
at once a better network position and a higher chance of passing, the association we find
between network and outcome is **biased upwards**. Criterion 08 asks for precisely this: name
the limitation, say which result it threatens, and in which direction. Burke & Kraut (2008) is
the citation establishing that those attributes matter.

**(c) No official opening or closing time in wiki-RfA.**

`opened_at` and `closed_at` in the delivered tables are the **first and last vote** of the
attempt. **I made that approximation**, in `build_attempts()` in `R/00_lib_data.R`, and it is
nothing more sophisticated than the minimum and maximum of the vote dates within an attempt.
Two consequences, and the second one is unpleasant:

- `duration_days` is by construction an **underestimate** of the true duration: an election
  opens before its first vote and closes after its last.
- **I cannot quantify the error of this approximation.** The only external reference would be
  `T` in wiki-Elec, which is unreliable (§7(i)): comparing my `closed_at` with `T` yields gaps
  with a median of about a hundred days, but that measures the defect of `T`, not mine. The
  approximation therefore stays declared and unmeasured. See §15.

**(d) No declared social relationship.** No kinship, no friendship, no following. Any network
we build is made of **behaviour** — who voted for whom — not of social ties. A vote is not a
friendship, and our network is not "the social network of Wikipedia". Olteanu et al. (2019)
§3.5 documents that networks built from declared links and networks built from interactions
have different structural properties: that is the citation to place beside this limitation.

## 6. Why the two reconstructions disagree

**The method for comparing them.** Match a wiki-Elec election to an attempt reconstructed from
wiki-RfA **by voter set**, not by date: compute the Jaccard overlap between the two voter sets
and keep the attempt with the highest overlap. Two different elections of the same person have
very different voters, so the criterion tells them apart; and it depends on no date field, so
it is not contaminated by the unreliability of `T`.

**Result: the two files largely describe the same elections.**

| Measure | Value |
|---|---|
| wiki-Elec elections matched to an attempt (Jaccard > 0.5) | **2,176 of 2,794 — 77.9%** |
| With a looser criterion (Jaccard > 0.3) | **2,353 — 84.2%** |
| Elections whose candidate does not appear in wiki-RfA at all | **273 — 9.8%** |
| Median Jaccard among the matched | **0.667** |
| Attempts of ours absorbing two distinct elections | **1** |

**Before blaming the two files, I checked whether I was the cause.** If my reconstruction were
splitting elections, the voters "missing" from the matched attempt should reappear in another
attempt of the same candidate. Measured: of the **20,025** voters present in a wiki-Elec
election and absent from my matched attempt, only **140, that is 0.7%**, are found in another
attempt of that same candidate. And merging *all* of a candidate's attempts makes the median
Jaccard **fall** (from 0.666 to 0.630) instead of rising. **So I am not scattering them: they
are genuinely missing from wiki-RfA.**

**Where they disagree: not on the elections, on the individual voters.** For the same election
the two files agree on *size* and differ on *composition*:

- median of 41 voters per election in wiki-Elec, 39 in my matched attempt;
- the voter count is **identical in 1,024 elections** out of 2,177;
- but **wiki-Elec holds a median of 8 voters that I do not have, and I hold 9 that wiki-Elec
  does not have**, out of about 41. The disagreement is **symmetric** and covers roughly a
  fifth of the names.

**Plausible causes**, ordered by how well they are supported:

1. **Different collection moments, on pages that change.** wiki-Elec comes from a dump of
   3 January 2008, wiki-RfA from pages read up to May 2013. In between, RfA pages are
   archived, moved, renamed, sometimes deleted, and struck or withdrawn votes are rewritten.
   Two readings five years apart give different lists. *A hypothesis consistent with the data,
   not directly verified.*
2. **Different purposes, hence different parsing choices.** Whoever was after sentiment kept
   the comment and the original spelling of the username; whoever was building signed networks
   normalised names to lowercase with underscores and kept the numeric id. The two
   normalisations are incompatible and have to be reconciled by hand (§7(d)).
3. **My reconstruction contributes little, and it is measured.** Only 0.7% of the missing
   voters end up in an adjacent attempt. What remains is the contribution of the 632 undated
   votes I dropped (§7(e)) and the duplicate votes removed (§7(h)), which do not account for
   the order of magnitude of the disagreement.
4. **The 273 absent candidates** are a genuine absence: elections that wiki-RfA does not
   contain in any form.

**A conclusion that corrects an earlier claim of mine.** I had written that wiki-RfA is not a
superset of wiki-Elec and that 61% of the elections were missing. **That was wrong**, and it
was an artefact of matching by date: wiki-RfA contains the great majority of wiki-Elec's
elections (77.9% matched under the strict criterion, 84.2% under the loose one), and genuine
absence concerns 9.8%. Details in §17.

---

# Part II — The processing

## 7. The eleven defects

For each one: what it is, **why it had to be fixed**, how I fixed it, and **what would have
happened if I had not**. All of them were found by measuring, not out of generic caution. The
last two, (j) and (k), only surfaced at the third verification round (§18), and (j) is the
most dangerous of all.

### (a) Trailing blanks in usernames — wiki-RfA

**What it is.** **43 spellings** carry a leading or trailing blank: `"Dream Focus "`,
`"Peripitus "`, `"Matthewrbowker "`, `"Noetica "`. Of those, **21 collide with the clean form
already present in the file** — the same name appears both with and without the blank — and
those are the ones that reduce the count of distinct names; the other 22 appear only with the
blank, so trimming renames them without merging them into anything.

**Why it had to be fixed.** A username *is* the identity of a node. Two spellings of the same
name are two different nodes for any network library.

**How.** `trimws()` inside `read_rfa()`, as part of `clean_name()`.

**What would have happened otherwise.** Distinct nodes would be 11,402 instead of **11,381**,
the figure published by SNAP: 21 more, exactly the 21 colliding spellings. In the networks
those 21 people would appear twice, with their degree split across the two copies.

**A side effect, which is itself a result.** Distinct voter–candidate pairs are 189,003 after
trimming and **189,004** before, because one single pair — `December21st2012Freak → Jeffrey
Mall` — appears under two spellings differing only in blanks. So **the totals published by
SNAP are not consistent with each other**: 11,381 users is a post-trim count, 189,004 pairs is
a pre-trim one. This belongs in the data section of the report, where criterion 03 asks for
figures that agree with each other.

### (b) The encoding of wiki-Elec

**What it is.** 19 lines out of 128,016 are not valid UTF-8, and they all belong to **the same
user**: a truncated sequence, `eivind_f_<c3>yangen` instead of `eivind_f_øyangen`.

**Why it had to be fixed.** `substr()` stops with *"invalid multibyte string"* and the file
cannot be read at all.

**How.** `iconv(from = "UTF-8", to = "UTF-8", sub = "")`, which drops the invalid bytes and
preserves everything else.

**What would have happened otherwise — and here is a trap I fell into.** My first fix
converted the whole file from ISO-8859-1, because `iconv -f ISO-8859-1` succeeds on it while
`iconv -f UTF-8` fails. **It works and it is wrong:** reinterpreting as latin1 the bytes that
were correct UTF-8 ruins every accented name, `anárion` becomes `anÃ¡rion`. I only noticed
because that name turned up in a list of unmatched candidates. It would otherwise have passed
unobserved and produced phantom nodes.

### (c) CRLF line terminators in wiki-Elec

**What it is.** The file uses **CRLF** terminators: 83,859 `0d 0a` byte pairs in the first
3 MB alone. wiki-RfA, by contrast, has no CRLF anywhere. The file has 128,016 lines.

**Why it looked like a problem.** The last field on every line is the **username**, so if the
`\r` stayed attached every name would carry an invisible character and no join between the two
files would work.

**How I handled it.** `sub("\r$", "", lines)` right after reading.

**CAREFUL — I had written something false here, and the verification caught me.** An earlier
version of this document claimed that without that line «no join would have worked». **That is
not true in R:** `readLines()` treats `\r\n` as the line terminator and strips it itself.
Measured: of the 128,016 lines read, **zero** contain a `\r`, and the last field of a `V` line
ends with the bytes `75 64 72 61 6d 61 6e` (`udraman`), with no `0d`.

The `sub()` is therefore a **safety net that does nothing** on this platform. It stays in
because it would genuinely matter when reading the file with `readBin`, with
`scan(sep = "\n")`, or on a connection opened in binary mode — but **it is not one of the
defects I had to fix**, and listing it among them was an error. The real spelling defect is
the next one.

### (d) Incompatible spellings across the two files

**What it is.** wiki-Elec writes usernames **entirely in lowercase** and uses an
**underscore** where wiki-RfA uses a **space**: 408 names with an underscore and 0 with a
space in wiki-Elec, against 0 with an underscore and 606 with a space in wiki-RfA.

**Why it had to be fixed.** Same reason as (c): without reconciling the spellings the two
files do not talk to each other.

**How.** `norm_user()` in `R/00_lib_data.R`: `clean_name`, then underscore → space, then
`tolower`. Used **only for comparing the files**, not for rewriting identity inside wiki-RfA.

**What would have happened otherwise.** The share of wiki-Elec candidates found again in
wiki-RfA would be **74.9%** instead of **89.8%**; a quarter of the elections would have looked
unvalidatable for a typographic reason.

### (e) Undated votes

**What it is.** 9,367 records out of 198,275 have an empty `DAT` field, but **1,661 of those
are the phantom records of §7(j), which are not votes at all**. The real undated votes are
**7,707 out of 196,614, that is 3.92%**. They touch **1,761 distinct candidates** (2,154 if
the phantoms are counted in).

Of those 7,707, **7,706 have the field literally empty and one carries an impossible value**:
`31:29, 24 May 2008`, hour 31. It passes the format check — two digits, colon, two digits —
but `as.POSIXct` rejects it. That is why the diagnostic now counts unrecognised formats and
**impossible values** separately: it used to count only the former, and reported «0
uninterpretable dates» when there was one.

**Why it had to be fixed.** Attempt reconstruction rests on time gaps: a vote with no date
cannot be ordered, so it cannot be assigned to an attempt directly.

**How.** They stay out of the reconstruction and are attached afterwards, **only where the
attribution is unambiguous**: the candidate has a single attempt with that year and that
outcome. That attaches **7,075** of them — of which **100 then turn out to be duplicates** of
a dated vote by the same voter in the same attempt and are removed, so **6,975 enter the
table** — and leaves **632 dropped**. Those attached are flagged `dat_imputed = TRUE` and stay
distinguishable.

**What would have happened otherwise.** Dropping them all would have lost 3.9% of the votes,
and not uniformly: they fall on 1,761 candidates, so they would have shrunk the vote counts of
some attempts systematically, distorting `support_share` and the number of voters, which are
two analysis variables. Attaching them all by force would instead have polluted the attempts
with unverifiable votes.

### (f) Months written in different ways, and three written wrong

**What it is.** The format of `DAT` is `"HH:MM, DD Month YYYY"`. Of the 188,908 non-empty
dates: **181,828 carry the month in full**, **7,077 carry it abbreviated to three letters**
(`Jan`, `Feb`, `Mar`, `Apr`, `Jun`, `Jul`, `Aug`, `Sep`, `Oct`, `Nov`, `Dec`), and **3 have it
misspelled in the source**: `Janry`, `Julu`, `Mya`, one vote each.

*A note on the count, because I got this wrong once:* `May` occurs 18,603 times and is
**identical in the full and the abbreviated form**, so it is not a problem case and does not
belong among the abbreviations. An earlier version counted it, and reported 25,680
abbreviations instead of 7,077.

**Why it had to be fixed.** Two reasons, the second worse than the first. First, a parser that
accepts only the full name loses the abbreviated dates and the misspelled ones. Second,
`format = "%d %B %Y"` depends on **`LC_TIME`**, that is on the language configured on the
machine: the same code would give different results on the instructor's computer, who has to
be able to run everything.

**How.** An explicit month table — full names, abbreviations and the three misspellings — and
the date built in ISO form, independent of the locale. In `parse_dat()`.

**What would have happened otherwise.** **7,080 dates** silently turned into `NA`, that is
**3.7%** of the dated votes. Those votes would have joined the undated ones, the attribution
would have scattered some of them, and the reconstruction would have run on a file full of
holes with nobody noticing. After the fix, exactly **one** uninterpretable date remains, the
one with hour 31.

### (g) `YEA` is not reliable

**What it is.** **1,875 votes, that is 0.99%,** carry a date in a different year from the one
declared by `YEA`, and they are not isolated cases: they come in **coherent blocks**.
`Scienceman123` has `YEA` 2008 and votes dated March 2006; `Jor` has `YEA` 2007 and votes
dated March 2004; `Danny` has `YEA` 2007 and votes dated January 2004. The differences are −3,
−2, −1 and +1 years.

**Why it had to be fixed.** The published precedent (Kołczyńska) groups by candidate, **year**
and outcome. If the year is wrong in blocks, that grouping splits whole elections.

**How.** The reconstruction **does not use `YEA`**: it groups by (candidate, `RES`) and uses
the dates. `YEA` stays in the table as an informative field, with the warning.

**What would have happened otherwise.** The elections of those candidates would have been cut
into two pieces assigned to different years, creating falsely "repeat" candidates — which is
exactly the population this study selects. We would have been studying artefacts.

**Where `YEA` remains unavoidable.** The attribution of undated votes (§7(e)) uses the key
(candidate, `YEA`, outcome), because a vote with no date has nothing else to place it by.
Quantified risk: among dated votes 0.99% carry a wrong `YEA`; applying the same proportion,
**about 69 of the 6,975 attributed votes may land in the wrong attempt**. It cannot be removed
without the dates. It is one more reason to exclude `dat_imputed` rows from time-sensitive
analyses.

### (h) Identical rows and repeated votes from the same voter

**What it is.** **595 fully identical rows** (same voter, candidate, vote, outcome, year,
date) across the 198,275 raw records — but **549 of those are among the phantom records of
§7(j)**, which are all empty in the same fields and therefore identical to one another. Among
real votes the identical rows are **46**. And after reconstruction there are **627 cases**
where the same voter appears more than once within the same attempt.

**Why it had to be fixed.** A voter appearing twice counts twice in the degree, in the number
of voters and in `support_share`; and in the network it creates a multi-edge that has to be
collapsed.

**How.** Keep **the most recent vote** of that voter in that attempt. The rule is stated
because it is not neutral: the hypothesis is that the voter **changed their mind**, in which
case the duplicate is signal rather than noise — Olteanu et al. (2019) §3.7 says exactly that,
*"redundancy can also be a signal by itself"*.

**A second deduplication, which I missed at first.** Undated votes enter the table *after* the
deduplication, so a voter can end up in the same attempt with one dated vote and one imputed
one: **100 cases**. The **dated** vote is kept, because it can be checked. Without this step
100 voters would be counted twice within the same attempt and `n_votes` would not match the
rows of `votes.rds`. I found it through the invariant checks, not by rereading the code (§18).

**What would have happened otherwise.** The brief called for "deduplication" without saying
how: keeping the **first** vote instead of the last would record the opinion the voter later
abandoned, that is the opposite of their final judgement. Ignoring the issue altogether would
have left 627 double votes inflating the counts.

### (i) `T` in wiki-Elec is not the closing date

**What it is.** The `T` field is supposed to be the closing time of the election. Compared
against **the last vote of the same election, inside the same file**, the gap has a **median
of 102 days**; **54%** of elections have `T` more than 30 days after their own last vote;
**1,217** more than 180 days; and the minimum is **−188 days**, meaning some elections have
`T` *before* their own last vote. The same shows up in an internal inconsistency: **78% of
elections are declared closed in 2007**, while the votes are spread over 2005, 2006 and 2007
(21,240, 44,702, 43,896).

**Why it had to be fixed.** Because it was the field on which I had based the entire
validation.

**How.** Matching real elections to reconstructed attempts **no longer uses dates**: it uses
the overlap of the voter sets (§6, §10).

**What would have happened otherwise — and it did happen, before I noticed.** The measured
coverage was 36% instead of 78%; 23 "under-splits" appeared instead of 1; and I concluded,
wrongly, that wiki-RfA did not contain the elections of wiki-Elec, and wrote that into the
document as a limitation of the project. An invented limitation is worse than an undetected
one. See §17.

### (j) 1,661 phantom records with no voter

**What it is.** **1,661 records out of 198,275 (0.84%) have `SRC` empty**, and **all 1,661
also have `TXT` empty and `DAT` empty**. They are not votes: they are records with no voter,
no comment and no date. They touch **926 candidates**, spread across every year but
concentrated in 2006 (800 cases). **Six candidates exist *only* through these records**, that
is they do not have a single real vote: without the removal they would be six invented
candidates.

**Why it had to be fixed, and it is the most dangerous defect of the eleven.** The empty
string is not discarded on its own: it becomes a **node** of the network, and a node with
**1,661 outgoing edges towards 926 candidates**. It would by far be the most active voter in
the dataset, a hub that does not exist. Every centrality measure, every community and the
whole co-voting projection would have been overwhelmed by it: 926 candidates would appear
connected to each other through an invented voter.

**How.** They are removed before anything else, and written to
`data/processed/records_without_voter.csv`, so nothing disappears silently. They cannot be
"flagged" like the other problematic rows: a vote with no voter is not an edge, and keeping it
in the table with a flag would let whoever analyses build the phantom node anyway.

**What would have happened otherwise.** Besides the hub: `n_votes` and `support_share` of 926
candidates would have been inflated by non-existent votes. And I had already written in an
earlier version of this document that «the most active voter has 1,661 votes», using it to
argue that the co-voting projection has a problematic hub. **That figure was the empty node.**
The real most active voter is `Siva1979`, with 1,232 votes.

### (k) 103 self-votes: the candidate voting in their own RfA

**What it is.** In **107 records** the voter coincides with the candidate. **98** of them
survive into the delivered table.

**Why it had to be fixed.** In a `voter → candidate` voting network a self-vote is a **loop**,
and loops break or distort several measures: degree, transitivity, shortest paths,
`simplify()`.

**How.** They stay in the table, with the `self_vote` column in the votes and `n_self_votes`
in the attempts. Whether to drop them is a decision for whoever analyses, and removing loops
in igraph costs one line.

**What would have happened otherwise.** They would have entered the network with nobody
knowing. The number is small, but a loop is exactly the kind of thing that makes an outlier
appear in a centrality measure and costs half a day to track down.

### (l) Attempt ids depended on the machine's locale

**What it is.** `attempt_id` is assigned by `cumsum()` over a table sorted with `order()` on
usernames. `order()` sorts character vectors using the machine's **collation locale**, so the
same code on the same data produced a different numbering on a different machine. Measured
between a Windows run and a macOS run: **3,763 of 4,081 `attempt_id` values differed**. The
attempts themselves were identical — same set, same `attempt_no`, all nineteen substantive
columns equal — only the ids were permuted.

**Why it had to be fixed.** Those ids leave the pipeline. `03_match_wikielec.csv` carries
`my_attempt`, and `output/results/attempt_pairs.csv` carries `previous_attempt_id` and
`next_attempt_id`. Anyone who regenerates the tables and then cross-references a committed CSV
**points at the wrong attempts** — and that is exactly the situation of an instructor who
re-runs the code, which the project instructions require to be possible.

**How.** `method = "radix"` on the seven `order()` calls that touch usernames, in
`00_lib_data.R` and `02_build_attempts.R`. Radix sorting compares bytes, which is
locale-independent.

**What would have happened otherwise.** Nothing visible, which is what makes it dangerous: the
counts, the outcomes and the figures would all have agreed, while the row-level
cross-references silently pointed elsewhere. Verified after the fix by running the whole
pipeline under `LC_COLLATE=it_IT` and `LC_COLLATE=C`: byte-identical output, and the headline
counts unchanged.

---

## 8. Attempt reconstruction

**The rule adopted — `res_then_gap`.** Group by (**candidate**, **`RES`**) and, within each
group ordered by date, open a new attempt when the gap between two consecutive votes exceeds
**7 days**. Undated votes do not take part and are attached afterwards (§7(e)). Implemented in
`reconstruct_attempts()`, `R/00_lib_data.R`.

Why `RES` is used for grouping: `RES` is a property of the **election**, repeated on every one
of its votes. So two votes of the same candidate with different `RES` necessarily belong to
two different elections, and grouping by `RES` automatically separates two nearby elections
with opposite outcomes, even when their votes are interleaved in the file.

**That assumption has been verified, and it holds at 97.7%.** The test: take the candidates
who have a **single** election in wiki-Elec — so there is no ambiguity about which election is
meant — pull from wiki-RfA the votes of those voters for that candidate, and check whether
`RES` is constant. Across **1,522** elections examined, `RES` is not constant in **35, that is
2.3%**. In those 35 cases my rule splits a single election in two: a residual error, measured
and not zero, that has to be reported.

*A note on a badly built test I ran first:* repeating the same check across **all** candidates
makes `RES` look non-constant in **15.0%** of cases (307 out of 2,048). That is an artefact:
candidates with several elections share voters between their own elections, so selecting votes
by voter membership pulls in the votes of the other election as well, which legitimately carry
a different `RES`. The valid figure is 2.3%.

**The rule discarded — `gap_then_res`.** Order by date within the candidate and open an
attempt when `RES` changes **or** the threshold is exceeded. This is the rule that looks more
natural, and it is the one I wrote first. It is wrong: a **single** vote with a different `RES`
sitting inside an election splits it into **three** pieces.

The case that made me see it is candidate `ABCD`: four "attempts" in one week of March 2005,
with outcomes alternating −1, 1, −1, 1, one of them made of a single vote. At the same
threshold the two rules give:

| | `gap_then_res` | `res_then_gap` |
|---|---|---|
| Attempts reconstructed | 5,401 | **4,081** |
| Attempts with fewer than 5 votes | 1,678 | **330** |
| Attempts with **a single vote** | 1,420, concentrated on 95 candidates | **few** |
| Attempts preceded by a success | 729 | **56** |

The 1,420 single-vote attempts are the diagnostic symptom: a rule that produces fourteen
hundred one-vote elections out of a file of 198,275 votes is not reconstructing elections. The
comparison between the two rules is in `03_threshold_sweep.csv` and is itself a result worth
reporting: it shows that the choice of rule matters far more than the choice of threshold.

## 9. Choosing the threshold

**The threshold is not assumed, it is chosen from the data.** wiki-Elec contains 2,794
already-separated elections: that is ground truth. I tried **2 rules × 17 thresholds**, from 1
to 60 days, and measured for each combination the matched elections, outcome agreement,
under-splits, fragments, and agreement on the **number of attempts per candidate**. Everything
is in `03_threshold_sweep.csv`.

**The result is a flat trade-off, not a sharp maximum.** With `res_then_gap`:

| Threshold | Matched elections | Exact attempt count |
|---|---|---|
| 4 days | 1,949 | 94.3% |
| **7 days** | **1,947** | **94.6%** |
| 21 days | 1,947 | 94.8% |
| 60 days | 1,899 | 95.5% |

Agreement on the count rises with the threshold, because merging reduces splitting; but
matched elections **fall**, because merging destroys distinct elections. **Between 4 and 21
days both measures are flat: the choice is not driven by the data, and that is the robustness
result to report.** We keep **7 days**, the value of the published precedent and the nominal
length of an RfA.

*A technical note on the figures in this table:* the sweep works on the raw reconstruction,
without deduplication and without the attributed undated votes, because its purpose is to
compare rules and thresholds against each other. The figures of the final validation (§10) are
higher, because there the attributed votes come back in and raise the overlaps.

Agreement on the count is computed **only on candidates whose wiki-Elec elections are all
matched**. Computing it on everyone — as I did in a first version — inflates it with
accidental agreement: a candidate whose correct election is missing from wiki-RfA but who has
another one scores "1 against 1" and counts as agreeing. See §17(a).

## 10. Validation

With the `res_then_gap` rule, a 7-day threshold, and matching by voter sets:

| Measure | Value |
|---|---|
| wiki-Elec elections matched (Jaccard > 0.5) | **2,176 of 2,794 — 77.9%** |
| **Outcome agreement** | **99.45%** — 12 disagreements out of 2,176 |
| Median Jaccard among the matched | 0.667 |
| Attempts absorbing two elections (under-split) | **1** |
| Attempts with an external match | **2,175 of 4,081 — 53%** |
| wiki-Elec candidates absent from wiki-RfA | 273 — 9.8% |

**What is validated and what is not.** The **outcome** is validated (at 99.45%) and, by
implication, the separation of attempts, because an election only matches if my attempt holds
substantially the same voters. **Not** validated: the duration, because I have no reliable
official closing time (§5(c), §7(i)); and nothing from **2008 to 2013**, because wiki-Elec
ends in January 2008 — and that period holds nearly half of our votes.

**Three methodological caveats on these figures, which have to be stated because they make
them optimistic.**

1. **There is no separation between tuning and validation.** The threshold and the rule were
   chosen by maximising agreement with wiki-Elec (§9), and then agreement with wiki-Elec is
   reported as validation. That is the same dataset used twice: it is not an out-of-sample
   check. Mitigating factor: the choice of threshold turned out to be **indifferent** across
   the 4–21 day plateau, so tuning consumed very little information; and **outcome** agreement
   does not depend on the tuning, because the outcome comes from `RES`, which is not a
   parameter.
2. **The matching picks the most similar attempt.** By construction it takes the maximum over
   all attempts of that candidate, so the agreement measured is an **upper bound**.
3. **Only the cases where the reconstruction worked are validated.** A badly reconstructed
   attempt has a low Jaccard, fails the 0.5 cut-off and **leaves the validation sample**. So
   the 99.45% is conditional on having been matched, and does not extend to the 1,906 attempts
   without a match. That is selection on the outcome, and it must be said.

---

# Part III — The output

## 11. The delivered tables, column by column

### `data/processed/votes.rds` — 195,252 rows, one per validated vote

| Column | Type | Content |
|---|---|---|
| `vote_id` | integer | position of the vote in the raw file, to trace it back to the source |
| `src` | character | voter, SNAP spelling with blanks and invisible characters normalised |
| `tgt` | character | candidate, same normalisation |
| `vot` | integer | **−1** oppose, **0** neutral, **1** support |
| `res` | integer | outcome of the attempt: −1 rejected, 1 approved |
| `yea` | integer | year declared by SNAP. **Unreliable**, §7(g) |
| `dat` | POSIXct, UTC | date and time of the vote; `NA` if the vote had no date |
| `dat_missing` | logical | the vote carried no date in the raw file |
| `attempt_id` | integer | **join key with `attempts`** |
| `attempt_no` | numeric | number of the attempt within the candidate, by opening date |
| `dat_imputed` | logical | undated vote attached to the attempt indirectly, §7(e) |
| `self_vote` | logical | the voter is the candidate: a **loop** in the network, §7(k) |

From 198,275 raw records to 195,252 rows, that is 3,023 fewer:
**1,661** **phantom** records with no voter, which are not votes (§7(j));
**630** removed because the same voter appeared more than once in the same attempt (§7(h));
**100** removed by a second deduplication, because a voter held both a dated vote and an
attributed undated one in the same attempt — the dated one is kept, being checkable (§7(h));
and **632** dropped because undated and not attributable (§7(e)).

### `data/processed/attempts.rds` — 4,081 rows, one per attempt

| Column | Type | Content |
|---|---|---|
| `attempt_id` | integer | primary key |
| `candidate` | character | candidate |
| `attempt_no` | numeric | 1, 2, 3… by opening date |
| `outcome` | integer | −1 rejected, 1 approved |
| `yea` | integer | SNAP year, unreliable |
| `opened_at` | POSIXct | **first vote** of the attempt, not the official opening — §5(c) |
| `closed_at` | POSIXct | **last vote** of the attempt, not the official closing — §5(c) |
| `n_votes` | integer | validated votes |
| `n_support`, `n_oppose`, `n_neutral` | integer | breakdown by sign |
| `n_self_votes` | integer | self-votes: the candidate voting in their own RfA (98 in total) |
| `support_share` | numeric | `n_support / (n_support + n_oppose)`. **Neutrals are not in the denominator**: a stated convention, not the only possible one — §14(b) |
| `duration_days` | numeric | `closed_at − opened_at`, hence an **underestimate** of the true duration |
| `n_votes_dated` | integer | of `n_votes`, how many carried a date of their own |
| `n_votes_imputed` | integer | of `n_votes`, how many are attached undated votes (6,975 in total) |
| `flag_short` | logical | fewer than 5 votes: possibly a fragment — **297 cases** |
| `flag_long` | logical | more than 14 days: longer than a normal RfA — **4 cases** |
| `flag_year_clash` | logical | another attempt of the same candidate exists in the same year (taken from the **date**, not from `yea`) with the same outcome: suspected split — **363 cases** |
| `prev_outcome` | integer | outcome of the candidate's previous attempt; `NA` at the first |

### `data/processed/attempts_validated.rds` — the same 4,081 attempts, plus the external match

Adds `elec_matched` (logical), `elec_outcome`, `elec_jaccard`, `outcome_agrees`.
**2,175 of 4,081** attempts have a counterpart in wiki-Elec.

### Supporting files

| File | Content |
|---|---|
| `03_threshold_sweep.csv` | the 2 rules × 17 thresholds grid with every metric |
| `03_match_wikielec.csv` | one row per wiki-Elec election: outcome, `T`, last vote, Jaccard, matched attempt |
| `username_case_variants.csv` | the 137 spelling groups differing only in the first letter, §14(a) |
| `records_without_voter.csv` | the 1,661 phantom records, §7(j) |
| `02_log.txt`, `03_log.txt` | the log of every quantity, to draw the report's figures from |
| `99_verification.txt`, `99b_verification.txt` | the output of the two verification rounds, §18 |

**The principle followed throughout the output: do not filter, flag.** Every problematic row
stays in the table with a flag column, so whoever analyses decides what to exclude, not
whoever cleans, and the number of exclusions is available for the report. In particular the
table is **not** restricted to repeat candidates: if it were, we would lose the votes a
candidate **cast** in other people's RfAs between one attempt and the next, which are the only
genuinely new information about a returning candidate.

## 12. Structural properties to know before using them

**Careful: two different sets of counts, and the report must say which it uses.** The
**raw-file** figures include the 1,661 phantom records and the un-normalised spellings; the
**delivered-table** figures do not, because 3,023 rows leave the pipeline and with them a few
users who appeared only once.

| | Raw file | Delivered table |
|---|---|---|
| Votes | 198,275 | **195,252** |
| Distinct nodes | 11,381 (trim only, as SNAP) | **11,243** |
| Voters | 10,417 | **10,300** |
| Candidates | 3,497 | **3,460** |
| Both voters and candidates | 2,533 | **2,549** |
| Support / oppose / neutral | 144,451 / 41,176 / 12,648 | **143,154 / 40,220 / 11,878** |

*A note on the nodes:* 11,381 is the total published by SNAP and is reproduced with `trimws()`
alone. We reach **11,380** because we also normalise one double internal space
(`Salvio  giuliano` → `Salvio giuliano`, which collides with a name already present) and one
invisible leading marker (§7(a)); **11,243** once first-letter case variants are merged, which
is the decision now adopted (§14(a)); and **11,211** on the delivered table, after the phantom
records are removed. They are all correct figures for different things, and the report must
say which one it quotes.

**The voting network is not bipartite.** On the raw file: 10,417 voters, 3,497 candidates,
11,381 in the union, and **2,533 users are both** — **72.4% of candidates have cast at least
one vote** in other people's RfAs (median 19 votes cast, third quartile 57, maximum 1,232).
964 candidates never voted. It is this property that makes a candidate's **out-degree**
measurable, which is the pre-t+1 variable that is not collinear with the previous attempt.

**The distributions have heavy tails.** Votes cast per voter: median **3**, mean 18.9, maximum
**1,232** (`Siva1979`). Votes received per candidate: median **41**, mean 56.3, maximum
**978**. Operational consequences: a voter present in more than a thousand elections is a
co-voter of a great many others, so the co-voting projection will have a hub in any case; null
models must be weighted by voter activity, otherwise they are dominated by occasional voters;
and using the mean as a summary needs justifying.

*An earlier version said "maximum 1,661" and built the hub argument on it. That was the empty
node of the phantom records, §7(j). The argument survives with 1,232, the figure does not.*

**The sign of the votes.** On the raw file 144,451 support (72.9%), 41,176 oppose (20.8%),
**12,648 neutral (6.4%)**. Neutrals are not negligible: they are in the table with `vot = 0`,
not removed.

**Self-votes.** 107 in the raw file, 98 in the table: they are **loops** in the voting
network, flagged by `self_vote` (§7(k)).

**Density.** N = 11,381, 189,003 distinct edges, density 0.00146: the sparse regime.

---

# Part IV — What remains

## 13. Problems still to be solved

Things that can be closed with work, not decisions.

**(a) The 12 outcome disagreements** between my reconstruction and wiki-Elec, out of 2,176
matched. They are in `03_match_wikielec.csv`. They should be inspected one by one: if my
reconstruction merged two elections with different outcomes they are my errors; if `RES` in
wiki-RfA contradicts `E` in wiki-Elec it is a defect of the sources, and then the report
should say that the two reconstructions disagree on the outcome in 12 cases out of 2,177.

**(b) The attempt that absorbs two elections.** Just one, identifiable in
`03_match_wikielec.csv` as two rows pointing at the same `my_attempt`. To be split by hand or
excluded.

**(c) The 297 attempts with fewer than 5 votes.** They are flagged, not excluded. They should
be inspected: some will be genuine early closures (SNOW/NOTNOW), others fragments of the
reconstruction. The distinction changes the count of repeat candidates.

**(d) The wiki-Elec parser does not extract the numeric ids** of voters and candidates, only
the usernames. The ids would be a sounder key inside wiki-Elec, although they do not help in
linking to wiki-RfA, which does not have them.

**(e) The 11 wiki-Elec votes with impossible years** (2061–2105) are excluded from the date
computations but not flagged in any output.

## 14. Open questions, to be decided together

Decisions, not work. They affect both roles, because they change both the study population and
the node set of the network.

**(a) First-letter case variants — DECIDED: merged.** This was the main open question and it
has been settled: `MERGE_FIRST_LETTER` is now `TRUE` in `R/02_build_attempts.R`, and every
figure in this document reflects that. The reasoning is below, kept because the choice has to
be defended, not merely stated.

On Wikipedia the first letter of a username is **always** capitalised, so `harej` and `Harej`
are **the same account**. SNAP does not merge them: the total of 11,381 keeps them apart.
Merging brings the nodes down to **11,243**. There are **137
groups** of spellings (the full list is in `username_case_variants.csv`); in **90** of them the
person is a candidate under at least one spelling; and in **8 the same candidate appears under
two different spellings**, in different years:

| Candidate | Spellings and years |
|---|---|
| Dustihowe | 2007 and 2008 |
| Imdanumber1 | 2006 and 2007 |
| Kylekieran | 2009 and 2011 |
| Maltesedog | 2005 and 2006 |
| Tdxiang | 2005 and 2006 |
| Xiner | 2006 and 2007 |
| Alexsautographs | two spellings in the same year, 2010 |
| Nenyedi | two spellings in the same year, 2007 |

**The effect has been measured, by running the pipeline in both configurations:**

| | `MERGE_FIRST_LETTER = FALSE` (current) | `= TRUE` |
|---|---|---|
| Distinct nodes | 11,380 | **11,243** |
| Attempts | 4,082 | **4,081** |
| **Repeat candidates** | 484 | **490** |
| Attempts preceded by a rejection | 558 | **565** |
| Attempts preceded by a success | 56 | **56** |
| Undated votes dropped | 616 | **632** |

**On the population it changes little: six more repeat candidates, and it moves further from
the brief's 414, not closer.** The strong argument is not the population, it is **node
identity in the network**: in **37 of the 137 groups** one spelling **casts** votes and another
**receives** them. Real examples: `ais523` cast 31 votes while `Ais523` received 66; `aitias`
cast 101 while `Aitias` cast 70 and received 240. Without merging, **the votes cast and the
votes received by the same person land on two different nodes**, which hits precisely the
variable that matters here: the candidate's out-degree, that is the votes they cast in other
people's RfAs. Altogether the 137 groups involve **12,788 votes** (7,167 cast and 5,621
received).

And there remain the **8 candidates** who, without merging, look like two different people
with one attempt each and therefore fall outside the repeat population.

**Why it was decided this way.** Not for the population — six candidates either way — but for
**node identity**. The alternative would have left 37 people split across two nodes, one
holding their outgoing votes and the other their incoming ones, which corrupts exactly the
variable the research question needs. The cost is a declared deviation from the SNAP totals,
and the report must state both counts: 11,381 as published, 11,243 as used.

**(b) The denominator of `support_share`.** It currently excludes the 12,648 neutral votes.
The alternative is to include them. Either way the choice has to be stated in the report.

**(c) What to exclude.** `flag_short` (297), `flag_long` (4), `flag_year_clash` (363), the
`dat_imputed` votes (6,975) and the 98 `self_vote` rows are in the table, not filtered out.
For time-sensitive analyses the `dat_imputed` rows should probably be excluded (§7(g)). The
number of exclusions belongs in the report.

**(d) The period.** Kołczyńska drops 2003 and 2013 because they are only partially covered
(155 and 3,348 votes). It has to be decided whether to do the same, and with what written
justification.

## 15. Problems that remain, as stated limitations

Things that **cannot** be solved with these data. They belong in the limitations section of
the report, each with the result it threatens and the direction, as criterion 08 requires.

**(a) No validation from 2008 to 2013.** wiki-Elec ends on 6 January 2008. Beyond that date
the attempt reconstruction has no external check, and that period holds roughly half of our
votes. *Threatens:* every result concerning recent attempts. *Direction:* unknown, which is
exactly the point.

**(b) Attempt duration is an underestimate that cannot be quantified.** `opened_at` and
`closed_at` are the first and last vote, an approximation I made in `build_attempts()`; and I
cannot measure its error, because the only external reference — `T` in wiki-Elec — is
unreliable (§7(i)). *Threatens:* any variable built on duration or on the time between two
attempts. *Direction:* `duration_days` is systematically below the true value.

**(c) No candidate attributes, hence an unobserved confounder.** We have no edit counts, no
tenure, no areas of work. *Threatens:* the association between network position and outcome.
*Direction:* if more experienced candidates have at once a better network position and a
higher chance of passing, the association is **biased upwards**. Citation: Burke & Kraut
(2008), which shows those attributes predict the outcome.

**(d) Normative bias: votes are public and sequential.** Whoever votes sees the previous
votes. *Threatens:* the construct validity of co-voting communities read as coalitions, and
the independence of the votes inside `support_share`. *Direction:* it **inflates** the apparent
cohesion of the communities. Citation: Olteanu et al. (2019) §4.2, which documents conformity
and herding in response to already visible ratings.

**(e) The network is one of behaviour, not of social ties.** A vote is not a friendship.
*Threatens:* any reading of the results in terms of "social relationships". Citation: Olteanu
et al. (2019) §3.5. *Direction:* not applicable; it is a limitation of interpretation.

**(f) The two files disagree on roughly a fifth of the voters of each election** (§6), and the
disagreement is symmetric. *Threatens:* the precision of the per-attempt counts. *Direction:*
unknown, because it is symmetric.

**(g) The totals published by SNAP are not consistent with each other** (§7(a)). *Threatens:*
the reproducibility claimed in the data section. *Remedy:* state which count is used and why.

**(h) About 69 votes may be attached to the wrong attempt** (§7(g)). *Threatens:* the counts
of the attempts that contain them. *Direction:* unknown, but the order of magnitude is 0.04%
of the votes.

**(i) 632 votes dropped** because undated and not unambiguously attributable. They are 0.3% of
the total, **but they are not uniformly distributed, and that is measured**: they touch 124
candidates, **77% of whom are repeat candidates**, against a share of repeat candidates among
all candidates of **14%**. A concentration of **5.4 times** the base rate. The reason is
mechanical: the attribution rule fails precisely when a candidate has several attempts with
the same year and outcome, that is on returning candidates — **the population this study
selects**. *Threatens:* the number of voters and `support_share` of the attempts of repeat
candidates. *Direction:* an underestimate of the number of voters, concentrated on the group
of interest.

## 16. Divergence from the figures in the brief

| | Brief | Here | Ratio |
|---|---|---|---|
| Repeat candidates (2+ attempts) | 414 | **490** | 1.18 |
| Previously rejected | 394 | **451** | 1.14 |
| Previously successful | 29 | **53** | 1.83 |
| Consecutive attempt pairs | not stated | **621** | — |
| Candidates with 3+ attempts | not stated | **91** | — |

The figures in the brief have never been reproduced by anyone, not even within the group, so
the divergence does not by itself show who is wrong. But it has to be reconciled, and the
*previously successful* group is the most divergent, at nearly double: consistent with the
existing suspicion that this group is partly an artefact of the reconstruction.

My rule is explicit, parametric, and validated at 99.45% on outcomes where validation is
possible. It is the starting point for the comparison, not a truth.

**To be clarified with whoever produced the 414:** with what attempt-separation rule, with what
treatment of duplicate votes, with what username normalisation, and whether 2003 and 2013 were
included.

## 17. My own errors, found while reviewing the work

They are listed because they matter for reading the figures in this document, and because some
of them had already made it into an earlier version of the documentation.

**(a) The metric I chose the threshold on was inflated.** I compared the number of attempts
per candidate across *all* candidates, including those whose wiki-Elec elections were not
matched: for those, the comparison is "1 against 1" by accident and counted as agreement. I
reported 93.6%. Restricted to candidates whose elections are all matched, the true value is
around 94.6%. The choice of threshold did not depend on it, because the plateau remains, but
the claim was measuring something else.

**(b) I matched elections by date, and the date field of wiki-Elec is unreliable.** This is the
most serious error. I used the proximity between `T` and my `closed_at`; then I measured `T`
against the last vote of the **same** election inside wiki-Elec and found a median gap of
**102 days**. Switching to matching by voter sets: matched elections rise from 1,015 (36%) to
**2,177 (77.9%)**, under-splits fall from 23 to **1**, and validated attempts rise from 992 to
**2,176**.

**(c) I had written a false statement into the project's limitations.** From the first version
of (b) I concluded that "61% of wiki-Elec elections do not exist in wiki-RfA" and that
"wiki-RfA is not a superset of wiki-Elec", with a coverage table by year. **It was an artefact
of matching by date.** The measured reality: 77.9% matched under the strict criterion, 84.2%
under the loose one, and genuine absence of 9.8%. An invented limitation is worse than an
undetected one, because it goes into the report and is never checked again.

**(d) I justified a conclusion with an inference rather than a measurement.** I wrote that "the
vote volumes of the two files are comparable, so this is not a question of scale". The
reasoning was weak and the conclusion wrong. The comparison between the two files now rests on
a direct measurement, the overlap of the voter sets (§6).

**(e) `flag_year_clash` used `yea`**, the very field I had declared unreliable and excluded
from the reconstruction. An internal inconsistency. It now uses the year taken from the
opening date; the count went from 374 to 359.

**(f) I picked the wrong encoding conversion** for wiki-Elec, converting the whole file from
ISO-8859-1 because it "worked". It ruined the correctly encoded accented names. See §7(b).

**(g) I claimed "0 uninterpretable dates" when there was one.** The diagnostic counted only
unrecognised formats, so the record with hour 31 slipped through as if it were simply empty.
See §7(e).

**(h) I let a figure I had myself retracted travel into the submission documentation.** My
§8 states that the 15.0% of elections with non-constant `RES` is an artefact of a badly built
test and that the valid figure is 2.3%. But `R/99_verify_data.R` printed only the contaminated
15.0%, so that is the number that was picked up and written into the limitations of the short
`docs/DATA.md`. Retracting a number in prose while the script keeps printing it is not a
retraction. The script now runs **both** tests, prints them side by side with the valid one
labelled, and asserts the 2.3%.

**(i) `attempt_id` was not reproducible across machines** (§7(l)). Found by re-running the
pipeline on another machine and comparing, not by reading the code.

**What remains unverified, and it is written down:** the 12 outcome disagreements and the
attempt that absorbs two elections have not been inspected case by case (§13(a), §13(b)).

## 17-bis. Decisions taken downstream, and what they imply

Three choices were made when the network workstream took over the tables. They are recorded
here with their reasoning and their cost, because `output/results/sample_flow.csv` shows the
counts but not the why, and criterion 05 asks for one line on each choice against the obvious
alternative.

**(a) The 12 outcome disagreements are withheld from analysis but kept in full.** Concretely,
`R/run_data_prep.R` writes `attempts_analysis.rds` with a new column `outcome_analysis`, equal
to `outcome` everywhere except on the 12 attempts where our reconstruction and wiki-Elec
disagree, where it is `NA`. The row itself is not deleted: it stays in `attempts.rds`, and
`output/results/outcome_validation.csv` carries all 4,081 attempts with
`validation_status = "outcome_mismatch"` and **both verdicts side by side** (`rfa_success` and
`wiki_success`). That is what "kept for provenance" means: the case remains auditable, only
its outcome is not used.

*Implication:* in `R/05_measure_change.R` a pair is skipped when either of its two attempts has
`outcome_analysis = NA`, which is exactly the step from **621 consecutive pairs to 609 pairs
with valid outcomes**. The alternative — trusting our `RES` over wiki-Elec — would have added
12 pairs of known-doubtful outcome to a sample of 609, that is 2%, with no way to tell which
source was right. The cost is 12 pairs; the gain is that no analysed outcome is one we know to
be contested.

**(b) Attempts with fewer than five votes stay in the descriptive comparison and leave the
model.** `R/06_model_outcome.R` builds `model_data` by dropping any pair where either attempt
has `flag_short`. The counts are in `sample_flow.csv`: **609 pairs in the descriptive
comparisons, 528 in the outcome models**.

*Implication:* those are mostly genuine early closures (§19.5 shows attempts under one day
have a 4.4% success rate against 65.9%), so they are real events and belong in any description
of what repeat candidacies look like. But a support share computed on three votes is not
comparable with one computed on forty, and feeding it to a logistic model would let a handful
of near-degenerate observations move the coefficients. Keeping them descriptive and out of the
model is the conservative reading. The cost is 81 pairs, about 13% of the usable sample, and
the README states the comparison is repeated with and without them.

**(c) A third reconstruction rule, `gap_only`, is run as a sensitivity check.** It groups by
candidate and time gap **only**, never using `RES` to set a boundary, and marks an attempt
whose votes carry mixed `RES` as outcome-unknown.

*Implication, and this is the point:* the main rule `res_then_gap` **does** use `RES` to draw
boundaries, so it is exposed to the cases where `RES` is not constant within one election
(§8: 2.3% of the clean test). `gap_only` is immune to that by construction, and at the chosen
seven-day threshold it yields **4,063 attempts against 4,081**, matching the same 1,947
elections. So the entire exposure of the main rule to the `RES` problem is bounded at
**18 attempts out of 4,081, that is 0.4%**. This is the right answer to that limitation: not a
disclaimer, a measurement.

## 18. The independent checks, and the errors they caught

**Round 1 — `R/99_verify_data.R`** recomputes every figure in this document **starting from
the two raw files**, using no intermediate output of the pipeline, and prints `OK` or
`MISMATCH` next to each. It also runs a sweep for the classic data-hygiene traps: empty names,
double internal blanks, invisible characters, non-breaking spaces, HTML entities, tabs,
out-of-domain values, out-of-period dates, self-votes, duplicate voters within an election,
elections with no votes. Output in `data/processed/99_verification.txt`.

**Round 2 — `R/99b_verify_output.R`** checks that the **tables produced are internally
consistent**: no voter twice in the same attempt; `n_votes` equal to the actual row count;
`n_support + n_oppose + n_neutral == n_votes`; `support_share` equal to its ratio; `attempt_no`
contiguous and ordered by opening date; `prev_outcome` equal to the previous attempt's outcome;
vote conservation (198,275 = 195,252 + 3,023). These must hold by construction, so a failure is
a bug. Output in `data/processed/99b_verification.txt`.

Between them they caught seven mistakes, all corrected above: the four claim errors listed in
§17(a)–(d) and §17(g), plus two genuine pipeline bugs and one dangerous data defect:

- **`support_share` silently excluded thousands of votes**, because the attempt table was built
  *before* the attributed undated votes were put back. The two delivered tables disagreed with
  each other.
- **A voter could appear twice in the same attempt**, once dated and once imputed, because the
  undated votes enter after the deduplication. 100 cases, now removed by a second pass.
- **The 1,661 phantom records of §7(j)**, which neither round could see at first because both
  compared figures the empty node did not alter. The hygiene sweep found them.

Both rounds are code in the repository, not checks performed once: if the data or the parser
change, they re-run themselves.

**Status: round 1, every verified claim matches. Round 2, every invariant holds and every
figure matches.**

## 19. Do the results make sense? Substantive analysis

The rounds in §18 verify that the figures are right and consistent. They do not say whether the
result **resembles the reality it is supposed to describe**. This section checks that by
comparing the output against known facts about the RfA process that never entered the code.

### 19.1 Reproducibility: code extracted from the document, clean room

The code in the appendix (§20) was extracted from this document, placed in an empty directory
together with the two files in `data/raw/` alone, and run from scratch. The extracted files are
**byte-identical** to those in `R/`, and the run reproduces **every** figure reported here.

### 19.2 `support_share` separates approved from rejected almost perfectly

This is the strongest check, because it **does not depend on wiki-Elec**: it uses only the
reconstruction. If votes landed in the wrong attempts, the two distributions would blur.

| Outcome | n | 1st quartile | median | 3rd quartile |
|---|---|---|---|---|
| Approved | 1,917 | 0.921 | **0.978** | 1.000 |
| Rejected | 2,162 | 0.000 | **0.240** | 0.537 |

Only **0.9%** of approved attempts fall below 70% support, and only **1.7%** of rejected ones
rise above 80%. The **AUC is 0.989**: pick one approved and one rejected attempt at random, and
in 98.9% of cases the former has the higher support share.

### 19.3 The promotion threshold emerges from the data, and we did not put it there

| Support share | n | Promoted |
|---|---|---|
| 0.60 – 0.65 | 138 | 2.2% |
| 0.65 – 0.70 | 141 | 4.3% |
| **0.70 – 0.75** | **120** | **20.0%** |
| **0.75 – 0.80** | **88** | **89.8%** |
| 0.80 – 0.85 | 124 | 92.7% |
| 0.90 – 0.95 | 248 | 99.2% |

There is a sharp jump between 70–75% and 75–80%, from 20% to 90% promoted. That is the
documented discretionary range of the bureaucrats, and **there is no threshold anywhere in our
code**: `support_share` is computed from the votes, the outcome comes from `RES`, and the two
never meet. Recovering a known institutional rule that we did not impose is strong evidence
that the reconstruction is putting the right votes with the right outcome.

### 19.4 Success falls with the attempt number

| Attempt | n | Success |
|---|---|---|
| 1st | 3,460 | 47.9% |
| 2nd | 490 | 44.7% |
| 3rd | 91 | 33.0% |
| 4th | 27 | 18.5% |

The direction is the one Burke & Kraut (2008) document. Our decline is steeper at higher
attempt numbers than their 11.8% per attempt, but they estimate an average effect in a specific
regression, not a raw table like this one: **agreement in direction, not in coefficients.**

### 19.5 Duration reproduces the process, checked against wiki-Elec

Here the comparison is **independent**: wiki-Elec has the elections already separated, so its
duration distribution owes nothing to our rule.

| | wiki-Elec (real elections) | Our reconstruction | 2004–2008 only |
|---|---|---|---|
| Median duration | 6.39 days | 6.24 | 6.35 |
| Between 6.5 and 7.5 days | 40.1% | **41.3%** | 41.5% |
| Under one day | 29.6% | **30.9%** | 27.7% |
| Success rate | 44.7% | — | 49.3% |

The distribution is **bimodal in both files**: a mass under one day and a sharp peak at 6.5–7.5
days (1,685 attempts out of 4,081). The peak is **not imposed by the threshold**: the threshold
separates two attempts when more than seven days pass *between one vote and the next*, it does
not cap an attempt's duration — indeed 26 attempts last between 10 and 20 days.

**The 31% of attempts under one day is not an artefact**, and it is what worried me most. Those
attempts have a **4.4% success rate** against 65.9% for the others, and a median support share
of **0.083** against 0.918. They are hopeless candidacies closed within hours — the WP:SNOW /
WP:NOTNOW pattern. wiki-Elec, which knows nothing of our reconstruction, has **the same share
(29.6%)**.

### 19.6 The historical trend is the known one

| Year | n | Success |
|---|---|---|
| 2003 | 53 | 100.0% |
| 2004 | 296 | 79.4% |
| 2005 | 590 | 66.1% |
| 2006 | 849 | 39.8% |
| 2008 | 565 | 34.9% |
| 2010 | 229 | 33.2% |
| 2012 | 97 | 30.9% |

The collapse in success rate and in the volume of candidacies between 2005 and 2008 is the
documented history of RfA, which turned from a routine process into a severe examination. It is
not a fact we fed into the code: it comes out of the data.

### 19.7 The two differences that remain, stated

- **Success rate 2004–2008: 49.3% ours against 44.7% in wiki-Elec.** Four and a half points.
  Consistent with the two files not containing exactly the same elections (§6), but not
  explained in detail.
- **wiki-Elec has an election lasting 780 days**, ours peak at 17.34. Our separation rule
  **truncates** durations by construction, theirs does not. It changes nothing in the bulk of
  the distribution, but it has to be said: extreme durations are not comparable.

### 19.8 Conclusion

The counts are right (§18) and the result behaves like the process it is meant to describe: it
separates the outcomes, recovers an institutional threshold nobody gave it, reproduces the
seven-day duration and the tail of early closures in the same proportions as an independent
source, and shows the correct historical trend. As far as can be established with these data,
**the reconstruction fits the raw material and produces sensible results.**

What this section does **not** establish: that the open choices of §14 are the right ones, that
the 1,906 attempts without an external match are reconstructed as well as the matched ones
(§10, third caveat), and that the network analysis built on top of these tables will be valid.

## 20. Appendix: all the R code

What follows is the full content of every file in `R/`, in execution order: the project runner,
the data-preparation wrapper, the five data-workstream scripts, the four network-workstream
scripts, the two verification rounds and the generator of this appendix. With the two files in `data/raw/` and this code, anyone can
redo the whole processing and obtain the same figures.
**This appendix is generated automatically from the real files** by `R/98_generate_appendix.R`,
so it cannot drift from the code that runs.

The whole data workstream can be run with one command, which executes the three steps in order
and refuses to leave a half-finished state behind:

```bash
Rscript R/run_data_prep.R
```

Or step by step, from the repository root:

```bash
Rscript R/00_run_all.R          # everything: data preparation and network analysis
Rscript R/run_data_prep.R       # data workstream only
Rscript R/99_verify_data.R      # optional: independent verification, round 1
Rscript R/99b_verify_output.R   # optional: internal invariants, round 2
```

<!-- GENERATED APPENDIX START -->

### `R/00_run_all.R`

````r
# 00 - Complete project runner.
#
# Run from the repository root:
#   Rscript R/00_run_all.R
#
# This keeps the analysis modular while providing one reproducible entry point.

steps <- c(
  "R/run_data_prep.R",
  "R/04_build_networks.R",
  "R/05_measure_change.R",
  "R/06_model_outcome.R",
  "R/07_figures.R"
)

for (step in steps) {
  if (!file.exists(step)) {
    stop("Missing pipeline step: ", step, call. = FALSE)
  }
  cat("\n===== Running ", step, " =====\n", sep = "")
  source(step, echo = FALSE, chdir = FALSE)
}

cat("\nProject pipeline completed successfully.\n")
````

### `R/run_data_prep.R`

````r
# run_data_prep.R - One command that runs the whole data workstream.
#
#   Rscript R/run_data_prep.R
#
# Run it from the repository root. It executes the three steps in order:
#   01_read_raw.R        parse both SNAP files
#   02_build_attempts.R  reconstruct attempts, write votes.rds and attempts.rds
#   03_validate_outcomes.R  validate against wiki-Elec, write attempts_validated.rds
#
# WHY A WRAPPER AND NOT ONE BIG SCRIPT
# The three steps stay separate files because they are three different jobs and
# because a failure in one must not be mistaken for a result of another. This
# file only orchestrates them; it contains no analysis.
#
# WHAT THIS WRAPPER GUARANTEES, which plain source() calls do not:
#  1. STALE OUTPUTS CANNOT SURVIVE A FAILURE. The outputs of the whole chain are
#     deleted before anything starts. Without this, a step that fails leaves the
#     previous run's .rds on disk, and the next step - or the next person -
#     silently works on data that does not correspond to the current code. That
#     is exactly the "one part fails and misleads the other part" problem.
#  2. IT STOPS AT THE FIRST ERROR, naming the step that failed, and exits with a
#     non-zero status so a shell or CI notices. Any output the failed step had
#     already written is moved aside into data/processed/failed_run_<time>/, so
#     it stays available for debugging but cannot be mistaken for a result: a
#     step that dies after writing some of its files is the worst case, and it
#     is the one this handles.
#  3. EACH STEP RUNS IN ITS OWN ENVIRONMENT. Steps 02 and 03 use several
#     variables with the same names (a, v, d, raw, note, log_lines). They never
#     pass anything to each other in memory - they communicate only through
#     files - but isolating them means a leftover object can never be mistaken
#     for a fresh one.
#  4. IT CHECKS THE EXPECTED OUTPUTS EXIST at the end, so a partial success
#     cannot pass for a complete run.
#  5. Warnings are printed as they happen rather than collected at the end, so
#     the line that produced them is visible.
#
# Expected total time: a few minutes, almost all of it in step 03, which sweeps
# 3 rules x 17 thresholds over the whole dataset.

options(warn = 1)
t_start <- Sys.time()
source(file.path("R", "00_paths.R"))

STEPS <- c("01_read_raw.R", "02_build_attempts.R", "03_validate_outcomes.R")

EXPECTED <- c(
  "votes_raw.rds", "elec_raw.rds", "username_case_variants.csv",
  "votes.rds", "attempts.rds", "records_without_voter.csv",
  "02_log.txt", "attempts_validated.rds", "03_match_wikielec.csv",
  "03_threshold_sweep.csv", "03_log.txt", "attempts_analysis.rds",
  "data_preparation_summary.txt"
)

dir.create(DIR_PROCESSED, showWarnings = FALSE, recursive = TRUE)

# --- 1. clear the outputs of the chain ---------------------------------------
old <- file.path(DIR_PROCESSED, EXPECTED)
removed <- sum(file.remove(old[file.exists(old)]))
cat(sprintf("Cleared %d output file(s) from a previous run.\n", removed))

# --- 2. run the steps --------------------------------------------------------
for (i in seq_along(STEPS)) {
  step <- STEPS[i]
  cat(sprintf("\n=============== STEP %d of %d: %s ===============\n",
              i, length(STEPS), step))
  t0 <- Sys.time()
  ok <- tryCatch({
    sys.source(file.path("R", step), envir = new.env(parent = globalenv()))
    TRUE
  }, error = function(e) {
    cat(sprintf("\nSTEP FAILED: %s\n  %s\n", step, conditionMessage(e)))
    FALSE
  })
  if (!ok) {
    # Move aside whatever this aborted run had already written. A step can fail
    # after producing some of its outputs, and those files are not results.
    left <- file.path(DIR_PROCESSED, EXPECTED)
    left <- left[file.exists(left)]
    if (length(left) > 0) {
      quarantine <- file.path(DIR_PROCESSED,
                              format(Sys.time(), "failed_run_%Y%m%d_%H%M%S"))
      dir.create(quarantine, showWarnings = FALSE, recursive = TRUE)
      file.rename(left, file.path(quarantine, basename(left)))
      cat(sprintf("\nMoved %d partial output file(s) into %s/\n",
                  length(left), quarantine))
    }
    cat("\nThe chain stopped here. Nothing downstream was run, and no file from\n",
        "this run is left where a result is expected, so nothing can be mistaken\n",
        "for one. Fix the error and run this script again.\n", sep = "")
    quit(status = 1, save = "no")
  }
  cat(sprintf("--- %s finished in %.1f s ---\n", step,
              as.numeric(difftime(Sys.time(), t0, units = "secs"))))
}

v <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
a <- readRDS(file.path(DIR_PROCESSED, "attempts_validated.rds"))

# --- 3. create the analysis table used by stages 04-07 ----------------------
outcome_mismatch <- !is.na(a$elec_matched) &
  a$elec_matched &
  !is.na(a$outcome_agrees) &
  !a$outcome_agrees
a$outcome_analysis <- a$outcome
a$outcome_analysis[outcome_mismatch] <- NA_integer_
a$year_analysis <- a$year_from_date
saveRDS(a, file.path(DIR_PROCESSED, "attempts_analysis.rds"))

repeat_counts <- table(a$candidate)
summary_lines <- c(
  paste("Validated vote rows:", nrow(v)),
  paste("Attempts:", nrow(a)),
  paste("Repeat candidates:", sum(repeat_counts >= 2L)),
  paste("Consecutive attempt pairs:", sum(repeat_counts[repeat_counts >= 2L] - 1L)),
  paste("Externally matched attempts:", sum(a$elec_matched)),
  paste(
    "Outcome disagreements excluded from outcome analysis:",
    sum(outcome_mismatch)
  ),
  paste("Self-votes retained in votes table:", sum(v$self_vote)),
  paste("Neutral votes retained in votes table:", sum(v$vot == 0L)),
  "First-letter username variants are merged.",
  "Network analysis excludes self-votes and neutral votes."
)
writeLines(
  summary_lines,
  file.path(DIR_PROCESSED, "data_preparation_summary.txt")
)

# --- 4. check that everything expected is on disk ---------------------------
missing <- EXPECTED[!file.exists(file.path(DIR_PROCESSED, EXPECTED))]
if (length(missing) > 0) {
  cat("\nINCOMPLETE RUN. These expected outputs are missing:\n  ",
      paste(missing, collapse = "\n  "), "\n", sep = "")
  quit(status = 1, save = "no")
}

av <- readRDS(file.path(DIR_PROCESSED, "attempts_validated.rds"))
cat(sprintf("\n=============== DONE in %.1f min ===============\n",
            as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
cat(sprintf("votes.rds              %7d validated votes\n", nrow(v)))
cat(sprintf("attempts.rds           %7d attempts, %d repeat candidates\n",
            nrow(a), sum(table(a$candidate) > 1)))
cat(sprintf("attempts_validated.rds %7d attempts with an external match\n",
            sum(av$elec_matched)))
cat("\nFull documentation of what these tables contain: docs/DATA.md\n")
cat("Optional verification rounds:\n")
cat("  Rscript R/99_verify_data.R      claims recomputed from the raw files\n")
cat("  Rscript R/99b_verify_output.R   internal invariants of the tables\n")
````

### `R/00_paths.R`

````r
# Shared paths and helpers. Sourced by the other scripts; not meant to be run
# on its own. All paths are relative to the repository root, so every script
# must be launched from there.

DIR_RAW       <- file.path("data", "raw")
DIR_PROCESSED <- file.path("data", "processed")
DIR_FIGURES   <- file.path("output", "figures")

FILE_RFA  <- file.path(DIR_RAW, "wiki-RfA.txt.gz")
FILE_ELEC <- file.path(DIR_RAW, "wikiElec.ElecBs3.txt.gz")

THRESHOLD_DAYS <- 7
MERGE_FIRST_LETTER <- TRUE

stop_if_missing <- function(path) {
  if (!file.exists(path)) {
    stop("Missing file: ", path, ". See data/raw/README.md for how to get it.",
         call. = FALSE)
  }
  invisible(TRUE)
}
````

### `R/00_lib_data.R`

````r
# Shared functions of the data workstream. Sourced by 01, 02, 03 and by the two
# verification scripts. Base R only: no dependencies.

# --- parsers for the two files ------------------------------------------------
FIELDS <- c("SRC", "TGT", "VOT", "RES", "YEA", "DAT", "TXT")

read_rfa <- function(path) {
  stop_if_missing(path)
  lines <- readLines(gzfile(path), warn = FALSE, encoding = "UTF-8")
  keys  <- sub(":.*$", "", lines)
  vals  <- sub("^[A-Z]{3}:", "", lines)
  keep  <- keys %in% FIELDS
  # Sanity check: the discarded lines must be the blank separators only. If any
  # non-empty line is dropped, TXT comments span several lines and the parser
  # would be losing text without noticing.
  dropped_non_empty <- sum(!keep & lines != "")
  if (dropped_non_empty > 0) {
    warning("non-empty lines discarded: ", dropped_non_empty,
            " (multi-line TXT comments?)")
  }
  keys <- keys[keep]; vals <- vals[keep]
  rec  <- cumsum(keys == "SRC")   # every SRC line opens a new record
  n_fields <- table(table(rec))
  if (length(n_fields) != 1L || names(n_fields)[1] != "7") {
    warning("records whose field count is not 7: ",
            paste(names(n_fields), n_fields, sep = "x", collapse = " "))
  }
  out <- as.data.frame(tapply(vals, list(rec, keys), identity),
                       stringsAsFactors = FALSE)
  # NOTE 1 - the spelling of a username is NOT its identity. Three fixes, each
  # forced by a defect measured in the file:
  #  - 43 spellings carry a leading or trailing blank, and 21 of those collide
  #    with the clean form already present: without trimming, distinct names are
  #    11,402 instead of 11,381, the figure published by SNAP;
  #  - one name has a double internal space ("Salvio  giuliano") and collides
  #    with the single-space form, which is already present;
  #  - one name carries an invisible marker at the front (U+200E, LEFT-TO-RIGHT
  #    MARK: "<U+200E>Jetijonez"), which would make it a node of its own.
  # After normalisation the distinct names are 11,380.
  out$SRC <- clean_name(out$SRC)
  out$TGT <- clean_name(out$TGT)
  out$vote_id <- seq_len(nrow(out))
  out[, c("vote_id", FIELDS)]
}

# NOTE 2 - first-letter case variants. On Wikipedia the first letter of a
# username is always capitalised, so "harej" and "Harej" are the same account.
# The SNAP total of 11,381 does NOT merge them; merging brings the count down to
# 11,243. OPEN DECISION (it concerns both roles): merge or not. If they are not
# merged, 8 candidates look like two different people with one attempt each and
# fall outside the repeat-candidate population. This function lists the cases so
# the decision can be made on data rather than by intuition.
capitalise_first <- function(s) {
  ifelse(s == "" | is.na(s), s,
         paste0(toupper(substr(s, 1, 1)), substr(s, 2, nchar(s))))
}

case_variants <- function(d) {
  names_all <- unique(c(d$SRC, d$TGT))
  groups <- split(names_all, capitalise_first(names_all))
  ambiguous <- groups[lengths(groups) > 1]
  if (length(ambiguous) == 0) return(data.frame())
  do.call(rbind, lapply(names(ambiguous), function(nm) {
    spellings <- ambiguous[[nm]]
    data.frame(
      merged_name    = nm,
      spelling       = spellings,
      n_votes_cast   = vapply(spellings, function(f) sum(d$SRC == f), integer(1)),
      n_votes_received = vapply(spellings, function(f) sum(d$TGT == f), integer(1)),
      years_as_candidate = vapply(spellings, function(f) {
        paste(sort(unique(d$YEA[d$TGT == f])), collapse = ";")
      }, character(1)),
      row.names = NULL, stringsAsFactors = FALSE
    )
  }))
}

# wiki-Elec: blocks, one per election, fields separated by tabs.
#   E <0|1>                                          outcome
#   T <YYYY-MM-DD HH:MM:SS>                          declared closing time
#   U <id> <username>                                candidate
#   N <id> <username>                                nominator (may be missing)
#   V <vote> <id> <YYYY-MM-DD HH:MM:SS> <username>   one vote per line
# NOTE 3 - three traps in this file, all about node identity:
#  (a) usernames are ALL LOWERCASE here, while wiki-RfA keeps the original
#      spelling, and wiki-Elec uses an UNDERSCORE where wiki-RfA uses a SPACE
#      (408 names with an underscore and 0 with a space, against 0 and 606 in
#      wiki-RfA). Normalising the names raises the share of wiki-Elec candidates
#      found again in wiki-RfA from 74.9% to 89.8%: see norm_user() below;
#  (b) the file is UTF-8 but contains corrupt bytes: 19 lines out of 128,016 are
#      not valid UTF-8, and all of them belong to the same user (a truncated
#      sequence, "eivind_f_<c3>yangen"). Without intervention substr() stops
#      with "invalid multibyte string". Invalid bytes are dropped with
#      iconv(sub = ""): converting the whole file from ISO-8859-1, which the
#      success of 'iconv -f ISO-8859-1' would seem to suggest, is WRONG, because
#      it ruins the names that were correct UTF-8 (anarion -> anÃ¡rion);
#  (c) lines end in CRLF. R's readLines() already strips the terminator, so the
#      sub() below is a safety net that does nothing here; it would matter when
#      reading the file with readBin, with scan(sep = "\n"), or on a connection
#      opened in binary mode.
read_elec <- function(path) {
  stop_if_missing(path)
  lines <- iconv(readLines(gzfile(path), warn = FALSE, skipNul = TRUE),
                 from = "UTF-8", to = "UTF-8", sub = "")   # (b)
  lines <- sub("\r$", "", lines)                           # (c)
  lines <- lines[!startsWith(lines, "#") & nzchar(lines)]
  tag   <- substr(lines, 1, 1)
  block <- cumsum(tag == "E")
  field_rows <- function(t) {
    i <- which(tag == t)
    data.frame(block = block[i], rest = sub("^.\t", "", lines[i]),
               stringsAsFactors = FALSE)
  }
  e <- field_rows("E"); tt <- field_rows("T"); u <- field_rows("U"); n <- field_rows("N")
  part_of <- function(x, k) vapply(strsplit(x, "\t", fixed = TRUE),
                                 function(p) if (length(p) >= k) p[k] else NA_character_,
                                 character(1))
  elections <- data.frame(
    election_id = e$block,
    outcome     = as.integer(e$rest),                       # 1 promoted, 0 not
    closed_at   = as.POSIXct(tt$rest[match(e$block, tt$block)],
                             format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    candidate   = trimws(part_of(u$rest[match(e$block, u$block)], 2)),
    nominator   = trimws(part_of(n$rest[match(e$block, n$block)], 2)),
    stringsAsFactors = FALSE
  )
  iv <- which(tag == "V")
  pv <- strsplit(sub("^V\t", "", lines[iv]), "\t", fixed = TRUE)
  elec_votes <- data.frame(
    election_id = block[iv],
    vot   = as.integer(vapply(pv, `[`, character(1), 1)),
    voter = trimws(vapply(pv, function(p) if (length(p) >= 4) p[4] else NA_character_,
                          character(1))),
    dat   = as.POSIXct(vapply(pv, function(p) if (length(p) >= 3) p[3] else NA_character_,
                              character(1)),
                       format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    stringsAsFactors = FALSE
  )
  list(elections = elections, votes = elec_votes)
}

# --- user identity ------------------------------------------------------------
# Spelling normalisation WITHIN a single file: strips invisible characters,
# collapses repeated blanks and trims the edges. It does not touch letter case:
# that is an open decision (MERGE_FIRST_LETTER in 02).
clean_name <- function(x) {
  for (code_point in c(0x200B:0x200F, 0xFEFF)) {
    x <- gsub(intToUtf8(code_point), "", x, fixed = TRUE)
  }
  x <- gsub("[[:space:]]+", " ", x)           # repeated or exotic blanks -> one
  trimws(x)
}

# Comparison key ACROSS the two files. Three normalisations, each forced by a
# measured defect, not by generic caution:
#  - clean_name, for the reasons in NOTE 1;
#  - underscore -> space: wiki-Elec writes "dream_focus", wiki-RfA "Dream Focus";
#  - tolower: wiki-Elec is entirely lowercase. On Wikipedia the first letter of a
#    username is always capitalised, so "harej" and "Harej" are the same account:
#    for COMPARING the two files, tolower is correct. Whether to apply it WITHIN
#    wiki-RfA as well, merging 137 groups of spellings, is an open decision (see
#    the documentation): it changes the node count and the study population.
norm_user <- function(x, lower = TRUE) {
  x <- clean_name(gsub("_", " ", x))
  if (lower) tolower(x) else x
}

# --- dates --------------------------------------------------------------------
# NOTE 4 - the DAT field of wiki-RfA has the shape "HH:MM, DD Month YYYY", but:
#  - 9,367 records have DAT empty, and 1,661 of those are the voter-less phantom
#    records removed in 02, so the real figure among actual votes is 7,707;
#  - 7,077 use the abbreviated month (Jan, Feb, ...). "May" is identical in both
#    forms and is therefore not a problem case;
#  - 3 have the month misspelled in the source: "Janry", "Julu", "Mya";
#  - 1 has an impossible value: "31:29, 24 May 2008", hour 31.
# A parser built on format = "%d %B %Y" would depend on LC_TIME (so it would
# give different results on another machine) and would silently turn 7,080 dates
# into NA. Here the month is translated with an explicit, locale-independent
# table.
MONTHS <- c(
  january = 1, february = 2, march = 3, april = 4, may = 5, june = 6,
  july = 7, august = 8, september = 9, october = 10, november = 11, december = 12,
  jan = 1, feb = 2, mar = 3, apr = 4, jun = 6, jul = 7, aug = 8,
  sep = 9, oct = 10, nov = 11, dec = 12,
  janry = 1, julu = 7, mya = 5          # misspellings found in the source
)

parse_dat <- function(x) {
  x <- trimws(x)
  m <- regmatches(x, regexec(
    "^([0-9]{1,2}):([0-9]{2}), ([0-9]{1,2}) ([A-Za-z]+) ([0-9]{4})$", x))
  ok <- lengths(m) == 6L
  out <- rep(NA_real_, length(x))
  if (any(ok)) {
    p <- do.call(rbind, m[ok])
    month_num <- MONTHS[tolower(p[, 5])]
    iso <- sprintf("%s-%02d-%02d %02d:%02d:00",
                   p[, 6], month_num, as.integer(p[, 4]),
                   as.integer(p[, 2]), as.integer(p[, 3]))
    out[ok] <- as.numeric(as.POSIXct(iso, format = "%Y-%m-%d %H:%M:%S", tz = "UTC"))
  }
  res <- as.POSIXct(out, origin = "1970-01-01", tz = "UTC")
  # Careful: passing the format check is not enough. One record reads
  # "31:29, 24 May 2008": hour 31 satisfies the regex but as.POSIXct rejects it
  # and returns NA. The diagnostic must count the NAs produced AFTER the date is
  # built, not just the unrecognised formats, otherwise it reports zero when the
  # true figure is one (it used to).
  attr(res, "n_bad_format") <- sum(!ok & nzchar(x))
  attr(res, "n_impossible") <- sum(ok & is.na(res))
  attr(res, "n_unparsed")        <- sum(!ok & nzchar(x)) + sum(ok & is.na(res))
  attr(res, "n_empty")              <- sum(!nzchar(x))
  res
}

# NOTE ON ORDERING - every order() call on usernames below passes
# method = "radix". Without it, order() sorts character vectors using the
# machine's collation locale, so the SAME data produces a DIFFERENT attempt_id
# numbering on a different machine: measured, 3,763 of 4,081 attempt_id values
# differed between a Windows run and a macOS run of identical code on identical
# data. The attempts themselves were identical - same set, same attempt_no, all
# 19 substantive columns equal - but the ids were permuted, which breaks any
# cross-reference between a committed CSV (03_match_wikielec.csv carries
# my_attempt, output/results/attempt_pairs.csv carries previous_attempt_id and
# next_attempt_id) and a locally regenerated table. "radix" sorts by byte, which
# is locale-independent, and makes the whole pipeline byte-reproducible: checked
# by running it under LC_COLLATE=it_IT and LC_COLLATE=C.

# --- attempt reconstruction ---------------------------------------------------
# Three rules are compared against wiki-Elec in 03 instead of being picked by
# feel.
#
# "gap_then_res": sort by date within the candidate and open a new attempt when
#   the gap exceeds the threshold or RES changes. DISCARDED after testing: a
#   single vote carrying a different RES, sitting inside an election, splits it
#   in three. It produced 1,420 single-vote attempts concentrated on 95
#   candidates (e.g. ABCD: four attempts in one week with outcomes alternating
#   -1, 1, -1, 1). It is kept implemented because the comparison between the two
#   rules is itself a result.
#
# "res_then_gap": group by (candidate, RES) and, within each group, open a new
#   attempt when the gap exceeds the threshold. The votes of two nearby
#   elections with different outcomes separate through RES, and a stray vote
#   does no damage. This is also the rule of the published precedent
#   (Kolczynska), which groups by candidate, year and outcome. The year is NOT
#   used here: YEA is unreliable, 1,875 votes carry a date in a different year
#   from the declared one, in coherent blocks (e.g. Scienceman123, YEA 2008,
#   votes dated March 2006).
#
# Undated votes cannot be ordered: they stay out and are attached afterwards,
# only where the attribution is unambiguous (see 02).
#
# "gap_only": group only by candidate and date gap, and mark an attempt with
#   mixed RES values as outcome-unknown. This is the sensitivity rule that avoids
#   using the potentially inconsistent RES field to define boundaries.
reconstruct_attempts <- function(d, threshold_days, mode = "res_then_gap") {
  stopifnot(all(c("tgt", "vot", "res", "yea", "dat") %in% names(d)))
  stopifnot(mode %in% c("res_then_gap", "gap_then_res", "gap_only"))
  d <- d[!is.na(d$dat), ]
  if (nrow(d) == 0) return(d)
  if (mode == "res_then_gap") {
    d <- d[order(d$tgt, d$res, d$dat, method = "radix"), ]
    n <- nrow(d)
    group_change <- c(TRUE, d$tgt[-1] != d$tgt[-n] | d$res[-1] != d$res[-n])
  } else if (mode == "gap_then_res") {
    d <- d[order(d$tgt, d$dat, method = "radix"), ]
    n <- nrow(d)
    group_change <- c(TRUE, d$tgt[-1] != d$tgt[-n] | d$res[-1] != d$res[-n])
  } else {
    d <- d[order(d$tgt, d$dat, method = "radix"), ]
    n <- nrow(d)
    group_change <- c(TRUE, d$tgt[-1] != d$tgt[-n])
  }
  gap_days <- c(NA_real_, as.numeric(difftime(d$dat[-1], d$dat[-n], units = "days")))
  is_new <- group_change | (!group_change & gap_days > threshold_days)
  is_new[is.na(is_new)] <- TRUE
  d$attempt_id <- cumsum(is_new)
  # running number of the attempt within the candidate, by opening date
  ap <- tapply(as.numeric(d$dat), d$attempt_id, min)
  first_tbl <- data.frame(attempt_id = as.integer(names(ap)), opened = as.numeric(ap))
  first_tbl$tgt <- d$tgt[match(first_tbl$attempt_id, d$attempt_id)]
  first_tbl <- first_tbl[order(first_tbl$tgt, first_tbl$opened, method = "radix"), ]
  first_tbl$attempt_no <- ave(first_tbl$opened, first_tbl$tgt, FUN = seq_along)
  d$attempt_no <- first_tbl$attempt_no[match(d$attempt_id, first_tbl$attempt_id)]
  d
}

# --- deduplication ------------------------------------------------------------
# A voter may appear more than once within the same attempt: a changed vote, or
# a duplicated row. Rule: keep that voter's most recent vote in that attempt.
# The most plausible reading is that the voter changed their mind, in which case
# the duplicate is signal rather than noise. Returns the cleaned table and the
# number of rows removed.
dedup_votes <- function(d) {
  o <- order(d$attempt_id, d$src, d$dat, method = "radix")
  d <- d[o, ]
  keep_row <- !duplicated(d[, c("attempt_id", "src")], fromLast = TRUE)
  attr(d, "n_rows_removed") <- sum(!keep_row)
  structure(d[keep_row, ], n_rows_removed = sum(!keep_row))
}

# --- attempt-level table ------------------------------------------------------
build_attempts <- function(v) {
  a <- data.frame(
    attempt_id   = sort(unique(v$attempt_id)),
    stringsAsFactors = FALSE
  )
  idx <- match(a$attempt_id, v$attempt_id)
  a$candidate  <- v$tgt[idx]
  a$attempt_no <- v$attempt_no[idx]
  a$outcome    <- v$res[idx]                       # -1 rejected, 1 approved
  a$yea        <- v$yea[idx]
  spl <- split(seq_len(nrow(v)), v$attempt_id)
  spl <- spl[as.character(a$attempt_id)]
  # opening and closing come from DATED votes only: imputed votes carry no date
  # and must not move the boundaries of the attempt
  a$opened_at    <- as.POSIXct(vapply(spl, function(i) min(as.numeric(v$dat[i]), na.rm = TRUE), 0),
                               origin = "1970-01-01", tz = "UTC")
  a$closed_at    <- as.POSIXct(vapply(spl, function(i) max(as.numeric(v$dat[i]), na.rm = TRUE), 0),
                               origin = "1970-01-01", tz = "UTC")
  a$n_votes      <- vapply(spl, length, 0L)
  a$n_support    <- vapply(spl, function(i) sum(v$vot[i] ==  1), 0L)
  a$n_oppose     <- vapply(spl, function(i) sum(v$vot[i] == -1), 0L)
  a$n_neutral    <- vapply(spl, function(i) sum(v$vot[i] ==  0), 0L)
  # self-votes: the candidate voting in their own RfA. There are 103 in the raw
  # file and they are loops in the voting network; they stay in the table, flagged.
  a$n_self_votes <- vapply(spl, function(i) sum(v$src[i] == v$tgt[i]), 0L)
  # support share over support and oppose votes only: neutrals are left out of
  # the denominator. This is a stated convention, not the only possible one.
  a$support_share <- ifelse(a$n_support + a$n_oppose > 0,
                            a$n_support / (a$n_support + a$n_oppose), NA_real_)
  a$duration_days <- as.numeric(difftime(a$closed_at, a$opened_at, units = "days"))
  # ambiguity flags
  a$flag_short      <- a$n_votes < 5          # few votes: possibly a fragment
  a$flag_long       <- a$duration_days > 14   # longer than a normal RfA
  # two attempts of the same candidate, in the same year, with the same outcome:
  # suspected of being a single attempt split by the threshold. The year is read
  # from the opening DATE, not from YEA: YEA is unreliable (1,875 votes carry a
  # date in a different year), and using it here would contradict the decision
  # not to use it in the reconstruction.
  a$year_from_date <- as.integer(format(a$opened_at, "%Y"))
  key <- paste(a$candidate, a$year_from_date, a$outcome)
  a$flag_year_clash <- key %in% key[duplicated(key)]
  a[order(a$candidate, a$attempt_no, method = "radix"), ]
}
````

### `R/01_read_raw.R`

````r
# 01 - Read the two raw files. No substantive cleaning here.
# Input : data/raw/wiki-RfA.txt.gz, data/raw/wikiElec.ElecBs3.txt.gz
# Output: data/processed/votes_raw.rds, data/processed/elec_raw.rds,
#         data/processed/username_case_variants.csv
# Packages: none (base R).
#
# The two parsers live in R/00_lib_data.R so the independent verification
# (R/99_verify_data.R) can use them too.
# This script only turns the text formats into tables and normalises username
# spelling (see NOTE 1 in the library). It does not deduplicate and decides
# nothing substantive: that is step 02.

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

votes_raw <- read_rfa(FILE_RFA)
dir.create(DIR_PROCESSED, showWarnings = FALSE, recursive = TRUE)
saveRDS(votes_raw, file.path(DIR_PROCESSED, "votes_raw.rds"))

elec <- read_elec(FILE_ELEC)
saveRDS(elec, file.path(DIR_PROCESSED, "elec_raw.rds"))

cv <- case_variants(votes_raw)
write.csv(cv, file.path(DIR_PROCESSED, "username_case_variants.csv"), row.names = FALSE)

# Control counts against the totals published by SNAP.
n_votes  <- nrow(votes_raw)
n_users  <- length(unique(c(votes_raw$SRC, votes_raw$TGT)))
cat("--- wiki-RfA ---\n")
cat("votes:                 ", n_votes, " (SNAP: 198275)",
    if (n_votes == 198275) " OK" else " MISMATCH", "\n", sep = "")
cat("distinct users:        ", n_users,
    " (expected 11380; SNAP reports 11381 because it does not merge one double",
    " internal space and one invisible character, see NOTE 1)",
    if (n_users == 11380) " OK" else " MISMATCH", "\n", sep = "")
# NOTE - distinct pairs are 189,001 after normalisation and 189,004 without it:
# a couple of pairs appear under two spellings. The SNAP totals are therefore
# not consistent with each other: 11,381 users is a post-trim count, 189,004
# pairs is a pre-trim one. This belongs in the data section of the report.
cat("voter-candidate pairs: ", nrow(unique(votes_raw[, c("SRC", "TGT")])),
    " (SNAP: 189004, pre-normalisation)\n", sep = "")
cat("users after merging the first letter: ",
    length(unique(capitalise_first(c(votes_raw$SRC, votes_raw$TGT)))), "\n", sep = "")
cat("spelling groups differing only in the first letter: ",
    length(unique(cv$merged_name)),
    " (listed in data/processed/username_case_variants.csv)\n", sep = "")
cat("  of which the person is a candidate under at least one spelling: ",
    length(unique(cv$merged_name[cv$n_votes_received > 0])), "\n", sep = "")
cat("  of which the CANDIDATE appears under two spellings: ",
    length(unique(cv$merged_name[ave(cv$n_votes_received > 0, cv$merged_name,
                                     FUN = sum) > 1])),
    "  <- destructive for attempt reconstruction\n", sep = "")

cat("\n--- wiki-Elec ---\n")
cat("elections: ", nrow(elec$elections), " (SNAP: 2794)",
    if (nrow(elec$elections) == 2794) " OK" else " MISMATCH", "\n", sep = "")
cat("votes: ", nrow(elec$votes), "\n", sep = "")
cat("promotions: ", sum(elec$elections$outcome == 1),
    "   rejections: ", sum(elec$elections$outcome == 0),
    "   (SNAP: about 1200 / 1500)\n", sep = "")
cat("declared closing times from ", format(min(elec$elections$closed_at), "%Y-%m-%d"),
    " to ", format(max(elec$elections$closed_at), "%Y-%m-%d"),
    "  -- but field T is unreliable, see 03\n", sep = "")
cat("distinct candidates: ", length(unique(elec$elections$candidate)),
    "   with more than one election: ",
    sum(table(elec$elections$candidate) > 1), "\n", sep = "")
cat("missing closing times: ", sum(is.na(elec$elections$closed_at)), "\n", sep = "")
````

### `R/02_build_attempts.R`

````r
# 02 - Attempt reconstruction: one row per (candidate, attempt).
# Input : data/processed/votes_raw.rds
# Output: data/processed/votes.rds              one row per validated vote
#         data/processed/attempts.rds           one row per attempt
#         data/processed/records_without_voter.csv
#         data/processed/02_log.txt             every quantity, for the report
# Packages: none (base R).
#
# PRINCIPLE: do not filter, flag. Every problematic row stays in the table with
# a flag column, so whoever analyses decides what to exclude, not whoever
# cleans. Only two kinds of row are dropped, and both are counted in the log:
# the voter-less phantom records, which are not votes at all, and the undated
# votes that cannot be attributed to a single attempt.
#
# The threshold is a PARAMETER, not an assumption: 03_validate_outcomes.R picks
# it by comparing the reconstruction against the real elections of wiki-Elec.
# The value set here is the published precedent (Kolczynska) and the nominal
# length of an RfA.

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

MODE               <- "res_then_gap"  # grouping rule, see 00_lib_data.R
                                      # variants (harej/Harej). FALSE keeps the
                                      # SNAP convention of 11,381 nodes.

log_lines <- character(0)
note <- function(...) {
  s <- paste0(...)
  log_lines <<- c(log_lines, s)
  cat(s, "\n", sep = "")
}

# --- 1. raw votes, columns renamed in lowercase ------------------------------
raw <- readRDS(file.path(DIR_PROCESSED, "votes_raw.rds"))
d <- data.frame(
  vote_id = raw$vote_id,
  src = raw$SRC, tgt = raw$TGT,
  vot = as.integer(raw$VOT), res = as.integer(raw$RES),
  yea = as.integer(raw$YEA),
  stringsAsFactors = FALSE
)
d$self_vote <- d$src == d$tgt
note("incoming records: ", nrow(d))

if (MERGE_FIRST_LETTER) {
  d$src <- capitalise_first(d$src); d$tgt <- capitalise_first(d$tgt)
  note("usernames: first letter merged -> distinct nodes: ",
       length(unique(c(d$src, d$tgt))))
} else {
  note("usernames: SNAP spelling kept -> distinct nodes: ",
       length(unique(c(d$src, d$tgt))))
}
d$self_vote <- d$src == d$tgt

# --- 2. dates ----------------------------------------------------------------
dd <- parse_dat(raw$DAT)
d$dat <- dd
d$dat_missing <- is.na(d$dat)
note("records with an empty DAT field: ", attr(dd, "n_empty"),
     sprintf("  (%.2f%% of all records)", 100 * attr(dd, "n_empty") / nrow(d)))
note("DAT present but not interpretable: ", attr(dd, "n_unparsed"),
     "  (unrecognised format: ", attr(dd, "n_bad_format"),
     " | impossible value, e.g. hour 31: ", attr(dd, "n_impossible"), ")")

# --- 3. phantom records, with no voter ---------------------------------------
# 1,661 records have SRC empty, and ALL of them also have TXT and DAT empty:
# they are phantom records of the file, not votes. They touch 926 candidates,
# concentrated in 2006 (800 of them). Left in the table they would become a
# SINGLE NODE with 1,661 outgoing edges towards 926 candidates: a hub that does
# not exist, which would distort every centrality measure and the whole
# co-voting projection. They cannot be "flagged": a vote with no voter is not an
# edge. They are removed and written out separately so that nothing disappears
# silently.
no_voter <- d[d$src == "", ]
write.csv(no_voter[, c("vote_id", "tgt", "vot", "res", "yea")],
          file.path(DIR_PROCESSED, "records_without_voter.csv"), row.names = FALSE)
note("phantom records with an empty SRC, removed: ", nrow(no_voter),
     " of ", nrow(d), sprintf("  (%.2f%%)", 100 * nrow(no_voter) / nrow(d)))
note("  candidates touched: ", length(unique(no_voter$tgt)),
     " | listed in records_without_voter.csv")
d <- d[d$src != "", ]
note("votes with an identifiable voter: ", nrow(d))

# --- 4. self-votes -----------------------------------------------------------
note("self-votes (the candidate voting in their own RfA): ", sum(d$src == d$tgt),
     "  -> kept in the table, flagged by the self_vote column")

# --- 5. where the undated votes fall -----------------------------------------
undated <- d[d$dat_missing, ]
note("undated votes, among those with a voter: ", nrow(undated))
note("candidates touched by undated votes: ", length(unique(undated$tgt)))
note("  of which with a single YEA among their undated votes: ",
     sum(tapply(undated$yea, undated$tgt, function(x) length(unique(x))) == 1))

# --- 6. fully identical rows -------------------------------------------------
row_keys <- paste(d$src, d$tgt, d$vot, d$res, d$yea, format(d$dat), sep = "\r")
note("fully identical rows (same voter, candidate, vote, outcome, year, date): ",
     sum(duplicated(row_keys)))

# --- 7. reconstruction -------------------------------------------------------
v <- reconstruct_attempts(d, THRESHOLD_DAYS, MODE)
note("rule: ", MODE, "; threshold: ", THRESHOLD_DAYS, " days")
note("dated votes used in the reconstruction: ", nrow(v))
note("attempts reconstructed: ", length(unique(v$attempt_id)))
note("candidates with at least one attempt: ", length(unique(v$tgt)))

# --- 8. deduplication within the attempt -------------------------------------
v <- dedup_votes(v)
note("votes removed because the same voter appears more than once in the same ",
     "attempt (most recent kept): ", attr(v, "n_rows_removed"))
note("validated votes: ", nrow(v))

# --- 9. attribution of the undated votes -------------------------------------
# They are attached only where the attribution is unambiguous: the candidate has
# a single attempt with that year and that outcome. The rest stay out, counted.
# A provisional attempt table, built on dated votes only, is needed just to know
# which (candidate, year, outcome) keys are unique.
a <- build_attempts(v)
a$key <- paste(a$candidate, a$yea, a$outcome)
unique_keys <- a$key[!duplicated(a$key) & !(a$key %in% a$key[duplicated(a$key)])]
undated$key <- paste(undated$tgt, undated$yea, undated$res)
undated$attempt_id <- a$attempt_id[match(undated$key, a$key)]
undated$attempt_id[!(undated$key %in% unique_keys)] <- NA_integer_
note("undated votes attributed unambiguously: ", sum(!is.na(undated$attempt_id)),
     " of ", nrow(undated))
note("undated votes that cannot be attributed (dropped): ",
     sum(is.na(undated$attempt_id)))
a$key <- NULL

# --- 10. attempt table, built on the COMPLETE vote table ---------------------
# ORDER MATTERS: the per-attempt counts (n_votes, n_support, ..., support_share)
# must be computed AFTER the attributed undated votes are put back, otherwise
# attempts.rds and votes.rds disagree and support_share silently excludes
# thousands of votes. That was a bug, caught by the invariant checks in
# R/99b_verify_output.R.
v$dat_imputed <- FALSE
if (any(!is.na(undated$attempt_id))) {
  extra <- undated[!is.na(undated$attempt_id), ]
  extra$attempt_no  <- a$attempt_no[match(extra$attempt_id, a$attempt_id)]
  extra$dat_imputed <- TRUE
  extra$key <- NULL
  common_cols <- intersect(names(v), names(extra))
  v <- rbind(v[, common_cols], extra[, common_cols])
}
# Second deduplication: within one attempt a voter may hold both a dated vote
# and an undated one that was attributed to them. The DATED vote is kept,
# because it can be checked. The first deduplication (step 8) could not see
# these, because the undated votes only enter here: another bug caught by the
# invariant checks.
v <- v[order(v$attempt_id, v$src, v$dat_imputed, v$dat, method = "radix"), ]
dup_second <- duplicated(v[, c("attempt_id", "src")])
note("votes removed in the second deduplication (same voter, one dated and one ",
     "imputed within the same attempt): ", sum(dup_second))
v <- v[!dup_second, ]
v <- v[order(v$attempt_id, v$src, method = "radix"), ]

a_dated <- a
a <- build_attempts(v)
a$n_votes_dated   <- a_dated$n_votes[match(a$attempt_id, a_dated$attempt_id)]
a$n_votes_imputed <- a$n_votes - a$n_votes_dated

# the previous outcome has to be recomputed on the final table
repeats <- table(a$candidate)
a$prev_outcome <- NA_integer_
for (cand in names(repeats)[repeats > 1]) {
  i <- which(a$candidate == cand); i <- i[order(a$attempt_no[i])]
  a$prev_outcome[i[-1]] <- a$outcome[i[-length(i)]]
}
note("attempts: ", nrow(a))
note("repeat candidates (2+ attempts): ", sum(repeats > 1),
     "   (the project brief states 414)")
note("  of which with 3+ attempts: ", sum(repeats > 2))
note("consecutive attempt pairs: ", sum(repeats[repeats > 1] - 1))
note("flagged attempts: few votes (<5): ", sum(a$flag_short),
     " | duration >14 days: ", sum(a$flag_long),
     " | same candidate/year/outcome: ", sum(a$flag_year_clash))
note("  preceded by a rejection: ", sum(a$prev_outcome == -1, na.rm = TRUE),
     " | preceded by a success: ", sum(a$prev_outcome == 1, na.rm = TRUE))

saveRDS(v, file.path(DIR_PROCESSED, "votes.rds"))
saveRDS(a, file.path(DIR_PROCESSED, "attempts.rds"))
writeLines(log_lines, file.path(DIR_PROCESSED, "02_log.txt"))
note("written: votes.rds (", nrow(v), " rows), attempts.rds (", nrow(a), " rows)")
````

### `R/03_validate_outcomes.R`

````r
# 03 - Validation of the reconstruction against wiki-Elec, and choice of the
#      separation threshold.
# Input : data/processed/votes_raw.rds, data/processed/elec_raw.rds,
#         data/processed/votes.rds, data/processed/attempts.rds
# Output: data/processed/03_threshold_sweep.csv, data/processed/03_match_wikielec.csv,
#         data/processed/attempts_validated.rds, data/processed/03_log.txt
# Packages: none (base R).
#
# HOW A REAL ELECTION IS MATCHED TO A RECONSTRUCTED ATTEMPT
# By voter set, not by date. Two elections of the same person have very
# different voter sets, so the overlap (Jaccard) tells them apart, and the
# criterion does not depend on any date field.
#
# The first version of this script matched by proximity between the declared
# closing time T of wiki-Elec and the last vote of the attempt. That is WRONG,
# because T is unreliable: the difference between T and the last vote OF THE
# SAME ELECTION, inside wiki-Elec itself, has a median of 102 days, and 54% of
# elections have T more than 30 days after their own last vote (1,217 more than
# 180 days; some have T BEFORE their own last vote). The same is visible in the
# fact that 78% of elections are declared closed in 2007 while the votes are
# spread over 2005-2007. Consequences of that error, all corrected here: the
# measured coverage was 36% instead of 78%, 23 under-splits appeared instead of
# 1, and the wrong conclusion was drawn that wiki-RfA did not contain the
# elections of wiki-Elec.

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

GRID           <- c(1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 18, 21, 28, 35, 45, 60)
MODES          <- c("res_then_gap", "gap_then_res", "gap_only")
J_MIN          <- 0.5   # minimum voter overlap to call it the same election
CHOSEN_THRESHOLD <- THRESHOLD_DAYS

log_lines <- character(0)
note <- function(...) { s <- paste0(...); log_lines <<- c(log_lines, s); cat(s, "\n", sep = "") }
jac <- function(x, y) length(intersect(x, y)) / length(union(x, y))

raw  <- readRDS(file.path(DIR_PROCESSED, "votes_raw.rds"))
elec <- readRDS(file.path(DIR_PROCESSED, "elec_raw.rds"))
d <- data.frame(src = raw$SRC, tgt = raw$TGT,
                vot = as.integer(raw$VOT), res = as.integer(raw$RES),
                yea = as.integer(raw$YEA), dat = parse_dat(raw$DAT),
                stringsAsFactors = FALSE)
if (MERGE_FIRST_LETTER) {
  d$src <- capitalise_first(d$src)
  d$tgt <- capitalise_first(d$tgt)
}

ev <- elec$votes; ev$voter_k <- norm_user(ev$voter)
set_el <- split(ev$voter_k, ev$election_id)
ele <- elec$elections
ele$cand_k <- norm_user(ele$candidate)
ele$last_vote <- as.POSIXct(vapply(
  split(as.numeric(ev$dat), ev$election_id)[as.character(ele$election_id)],
  function(x) max(x[x < as.numeric(as.POSIXct("2009-01-01", tz = "UTC"))]), 0),
  origin = "1970-01-01", tz = "UTC")

# --- diagnostic: the T field is unreliable -----------------------------------
dT <- as.numeric(difftime(ele$closed_at, ele$last_vote, units = "days"))
note("wiki-Elec: ", nrow(ele), " elections, declared closing times from ",
     format(min(ele$closed_at), "%Y-%m-%d"), " to ",
     format(max(ele$closed_at), "%Y-%m-%d"),
     ". Earliest last-vote of an election: ",
     format(min(ele$last_vote), "%Y-%m-%d"), ".")
note("Field T (closing time) is UNRELIABLE: the gap between T and the last vote")
note("  of the same election has a median of ", round(median(dT), 1),
     " days; it exceeds 30 days in ", sprintf("%.0f%%", 100 * mean(dT > 30)),
     " of cases; it exceeds 180 days in ", sum(dT > 180),
     " elections; the minimum is ", round(min(dT), 1),
     " days (T before the last vote).")
note("  This is why matching uses VOTER SETS, not dates.\n")

# --- evaluate one rule and one threshold -------------------------------------
evaluate <- function(mode, threshold) {
  v <- reconstruct_attempts(d, threshold, mode)
  v$src_k <- norm_user(v$src)
  set_at <- split(v$src_k, v$attempt_id)
  idx <- match(as.integer(names(set_at)), v$attempt_id)
  outcome_by_attempt <- tapply(v$res, v$attempt_id, function(x) {
    values <- unique(x)
    if (length(values) == 1L) values else NA_integer_
  })
  info <- data.frame(attempt_id = as.integer(names(set_at)),
                     cand_k = norm_user(v$tgt[idx]),
                     outcome = as.integer(outcome_by_attempt[names(set_at)]),
                     n_votes = lengths(set_at), stringsAsFactors = FALSE)
  per <- split(info$attempt_id, info$cand_k)
  best <- rep(NA_real_, nrow(ele)); bid <- rep(NA_integer_, nrow(ele))
  for (r in seq_len(nrow(ele))) {
    ids <- per[[ele$cand_k[r]]]; if (is.null(ids)) next
    s <- set_el[[as.character(ele$election_id[r])]]
    jj <- vapply(ids, function(k) jac(s, set_at[[as.character(k)]]), 0)
    best[r] <- max(jj); bid[r] <- ids[which.max(jj)]
  }
  ok <- !is.na(best) & best > J_MIN
  mo <- info$outcome[match(bid[ok], info$attempt_id)]
  # Agreement on the NUMBER of attempts per candidate is computed only on
  # candidates whose wiki-Elec elections are ALL matched. Computing it on every
  # candidate inflates the figure with accidental agreement: a candidate whose
  # correct election is missing from wiki-RfA, but who has another one, scores
  # "1 against 1" and counts as agreeing.
  per_c <- split(seq_len(nrow(ele)), ele$cand_k)
  full <- names(per_c)[vapply(per_c, function(ii) all(ok[ii]), TRUE)]
  n_true <- table(ele$cand_k[ele$cand_k %in% full])
  n_mine <- table(info$cand_k[info$cand_k %in% full])
  common <- intersect(names(n_true), names(n_mine))
  data.frame(mode, threshold,
             n_attempts = nrow(info),
             matched = sum(ok),
             matched_share = mean(ok),
             median_jaccard = median(best[ok]),
             outcome_agreement = mean(
               (mo == 1) == (ele$outcome[ok] == 1),
               na.rm = TRUE
             ),
             under_split = sum(duplicated(bid[ok])),
             comparable_candidates = length(common),
             count_agreement = mean(n_true[common] == n_mine[common]),
             over = sum(n_mine[common] > n_true[common]),
             under = sum(n_mine[common] < n_true[common]),
             fragments_lt5 = sum(info$n_votes < 5),
             stringsAsFactors = FALSE)
}

note("sweep: ", length(MODES), " rules x ", length(GRID), " thresholds...")
res <- do.call(rbind, lapply(MODES, function(m)
  do.call(rbind, lapply(GRID, function(s) evaluate(m, s)))))
write.csv(res, file.path(DIR_PROCESSED, "03_threshold_sweep.csv"), row.names = FALSE)
pr <- res
for (cc in c("matched_share", "median_jaccard", "outcome_agreement", "count_agreement"))
  pr[[cc]] <- round(pr[[cc]], 4)
print(pr, row.names = FALSE)

rtg <- res[res$mode == "res_then_gap", ]
g <- function(s, col) rtg[[col]][rtg$threshold == s]
note("\nCHOICE OF THE THRESHOLD")
note("  matched elections: ", g(4, "matched"), " at 4 days, ", g(7, "matched"),
     " at 7, ", g(21, "matched"), " at 21, ", g(60, "matched"), " at 60.")
note("  exact attempt count: ", sprintf("%.1f%%", 100 * g(4, "count_agreement")),
     " at 4 days, ", sprintf("%.1f%%", 100 * g(7, "count_agreement")), " at 7, ",
     sprintf("%.1f%%", 100 * g(60, "count_agreement")), " at 60.")
note("  Both measures are flat between 4 and 21 days: the choice is NOT driven")
note("  by the data, and that flatness is itself the robustness result. 7 days")
note("  is kept, the value of the published precedent (Kolczynska) and the")
note("  nominal length of an RfA.")
note("  Discarded rule (gap_then_res): at 7 days it produces ",
     res$fragments_lt5[res$mode == "gap_then_res" & res$threshold == 7],
     " attempts with fewer than 5 votes against ", g(7, "fragments_lt5"), ".")

# --- final pass --------------------------------------------------------------
note("\n--- VALIDATION with res_then_gap and a ", CHOSEN_THRESHOLD, "-day threshold ---")
v <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
a <- readRDS(file.path(DIR_PROCESSED, "attempts.rds"))
v$src_k <- norm_user(v$src); set_at <- split(v$src_k, v$attempt_id)
a$cand_k <- norm_user(a$candidate); per <- split(a$attempt_id, a$cand_k)
best <- rep(NA_real_, nrow(ele)); bid <- rep(NA_integer_, nrow(ele))
for (r in seq_len(nrow(ele))) {
  ids <- per[[ele$cand_k[r]]]; if (is.null(ids)) next
  s <- set_el[[as.character(ele$election_id[r])]]
  jj <- vapply(ids, function(k) jac(s, set_at[[as.character(k)]]), 0)
  best[r] <- max(jj); bid[r] <- ids[which.max(jj)]
}
ele$jaccard <- best
ele$my_attempt <- ifelse(!is.na(best) & best > J_MIN, bid, NA)
ok <- !is.na(ele$my_attempt)
note("elections matched (Jaccard > ", J_MIN, "): ", sum(ok), " of ", nrow(ele),
     sprintf("  (%.1f%%)", 100 * mean(ok)))
note("  with Jaccard > 0.3: ", sum(best > 0.3, na.rm = TRUE),
     "   candidate absent from wiki-RfA: ", sum(is.na(best)),
     sprintf("  (%.1f%%)", 100 * mean(is.na(best))))
note("  median Jaccard on the matched ones: ", round(median(best[ok]), 3))
mo <- a$outcome[match(ele$my_attempt[ok], a$attempt_id)]
note("OUTCOME AGREEMENT: ",
     sprintf("%.2f%%", 100 * mean((mo == 1) == (ele$outcome[ok] == 1))),
     "  (disagreements: ", sum((mo == 1) != (ele$outcome[ok] == 1)),
     " of ", sum(ok), ")")
note("distinct attempts matched: ", length(unique(ele$my_attempt[ok])), " of ", nrow(a),
     "; attempts absorbing two elections: ", sum(duplicated(ele$my_attempt[ok])))
missing_from_me <- mapply(function(r, k)
  length(setdiff(set_el[[as.character(r)]], set_at[[as.character(k)]])),
  ele$election_id[ok], ele$my_attempt[ok])
missing_from_them <- mapply(function(r, k)
  length(setdiff(set_at[[as.character(k)]], set_el[[as.character(r)]])),
  ele$election_id[ok], ele$my_attempt[ok])
note("disagreement on individual voters (medians): wiki-Elec holds ",
     median(missing_from_me), " that we do not, we hold ", median(missing_from_them),
     " that it does not,")
note("  out of a median of ",
     median(lengths(set_el)[as.character(ele$election_id[ok])]),
     " voters per election. Similar sizes (identical in ",
     sum(lengths(set_el)[as.character(ele$election_id[ok])] ==
           a$n_votes[match(ele$my_attempt[ok], a$attempt_id)]),
     " elections), different lists.")

a$elec_matched  <- a$attempt_id %in% ele$my_attempt[ok]
a$elec_outcome  <- ele$outcome[match(a$attempt_id, ele$my_attempt)]
a$elec_jaccard  <- ele$jaccard[match(a$attempt_id, ele$my_attempt)]
a$outcome_agrees <- ifelse(a$elec_matched, (a$outcome == 1) == (a$elec_outcome == 1), NA)
saveRDS(a, file.path(DIR_PROCESSED, "attempts_validated.rds"))
write.csv(ele[, c("election_id", "candidate", "outcome", "closed_at", "last_vote",
                  "jaccard", "my_attempt")],
          file.path(DIR_PROCESSED, "03_match_wikielec.csv"), row.names = FALSE)
note("LIMIT: the validation covers ", sum(a$elec_matched), " attempts of ", nrow(a),
     sprintf(" (%.0f%%)", 100 * mean(a$elec_matched)),
     ". Outside the period covered by wiki-Elec, that is from 2008 to 2013,",
     " no validation exists.")
note("written: attempts_validated.rds, 03_match_wikielec.csv")
writeLines(log_lines, file.path(DIR_PROCESSED, "03_log.txt"))
````

### `R/04_build_networks.R`

````r
# 04 - Historical signed voter co-voting networks.
#
# Input : data/processed/votes.rds
#         data/processed/attempts_analysis.rds
# Output: data/processed/network_objects.rds
#         output/results/network_summary.csv
#         output/results/community_method_check.csv
# Packages: igraph, Matrix

set.seed(1421)

local_lib <- file.path(getwd(), ".Rlib")
if (dir.exists(local_lib)) {
  .libPaths(c(local_lib, .libPaths()))
}

suppressPackageStartupMessages({
  library(igraph)
  library(Matrix)
})

source(file.path("R", "00_paths.R"))
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)

required <- file.path(
  DIR_PROCESSED,
  c("votes.rds", "attempts_analysis.rds")
)
if (any(!file.exists(required))) {
  stop("Run R/01_prepare_data.R before R/04_build_networks.R.", call. = FALSE)
}

assert_condition <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
}

votes <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))

votes <- votes[
  !is.na(votes$attempt_id) &
    votes$vot %in% c(-1L, 1L) &
    !votes$self_vote,
]
attempt_index <- match(votes$attempt_id, attempts$attempt_id)
votes$voter <- votes$src
votes$candidate <- votes$tgt
votes$vote <- votes$vot
votes$year <- attempts$year_from_date[attempt_index]
votes$vote_time <- votes$dat
votes$vote_time_effective <- votes$dat
missing_vote_time <- is.na(votes$vote_time_effective)
votes$vote_time_effective[missing_vote_time] <-
  attempts$opened_at[attempt_index[missing_vote_time]]

build_covoting_snapshot <- function(cutoff_year, all_voters) {
  history <- votes[
    votes$year < cutoff_year,
    c("attempt_id", "voter", "vote"),
  ]
  if (nrow(history) == 0L) {
    return(NULL)
  }

  group_key <- paste(history$attempt_id, history$vote, sep = "|")
  group_id <- match(group_key, unique(group_key))
  voter_id <- match(history$voter, all_voters)
  incidence <- sparseMatrix(
    i = group_id,
    j = voter_id,
    x = 1,
    dims = c(length(unique(group_key)), length(all_voters))
  )
  projection <- crossprod(incidence)
  diag(projection) <- 0
  entries <- summary(projection)

  # A link requires agreement in at least two historical attempts.
  entries <- entries[entries$i < entries$j & entries$x >= 2, ]
  assert_condition(
    all(entries$x >= 2),
    "Covoting network contains an edge below the two-event threshold."
  )
  if (nrow(entries) == 0L) {
    return(NULL)
  }

  edge_table <- data.frame(
    from = all_voters[entries$i],
    to = all_voters[entries$j],
    weight = entries$x,
    stringsAsFactors = FALSE
  )
  graph <- graph_from_data_frame(edge_table, directed = FALSE)

  set.seed(1421 + cutoff_year)
  communities <- cluster_louvain(graph, weights = E(graph)$weight)
  graph_membership <- membership(communities)
  graph_degree <- strength(graph, mode = "all", weights = E(graph)$weight)
  graph_pagerank <- page_rank(
    graph,
    directed = FALSE,
    weights = E(graph)$weight
  )$vector
  graph_eigenvector <- tryCatch(
    eigen_centrality(
      graph,
      directed = FALSE,
      weights = E(graph)$weight
    )$vector,
    error = function(e) rep(0, vcount(graph))
  )
  graph_local_clustering <- transitivity(
    graph,
    type = "local",
    weights = NA
  )
  graph_local_clustering[is.na(graph_local_clustering)] <- 0

  membership_all <- rep(NA_integer_, length(all_voters))
  names(membership_all) <- all_voters
  degree_all <- rep(0, length(all_voters))
  names(degree_all) <- all_voters
  pagerank_all <- rep(0, length(all_voters))
  names(pagerank_all) <- all_voters
  eigenvector_all <- rep(0, length(all_voters))
  names(eigenvector_all) <- all_voters
  local_clustering_all <- rep(0, length(all_voters))
  names(local_clustering_all) <- all_voters
  membership_all[V(graph)$name] <- graph_membership
  degree_all[V(graph)$name] <- graph_degree
  pagerank_all[V(graph)$name] <- graph_pagerank
  eigenvector_all[V(graph)$name] <- graph_eigenvector
  local_clustering_all[V(graph)$name] <- graph_local_clustering

  edge_vertices <- ends(graph, E(graph), names = TRUE)
  from_community <- membership_all[edge_vertices[, 1]]
  to_community <- membership_all[edge_vertices[, 2]]
  cross <- from_community != to_community

  max_community <- max(membership_all, na.rm = TRUE)
  community_bridge_exposure <- rep(0L, max_community)
  names(community_bridge_exposure) <- as.character(seq_len(max_community))
  if (any(cross)) {
    long_cross <- rbind(
      data.frame(community = from_community[cross],
                 other = to_community[cross]),
      data.frame(community = to_community[cross],
                 other = from_community[cross])
    )
    bridge_counts <- tapply(
      long_cross$other,
      long_cross$community,
      function(x) length(unique(x))
    )
    community_bridge_exposure[names(bridge_counts)] <-
      as.integer(bridge_counts)
  }
  cross_edges <- data.frame(
    lower = pmin(from_community[cross], to_community[cross]),
    upper = pmax(from_community[cross], to_community[cross]),
    weight = E(graph)$weight[cross],
    stringsAsFactors = FALSE
  )
  community_edge_summary <- if (nrow(cross_edges) == 0L) {
    data.frame(lower = integer(), upper = integer(), weight = numeric())
  } else {
    aggregate(
      cross_edges$weight,
      by = list(lower = cross_edges$lower, upper = cross_edges$upper),
      FUN = sum
    ) |>
      setNames(c("lower", "upper", "weight"))
  }

  summary_row <- data.frame(
    cutoff_year = cutoff_year,
    historical_votes = nrow(history),
    eligible_voters = length(unique(history$voter)),
    network_voters = vcount(graph),
    covoting_edges = ecount(graph),
    communities_nonempty = length(unique(na.omit(membership_all))),
    modularity = modularity(communities),
    cross_community_edges = sum(cross),
    cross_community_share = sum(cross) / ecount(graph),
    mean_weighted_degree = mean(degree_all[degree_all > 0]),
    density = edge_density(graph, loops = FALSE),
    global_transitivity = transitivity(graph, type = "global", weights = NA),
    stringsAsFactors = FALSE
  )

  list(
    graph = graph,
    membership = membership_all,
    weighted_degree = degree_all,
    pagerank = pagerank_all,
    eigenvector = eigenvector_all,
    local_clustering = local_clustering_all,
    community_bridge_exposure = community_bridge_exposure,
    community_edges = community_edge_summary,
    summary = summary_row
  )
}

all_voters <- sort(unique(votes$voter))
target_years <- sort(unique(attempts$year_from_date))
snapshots <- list()
for (target_year in target_years) {
  snapshot <- build_covoting_snapshot(target_year, all_voters)
  if (!is.null(snapshot)) {
    snapshots[[as.character(target_year)]] <- snapshot
  }
}
if (length(snapshots) == 0L) {
  stop("No historical co-voting networks could be built.", call. = FALSE)
}

network_summary <- do.call(rbind, lapply(snapshots, `[[`, "summary"))
write.csv(
  network_summary,
  file.path("output", "results", "network_summary.csv"),
  row.names = FALSE
)

small_graph <- snapshots[[1]]$graph
set.seed(1421)
girvan_newman <- cluster_edge_betweenness(
  small_graph,
  weights = 1 / E(small_graph)$weight,
  directed = FALSE
)
set.seed(1421)
girvan_newman_unweighted <- cluster_edge_betweenness(
  small_graph,
  weights = NA,
  directed = FALSE
)
community_method_check <- data.frame(
  method = c(
    "Weighted Louvain",
    "Weighted Girvan-Newman",
    "Unweighted Girvan-Newman"
  ),
  cutoff_year = network_summary$cutoff_year[1],
  network_voters = vcount(small_graph),
  covoting_edges = ecount(small_graph),
  communities = c(
    network_summary$communities_nonempty[1],
    length(unique(membership(girvan_newman))),
    length(unique(membership(girvan_newman_unweighted)))
  ),
  modularity = c(
    network_summary$modularity[1],
    modularity(girvan_newman),
    modularity(girvan_newman_unweighted)
  ),
  stringsAsFactors = FALSE
)
write.csv(
  community_method_check,
  file.path("output", "results", "community_method_check.csv"),
  row.names = FALSE
)

saveRDS(
  list(
    snapshots = lapply(snapshots, function(x) {
      list(
        summary = x$summary,
        membership = x$membership,
        weighted_degree = x$weighted_degree,
        pagerank = x$pagerank,
        eigenvector = x$eigenvector,
        local_clustering = x$local_clustering,
        community_bridge_exposure = x$community_bridge_exposure,
        community_edges = x$community_edges
      )
    })
  ),
  file.path(DIR_PROCESSED, "network_objects.rds")
)
````

### `R/05_measure_change.R`

````r
# 05 - Coalition and network change between consecutive attempts.
#
# Input : data/processed/votes.rds
#         data/processed/attempts_analysis.rds
#         data/processed/network_objects.rds
# Output: data/processed/attempt_pairs.rds
#         output/results/attempt_pairs.csv
#         output/results/outcome_validation.csv
# Packages: base R

source(file.path("R", "00_paths.R"))
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)

required <- file.path(
  DIR_PROCESSED,
  c("votes.rds", "attempts_analysis.rds", "network_objects.rds")
)
if (any(!file.exists(required))) {
  stop("Run R/01_prepare_data.R and R/04_build_networks.R first.", call. = FALSE)
}

assert_condition <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
}

community_entropy <- function(values) {
  values <- values[!is.na(values)]
  if (length(values) == 0L) {
    return(NA_real_)
  }
  frequencies <- as.numeric(table(values)) / length(values)
  -sum(frequencies * log(frequencies))
}

effective_communities <- function(values) {
  entropy <- community_entropy(values)
  if (is.na(entropy)) NA_real_ else exp(entropy)
}

js_divergence <- function(values_previous, values_current) {
  if (length(values_previous) == 0L || length(values_current) == 0L) {
    return(NA_real_)
  }
  categories <- union(values_previous, values_current)
  previous_distribution <- as.numeric(table(
    factor(values_previous, levels = categories)
  )) / length(values_previous)
  current_distribution <- as.numeric(table(
    factor(values_current, levels = categories)
  )) / length(values_current)
  midpoint <- (previous_distribution + current_distribution) / 2
  term <- function(distribution) {
    positive <- distribution > 0
    0.5 * sum(
      distribution[positive] *
        log2(distribution[positive] / midpoint[positive])
    )
  }
  term(previous_distribution) + term(current_distribution)
}

support_network_stats <- function(voters, snapshot) {
  n_supporters <- length(voters)
  if (n_supporters == 0L) {
    return(list(
      effective_communities = 0,
      unclassified_supporters = 0L,
      known_community_share = NA_real_,
      mean_weighted_degree = 0,
      mean_pagerank = 0,
      mean_eigenvector = 0,
      mean_local_clustering = 0,
      community_bridge_exposure = 0,
      community_labels = character()
    ))
  }

  if (is.null(snapshot)) {
    memberships <- rep(NA_integer_, n_supporters)
    degrees <- rep(0, n_supporters)
    pageranks <- rep(0, n_supporters)
    eigenvectors <- rep(0, n_supporters)
    local_clustering <- rep(0, n_supporters)
    bridge_exposure <- rep(0, n_supporters)
  } else {
    memberships <- unname(snapshot$membership[voters])
    degrees <- unname(snapshot$weighted_degree[voters])
    pageranks <- unname(snapshot$pagerank[voters])
    eigenvectors <- unname(snapshot$eigenvector[voters])
    local_clustering <- unname(snapshot$local_clustering[voters])
    bridge_exposure <- unname(
      snapshot$community_bridge_exposure[as.character(memberships)]
    )
    degrees[is.na(degrees)] <- 0
    pageranks[is.na(pageranks)] <- 0
    eigenvectors[is.na(eigenvectors)] <- 0
    local_clustering[is.na(local_clustering)] <- 0
    bridge_exposure[is.na(bridge_exposure)] <- 0
  }

  unclassified <- is.na(memberships)
  community_labels <- as.character(memberships)
  community_labels[unclassified] <- "unclassified"

  list(
    effective_communities = effective_communities(community_labels),
    unclassified_supporters = sum(unclassified),
    known_community_share = mean(!unclassified),
    mean_weighted_degree = mean(degrees),
    mean_pagerank = mean(pageranks),
    mean_eigenvector = mean(eigenvectors),
    mean_local_clustering = mean(local_clustering),
    community_bridge_exposure = mean(bridge_exposure),
    community_labels = community_labels
  )
}

votes <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
network_objects <- readRDS(file.path(DIR_PROCESSED, "network_objects.rds"))
snapshots <- network_objects$snapshots

votes <- votes[
  !is.na(votes$attempt_id) &
    votes$vot %in% c(-1L, 1L) &
    !votes$self_vote,
]
attempt_index <- match(votes$attempt_id, attempts$attempt_id)
votes$voter <- votes$src
votes$candidate <- votes$tgt
votes$vote <- votes$vot
votes$year <- attempts$year_from_date[attempt_index]
votes$vote_time <- votes$dat
votes$vote_time_effective <- votes$dat
missing_vote_time <- is.na(votes$vote_time_effective)
votes$vote_time_effective[missing_vote_time] <-
  attempts$opened_at[attempt_index[missing_vote_time]]

attempts$attempt_number <- attempts$attempt_no
attempts$start_date <- attempts$opened_at
attempts$end_date <- attempts$closed_at
attempts$year <- attempts$year_from_date
attempts$n_raw_votes <- attempts$n_votes
attempts$outcome <- attempts$outcome_analysis
attempts <- attempts[order(attempts$candidate, attempts$attempt_number), ]

outcome_validation <- attempts[
  ,
  c(
    "attempt_id", "candidate", "attempt_number", "start_date", "end_date",
    "year", "outcome", "outcome_analysis", "elec_matched", "elec_outcome",
    "elec_jaccard", "outcome_agrees"
  )
]
outcome_validation$validation_status <- ifelse(
  outcome_validation$elec_matched,
  ifelse(outcome_validation$outcome_agrees, "validated", "outcome_mismatch"),
  "not_matched_in_companion_file"
)
outcome_validation$rfa_success <- as.integer(outcome_validation$outcome == 1L)
outcome_validation$wiki_success <- as.integer(outcome_validation$elec_outcome == 1L)
write.csv(
  outcome_validation,
  file.path("output", "results", "outcome_validation.csv"),
  row.names = FALSE
)

vote_maps <- split(setNames(votes$vote, votes$voter), votes$attempt_id)
attempt_votes <- lapply(vote_maps, function(x) x[!is.na(x)])
outgoing_by_voter <- split(votes$vote_time_effective, votes$voter)
candidate_groups <- split(seq_len(nrow(attempts)), attempts$candidate)
pair_rows <- list()

for (candidate_rows in candidate_groups) {
  if (length(candidate_rows) < 2L) {
    next
  }
  for (i in seq_len(length(candidate_rows) - 1L)) {
    previous <- attempts[candidate_rows[i], ]
    current <- attempts[candidate_rows[i + 1L], ]
    if (is.na(previous$outcome_analysis) || is.na(current$outcome_analysis)) {
      next
    }

    previous_votes <- attempt_votes[[as.character(previous$attempt_id)]]
    current_votes <- attempt_votes[[as.character(current$attempt_id)]]
    if (is.null(previous_votes) || is.null(current_votes)) {
      next
    }

    previous_support <- names(previous_votes)[previous_votes == 1]
    previous_oppose <- names(previous_votes)[previous_votes == -1]
    current_support <- names(current_votes)[current_votes == 1]
    current_oppose <- names(current_votes)[current_votes == -1]
    returning_support <- intersect(previous_support, current_support)
    new_support <- setdiff(current_support, previous_support)
    converted_opposition <- intersect(previous_oppose, current_support)
    supporter_union <- union(previous_support, current_support)

    supporter_jaccard <- if (length(supporter_union) == 0L) {
      NA_real_
    } else {
      length(returning_support) / length(supporter_union)
    }

    active_before <- unique(votes$voter[
      votes$vote_time_effective < current$start_date
    ])
    pool_size <- length(active_before)
    expected_intersection <- if (pool_size > 0L) {
      length(previous_support) * length(current_support) / pool_size
    } else {
      NA_real_
    }
    expected_union <- length(previous_support) + length(current_support) -
      expected_intersection
    expected_jaccard <- if (!is.na(expected_union) && expected_union > 0) {
      expected_intersection / expected_union
    } else {
      NA_real_
    }

    snapshot <- snapshots[[as.character(current$year)]]
    previous_network <- support_network_stats(previous_support, snapshot)
    current_network <- support_network_stats(current_support, snapshot)
    community_mix_change <- js_divergence(
      previous_network$community_labels,
      current_network$community_labels
    )

    previous_total <- length(previous_support) + length(previous_oppose)
    previous_support_share <- if (previous_total > 0L) {
      length(previous_support) / previous_total
    } else {
      NA_real_
    }

    times <- outgoing_by_voter[[previous$candidate]]
    outgoing_between <- if (is.null(times)) {
      0L
    } else {
      sum(times > previous$end_date & times < current$start_date, na.rm = TRUE)
    }

    pair_rows[[length(pair_rows) + 1L]] <- data.frame(
      pair_id = length(pair_rows) + 1L,
      candidate = previous$candidate,
      previous_attempt_id = previous$attempt_id,
      next_attempt_id = current$attempt_id,
      previous_attempt_number = previous$attempt_number,
      next_attempt_year = current$year,
      previous_outcome = previous$outcome_analysis,
      next_outcome = current$outcome_analysis,
      previous_short_attempt = previous$flag_short,
      next_short_attempt = current$flag_short,
      previous_year_clash = previous$flag_year_clash,
      next_year_clash = current$flag_year_clash,
      days_between = as.numeric(difftime(
        current$start_date, previous$end_date, units = "days"
      )),
      previous_supporters = length(previous_support),
      previous_opponents = length(previous_oppose),
      current_supporters = length(current_support),
      current_opponents = length(current_oppose),
      previous_support_share = previous_support_share,
      returning_supporters = length(returning_support),
      new_supporters = length(new_support),
      converted_opposition = length(converted_opposition),
      supporter_jaccard = supporter_jaccard,
      null_expected_jaccard = expected_jaccard,
      jaccard_excess = supporter_jaccard - expected_jaccard,
      returning_support_share = if (length(current_support) > 0L) {
        length(returning_support) / length(current_support)
      } else {
        NA_real_
      },
      new_support_share = if (length(current_support) > 0L) {
        length(new_support) / length(current_support)
      } else {
        NA_real_
      },
      previous_support_effective_communities =
        previous_network$effective_communities,
      current_support_effective_communities =
        current_network$effective_communities,
      community_breadth_change =
        current_network$effective_communities -
        previous_network$effective_communities,
      community_mix_js = community_mix_change,
      previous_unclassified_supporters =
        previous_network$unclassified_supporters,
      current_unclassified_supporters =
        current_network$unclassified_supporters,
      previous_known_community_share =
        previous_network$known_community_share,
      current_known_community_share =
        current_network$known_community_share,
      previous_supporter_mean_weighted_degree =
        previous_network$mean_weighted_degree,
      current_supporter_mean_weighted_degree =
        current_network$mean_weighted_degree,
      previous_supporter_mean_pagerank = previous_network$mean_pagerank,
      current_supporter_mean_pagerank = current_network$mean_pagerank,
      previous_supporter_mean_eigenvector = previous_network$mean_eigenvector,
      current_supporter_mean_eigenvector = current_network$mean_eigenvector,
      previous_supporter_mean_local_clustering =
        previous_network$mean_local_clustering,
      current_supporter_mean_local_clustering =
        current_network$mean_local_clustering,
      previous_community_bridge_exposure =
        previous_network$community_bridge_exposure,
      current_community_bridge_exposure =
        current_network$community_bridge_exposure,
      outgoing_votes_between_attempts = outgoing_between,
      stringsAsFactors = FALSE
    )
  }
}

pairs <- do.call(rbind, pair_rows)
rownames(pairs) <- NULL
pairs$previous_group <- factor(
  ifelse(
    pairs$previous_outcome == 1L,
    "Previously successful",
    "Previously rejected"
  ),
  levels = c("Previously rejected", "Previously successful")
)
pairs$next_group <- factor(
  ifelse(pairs$next_outcome == 1L, "Next: successful", "Next: rejected"),
  levels = c("Next: rejected", "Next: successful")
)
pairs$next_success <- as.integer(pairs$next_outcome == 1L)

assert_condition(!anyDuplicated(pairs$pair_id), "Pair IDs are not unique.")
assert_condition(
  all(is.na(pairs$supporter_jaccard) |
        pairs$supporter_jaccard >= 0 & pairs$supporter_jaccard <= 1),
  "Supporter Jaccard values are outside [0, 1]."
)
assert_condition(
  all(is.na(pairs$new_support_share) |
        pairs$new_support_share >= 0 & pairs$new_support_share <= 1),
  "New-supporter shares are outside [0, 1]."
)
assert_condition(
  all(is.na(pairs$returning_support_share) |
        pairs$returning_support_share >= 0 &
          pairs$returning_support_share <= 1),
  "Returning-supporter shares are outside [0, 1]."
)
assert_condition(
  all(pairs$previous_support_effective_communities >= 0),
  "Negative previous effective-community value."
)
assert_condition(
  all(pairs$current_support_effective_communities >= 0),
  "Negative current effective-community value."
)
assert_condition(
  all(is.na(pairs$community_mix_js) |
        pairs$community_mix_js >= -1e-12 &
          pairs$community_mix_js <= 1 + 1e-12),
  "Jensen-Shannon divergence is outside [0, 1]."
)

saveRDS(pairs, file.path(DIR_PROCESSED, "attempt_pairs.rds"))
write.csv(
  pairs,
  file.path("output", "results", "attempt_pairs.csv"),
  row.names = FALSE
)

cat("Attempt pairs written:", nrow(pairs), "\n")
````

### `R/06_model_outcome.R`

````r
# 06 - Descriptive comparisons and outcome models.
#
# Input : data/processed/attempt_pairs.rds
#         data/processed/attempts_analysis.rds
#         data/processed/network_objects.rds
# Output: output/results/group_comparison.csv
#         output/results/model_data.csv
#         output/results/model_formula.txt
#         output/results/model_coefficients.csv
#         output/results/model_performance.csv
#         output/results/model_performance_sensitivity.csv
#         output/results/sample_flow.csv
#         output/results/analysis_summary.txt
#         data/processed/model_objects.rds
# Packages: base R

set.seed(1421)
source(file.path("R", "00_paths.R"))
dir.create(file.path("output", "results"), showWarnings = FALSE, recursive = TRUE)

required <- file.path(
  DIR_PROCESSED,
  c("attempt_pairs.rds", "attempts_analysis.rds", "network_objects.rds")
)
if (any(!file.exists(required))) {
  stop("Run R/01_prepare_data.R, R/04_build_networks.R and R/05_measure_change.R first.",
       call. = FALSE)
}

assert_condition <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
}

pairs <- readRDS(file.path(DIR_PROCESSED, "attempt_pairs.rds"))
attempts <- readRDS(file.path(DIR_PROCESSED, "attempts_analysis.rds"))
network_objects <- readRDS(file.path(DIR_PROCESSED, "network_objects.rds"))

cliff_delta <- function(failure_values, success_values) {
  failure_values <- failure_values[is.finite(failure_values)]
  success_values <- success_values[is.finite(success_values)]
  if (length(failure_values) == 0L || length(success_values) == 0L) {
    return(NA_real_)
  }
  mean(sign(outer(success_values, failure_values, "-")))
}

compare_groups <- function(data, group, comparison_label) {
  metrics <- c(
    "supporter_jaccard",
    "jaccard_excess",
    "new_support_share",
    "returning_support_share",
    "previous_support_effective_communities",
    "current_support_effective_communities",
    "community_breadth_change",
    "community_mix_js",
    "previous_supporter_mean_weighted_degree",
    "previous_supporter_mean_pagerank",
    "previous_supporter_mean_eigenvector",
    "previous_supporter_mean_local_clustering",
    "previous_community_bridge_exposure"
  )

  rows <- lapply(metrics, function(metric) {
    failure_values <- data[[metric]][group == "failure"]
    success_values <- data[[metric]][group == "success"]
    test <- tryCatch(
      wilcox.test(failure_values, success_values, exact = FALSE),
      error = function(e) NULL
    )
    data.frame(
      comparison = comparison_label,
      metric = metric,
      failure_n = sum(!is.na(failure_values)),
      failure_mean = mean(failure_values, na.rm = TRUE),
      failure_median = median(failure_values, na.rm = TRUE),
      success_n = sum(!is.na(success_values)),
      success_mean = mean(success_values, na.rm = TRUE),
      success_median = median(success_values, na.rm = TRUE),
      difference_success_minus_failure =
        mean(success_values, na.rm = TRUE) -
        mean(failure_values, na.rm = TRUE),
      cliffs_delta_success_vs_failure =
        cliff_delta(failure_values, success_values),
      wilcoxon_p = if (is.null(test)) NA_real_ else test$p.value,
      stringsAsFactors = FALSE
    )
  })
  result <- do.call(rbind, rows)
  result$wilcoxon_p_adjusted <- p.adjust(result$wilcoxon_p, method = "BH")
  result
}

group_comparison <- rbind(
  compare_groups(
    pairs,
    ifelse(pairs$previous_outcome == 1L, "success", "failure"),
    "Previous attempt outcome"
  ),
  compare_groups(
    pairs,
    ifelse(pairs$next_outcome == 1L, "success", "failure"),
    "Next attempt outcome"
  )
)
write.csv(
  group_comparison,
  file.path("output", "results", "group_comparison.csv"),
  row.names = FALSE
)

model_columns <- c(
  "next_success",
  "previous_outcome",
  "previous_support_share",
  "previous_supporters",
  "previous_support_effective_communities",
  "previous_supporter_mean_weighted_degree",
  "days_between",
  "next_attempt_year"
)
model_data_all <- pairs[complete.cases(pairs[, model_columns]), ]
model_data_all$previous_success <-
  as.integer(model_data_all$previous_outcome == 1L)
model_data_all$previous_support_share_10 <-
  model_data_all$previous_support_share * 10
model_data_all$log2_previous_supporters <-
  log2(1 + model_data_all$previous_supporters)
model_data_all$log2_previous_supporter_weighted_degree <-
  log2(1 + model_data_all$previous_supporter_mean_weighted_degree)
model_data_all$log2_days_between <-
  log2(1 + pmax(model_data_all$days_between, 0))
model_data_all$year_centered <- model_data_all$next_attempt_year -
  min(model_data_all$next_attempt_year)
model_data <- model_data_all[
  !model_data_all$previous_short_attempt &
    !model_data_all$next_short_attempt,
]

base_model_formula <- next_success ~
  previous_success +
  previous_support_share_10 +
  log2_previous_supporters +
  log2_days_between +
  year_centered

network_model_formula <- update(
  base_model_formula,
  . ~ . +
    previous_support_effective_communities +
    log2_previous_supporter_weighted_degree
)

fit_base <- glm(
  base_model_formula,
  data = model_data,
  family = binomial(),
  control = glm.control(maxit = 100)
)
fit_network <- glm(
  network_model_formula,
  data = model_data,
  family = binomial(),
  control = glm.control(maxit = 100)
)

tidy_glm <- function(fit, model_label) {
  fit_coefficients <- coef(summary(fit))
  confidence_intervals <- confint.default(fit)
  data.frame(
    model = model_label,
    term = rownames(fit_coefficients),
    estimate = fit_coefficients[, "Estimate"],
    standard_error = fit_coefficients[, "Std. Error"],
    p_value = fit_coefficients[, "Pr(>|z|)"],
    odds_ratio = exp(fit_coefficients[, "Estimate"]),
    confidence_low = exp(confidence_intervals[, 1]),
    confidence_high = exp(confidence_intervals[, 2]),
    stringsAsFactors = FALSE
  )
}

coefficient_table <- rbind(
  tidy_glm(fit_base, "Vote shares and timing"),
  tidy_glm(fit_network, "Network-augmented")
)
coefficient_labels <- c(
  "(Intercept)" = "Intercept",
  previous_success = "Prior success vs prior rejection",
  previous_support_share_10 = "Prior support share (per 10 pp)",
  log2_previous_supporters = "Prior supporters (per doubling)",
  previous_support_effective_communities =
    "Prior effective supporter communities",
  log2_previous_supporter_weighted_degree =
    "Supporter weighted degree (per doubling)",
  log2_days_between = "Days between attempts (per doubling)",
  year_centered = "Calendar year"
)
coefficient_table$term_label <- unname(coefficient_labels[
  coefficient_table$term
])
write.csv(
  coefficient_table,
  file.path("output", "results", "model_coefficients.csv"),
  row.names = FALSE
)

auc_value <- function(actual, probability) {
  actual <- as.integer(actual)
  positive <- sum(actual == 1L)
  negative <- sum(actual == 0L)
  if (positive == 0L || negative == 0L) {
    return(NA_real_)
  }
  ranks <- rank(probability, ties.method = "average")
  (sum(ranks[actual == 1L]) - positive * (positive + 1) / 2) /
    (positive * negative)
}

candidate_outcomes <- aggregate(
  previous_success ~ candidate,
  data = model_data_all,
  FUN = max
)
candidate_outcomes$fold <- NA_integer_
set.seed(1421)
for (stratum in c(0L, 1L)) {
  candidate_ids <- candidate_outcomes$candidate[
    candidate_outcomes$previous_success == stratum
  ]
  candidate_ids <- sample(candidate_ids)
  candidate_outcomes$fold[
    candidate_outcomes$candidate %in% candidate_ids
  ] <- rep(seq_len(5), length.out = length(candidate_ids))
}
fold_lookup <- setNames(candidate_outcomes$fold, candidate_outcomes$candidate)
model_data_all$fold <- unname(fold_lookup[model_data_all$candidate])
model_data$fold <- unname(fold_lookup[model_data$candidate])

evaluate_model <- function(data, formula) {
  fold_predictions <- rep(NA_real_, nrow(data))
  baseline_predictions <- rep(NA_real_, nrow(data))
  for (fold in seq_len(5)) {
    train <- data[data$fold != fold, ]
    test <- data[data$fold == fold, ]
    if (nrow(test) == 0L) {
      next
    }
    fold_fit <- glm(
      formula,
      data = train,
      family = binomial(),
      control = glm.control(maxit = 100)
    )
    fold_predictions[data$fold == fold] <-
      predict(fold_fit, newdata = test, type = "response")
    baseline_predictions[data$fold == fold] <- mean(train$next_success)
  }
  list(prediction = fold_predictions, baseline = baseline_predictions)
}

base_evaluation <- evaluate_model(model_data, base_model_formula)
network_evaluation <- evaluate_model(model_data, network_model_formula)

base_terms <- all.vars(base_model_formula)
assert_condition(
  !any(grepl("^current_", base_terms)),
  "Leakage detected: the outcome model contains a current-attempt variable."
)
assert_condition(
  !anyNA(model_data$fold),
  "Cross-validation folds are missing for at least one modelling row."
)
assert_condition(
  all(tapply(
    model_data$fold,
    model_data$candidate,
    function(x) length(unique(x)) == 1L
  )),
  "At least one candidate appears in more than one cross-validation fold."
)

model_export_columns <- c(
  "candidate", "fold", "next_success", "previous_outcome",
  "previous_success", "previous_support_share_10",
  "log2_previous_supporters", "previous_support_effective_communities",
  "log2_previous_supporter_weighted_degree", "log2_days_between",
  "year_centered"
)
write.csv(
  model_data[, model_export_columns],
  file.path("output", "results", "model_data.csv"),
  row.names = FALSE
)
writeLines(
  c(
    paste("Base model:", paste(deparse(base_model_formula), collapse = " ")),
    paste("Network model:",
          paste(deparse(network_model_formula), collapse = " "))
  ),
  file.path("output", "results", "model_formula.txt")
)

performance <- data.frame(
  model = c("Prevalence only", "Vote shares and timing", "Network-augmented"),
  auc = c(
    0.5,
    auc_value(model_data$next_success, base_evaluation$prediction),
    auc_value(model_data$next_success, network_evaluation$prediction)
  ),
  brier_score = c(
    mean((base_evaluation$baseline - model_data$next_success)^2),
    mean((base_evaluation$prediction - model_data$next_success)^2),
    mean((network_evaluation$prediction - model_data$next_success)^2)
  ),
  observations = nrow(model_data),
  candidates = length(unique(model_data$candidate)),
  stringsAsFactors = FALSE
)
write.csv(
  performance,
  file.path("output", "results", "model_performance.csv"),
  row.names = FALSE
)

all_base_evaluation <- evaluate_model(model_data_all, base_model_formula)
all_network_evaluation <- evaluate_model(model_data_all, network_model_formula)
performance_sensitivity <- data.frame(
  sample = rep(c("Excluding short attempts", "All complete pairs"), each = 2L),
  model = rep(c("Vote shares and timing", "Network-augmented"), 2L),
  observations = c(
    nrow(model_data), nrow(model_data),
    nrow(model_data_all), nrow(model_data_all)
  ),
  auc = c(
    auc_value(model_data$next_success, base_evaluation$prediction),
    auc_value(model_data$next_success, network_evaluation$prediction),
    auc_value(model_data_all$next_success, all_base_evaluation$prediction),
    auc_value(model_data_all$next_success, all_network_evaluation$prediction)
  ),
  brier_score = c(
    mean((base_evaluation$prediction - model_data$next_success)^2),
    mean((network_evaluation$prediction - model_data$next_success)^2),
    mean((all_base_evaluation$prediction - model_data_all$next_success)^2),
    mean((all_network_evaluation$prediction - model_data_all$next_success)^2)
  ),
  stringsAsFactors = FALSE
)
write.csv(
  performance_sensitivity,
  file.path("output", "results", "model_performance_sensitivity.csv"),
  row.names = FALSE
)

all_pair_count <- sum(pmax(table(attempts$candidate) - 1L, 0L))
sample_flow <- data.frame(
  stage = c(
    "Reconstructed attempts", "Repeat candidates",
    "All consecutive attempt pairs", "Pairs with valid outcomes",
    "Pairs used in descriptive comparisons", "Pairs used in outcome models"
  ),
  count = c(
    nrow(attempts), sum(table(attempts$candidate) >= 2L),
    all_pair_count, nrow(pairs), nrow(pairs), nrow(model_data)
  ),
  stringsAsFactors = FALSE
)
write.csv(
  sample_flow,
  file.path("output", "results", "sample_flow.csv"),
  row.names = FALSE
)

summary_lines <- c(
  paste("All consecutive attempt pairs:", all_pair_count),
  paste("Pairs with valid outcomes:", nrow(pairs)),
  paste("Pairs after prior success:", sum(pairs$previous_outcome == 1L)),
  paste("Pairs after prior rejection:", sum(pairs$previous_outcome == -1L)),
  paste("Next-attempt successes:", sum(pairs$next_success == 1L)),
  paste(
    "Attempts matched to wikiElec by voter set:",
    sum(attempts$elec_matched, na.rm = TRUE)
  ),
  paste(
    "Validated outcome agreements:",
    sum(attempts$elec_matched & attempts$outcome_agrees, na.rm = TRUE),
    "of",
    sum(attempts$elec_matched, na.rm = TRUE)
  ),
  paste("Network snapshots:", length(network_objects$snapshots)),
  paste("Model observations:", nrow(model_data)),
  paste("Model candidates:", length(unique(model_data$candidate))),
  sprintf("Vote/timing model AUC: %.3f",
          performance$auc[performance$model == "Vote shares and timing"]),
  sprintf("Network-augmented model AUC: %.3f",
          performance$auc[performance$model == "Network-augmented"]),
  sprintf("Vote/timing model Brier score: %.3f",
          performance$brier_score[performance$model == "Vote shares and timing"]),
  sprintf("Network-augmented model Brier score: %.3f",
          performance$brier_score[performance$model == "Network-augmented"]),
  sprintf("Prevalence-only Brier score: %.3f",
          performance$brier_score[performance$model == "Prevalence only"]),
  "Network snapshots use same-direction co-voting before the target year.",
  "Louvain is the main method; Girvan-Newman is checked only on the first snapshot and is method-sensitive.",
  "Network measures showed no material improvement in held-out prediction; AUC and Brier differences were negligible and mixed.",
  "Model predictors use only information available before the next attempt.",
  "All estimates describe association, not a causal effect."
)
writeLines(
  summary_lines,
  file.path("output", "results", "analysis_summary.txt")
)

saveRDS(
  list(
    network_objects = network_objects,
    model_base = fit_base,
    model_network = fit_network,
    folds = fold_lookup,
    performance = performance,
    performance_sensitivity = performance_sensitivity,
    group_comparison = group_comparison,
    coefficient_table = coefficient_table
  ),
  file.path(DIR_PROCESSED, "model_objects.rds")
)

cat("Model observations:", nrow(model_data), "\n")
````

### `R/07_figures.R`

````r
# 07 - Report figures.
#
# Input : data/processed/attempt_pairs.rds
#         data/processed/network_objects.rds
#         data/processed/model_objects.rds
# Output: output/figures/fig1_covoting_network.png
#         output/figures/fig2_supporter_overlap.png
#         output/figures/fig3_community_diversity.png
#         output/figures/fig4_model_coefficients.png
# Packages: igraph, ggplot2

local_lib <- file.path(getwd(), ".Rlib")
if (dir.exists(local_lib)) {
  .libPaths(c(local_lib, .libPaths()))
}

suppressPackageStartupMessages({
  library(igraph)
  library(ggplot2)
})

source(file.path("R", "00_paths.R"))
dir.create(DIR_FIGURES, showWarnings = FALSE, recursive = TRUE)

required <- file.path(
  DIR_PROCESSED,
  c("attempt_pairs.rds", "network_objects.rds", "model_objects.rds")
)
if (any(!file.exists(required))) {
  stop(
    "Run R/04_build_networks.R, R/05_measure_change.R and R/06_model_outcome.R first.",
    call. = FALSE
  )
}

pairs <- readRDS(file.path(DIR_PROCESSED, "attempt_pairs.rds"))
network_objects <- readRDS(file.path(DIR_PROCESSED, "network_objects.rds"))
model_objects <- readRDS(file.path(DIR_PROCESSED, "model_objects.rds"))

network_summary <- do.call(
  rbind,
  lapply(network_objects$snapshots, `[[`, "summary")
)

latest_snapshot <- network_objects$snapshots[[
  length(network_objects$snapshots)
]]
graph_membership <- latest_snapshot$membership
community_sizes <- table(
  graph_membership[!is.na(graph_membership)]
)
community_ids <- as.integer(names(community_sizes))
angles <- seq(0, 2 * pi, length.out = length(community_ids) + 1)[
  seq_along(community_ids)
]
coordinates <- data.frame(
  community = community_ids,
  x = cos(angles),
  y = sin(angles),
  size = as.integer(community_sizes)
)

cross_summary <- latest_snapshot$community_edges
cross_summary <- merge(
  cross_summary,
  coordinates[, c("community", "x", "y")],
  by.x = "lower",
  by.y = "community"
)
names(cross_summary)[names(cross_summary) == "x"] <- "x_from"
names(cross_summary)[names(cross_summary) == "y"] <- "y_from"
cross_summary <- merge(
  cross_summary,
  coordinates[, c("community", "x", "y")],
  by.x = "upper",
  by.y = "community"
)
names(cross_summary)[names(cross_summary) == "x"] <- "x_to"
names(cross_summary)[names(cross_summary) == "y"] <- "y_to"
png(
  file.path(DIR_FIGURES, "fig1_covoting_network.png"),
  width = 1800,
  height = 850,
  res = 180
)
layout(matrix(c(1, 2), nrow = 1), widths = c(1.15, 1))
par(mar = c(2, 2, 4, 1))
plot(
  NA,
  xlim = c(-1.35, 1.35),
  ylim = c(-1.35, 1.35),
  asp = 1,
  axes = FALSE,
  xlab = "",
  ylab = "",
  main = "Voter-community network"
)
edge_width <- 0.5 + 3.5 * log1p(cross_summary$weight) /
  max(log1p(cross_summary$weight))
segments(
  cross_summary$x_from,
  cross_summary$y_from,
  cross_summary$x_to,
  cross_summary$y_to,
  col = adjustcolor("#4C78A8", alpha.f = 0.28),
  lwd = edge_width
)
points(
  coordinates$x,
  coordinates$y,
  pch = 21,
  cex = 2.2 + 3.3 * sqrt(coordinates$size / max(coordinates$size)),
  bg = "#F58518",
  col = "white",
  lwd = 1.5
)
text(
  coordinates$x,
  coordinates$y,
  labels = paste0("C", coordinates$community, "\n", coordinates$size),
  cex = 0.78,
  font = 2
)
mtext("Latest cumulative snapshot", side = 1, line = 0.5, cex = 0.8)

par(mar = c(4.5, 4.5, 4, 1))
plot(
  network_summary$cutoff_year,
  network_summary$modularity,
  type = "b",
  pch = 19,
  col = "#E45756",
  ylim = c(
    0,
    max(
      c(network_summary$modularity, network_summary$cross_community_share),
      na.rm = TRUE
    ) * 1.08
  ),
  xlab = "Start of target year",
  ylab = "Network measure",
  main = "Community structure over time"
)
lines(
  network_summary$cutoff_year,
  network_summary$cross_community_share,
  type = "b",
  pch = 17,
  col = "#4C78A8"
)
legend(
  "bottomright",
  legend = c("Modularity", "Cross-community edge share"),
  col = c("#E45756", "#4C78A8"),
  pch = c(19, 17),
  lty = 1,
  bty = "n",
  cex = 0.85
)
mtext(
  "Historical same-direction voter co-voting network",
  outer = TRUE,
  side = 3,
  line = -1.5,
  cex = 1.1,
  font = 2
)
dev.off()

plot_pairs <- pairs[
  !is.na(pairs$supporter_jaccard) & !is.na(pairs$jaccard_excess),
]
prior_counts <- table(plot_pairs$previous_group)
p2 <- ggplot(
  plot_pairs,
  aes(x = previous_group, y = jaccard_excess, fill = next_group)
) +
  geom_hline(yintercept = 0, linetype = 2, color = "gray45") +
  geom_boxplot(
    position = position_dodge(width = 0.72),
    width = 0.62,
    outlier.shape = NA,
    alpha = 0.55,
    linewidth = 0.35
  ) +
  geom_point(
    position = position_jitterdodge(jitter.width = 0.16, dodge.width = 0.72),
    size = 0.9,
    alpha = 0.45,
    stroke = 0
  ) +
  scale_x_discrete(
    labels = c(
      paste0("Previously rejected\n(n = ", prior_counts[1], ")"),
      paste0("Previously successful\n(n = ", prior_counts[2], ")")
    )
  ) +
  scale_fill_manual(
    values = c("Next: rejected" = "#9ECAE1",
               "Next: successful" = "#F4A582")
  ) +
  scale_y_continuous(
    trans = scales::pseudo_log_trans(sigma = 0.01),
    breaks = c(-0.01, 0, 0.01, 0.05, 0.10, 0.25, 0.50, 1.00)
  ) +
  labs(
    x = "Outcome of previous request",
    y = "Observed supporter overlap minus random expectation",
    fill = NULL,
    title = "Repeat support is uncommon, but rises before later success",
    subtitle = "Each point is a pair of consecutive requests"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top")
ggsave(
  file.path(DIR_FIGURES, "fig2_supporter_overlap.png"),
  p2,
  width = 8,
  height = 5,
  dpi = 300
)

p3_data <- pairs[!is.na(pairs$community_breadth_change), ]
p3 <- ggplot(
  p3_data,
  aes(x = previous_group, y = community_breadth_change, fill = next_group)
) +
  geom_hline(yintercept = 0, linetype = 2, color = "gray45") +
  geom_boxplot(
    position = position_dodge(width = 0.72),
    width = 0.62,
    outlier.shape = NA,
    alpha = 0.55,
    linewidth = 0.35
  ) +
  geom_point(
    position = position_jitterdodge(jitter.width = 0.16, dodge.width = 0.72),
    size = 0.9,
    alpha = 0.45,
    stroke = 0
  ) +
  scale_fill_manual(
    values = c("Next: rejected" = "#9ECAE1",
               "Next: successful" = "#F4A582")
  ) +
  labs(
    x = "Outcome of previous request",
    y = "Change in effective supporter communities",
    fill = NULL,
    title = "Change in the breadth of a candidate's voter coalition"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "top")
ggsave(
  file.path(DIR_FIGURES, "fig3_community_diversity.png"),
  p3,
  width = 8,
  height = 5,
  dpi = 300
)

coefficient_table <- model_objects$coefficient_table
plot_coefficients <- coefficient_table[
  coefficient_table$model == "Network-augmented" &
    coefficient_table$term != "(Intercept)",
]
plot_coefficients$term_label <- factor(
  plot_coefficients$term_label,
  levels = rev(plot_coefficients$term_label)
)
p4 <- ggplot(
  plot_coefficients,
  aes(x = odds_ratio, y = term_label)
) +
  geom_vline(xintercept = 1, linetype = 2, color = "gray45") +
  geom_errorbar(
    aes(xmin = confidence_low, xmax = confidence_high),
    orientation = "y",
    width = 0.18,
    color = "#176B87",
    linewidth = 0.6
  ) +
  geom_point(size = 2.1, color = "#176B87") +
  scale_x_log10() +
  labs(
    x = "Odds ratio for success at the next request (95% CI)",
    y = NULL,
    title = "Network-augmented pre-request model",
    subtitle = sprintf(
      "Grouped CV AUC %.3f without network measures; %.3f with them",
      model_objects$performance$auc[
        model_objects$performance$model == "Vote shares and timing"
      ],
      model_objects$performance$auc[
        model_objects$performance$model == "Network-augmented"
      ]
    )
  ) +
  theme_minimal(base_size = 11)
ggsave(
  file.path(DIR_FIGURES, "fig4_model_coefficients.png"),
  p4,
  width = 8,
  height = 5,
  dpi = 300
)
````

### `R/99_verify_data.R`

````r
# 99 - Independent verification of the claims made in docs/DATA.md.
# Recomputes every figure STARTING FROM THE RAW FILES, without using any
# intermediate output, and compares it with what is stated. Prints OK or MISMATCH.
# It is there for anyone who wants to check the work rather than trust it.
# Input : data/raw/*.gz    Output: data/processed/99_verification.txt

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

ko <- 0L; log_lines <- character(0)
chk <- function(label, got, expected, tol = 0) {
  verdict <- if (is.na(got) || is.na(expected)) "?" else
             if (abs(got - expected) <= tol) "OK" else { ko <<- ko + 1L; "MISMATCH" }
  s <- sprintf("%-62s %12s  expected %12s  %s", label,
               format(got, big.mark = " "), format(expected, big.mark = " "), verdict)
  log_lines <<- c(log_lines, s); cat(s, "\n", sep = "")
}
sect <- function(t) { s <- paste0("\n== ", t, " =="); log_lines <<- c(log_lines, s); cat(s, "\n") }

# ---------------------------------------------------------------- wiki-RfA --
sect("wiki-RfA: parsed independently of the pipeline parser")
L <- readLines(gzfile(FILE_RFA), warn = FALSE, encoding = "UTF-8")
k <- sub(":.*$", "", L); v <- sub("^[A-Z]{3}:", "", L)
keep <- k %in% c("SRC","TGT","VOT","RES","YEA","DAT","TXT")
chk("total lines in the file", length(L), 1586200)
chk("discarded lines that are NOT blank separators", sum(!keep & L != ""), 0)
rec <- cumsum(k[keep] == "SRC")
chk("records (= votes)", max(rec), 198275)
chk("records whose field count is not 7", sum(table(rec) != 7), 0)
D <- as.data.frame(tapply(v[keep], list(rec, k[keep]), identity), stringsAsFactors = FALSE)

sect("wiki-RfA: user identity")
all_names_raw <- c(D$SRC, D$TGT)
chk("distinct users WITHOUT trimming", length(unique(all_names_raw)), 11402)
chk("distinct users WITH trimming (SNAP total)", length(unique(trimws(all_names_raw))), 11381)
chk("distinct users after full normalisation", length(unique(clean_name(all_names_raw))), 11380)
con_sp <- unique(all_names_raw)[unique(all_names_raw) != trimws(unique(all_names_raw))]
chk("spellings with a leading or trailing blank", length(con_sp), 43)
chk("  of which collide with the clean form already present", sum(trimws(con_sp) %in% all_names_raw), 21)
chk("  reduction in distinct names", length(unique(all_names_raw)) - length(unique(trimws(all_names_raw))), 21)
chk("voter-candidate pairs WITHOUT trimming (SNAP total)",
    nrow(unique(D[, c("SRC","TGT")])), 189004)
# Dt: the same data with usernames normalised the way read_rfa() does. D stays
# raw, so that both stages can be checked.
Dt <- D; Dt$SRC <- clean_name(D$SRC); Dt$TGT <- clean_name(D$TGT)
chk("voter-candidate pairs after normalisation", nrow(unique(Dt[, c("SRC","TGT")])), 189001)
chk("distinct voters, normalised (empty node included)", length(unique(Dt$SRC)), 10416)
chk("distinct candidates", length(unique(Dt$TGT)), 3497)
chk("users who are BOTH voters AND candidates", length(intersect(unique(Dt$SRC), unique(Dt$TGT))), 2533)
chk("candidates who never voted", length(setdiff(unique(Dt$TGT), unique(Dt$SRC))), 964, tol = 5)
cap <- function(s) ifelse(s == "", s, paste0(toupper(substr(s,1,1)), substr(s,2,nchar(s))))
chk("users after merging the first letter", length(unique(cap(clean_name(all_names_raw)))), 11243)
gr <- split(unique(trimws(all_names_raw)), cap(unique(trimws(all_names_raw))))
chk("groups of spellings differing only in first-letter case", sum(lengths(gr) > 1), 137)
chk("  of which the person is a candidate under some spelling",
    sum(vapply(gr, function(f) length(f) > 1 && any(f %in% Dt$TGT), TRUE)), 90)
chk("  of which the CANDIDATE appears under two spellings",
    sum(lengths(split(unique(Dt$TGT), cap(unique(Dt$TGT)))) > 1), 8)

sect("wiki-RfA: fields")
chk("support votes (VOT=1)",  sum(D$VOT ==  "1"), 144451)
chk("oppose votes (VOT=-1)",   sum(D$VOT == "-1"),  41176)
chk("neutral votes (VOT=0)",      sum(D$VOT ==  "0"),  12648)
chk("rejected outcome (RES=-1)",  sum(D$RES == "-1"),  74987)
chk("approved outcome (RES=1)",  sum(D$RES ==  "1"), 123288)
chk("empty DAT", sum(D$DAT == ""), 9367)
dt <- parse_dat(D$DAT)
chk("DAT with an unrecognised format", attr(dt, "n_bad_format"), 0)
chk("DAT with an impossible value (hour 31)", attr(dt, "n_impossible"), 1)
mm <- sub("^.*, [0-9]{1,2} ([A-Za-z]+) [0-9]{4}$", "\\1", D$DAT[D$DAT != ""])
abbr <- c("Jan","Feb","Mar","Apr","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
chk("votes with an abbreviated month (May excluded: identical in both forms)", sum(mm %in% abbr), 7077)
chk("  votes whose month is 'May'", sum(mm == "May"), 18603)
chk("votes with the month misspelled in the source", sum(mm %in% c("Janry","Julu","Mya")), 3)
chk("dates a %B parser would lose", sum(mm %in% abbr) + sum(mm %in% c("Janry","Julu","Mya")), 7080)
ya <- as.integer(format(dt, "%Y"))
chk("votes whose date year differs from YEA",
    sum(ya != as.integer(D$YEA), na.rm = TRUE), 1875)
chk("votes dated 2003", sum(ya == 2003, na.rm = TRUE), 155)
chk("votes dated 2013", sum(ya == 2013, na.rm = TRUE), 3348)
ch <- paste(D$SRC, D$TGT, D$VOT, D$RES, D$YEA, D$DAT, sep = "\r")
chk("fully identical rows", sum(duplicated(ch)), 595)
chk("empty comments", sum(D$TXT == ""), 7190)
chk("median comment length", median(nchar(D$TXT)), 98)
chk("maximum comment length", max(nchar(D$TXT)), 7610)
chk("comments starting with a bold marker", sum(startsWith(D$TXT, "'''")), 162939)
chk("votes cast per voter: median", median(table(Dt$SRC)), 3)
chk("votes cast per voter: maximum, phantom records EXCLUDED", max(table(Dt$SRC[Dt$SRC != ""])), 1232)
chk("votes received per candidate: median", median(table(Dt$TGT)), 41)
chk("votes received per candidate: maximum", max(table(Dt$TGT)), 987)

# --------------------------------------------------------------- wiki-Elec --
sect("wiki-Elec: format defects")
raw_b <- readLines(gzfile(FILE_ELEC), warn = FALSE, skipNul = TRUE)
chk("lines read by readLines()", length(raw_b), 128016)
chk("lines where readLines() LEAVES a CR", sum(grepl("\r", raw_b, fixed = TRUE)), 0)
con <- gzfile(FILE_ELEC, open = "rb"); bb <- readBin(con, "raw", 3e6); close(con)
chk("CRLF byte pairs in the first 3 MB of the file", 
    sum(bb[-length(bb)] == as.raw(13) & bb[-1] == as.raw(10)), 83859)
chk("lines that are not valid UTF-8",
    sum(is.na(iconv(raw_b, from = "UTF-8", to = "UTF-8"))), 19)
E <- read_elec(FILE_ELEC)
chk("elections", nrow(E$elections), 2794)
chk("votes", nrow(E$votes), 114040)
chk("distinct voters", length(unique(E$votes$voter)), 6210)
chk("promotions", sum(E$elections$outcome == 1), 1248)
chk("rejections", sum(E$elections$outcome == 0), 1546)
chk("distinct candidates", length(unique(E$elections$candidate)), 2391)
chk("nominator = UNKNOWN", sum(E$elections$nominator == "UNKNOWN"), 2117)
chk("declared self-nominations", sum(E$elections$nominator == E$elections$candidate), 85)
chk("votes per election: median", median(table(E$votes$election_id)), 34)
chk("votes per election: maximum", max(table(E$votes$election_id)), 370)
chk("support votes", sum(E$votes$vot == 1), 83962)
chk("oppose votes",   sum(E$votes$vot == -1), 23118)
chk("neutral votes",     sum(E$votes$vot == 0), 6960)
chk("missing closing times", sum(is.na(E$elections$closed_at)), 0)
yv <- as.integer(format(E$votes$dat, "%Y"))
chk("votes with an impossible year (>2008)", sum(yv > 2008), 11)
cat("  declared closing times from", format(min(E$elections$closed_at)),
    "to", format(max(E$elections$closed_at)), "\n")
cat("  votes (plausible years) from", format(min(E$votes$dat[yv <= 2008])),
    "to", format(max(E$votes$dat[yv <= 2008])), "\n")
chk("elections closed before September 2004",
    sum(E$elections$closed_at < as.POSIXct("2004-09-01", tz = "UTC")), 0)
chk("elections closed in 2007", sum(format(E$elections$closed_at, "%Y") == "2007"), 2180)

sect("wiki-Elec: the T field is unreliable")
ul <- vapply(split(as.numeric(E$votes$dat), E$votes$election_id)[
               as.character(E$elections$election_id)],
             function(x) max(x[x < as.numeric(as.POSIXct("2009-01-01", tz="UTC"))]), 0)
dT <- as.numeric(difftime(E$elections$closed_at,
                          as.POSIXct(ul, origin="1970-01-01", tz="UTC"), units="days"))
chk("gap T - last vote: median (days)", round(median(dT)), 102, tol = 1)
chk("elections with T more than 30 days later", sum(dT > 30), 1512)
chk("elections with T more than 180 days later", sum(dT > 180), 1217)
chk("minimum gap (T before the last vote)", round(min(dT)), -188, tol = 1)

sect("spellings across the two files")
chk("wiki-Elec: candidates with an underscore", sum(grepl("_", unique(E$elections$candidate))), 408)
chk("wiki-Elec: candidates with a space",    sum(grepl(" ",  unique(E$elections$candidate))), 0)
chk("wiki-RfA: candidates with an underscore", sum(grepl("_", unique(Dt$TGT))), 0)
chk("wiki-RfA: candidates with a space",     sum(grepl(" ",  unique(Dt$TGT))), 606)
ec <- unique(E$elections$candidate); rc <- unique(tolower(Dt$TGT))
chk("wiki-Elec candidates found in wiki-RfA, direct match (%)",
    round(100*mean(ec %in% rc), 1), 74.9, tol = 0.2)
chk("wiki-Elec candidates found after normalisation (%)",
    round(100*mean(norm_user(ec) %in% norm_user(rc)), 1), 89.8, tol = 0.2)

# ---------------------------------------- igiene: le trappole classiche -----
# This section does not verify claims: it actively looks for the category of
# "basic" problems that are easy to miss. Each line is a defect that, if
# present and untreated, produces phantom nodes, invented edges or wrong
# counts. The expected values are the ones measured and handled; if they
# change, something in the data or in the code has changed and needs a look.
sect("HYGIENE: the classic traps")
uu_raw <- unique(c(D$SRC, D$TGT))            # original spelling in the file
uu     <- unique(c(Dt$SRC, Dt$TGT))          # after clean_name()
chk("empty names among the nodes (phantom records still present here)", sum(uu == ""), 1)
chk("PHANTOM RECORDS: votes with an empty SRC", sum(Dt$SRC == ""), 1661)
chk("  of these, how many also have an empty TXT", sum(Dt$SRC == "" & Dt$TXT == ""), 1661)
chk("  candidates that exist ONLY through phantom records",
    length(setdiff(unique(Dt$TGT[Dt$SRC == ""]), unique(Dt$TGT[Dt$SRC != ""]))), 6)
chk("names with multiple internal blanks, BEFORE cleaning", sum(grepl("  ", uu_raw)), 1)
chk("  and after cleaning", sum(grepl("  ", uu)), 0)
chk("names with invisible characters, BEFORE cleaning",
    sum(grepl("[\u200b-\u200f\ufeff]", uu_raw)), 1)
chk("  and after cleaning", sum(grepl("[\u200b-\u200f\ufeff]", uu)), 0)
chk("names with a tab or newline", sum(grepl("[\t\r\n]", uu)), 0)
chk("names with a non-breaking space U+00A0", sum(grepl("\u00a0", uu)), 0)
chk("names with HTML entities", sum(grepl("&[a-z]+;|&#[0-9]+;", uu)), 0)
chk("names with an underscore (wiki-RfA uses none)", sum(grepl("_", uu)), 0)
chk("non-ASCII names (legitimate)", sum(grepl("[^\x01-\x7f]", uu, perl = TRUE)), 78)
chk("SELF-VOTES: the candidate votes in their own RfA", sum(Dt$SRC == Dt$TGT), 103)
chk("votes with an empty TGT", sum(Dt$TGT == ""), 0)
chk("VOT outside {-1,0,1}", sum(!(D$VOT %in% c("-1","0","1"))), 0)
chk("RES outside {-1,1}", sum(!(D$RES %in% c("-1","1"))), 0)
chk("YEA outside 2003-2013", sum(!(as.integer(D$YEA) %in% 2003:2013)), 0)
chk("dates before 2003", sum(dt < as.POSIXct("2003-01-01", tz = "UTC"), na.rm = TRUE), 0)
chk("dates after May 2013 (declared end of coverage)",
    sum(dt > as.POSIXct("2013-05-31 23:59", tz = "UTC"), na.rm = TRUE), 75)

sect("HYGIENE: wiki-Elec")
chk("duplicate voters within the same election",
    sum(duplicated(paste(E$votes$election_id, E$votes$voter))), 0)
chk("elections with no votes at all", nrow(E$elections) - length(unique(E$votes$election_id)), 0)
chk("elections with a single vote", sum(table(E$votes$election_id) == 1), 97)
chk("the candidate votes in their own election",
    sum(norm_user(E$votes$voter) == norm_user(
      E$elections$candidate[match(E$votes$election_id, E$elections$election_id)])), 72)
chk("empty usernames among the voters", sum(E$votes$voter == "" | is.na(E$votes$voter)), 0)
chk("two elections with the same candidate and closing time",
    sum(duplicated(paste(E$elections$candidate, E$elections$closed_at))), 0)

# ------------------------------------------------ assunzioni del metodo -----
sect("ASSUMPTION: RES is a property of the election, not of the vote")
# Grouping by (candidate, RES) rests on this assumption, so it is tested here.
# TWO tests, and only the second one is valid.
#
# (1) Across ALL candidates: for each wiki-Elec election, take the wiki-RfA
#     votes of that election's voters for that candidate and check whether RES
#     is constant. This gives 15.0% non-constant, and that figure is an
#     ARTEFACT: a candidate with several elections shares voters between their
#     own elections, so selecting votes by voter membership pulls in the votes
#     of the OTHER election, which legitimately carry a different RES. Reported
#     only to show why it must not be quoted.
#
# (2) Restricted to candidates who have a SINGLE election in wiki-Elec, where
#     there is no ambiguity about which election is meant. This is the valid
#     test: 2.3% non-constant. In those cases the rule splits one election in
#     two, and that is the residual error of the method.
#
# The exposure is bounded independently: the gap_only rule in 03 does not use
# RES to set boundaries at all, and at a 7-day threshold it yields 4,063
# attempts against 4,081, so the whole question moves 18 attempts out of 4,081.
Dt$kc <- norm_user(Dt$TGT); Dt$kv <- norm_user(Dt$SRC)
ev <- E$votes; ev$kv <- norm_user(ev$voter)
ele <- E$elections; ele$kc <- norm_user(ele$candidate)
set_el <- split(ev$kv, ev$election_id)
n_el <- table(ele$kc)
idx_c <- split(seq_len(nrow(Dt)), Dt$kc)
run_res_test <- function(single_election_only) {
  sel <- if (single_election_only) which(n_el[ele$kc] == 1) else seq_len(nrow(ele))
  mixed <- 0L; examined <- 0L
  for (r in sel) {
    ii <- idx_c[[ele$kc[r]]]; if (is.null(ii)) next
    jj <- ii[Dt$kv[ii] %in% set_el[[as.character(ele$election_id[r])]]]
    if (length(jj) < 10) next
    examined <- examined + 1L
    if (length(unique(Dt$RES[jj])) > 1) mixed <- mixed + 1L
  }
  c(examined = examined, mixed = mixed)
}
t_all <- run_res_test(FALSE); t_one <- run_res_test(TRUE)
cat(sprintf("  (1) all candidates      : %d examined, %d with non-constant RES (%.1f%%)  <- CONTAMINATED, do not quote\n",
            t_all[1], t_all[2], 100*t_all[2]/t_all[1]))
cat(sprintf("  (2) one-election only   : %d examined, %d with non-constant RES (%.1f%%)  <- THE VALID FIGURE\n",
            t_one[1], t_one[2], 100*t_one[2]/t_one[1]))
log_lines <- c(log_lines,
  sprintf("  (1) all candidates: %d examined, %d non-constant RES (%.1f%%) - CONTAMINATED",
          t_all[1], t_all[2], 100*t_all[2]/t_all[1]),
  sprintf("  (2) one-election candidates only: %d examined, %d non-constant RES (%.1f%%) - VALID",
          t_one[1], t_one[2], 100*t_one[2]/t_one[1]))
chk("valid RES test: non-constant share, one-election candidates (%)",
    round(100*t_one[2]/t_one[1], 1), 2.3, tol = 0.1)

sect("RESULT")
cat(if (ko == 0) "Every verified claim matches.\n" else
    sprintf("%d claims DO NOT match.\n", ko))
log_lines <- c(log_lines, if (ko == 0) "Every claim matches." else
               sprintf("%d claims DO NOT match.", ko))
writeLines(log_lines, file.path(DIR_PROCESSED, "99_verification.txt"))
````

### `R/99b_verify_output.R`

````r
# 99b - Second verification round: the INTERNAL INVARIANTS of the tables produced
# and the derived figures quoted in docs/DATA.md.
# While 99_verify_data.R checks the claims about the RAW files, this one checks
# that the output is internally consistent: if one of these conditions fails
# there is a bug in the pipeline, not an inaccuracy in the text.
# Input : data/processed/*.rds   Output: data/processed/99b_verification.txt

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

ko <- 0L; log_lines <- character(0)
inv <- function(label, condition, detail = "") {
  ok <- isTRUE(all(condition))
  if (!ok) ko <<- ko + 1L
  s <- sprintf("%-70s %s%s", label, if (ok) "OK" else "FAILED",
               if (!ok && nzchar(detail)) paste0("  <- ", detail) else "")
  log_lines <<- c(log_lines, s); cat(s, "\n", sep = "")
}
chk <- function(label, got, expected, tol = 0) {
  ok <- !is.na(got) && abs(got - expected) <= tol
  if (!ok) ko <<- ko + 1L
  s <- sprintf("%-62s %12s  expected %12s  %s", label,
               format(got, big.mark = " "), format(expected, big.mark = " "),
               if (ok) "OK" else "MISMATCH")
  log_lines <<- c(log_lines, s); cat(s, "\n", sep = "")
}
sect <- function(t) { s <- paste0("\n== ", t, " =="); log_lines <<- c(log_lines, s); cat(s, "\n") }

v <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
a <- readRDS(file.path(DIR_PROCESSED, "attempts.rds"))
av <- readRDS(file.path(DIR_PROCESSED, "attempts_validated.rds"))

sect("INVARIANTS: votes.rds")
inv("no voter appears twice within the same attempt",
    !any(duplicated(v[, c("attempt_id", "src")])))
inv("no missing attempt_id", !any(is.na(v$attempt_id)))
inv("vot only takes the values -1, 0, 1", all(v$vot %in% c(-1, 0, 1)))
inv("res only takes the values -1, 1", all(v$res %in% c(-1, 1)))
inv("dat is NA exactly when the vote had no date",
    all(is.na(v$dat) == v$dat_missing))
inv("imputed votes all lack an original date",
    all(v$dat_missing[v$dat_imputed]))
inv("res is constant within every attempt",
    all(tapply(v$res, v$attempt_id, function(x) length(unique(x))) == 1))
inv("the candidate is constant within every attempt",
    all(tapply(v$tgt, v$attempt_id, function(x) length(unique(x))) == 1))
inv("no leading or trailing blanks in usernames",
    all(v$src == trimws(v$src)) && all(v$tgt == trimws(v$tgt)))
inv("no empty username (phantom records were removed)",
    all(v$src != "") && all(v$tgt != ""))
inv("no invisible character or double blank in usernames",
    all(v$src == clean_name(v$src)) && all(v$tgt == clean_name(v$tgt)))
inv("self_vote matches src == tgt", all(v$self_vote == (v$src == v$tgt)))
inv("n_self_votes matches the per-attempt count of self-votes",
    all(a$n_self_votes == as.integer(tapply(v$src == v$tgt, v$attempt_id, sum)[as.character(a$attempt_id)])))

sect("INVARIANTS: attempts.rds and consistency with votes.rds")
inv("attempt_id is unique", !any(duplicated(a$attempt_id)))
inv("the attempt_ids of the two tables coincide",
    setequal(a$attempt_id, unique(v$attempt_id)))
n_per <- table(v$attempt_id)
inv("n_votes matches the actual vote count",
    all(a$n_votes == as.integer(n_per[as.character(a$attempt_id)])))
inv("n_support + n_oppose + n_neutral == n_votes",
    all(a$n_support + a$n_oppose + a$n_neutral == a$n_votes))
inv("no attempt with zero votes", all(a$n_votes > 0))
inv("support_share == n_support / (n_support + n_oppose)",
    all(abs(a$support_share - a$n_support/(a$n_support + a$n_oppose)) < 1e-9 |
        is.na(a$support_share)))
inv("opened_at <= closed_at", all(a$opened_at <= a$closed_at))
inv("duration_days matches the difference between the two dates",
    all(abs(a$duration_days -
            as.numeric(difftime(a$closed_at, a$opened_at, units = "days"))) < 1e-6))
inv("attempt_no is a contiguous 1..k for every candidate",
    all(tapply(a$attempt_no, a$candidate,
               function(x) identical(sort(as.integer(x)), seq_along(x)))))
inv("attempt_no is ordered by opened_at",
    all(tapply(seq_len(nrow(a)), a$candidate, function(i)
      !is.unsorted(a$opened_at[i][order(a$attempt_no[i])]))))
inv("prev_outcome is the outcome of the candidate's previous attempt",
    all(vapply(split(seq_len(nrow(a)), a$candidate), function(i) {
      i <- i[order(a$attempt_no[i])]
      if (length(i) == 1) return(is.na(a$prev_outcome[i]))
      is.na(a$prev_outcome[i[1]]) &&
        identical(a$prev_outcome[i[-1]], a$outcome[i[-length(i)]])
    }, TRUE)))
inv("flag_short == (n_votes < 5)", all(a$flag_short == (a$n_votes < 5)))
inv("flag_long == (duration_days > 14)", all(a$flag_long == (a$duration_days > 14)))
inv("attempt_no agrees across the two tables",
    all(v$attempt_no == a$attempt_no[match(v$attempt_id, a$attempt_id)]))

sect("VOTE CONSERVATION")
raw_n <- 198275L
phantom <- 1661L; removed <- 630L + 100L; lost <- 632L
chk("raw records", raw_n, 198275)
chk("votes in votes.rds", nrow(v), 195252)
chk("phantom + duplicate + undated losses", phantom + removed + lost, raw_n - nrow(v))
chk("votes with an imputed date", sum(v$dat_imputed), 6975)
chk("undated votes kept in the table", sum(v$dat_missing), 6975)

sect("FIGURES QUOTED IN docs/DATA.md")
chk("attempts", nrow(a), 4081)
repeats <- table(a$candidate)
chk("repeat candidates (2+ attempts)", sum(repeats > 1), 490)
chk("candidates with 3+ attempts", sum(repeats > 2), 91)
chk("consecutive attempt pairs", sum(repeats[repeats > 1] - 1), 621)
chk("attempts with a known previous outcome", sum(!is.na(a$prev_outcome)), 621)
chk("candidates with at least one previous rejection",
    length(unique(a$candidate[!is.na(a$prev_outcome) & a$prev_outcome == -1])), 451)
chk("candidates with at least one previous success",
    length(unique(a$candidate[!is.na(a$prev_outcome) & a$prev_outcome == 1])), 53)
chk("flag_short", sum(a$flag_short), 297)
chk("flag_long", sum(a$flag_long), 4)
chk("flag_year_clash", sum(a$flag_year_clash), 363)
chk("attempts matched in wiki-Elec", sum(av$elec_matched), 2175)
chk("of which the outcome agrees", sum(av$outcome_agrees, na.rm = TRUE), 2175 - 12)
chk("attempts with no external match", sum(!av$elec_matched), 4081 - 2175)

sect("NETWORK STRUCTURE, ON THE DELIVERED TABLE (not on the raw file)")
# NB: the raw-file figures (10,417 voters, 3,497 candidates, 2,533 both) are NOT
# these: thousands of records leave the pipeline and with them some users
# disappear entirely. The document must report both.
chk("distinct voters in votes.rds", length(unique(v$src)), 10300, tol = 30)
chk("distinct candidates in votes.rds", length(unique(v$tgt)), 3460, tol = 10)
chk("users who are both voters and candidates", length(intersect(v$src, v$tgt)), 2549, tol = 10)
chk("support votes", sum(v$vot == 1), 143154, tol = 600)
chk("oppose votes", sum(v$vot == -1), 40220, tol = 600)
chk("neutral votes", sum(v$vot == 0), 11878, tol = 600)
chk("attempts where n_votes_dated + n_votes_imputed != n_votes",
    sum(a$n_votes_dated + a$n_votes_imputed != a$n_votes), 0)
chk("sum of imputed votes across attempts", sum(a$n_votes_imputed), 6975)
chk("self-votes surviving in the table", sum(v$self_vote), 98)
chk("sum of n_self_votes", sum(a$n_self_votes), sum(v$self_vote))

sect("ROUND 2 RESULT")
cat(if (ko == 0) "Every invariant holds and every figure matches.\n" else
    sprintf("%d checks FAILED.\n", ko))
log_lines <- c(log_lines, if (ko == 0) "Everything consistent." else sprintf("%d checks failed.", ko))
writeLines(log_lines, file.path(DIR_PROCESSED, "99b_verification.txt"))
````

### `R/98_generate_appendix.R`

````r
# 98 - Regenerates the code appendix of docs/DATA_FULL.md from the real files in R/.
# Run it after every change to the scripts, so that the code shown in the
# document cannot drift from the code that actually runs. It rewrites only the
# region between the two markers and leaves the rest of the document untouched.
FILES <- c("R/00_run_all.R", "R/run_data_prep.R",
           "R/00_paths.R", "R/00_lib_data.R", "R/01_read_raw.R",
           "R/02_build_attempts.R", "R/03_validate_outcomes.R",
           "R/04_build_networks.R", "R/05_measure_change.R",
           "R/06_model_outcome.R", "R/07_figures.R",
           "R/99_verify_data.R", "R/99b_verify_output.R",
           "R/98_generate_appendix.R")
doc <- "docs/DATA_FULL.md"
text_lines <- readLines(doc, warn = FALSE)
i <- grep("^<!-- GENERATED APPENDIX START -->$", text_lines)
j <- grep("^<!-- GENERATED APPENDIX END -->$", text_lines)
stopifnot(length(i) == 1, length(j) == 1, j > i)
# Four-backtick fences: this very file contains three-backtick sequences in its
# own strings, and a three-backtick fence would be closed by them, breaking the
# last block of the appendix.
blocks <- unlist(lapply(FILES, function(f) {
  c(paste0("### `", f, "`"), "",
    "````r", readLines(f, warn = FALSE), "````", "")
}))
out <- c(text_lines[seq_len(i)], "", blocks, text_lines[j:length(text_lines)])
writeLines(out, doc)
cat("appendix regenerated:", length(blocks), "lines from", length(FILES), "files\n")
````

<!-- GENERATED APPENDIX END -->
