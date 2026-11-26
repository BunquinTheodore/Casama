# Parcel Timing Explorer: Casama Data Science final project

Group Theoraux: Theodore Von Joshua M. Bunquin, Christian B. Nayre, Daniel B. Villanueva, John C. Alcaraz and Paul C. Alcaraz.

This project asks **when parcels arrive late, and whether weather or public holidays help explain it**, to inform Casama's parcel board. It analyses {{cleaning.analysed}} real marketplace orders (Olist, Brazil) together with daily weather from the Open-Meteo API and public holidays from the Nager.Date API. It is the Data Science final project, built in a fork of the 3rd year Casama repository. It is an analysis, not an app.

## What is here

| Output | Where |
|---|---|
| Explorer page, one self contained file that opens offline | `explorer/index.html` |
| Video presentation (Google Drive) | to be added after upload |
| Every number and chart series | `output/findings.json`, `output/series.json` |
| Sources, licences and references | `REFERENCES.md` |

Open the page by double clicking `explorer/index.html` (or open it from the repository in a browser). It needs no server and no internet connection.

## Results in short

* {{late.rate_pct|2}}% of delivered parcels arrive on a later calendar day than the estimate. The median parcel takes {{delivery_days.median|1}} days.
* A slow seller handoff is the strongest warning sign: {{handoff.late_pct_slow|1}}% late when the seller takes a week or more, against {{handoff.late_pct_fast|1}}% when it takes under a day.
* Heavy rain: {{#if h1.verdict=supported}}supported, even after accounting for month and state.{{/if}}{{#if h1.verdict=no clear effect}}no clear effect once month and state are accounted for (odds ratio {{h1.adjusted_or.odds_ratio|2}}, interval {{h1.adjusted_or.ci_low|2}} to {{h1.adjusted_or.ci_high|2}}), although the raw late rate rises from {{h1.late_pct_no_heavy_rain|1}}% to {{h1.late_pct_three_or_more|1}}%.{{/if}}{{#if h1.verdict=opposite}}the opposite of the guess after accounting for month and state.{{/if}}
* Public holidays: {{#if h2.verdict=supported}}supported (more late parcels).{{/if}}{{#if h2.verdict=no clear effect}}no clear effect.{{/if}}{{#if h2.verdict=opposite}}the opposite of our guess. Parcels with a holiday in their window were late {{h2.late_pct_with_holiday|1}}% of the time against {{h2.late_pct_without|1}}% (odds ratio {{h2.adjusted_or.odds_ratio|2}}). We did not test why.{{/if}}
* Model: {{h3.auc_stage_1|3}} AUC at purchase, {{h3.auc_stage_2|3}} after shipping and {{h3.auc_stage_3|3}} with weather and holidays. {{#if h3.verdict=improved}}The weather and holiday gain of {{h3.diff|3}} is clear in the data (interval {{h3.diff_ci_low|3}} to {{h3.diff_ci_high|3}}), but it may partly reflect where and when parcels were sent.{{/if}}{{#if h3.verdict=no clear improvement}}The change is not clearly different from zero.{{/if}}{{#if h3.verdict=worse}}Adding weather and holidays made it worse.{{/if}}
* The model is modest and uses observed weather, so it explains past parcels and is not a forecast.

## Run it again

Python 3.12 is used. No API keys are needed.

```bash
pip install -r requirements.txt
python src/run_all.py            # downloads the Kaggle tables, calls the two APIs, then writes output/*.json,
                                 # explorer/index.html, this README and video/narration.json
python -m pytest                 # runs the tests
```

The video needs Node 20 or newer. The voice needs an ElevenLabs key in `.env.local` at the repository root and enough
characters left on the account; scenes that were already rendered for the same text are never billed twice.

```bash
python src/make_voice.py --dry-run   # characters per scene, no key needed
python src/make_voice.py             # renders the narration (voice: Brian) with word timings: video/scene_timings.json, video/cues.json
python src/make_sfx.py               # synthesises the sound effects into video/sfx (original sounds, nothing downloaded)
cd video/remotion
npm install
npm run render:final                 # out/theoraux-data-science.mp4: narration, sound effects, every picture timed to the words
```

Every picture in the video is tied to the phrase of the narration it illustrates, using the word timings of the voice, so what is on screen is what the voice is saying. Without credits, `python src/make_voice.py --estimate` builds scene lengths from the word count for a silent draft.

Kaggle downloads work without an account for these public datasets. The two API pulls are cached in `data/cache/`, so a second run needs no network for them.

## Reusing it for another country

Change the country code in the holiday call and the coordinates in the weather call. The page shows the same holiday call returning Philippine 2026 holidays.

## Limits

The data is Brazilian, holds timestamps only (no courier, payment type or cash on delivery amount), and weather is one point per state capital. Results are associations, not causes. See section 09 of the page.

## Attribution

Weather data by [Open-Meteo.com](https://open-meteo.com/) (CC BY 4.0). Public holidays from [Nager.Date](https://date.nager.at/Api). Orders from the Olist public dataset on Kaggle. Full references and licence notes: `REFERENCES.md`.
