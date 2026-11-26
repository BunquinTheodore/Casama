# Data Science final project: Casama delivery timing explorer

Status: draft for approval. Date: 2026-11-24. Scope: the Data Science project only. The AI project gets its own design after this one is approved.

## Intent and why

This is a group graded final project for the Data Science class, built in a fork of the 3rd year Casama repo. The fork is already in place: `origin` is `BunquinTheodore/Casama`, a GitHub fork of `pol-xy/Casama` (confirmed with `gh`).

Two outputs are required:

1. A data analysis written in the "Data Science Explorer" format.
2. A video of 8 to 10 minutes in the same style. One presenter is enough.

Citations and references are required. The project must not become a system or an app.

The data must be relevant to Casama. Casama's parcel board tracks incoming couriers, housemate availability, conflict alerts and COD. The question the analysis answers is: **when do parcels arrive late, and what could Casama do with that?** The brief says the data should ideally come from an API that can be reused and repurposed.

### What "Data Science Explorer" means here (assumption)

No official source for the name exists. The closest public match is the repo `UmaSaiEswariMylavarapu/data-science-explorer`. It is a single interactive HTML page with numbered sections (01 to 09, including a "Student Performance Project"), a tools section and a short quiz. The working reading is:

- The output is a single scrolling, interactive web page with numbered sections.
- The video walks through the same sections in the same order.

The instructor has no sample to give and said to search for it ourselves, so this reading stands as the working format. If a real sample ever turns up, only the page structure changes, and the pipeline and numbers stay the same.

## Goals, non goals, anti goals

Goals
- A reproducible pipeline: from an empty `data/` folder to every chart, number and the final page, with no API keys.
- A relevant dataset with a real API angle (weather and holidays pulled live from public APIs).
- An explorer page and a video whose numbers match each other and the generated findings file.
- Honest findings, including null results and the limits of the data.
- A references list with real, checked sources.

Non goals
- No new app, backend, login or deployed service.
- No changes to Casama's Flutter code (that belongs to the AI project).
- No claims about Philippine deliveries. The data is Brazilian.

Anti goals (a failure even if it technically works)
- Overclaiming from a weak model or a small effect.
- Invented quotes, numbers, logos or facts. `qualitative.json` stays empty unless the group collects real interviews.
- A page and a video that disagree.

## Constraints

- Data sources, all checked on 2026-11-24:
  - Olist orders, Kaggle `zeynepustun/customer-order-delivery-dataset`: 99,441 orders with timestamps only, already on disk (17 MB, git ignored).
  - Olist customers, Kaggle `olistbr/brazilian-ecommerce`, file `olist_customers_dataset.csv`: gives `customer_state`. It joins to the orders file on `customer_id` with 99,441 of 99,441 matched and 27 states.
  - Open-Meteo Historical Weather API: no key, daily precipitation and temperature, supports several locations in one call. Tested.
  - Nager.Date public holidays API: no key, tested for `BR` 2017 and `PH` 2026. Swapping the country code is what makes the pipeline reusable for the Philippines.
- The orders file has no location, courier, payment type or COD amount. Seller location is unavailable, so weather can only be taken at the destination.
- Weather is observed, not forecast, so models using it explain what happened. They are not a deployable predictor (see Model).
- Licence and attribution text for all four sources must be read and cited. I have not verified any licence yet.
- Tooling on this machine: Python 3.12, pandas 3, scikit-learn 1.9, matplotlib, Node 24, ffmpeg.
- Per the user's standing rules: do not commit or push unless asked in that turn; verify the page in a real browser at desktop, tablet and phone widths; no dashes before labels; never hyphenate words.

## Approaches considered

| | What | Trade off |
|---|---|---|
| A | Keep the Olist orders as they are, restructure into the explorer page and video | Fast and safe, but not API based and the late parcel model stays weak (AUC 0.59 at purchase, 0.65 after shipping) |
| **B (chosen)** | Olist orders plus customers, enriched with Open-Meteo weather and Nager.Date holidays | Meets "ideally an API", adds real new questions, reusable for the Philippines by changing coordinates and country code. The effect may turn out small, and we report that |
| C | Philippine data only, from APIs | No dataset with delivery outcomes exists, so there would be no real finding |

The user picked B ("do what you recommend").

## Design

### Questions, declared before looking

- H1: parcels that see more heavy rain days at the destination after carrier handoff are late more often.
- H2: parcels with a national holiday in that same window are late more often.
- H3: adding weather and holiday features improves the held out model beyond the stage 2 model, with its AUC recomputed under the definition of late below (the old 0.649 used the timestamp definition).

Each is reported whether it holds or not. A flat result is a finding, not a failure.

