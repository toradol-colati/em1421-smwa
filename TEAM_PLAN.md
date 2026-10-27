# EM1421 Team Delivery Plan

## Status

- Proposal question: approved.
- Team: Umberto Toraldo and Mihretab Worku Morka.
- Final project report length: 12,000-20,000 characters, including spaces.
- Project submission deadline: 2 November 2026 at 09:00 CET.
- The final report must be a PDF and must not contain code or a description of the code.
- The final package must include the report, commented R code and all data needed to run it.

## Roles

### Data member: Umberto

Umberto is responsible for the data pipeline:

1. Download and commit the two SNAP source files.
2. Correct the raw RfA parser so every field is an ordinary column rather than a nested list column.
3. Implement the `wikiElec` parser.
4. Normalise usernames.
5. Remove duplicate votes using a documented rule.
6. Reconstruct candidate attempts and record their opening, closing and outcome.
7. Validate outcomes against `wikiElec`.
8. Audit votes without dates, contradictory outcomes and the previously successful repeat candidates.
9. Produce documented, analysis-ready vote and attempt tables.

Primary code responsibility: `01_prepare_data.R`.

### Network member: Mihretab

Mihretab is responsible for the network and outcome analysis:

1. Build the voter-to-candidate network.
2. Build the voter-to-voter co-voting projection.
3. Identify voter communities.
4. Measure supporter overlap, community diversity, centrality and brokerage.
5. Compare changes across consecutive candidate attempts.
6. Run the leakage-safe outcome analysis using only information available before attempt t+1.
7. Produce the numerical results and four report figures or tables.

Primary code responsibility: `02_analysis.R`.

### Joint responsibilities

- Agree on the table schemas before either script is finalised.
- Agree on the definition of both networks before network metrics are calculated.
- Maintain literature notes in Markdown and connect each source to the research question.
- Interpret the results together.
- Write the report source in Markdown, then export the final PDF.
- Include the required paragraph describing each member's contribution.
- Test the complete package from a clean checkout.

Code review is internal quality control, not a separate course deliverable.
The seven-minute project discussion is required, but presentation slides are optional and no slide deck needs to be submitted with the project.

## Current repository state

Completed by Umberto:

- Created the private repository and directory structure.
- Added the approved research question and the relevant course documents.
- Added detailed course-material and coding notes.
- Created the numbered R workflow.
- Implemented shared paths and a first version of the raw RfA parser.
- Invited Mihretab as a collaborator.

Current blockers:

- The SNAP data files are not committed.
- `R/01_read_raw.R` runs but produces incorrect nested list columns.
- The parser reports 11,402 users instead of the documented 11,381.
- The `wikiElec` parser is not implemented.
- `R/02` through `R/07` contain comments only.
- No cleaned dataset, network results, model results or figures exist.
- No report draft or contribution paragraph exists.
- `igraph`, `ggplot2` and `data.table` are currently unavailable in the tested R installation.

## Agreed code structure

Use two scripts rather than the current eight-script skeleton:

1. `01_prepare_data.R`
   - Reads both raw files.
   - Cleans votes.
   - Reconstructs and validates attempts.
   - Writes clean `votes` and `attempts` data.
   - Fails clearly if an input or validation check fails.

2. `02_analysis.R`
   - Builds both networks.
   - Calculates community, support coalition, centrality and brokerage measures.
   - Runs the outcome analysis.
   - Writes results tables and four report figures.

All scripts must use relative repository paths and must not install packages or download data during execution.

## Data handoff

Umberto delivers:

- `data/raw/wiki-RfA.txt.gz`
- `data/raw/wikiElec.ElecBs3.txt.gz`
- Clean vote-level data
- One row per validated candidate attempt
- An audit table containing rejected or ambiguous records

Mihretab can begin only after the following are fixed:

- Column types are ordinary vectors.
- Duplicate rule is documented.
- Attempt rule is documented.
- Outcome validation is complete.
- The final counts of repeat candidates are reported.

## Literature-to-report workflow

- Keep literature notes and source details in Markdown.
- Link each reference to a specific claim in the research question, methods or discussion.
- Include at least five scientific references in the final PDF.
- Write the report in Markdown, then export and visually check the PDF.
- Do not include Markdown working notes in the final Moodle ZIP unless needed to reproduce the project.

## Final submission package

```text
EM1421_Submission/
  report.pdf
  README.txt
  data/
    wiki-RfA.txt.gz
    wikiElec.ElecBs3.txt.gz
  R/
    01_prepare_data.R
    02_analysis.R
  output/
    results/
    figures/
```

The report must contain:

- The approved research question and motivation.
- A precise data description.
- Network and statistical methodology.
- Results and interpretation.
- Specific limitations and biases.
- At least five scientific references.
- No more than four captioned and referenced figures or tables.
- A paragraph describing each member's contribution.

## Next actions

1. Record the agreed roles in the team communication.
2. Freeze the schemas for `votes` and `attempts`.
3. Freeze node, edge, direction, weight and time-window definitions for both networks.
4. Umberto fixes and completes data preparation.
5. Mihretab implements network and outcome analysis against the prepared data.
6. Both members review results and limitations.
7. Both members write and format the report.
8. Run the package from a clean checkout and submit it before the deadline.