**Exposure window (fixed now, before any result is read).** The window is the 7 days after carrier handoff, the same length for every parcel. Measured on the analysis set, real handoff to arrival has a median of 7.1 days (p10 1.9, p90 18.7), while handoff to the estimated date has a median of 20.3 days. A window that long would contain rain or a holiday for almost every parcel and make H1 and H2 flat by construction, and a window that ends at actual delivery would let the outcome leak into the feature (late parcels get longer windows). Seven days is known at handoff time and treats every parcel alike.
- H1 is a dose response: late rate by number of heavy rain days in the window (0, 1, 2, 3 or more).
- A sensitivity check repeats everything with 10 and 14 day windows. It is reported next to the 7 day result, and the 7 day result stays the headline whatever the others show.
- The heavy rain threshold is fixed in advance and written on the page (the builder picks it from a cited convention, not from the results).

**Definition of late (changed from the earlier analysis).** The estimated delivery date is stored at midnight for 100% of orders, so a parcel delivered at 2pm on the promised day counted as late. Late now means delivered on a later calendar day than the estimated date. On the analysis set of 95,736 parcels that is 6,229 late (6.51%), against 7,519 (7.85%) under the timestamp rule. The 1,290 parcels that were late only by clock time (17.2% of the old late count) are stated once as a data note. Every earlier headline number (7.9% late, 23% late after a slow handoff, both model AUCs) is recomputed. None of them has been shown outside the group yet.

### Pipeline (Python, in `Data Science/src/`)

1. `download_data.py`: fetch both Kaggle tables with `kagglehub` into `data/raw/` (git ignored).
2. `fetch_weather.py`: one Open-Meteo call per batch of state capitals, daily precipitation sum and mean temperature, 2016-09 to 2018-10. Output cached as a small CSV that can be committed.
3. `fetch_holidays.py`: Nager.Date `BR` for 2016 to 2018, keeping nationwide holidays. Output cached as a small CSV.
4. `delivery_data.py`: existing cleaning (99,441 raw, 95,736 delivered and analysed, 740 dropped as impossible or extreme, 96.3% kept), extended with the calendar day definition of late, the state join, and the weather and holiday features for the 7 day window.
5. `eda_*.py`: existing charts plus new ones for H1 and H2: late rate with and without heavy rain, late rate by holiday proximity, each with a bootstrap 95% interval, plus a month and state controlled comparison.
6. `late_model.py`: existing two stage gradient boosting, trained on 2017 and tested on 2018, plus a third stage with weather and holiday features. Reported next to the first two.
7. `build_findings.py`: one `findings.json` and the aggregated series both the page and the video read. Every number on the page and in the video comes from here.
8. `build_explorer.py`: generates the page.

State capital coordinates come from a cited public source (not typed from memory). Coverage and its coarseness (one point per state) are stated as a limit.

### The explorer page (`Data Science/explorer/index.html`)

A single self contained file that opens offline with a double click (data inlined, no server). It extends the existing `dashboard.html`, which already follows the user's mono editorial look: black and white sections, Josefin Sans Light all caps headings, Manrope body.

Sections, numbered as plain text labels:

| | Section |
|---|---|
| 01 | The question: parcels arrive when nobody is in, and why it matters to Casama |
| 02 | The data: four sources, what each gives, how it is fetched (the API calls are shown) |
| 03 | Cleaning: the funnel from 99,441 orders down to what is analysed |
| 04 | What the data shows: delivery time, the gap to the estimate, lateness by month and by seller handoff |
| 05 | Weather and holidays: H1 and H2 with intervals |
| 06 | Can we predict late parcels: three model stages, H3, honest metrics |
| 07 | Takeaways |
| 08 | From findings to Casama: what the parcel board could do with this (an idea, not built here), plus a small "reuse" box showing the same holiday call returning Philippine 2026 holidays |
| 09 | What this does not prove |
| 10 | Definitions, references and credits |

Interaction stays light: hover values on charts, a state filter on the weather section, a month range filter. An optional three question check yourself block mirrors the reference page. No model runs in the page.

Chart colour: the page chrome stays black and white. Charts keep the single accent already used (`#E4572E`) only to mark the thing being shown. This is a deliberate small exception to the taste skill's "no accent", and the user can say to remove it.

### The video (`Data Science/video/`)

- 1920 by 1080, 30 fps, 8 to 10 minutes. Scenes follow the page sections 01 to 10.
- Built in **Remotion**, with the charts drawn in React from the same JSON the page uses, so the video and page cannot drift apart. I have not yet read the Remotion skill's render contract and will do so before building.
- Narration: I write a timed script (about 1,200 to 1,400 words for 9 minutes) and generate the voice with ElevenLabs (the `elevenlabs` skill, which reads `ELEVENLABS_API_KEY` from the git ignored `.env.local` at the repo root, shared with the AI project). Nobody appears on camera. Scene lengths are set from the generated audio timings, so the picture follows the voice.
- Only the narration text goes to ElevenLabs. Group and member names appear on the title and credits cards, not in the text sent to the voice service.
- Credits card: group Theoraux. Members: Theodore Von Joshua M. Bunquin, Christian B. Nayre, Daniel B. Villanueva, John C. Alcaraz, Paul C. Alcaraz. (The user typed "Thedoroe"; I assumed "Theodore".)
- The reference list appears on screen at the end and in the README.
- The MP4 is not committed (GitHub rejects files over 100 MB). It is uploaded to Google Drive, and the README links to the Drive copy. The page is handed in as the repo link.

### Folder layout

```
Data Science/
  README.md            what it is, how to run, results, limits, references
  requirements.txt
  src/                 pipeline scripts (moved from analysis/ with git mv, history kept)
  data/cache/          small API pulls (committed); data/raw is git ignored
  output/              charts, findings.json, aggregated series
  explorer/index.html  the page
  video/               Remotion project, narration script, render notes
  REFERENCES.md        cited sources with links and access dates
```

`analysis/` is moved into this layout and removed, so there is one source of truth. The existing `.gitignore` entry for `/data/` is updated for the new paths.

## Definition of done

- On a fresh clone, the documented commands rebuild every output with no API keys.
- Every figure on the page and in the video appears in `findings.json`.
- Every chart has labelled axes and a source line.
- H1, H2 and H3 each have a stated result with an interval or metric, whichever way they came out.
- All four sources and the main libraries are cited with working links.
- The page is checked in a real browser at desktop, tablet and phone widths. The video runs 8 to 10 minutes, and its length is confirmed from the rendered file.
- The README links the Drive copy of the video and explains how to open the page from the repo.
- Nothing is committed or pushed until the user asks.

## Calls I made (the user can change these)

- Folder names are `AI` and `Data Science`; `analysis/` moves into the second.
- Weather is taken at the destination state capital, one point per state.
- Hypotheses are fixed before the results are read.
- Remotion for this video; HyperFrames is kept for the AI video.
- The voice is generated with ElevenLabs (the user's choice), with no one on camera.
- The MP4 lives on Google Drive and the README links to it (the user's choice: repo link and drive link).
- There is no known deadline, so the work runs in the order below and gets done as fast as it can be done well. I do every part.
- Numbered section labels (01 to 10) are kept because the explorer format uses them. The user's global rule allows "01" as plain text.
- Late means a later calendar day than the estimate, not a later clock time (see Design). This lowers the headline late rate from 7.85% to 6.51%.
- The exposure window is 7 days after handoff, with 10 and 14 day sensitivity checks.
- Order of work: analysis, then page, then narration script, then recording, then video. The numbers freeze in `findings.json` when the analysis step is accepted, so the script is written once. The state filter, month filter and quiz are stretch items after the core page. The Remotion charts are core.
- A reuse box on the page shows the Philippine holiday pull, to demonstrate "reused and repurposed" rather than only claim it.

## Left to the builder

Chart library choice (inline SVG or a pinned CDN library), the exact heavy rain threshold and its citation, the bootstrap settings, the state capital coordinate source, the scene timings, and the quiz wording.

## Settled by the user (2026-11-24)

- Narration is an ElevenLabs voice, nobody on camera.
- Submission is the repo link (the page) and a Drive link (the video).
- Group name Theoraux, with five members (see Credits card above).
- The instructor says a Kaggle CSV plus two live APIs is enough, requires no particular method, and has no sample of the Data Science Explorer to share.

## Still open

- The deadline is unknown. If one appears, the order of work does not change, but a stretch item may be cut.
- The ElevenLabs key was created on 2026-11-24 through the ElevenLabs sign in flow and stored in `.env.local` at the repo root (git ignored). It should be rotated or deleted once both videos are done.

## Appendix: the brief as given

Final Project, Data Science. Separate repo (ideally). Do not make a system or app. Fork the 3rd year repo, do not clone. Coordinate with the 3rd year group. Video presentation of 8 to 10 minutes each, one presenter is fine (group grade). Include citations and references.

Data Science: the video and output format is like the Data Science Explorer. Find a suitable dataset relevant to the 3rd year app, ideally an API that can be reused and repurposed. Outputs: (1) the Data Science Explorer format of data analysis, (2) a video presentation like the Data Science Explorer.
