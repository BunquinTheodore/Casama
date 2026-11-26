# Data Science Explorer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Data Science final project in `C:\Casama\Data Science\`: a reproducible Olist plus weather plus holidays analysis, a self contained explorer page, and an 8 to 10 minute narrated video.

**Architecture:** A Python pipeline turns three sources into one `findings.json` (every number) and one `series.json` (every chart). The explorer page and the Remotion video both read those two files and nothing else, so they cannot disagree. Pure functions take DataFrames in and return DataFrames or dicts out, and are tested with small fixtures and stubbed HTTP.

**Tech Stack:** Python 3.12, pandas 3, scikit-learn 1.9, statsmodels, pytest, requests, kagglehub; vanilla HTML, CSS and inline SVG for the page; Remotion (Node 24) and ffmpeg for the video; ElevenLabs for the voice.

**Spec:** `docs/superpowers/specs/2026-11-24-data-science-explorer-design.md`

## Global Constraints

- Sources: Olist orders (Kaggle `zeynepustun/customer-order-delivery-dataset`, 99,441 orders), Olist customers (Kaggle `olistbr/brazilian-ecommerce`, file `olist_customers_dataset.csv`), Open-Meteo Historical Weather API, Nager.Date public holidays API (`BR` for the analysis, `PH` 2026 for the reuse box). The pipeline needs no API keys.
- Late means delivered on a later calendar day than the estimated date. Expected on the analysis set: 95,736 parcels, 6,229 late (6.51%); timestamp rule gives 7,519 (7.85%); 1,290 late only by clock time.
- Exposure window: 7 calendar days starting on the carrier handoff date, same for every parcel; 10 and 14 day sensitivity runs reported beside it. The 7 day result stays the headline.
- Model split: train on purchases before 2018-01, test from 2018-01. Three stages: stage 1 at purchase, stage 2 adds `handoff_days`, stage 3 adds weather and holiday features.
- H1 heavy rain days (dose response 0, 1, 2, 3 or more), H2 holiday in window, H3 stage 3 beats stage 2. Each result is reported whichever way it falls.
- Intervals: bootstrap 95%, seed 7. A group under 30 parcels gets no interval and is marked unreliable.
- Page: one self contained `explorer/index.html` that opens offline; sections 01 to 10; chrome black and white, Josefin Sans Light all caps headings, Manrope body; the single accent `#E4572E` only inside charts; no dashes or leading rules before labels; never hyphenate or cut words; checked in a real browser at desktop, tablet and phone widths.
- Every number on the page, in the narration and in the video comes from `findings.json`. Never invent facts, quotes, logos or numbers.
- Video: 1920 by 1080, 30 fps, 8 to 10 minutes, built in Remotion; narration generated with ElevenLabs; nobody on camera. Only narration text is sent to ElevenLabs, never names. Credits card: group Theoraux; Theodore Von Joshua M. Bunquin, Christian B. Nayre, Daniel B. Villanueva, John C. Alcaraz, Paul C. Alcaraz.
- The MP4 and the ElevenLabs key never enter git. `ELEVENLABS_API_KEY` lives in `C:\Casama\.env.local` at the repo root (already git ignored by the existing `.env*.local` rule), shared with the AI project. Never open, print or paste that file.
- Do not commit or push unless the user asks in that turn. Each task ends with a verification and a checkpoint report, not a commit.
- Skills to load when the task needs them: `mono-editorial-taste` (page), `elevenlabs` (voice), `remotion` and `remotion-best-practices` (video).

## Review Focus

- A parcel with no carrier handoff date: window features are NaN and the parcel is excluded from H1 and H2, never counted as zero rain days. (Task 5)
- A customer state with no capital, no weather rows, or no customer match: the parcel is excluded from weather analyses and the exclusion count is reported. (Tasks 2, 5)
- A tiny group (a state or the "3 or more" rain bucket with under 30 parcels): no interval is published and the row is marked unreliable. (Task 6)
- A failed, rate limited or partial API response: the script raises and writes no cache; a re-run with a cache needs no network. (Tasks 3, 4)
- Window edges: a holiday on the handoff day, a window crossing a year boundary, and a window running past the last weather date (NaN, not zero). (Task 5)

## File Structure

```
Data Science/
  pytest.ini  requirements.txt  README.md  REFERENCES.md
  src/   config.py download_data.py delivery_data.py fetch_holidays.py fetch_weather.py
         window_features.py stats.py eda.py model.py build_findings.py build_explorer.py
         check_references.py run_all.py   (legacy/ holds the old scripts until Task 15)
  explorer/  template.html style.css charts.js fonts/   (index.html is built)
  data/cache/ (committed API pulls)   data/raw/ (git ignored)
  output/ findings.json series.json reuse_ph_2026.json
  tests/
  video/ script.md build_script.py make_voice.py narration.json audio/ remotion/
```

---

### Task 1: Move, scaffold and test harness

**Files:**
- Move: `analysis/*` to `Data Science/src/legacy/` (scripts) with `git mv`; `git rm -r analysis/output`; move untracked `data/raw` to `Data Science/data/raw`.
- Create: `Data Science/pytest.ini` (`pythonpath = src`, `testpaths = tests`), `Data Science/requirements.txt` (pandas, numpy, scikit-learn, statsmodels, requests, kagglehub, python-dotenv, elevenlabs, pytest, matplotlib until Task 15), `Data Science/src/config.py`, `Data Science/tests/test_layout.py`.
- Modify: root `.gitignore` (replace `/data/` with `/Data Science/data/raw/`; add `*.mp4`, `node_modules/`, `Data Science/video/audio/`, `Data Science/video/remotion/out/`; `.env` and `.env*.local` are already ignored).

**Interfaces:**
- Produces: `config` constants `ROOT, RAW_DIR, CACHE_DIR, OUT_DIR, SPLIT_MONTH="2018-01", WINDOW_DAYS=7, SENSITIVITY_DAYS=(10, 14), MIN_GROUP=30, SEED=7, N_BOOT=2000`. `HEAVY_RAIN_MM` is added in Task 5.

- [ ] **Step 1: Write the failing test** `test_layout.py::test_expected_folders_exist` asserting `src`, `tests`, `data/raw`, `data/cache`, `output`, `explorer`, `video` exist under `Data Science/` and `analysis/` does not.
- [ ] **Step 2: Run** `cd "C:/Casama/Data Science" && python -m pytest tests/test_layout.py -v`. Expected: FAIL.
- [ ] **Step 3: Do the moves, create the folders (with `.gitkeep` where empty and tracked), write `pytest.ini`, `requirements.txt`, `config.py`, update `.gitignore`.** Run `pip install -r requirements.txt`.
- [ ] **Step 4: Run the test again.** Expected: PASS. Also run `git status --short` and confirm `data/raw` files are not listed.
- [ ] **Step 5: Checkpoint.** Report the diff summary. No commit.

### Task 2: Calendar day lateness, loaders and the state join

**Files:** Modify `src/legacy/delivery_data.py` into `src/delivery_data.py` (move, then edit); Create `src/download_data.py`; Test `tests/test_delivery_data.py`.

**Interfaces:**
- Produces: `load_raw() -> DataFrame`, `load_customers() -> DataFrame[customer_id, customer_state, customer_city]`, `delivered_orders(raw) -> DataFrame` (adds `is_late` by calendar day, `is_late_timestamp`, `handoff_date`), `clean_delivered(done) -> DataFrame`, `add_state(orders, customers) -> DataFrame` (left join, adds `customer_state`).

- [ ] **Step 1: Write failing tests:** `test_delivery_at_2pm_on_estimate_day_is_not_late`, `test_delivery_next_calendar_day_is_late`, `test_timestamp_rule_still_recorded` (same 2pm row has `is_late_timestamp` True), `test_add_state_keeps_every_order_and_nulls_unknown_customers`, and an integration test (skipped if raw files are absent) `test_real_counts`: analysis set 95,736 rows, 6,229 late, 7,519 late by timestamp, every order matched to a state, 27 states.
- [ ] **Step 2: Run** `python -m pytest tests/test_delivery_data.py -v`. Expected: FAIL (import error).
- [ ] **Step 3: Implement** by moving `legacy/delivery_data.py` and changing `is_late` to compare `.dt.normalize()` of delivery and estimate. `download_data.py` fetches both Kaggle files with `kagglehub` into `RAW_DIR` (same call used in the probe: `dataset_download("olistbr/brazilian-ecommerce", path="olist_customers_dataset.csv")`).
- [ ] **Step 4: Run the tests.** Expected: PASS including `test_real_counts`.
- [ ] **Step 5: Checkpoint.**

### Task 3: Holidays and the Philippine reuse pull

**Files:** Create `src/fetch_holidays.py`; Test `tests/test_fetch_holidays.py`.

**Interfaces:**
- Produces: `class ApiError(Exception)`, `http_get_json(url: str) -> Any` (raises `ApiError` on a non 200 status), `fetch_holidays(country: str, years: Sequence[int], get_json=http_get_json) -> DataFrame[date, name, local_name, country, nationwide, types]` (keeps rows where the API `global` flag is true, keeps Carnaval, records `types`), `load_or_fetch_holidays(country, years) -> DataFrame` (reads `data/cache/holidays_<country>_<first>_<last>.csv`, otherwise fetches and writes it), `reuse_demo() -> dict` (writes `output/reuse_ph_2026.json` with country `PH`, year 2026, holiday count and the first five names).

- [ ] **Step 1: Write failing tests** with a stub `get_json`: `test_keeps_only_nationwide_holidays`, `test_error_response_raises_and_writes_no_cache`, `test_second_call_uses_cache_without_network` (stub raises if called), `test_reuse_demo_uses_country_code_only` (same function, `PH`, no other code path).
- [ ] **Step 2: Run** `python -m pytest tests/test_fetch_holidays.py -v`. Expected: FAIL.
- [ ] **Step 3: Implement** with `requests` and a 20 second timeout against `https://date.nager.at/api/v3/PublicHolidays/{year}/{country}`. Write the cache only after every year succeeded.
- [ ] **Step 4: Run tests, then fetch for real:** `python -c "from fetch_holidays import *; load_or_fetch_holidays('BR',[2016,2017,2018]); reuse_demo()"` from `src/`. Expected: cache file and `reuse_ph_2026.json` exist.
- [ ] **Step 5: Checkpoint.**

### Task 4: State capitals and weather

**Files:** Create `src/fetch_weather.py`; Test `tests/test_fetch_weather.py`.

**Interfaces:**
- Consumes: `ApiError`, `http_get_json` from Task 3.
- Produces: `STATE_CAPITALS: dict[str, str]` (27 UF code to capital name), `fetch_capital_coords(get_json=http_get_json) -> DataFrame[state, capital, lat, lon]` (Open-Meteo geocoding API, cached to `data/cache/state_capitals.csv`), `fetch_weather(coords, start: str, end: str, get_json=http_get_json) -> DataFrame[state, date, precip_mm, temp_mean_c]` (cached to `data/cache/weather_<start>_<end>.csv`).

- [ ] **Step 1: Write failing tests** with stubs: `test_capitals_cover_every_state_in_customers` (integration, skipped without raw data), `test_coords_inside_brazil_box` (lat -34 to 6, lon -74 to -34), `test_fetch_weather_batches_and_returns_one_row_per_state_day`, `test_partial_failure_raises_and_writes_no_cache`, `test_missing_daily_key_raises`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Capital names are the 27 official state capitals; coordinates come only from the geocoding API response and are cited in `REFERENCES.md` later. Weather requests: archive API, `daily=precipitation_sum,temperature_2m_mean`, several locations per call, `timezone=auto`. Date range `2016-09-01` to `2018-12-31` (covers 14 day windows).
- [ ] **Step 4: Run tests, then fetch for real** and confirm the cache has 27 states and no missing dates.
- [ ] **Step 5: Checkpoint.**

### Task 5: Window features (H1 and H2 inputs)

**Files:** Create `src/window_features.py`; Modify `src/config.py` (add `HEAVY_RAIN_MM`); Test `tests/test_window_features.py`.

**Interfaces:**
- Consumes: orders with `order_delivered_carrier_date`, `customer_state` (Task 2); weather (Task 4); holidays (Task 3).
- Produces: `add_window_features(orders, weather, holidays, days: int = WINDOW_DAYS, heavy_mm: float = HEAVY_RAIN_MM) -> DataFrame` adding `heavy_rain_days` (Int64), `rain_mm_total` (float), `holiday_in_window` (boolean). The window is `days` calendar days starting on the handoff date, inclusive.

- [ ] **Step 1: Find and fix the heavy rain threshold before any result exists.** Look up a published daily heavy rain definition (a national met service or WMO), set `HEAVY_RAIN_MM` in `config.py` with a comment holding the source URL and today's date, and add the same entry to `REFERENCES.md` (create it if absent). Do not run any late rate by rain before this is done.
- [ ] **Step 2: Write failing tests** on a hand built frame: `test_counts_heavy_days_inside_window_only`, `test_handoff_day_is_day_one`, `test_holiday_on_handoff_day_counts`, `test_window_crossing_year_boundary`, `test_missing_handoff_gives_na_not_zero`, `test_unknown_state_gives_na`, `test_window_past_last_weather_date_gives_na`, `test_days_parameter_changes_window` (10 day window picks up a day a 7 day window misses).
- [ ] **Step 3: Run.** Expected: FAIL.
- [ ] **Step 4: Implement** by building a per state daily lookup and a cumulative sum so the work stays vectorised for 96k rows.
- [ ] **Step 5: Run tests, then check the real data:** share of analysis parcels with non NA features is printed and recorded for `findings.json.limits`.
- [ ] **Step 6: Checkpoint.**

### Task 6: Statistics

**Files:** Create `src/stats.py`; Test `tests/test_stats.py`.

**Interfaces:**
- Produces: `late_rate_ci(df, by: str, n_boot: int = N_BOOT, seed: int = SEED, min_group: int = MIN_GROUP) -> DataFrame[group, n, late_rate, ci_low, ci_high, reliable]` (interval columns NaN when `reliable` is False); `adjusted_odds_ratios(df, exposures: list[str]) -> DataFrame[term, odds_ratio, ci_low, ci_high]` (logistic regression of `is_late` on the exposures plus purchase month and state, via statsmodels); `verdict(odds_ratio_row) -> Literal["supported","no clear effect","opposite"]` (supported if the interval is above 1, opposite if below 1, otherwise no clear effect).

- [ ] **Step 1: Write failing tests:** `test_ci_contains_true_rate_on_known_sample` (200 rows at 0.5), `test_same_seed_same_interval`, `test_group_under_min_is_unreliable_with_nan_interval`, `test_adjusted_or_near_one_for_noise_exposure` (random exposure, seeded), `test_verdict_rules` (three hand made rows).
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Drop rows with NA exposure before fitting and return the dropped count as `DataFrame.attrs["dropped"]`.
- [ ] **Step 4: Run tests.** Expected: PASS.
- [ ] **Step 5: Checkpoint.**

### Task 7: EDA series (port the 14 existing charts)

**Files:** Create `src/eda.py`; Test `tests/test_eda.py`. Read `src/legacy/eda_delivery.py`, `eda_extra.py`, `late_model.py` for what each chart computes.

**Interfaces:**
- Produces: `SERIES_NAMES: list[str]` with one name per old chart 01 to 12 (`delivery_hist, estimate_gap_hist, late_by_month, late_by_handoff, late_by_promise, order_rhythm, cleaning_funnel, volume_vs_late, delivery_spread, promise_vs_actual, correlation`, plus `importance` from the model task); `series(name: str, df: DataFrame, ...) -> list[dict]` returning plain JSON rows; `cleaning_funnel(raw, done, clean) -> list[dict]`.

- [ ] **Step 1: Write failing tests:** `test_every_series_name_returns_nonempty_json_serialisable_rows` (parametrised), `test_cleaning_funnel_counts` (99,441 raw, 95,736 analysed, 740 dropped, integration), `test_late_by_month_uses_calendar_day_rule`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** each series as pure pandas with no plotting; `promise_vs_actual` is sampled to at most 3,000 points with seed 7 so the page stays small.
- [ ] **Step 4: Run tests.** Expected: PASS.
- [ ] **Step 5: Checkpoint.**

### Task 8: Three stage model and H3

**Files:** Create `src/model.py`; Test `tests/test_model.py`.

**Interfaces:**
- Consumes: frame with window features (Task 5).
- Produces: `STAGES: dict[str, list[str]]` (`stage_1`: estimated_days, purchase_weekday, purchase_hour, month_of_year; `stage_2`: stage_1 plus handoff_days; `stage_3`: stage_2 plus heavy_rain_days, rain_mm_total, holiday_in_window), `split_by_time(df) -> tuple[DataFrame, DataFrame]`, `fit_stage(train, test, features) -> dict` (keys `roc_auc, average_precision, alert_precision_pct, alert_recall_pct, importance, roc_points, risk_deciles, scores`), `auc_difference_ci(truth, scores_a, scores_b, n_boot=500, seed=SEED) -> tuple[float, float, float]`. H3 counts as improved only if the interval excludes 0. Uses `HistGradientBoostingClassifier` with the same settings as `legacy/late_model.py`.

- [ ] **Step 1: Write failing tests:** `test_split_has_no_overlap_and_respects_split_month`, `test_no_stage_uses_outcome_columns` (none of `delivery_days, days_vs_estimate, is_late, order_delivered_customer_date` in any stage), `test_fit_stage_returns_expected_keys_on_synthetic_data`, `test_auc_difference_ci_zero_for_identical_scores`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Rows with NA stage 3 features are dropped for stages 2 and 3 alike, so the comparison uses the same parcels; the dropped count is returned.
- [ ] **Step 4: Run tests, then run on real data** and print the three AUCs.
- [ ] **Step 5: Checkpoint.**

### Task 9: findings.json and series.json

**Files:** Create `src/build_findings.py`, `src/run_all.py`; Test `tests/test_build_findings.py`.

**Interfaces:**
- Consumes: Tasks 2 to 8.
- Produces: `build(out_dir: Path = OUT_DIR) -> tuple[dict, dict]` writing `output/findings.json` with top level keys `data_note, cleaning, late, delivery_days, handoff, h1, h2, h3, sensitivity, limits, sources` and `output/series.json` keyed by `SERIES_NAMES` plus `rain_dose, holiday_effect, state_rain, roc_curves, risk_deciles`. `h1`, `h2`, `h3` each hold `result` (the numbers), `verdict` (from `stats.verdict`, or "improved" or "no clear improvement" for H3) and `sensitivity` for the 10 and 14 day runs. `run_all.main()` runs download, fetches, build and explorer in order.

- [ ] **Step 1: Write failing tests:** `test_findings_has_required_keys_and_numeric_values`, `test_late_rate_matches_spec_on_real_data` (6.51 and 7.85), `test_every_series_row_is_json_serialisable`, `test_verdict_comes_from_rule_not_text` (h1 verdict equals `stats.verdict` of its own row).
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Round once, here, so every consumer sees identical values.
- [ ] **Step 4: Run `python run_all.py` from a state with an empty `output/`, then the tests.** Expected: both files appear, tests PASS. Read H1, H2, H3 verdicts aloud to the user in the checkpoint; do not edit any threshold or window after seeing them.
- [ ] **Step 5: Checkpoint. Numbers freeze here.**

### Task 10: The explorer page

**Files:** Create `explorer/template.html`, `explorer/style.css`, `explorer/charts.js`, `explorer/fonts/` (Josefin Sans Light and Manrope woff2, SIL OFL, inlined as base64), `src/build_explorer.py`; Test `tests/test_build_explorer.py`. Load the `mono-editorial-taste` skill and reuse the CSS of `src/legacy/build_dashboard.py`.

**Interfaces:**
- Consumes: `findings.json`, `series.json`, `reuse_ph_2026.json`.
- Produces: `render_placeholders(html: str, findings: dict) -> str` (replaces `{{dotted.path}}` and `{{dotted.path|decimals}}`; raises `KeyError` naming the path when unresolved), `build_explorer(findings, series, out_path=explorer/index.html) -> Path` (inlines CSS, JS, fonts and the two JSON blobs). `charts.js` exposes `drawBars`, `drawLine`, `drawHist`, `drawScatter` writing inline SVG with labelled axes and a source line.

- [ ] **Step 1: Write failing tests:** `test_unresolved_placeholder_raises_keyerror`, `test_sections_s01_to_s10_present_in_order`, `test_page_makes_no_external_requests` (no `http` in `src=`, `href=`, `@import`, `url(`), `test_no_leading_dash_or_rule_before_labels`, `test_every_number_in_text_has_a_placeholder` (no bare digits in section prose outside placeholders and section labels), `test_reuse_box_shows_ph_2026_values`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Write the sections** exactly as in the spec table (01 question, 02 data and APIs, 03 cleaning, 04 what the data shows, 05 weather and holidays, 06 prediction, 07 takeaways, 08 findings to Casama plus reuse box, 09 limits, 10 definitions, references and credits). H1, H2 and H3 text is chosen by the `verdict` field, with a sentence for each of the three outcomes, so prose cannot overclaim.
- [ ] **Step 4: Run tests.** Expected: PASS.
- [ ] **Step 5: Verify in a real browser** (claude-in-chrome or chrome devtools) at 1440, 820 and 390 pixel widths: `document.documentElement.scrollWidth <= window.innerWidth`, no console errors, every chart has labelled axes, text lines up with chart edges. Take a screenshot at each width and read it.
- [ ] **Step 6: Checkpoint.**

### Task 11: References, licences and README

**Files:** Create `Data Science/REFERENCES.md`, `Data Science/README.md`, `src/check_references.py`; Test `tests/test_references.py`.

**Interfaces:** Produces `check_references(path: Path) -> list[tuple[str, int]]` (URL and HTTP status for every link in the file).

- [ ] **Step 1: Write failing test:** `test_every_reference_link_resolves` (live, marked `network`; every status below 400) and `test_references_cover_required_sources` (Olist orders, Olist customers, Open-Meteo, Nager.Date, pandas, scikit-learn, statsmodels, Remotion, ElevenLabs, heavy rain definition, geocoding source).
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Read the licence or terms page of each of the four data sources, and write the licence name, URL and access date next to each entry.** If a licence restricts reuse in a way that affects a class project, tell the user instead of guessing.
- [ ] **Step 4: Write the README:** what it is, the commands to rebuild everything from an empty `data/`, the results in six lines (read from `findings.json`), limits, credits, and a placeholder line for the Drive link filled in Task 15.
- [ ] **Step 5: Run tests.** Expected: PASS.
- [ ] **Step 6: Checkpoint.**

### Task 12: Narration script

**Files:** Create `video/script.md`, `video/build_script.py`; Test `tests/test_script.py`.

**Interfaces:**
- Produces: `build_script(findings: dict, template: Path = video/script.md) -> list[dict]` returning scenes `{id, text}` and writing `video/narration.json`. Scene ids: `title, question, data, cleaning, shows, weather, model, takeaways, casama, limits, credits`.

- [ ] **Step 1: Write failing tests:** `test_scene_ids_match_the_list_in_order`, `test_total_words_between_1200_and_1450`, `test_every_number_in_narration_comes_from_findings` (each number token appears among the formatted values of `findings.json`), `test_no_member_names_in_narration`, `test_unresolved_placeholder_raises`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Write `script.md`:** plain spoken English, numbers as `{{path|decimals}}`, one paragraph per scene, citing sources aloud where a claim rests on one (Olist, Open-Meteo, Nager.Date). The `credits` scene is read as "group Theoraux" only; member names stay on screen.
- [ ] **Step 4: Run tests.** Expected: PASS. Read the script once for tone and tell the user the word count.
- [ ] **Step 5: Checkpoint.**

### Task 13: ElevenLabs voice (needs the user)

**Files:** Create `video/make_voice.py`; Test `tests/test_make_voice.py`. Load the `elevenlabs` skill.

**Interfaces:**
- Consumes: `narration.json`.
- Produces: `synthesize(scenes, voice_id: str, out_dir: Path, client=None) -> list[dict]` writing `video/audio/<id>.mp3` and `video/scene_timings.json` with `{id, file, seconds}` per scene; `audio_seconds(path: Path) -> float` (ffprobe); CLI flags `--dry-run` (prints characters per scene, needs no key) and `--sample` (renders only the title scene).

- [ ] **Step 1: Write failing tests:** `test_audio_seconds_on_generated_silence` (ffmpeg makes a 2 second silent mp3), `test_dry_run_needs_no_key_and_lists_all_scenes`, `test_missing_key_raises_clear_error`, `test_timings_written_in_scene_order` (fake client returning the silent file).
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** with `eleven_multilingual_v2` and voice id `JBFqnCBsd6RMkjVDRZzb` as the default (the skill's example voice), loading the key with `python-dotenv` (`load_dotenv(find_dotenv(".env.local"))`, which finds the repo root file from either project folder).
- [ ] **Step 4: Run tests and the dry run.** Report the total character count to the user, since it uses their ElevenLabs credits.
- [ ] **Step 5: Confirm the key works** with `npx -y @elevenlabs/cli@latest onboard check --env-path .env.local` from the repo root (the key was already created through the ElevenLabs sign in flow on 2026-11-24). Render the `--sample`, share its length and file path, and ask the user to accept this voice or name another before the full render.
- [ ] **Step 6: Full render, then confirm the summed `seconds` is between 480 and 600.** If not, adjust the script (Task 12) and re render only changed scenes.
- [ ] **Step 7: Checkpoint.**

### Task 14: The Remotion video

**Files:** Create `video/remotion/` (standard Remotion project: `package.json`, `src/Root.tsx`, `src/scenes/*.tsx` one per scene id, `src/data.ts` loading `findings.json`, `series.json`, `scene_timings.json`), output `video/remotion/out/theoraux-data-science.mp4`. Load the `remotion` and `remotion-best-practices` skills before writing any scene.

**Interfaces:**
- Consumes: the three JSON files and `video/audio/*.mp3`.
- Produces: one composition `Explorer` (1920 by 1080, 30 fps) whose duration comes from `calculateMetadata` using `scene_timings.json`; one still composition per scene for review.

- [ ] **Step 1: Write the failing check** `video/remotion/check.mjs`: loads the built bundle metadata, asserts width 1920, height 1080, fps 30, duration in frames between 14,400 and 18,000, and that every scene id in `scene_timings.json` has a scene component.
- [ ] **Step 2: Run** `node check.mjs`. Expected: FAIL.
- [ ] **Step 3: Build the scenes.** Same look as the page (black and white, Josefin Sans Light, Manrope, accent `#E4572E` only on data). Charts are drawn in React from `series.json`; text numbers read `findings.json`. Scenes: title card, the question, the data and APIs (animated pipeline), cleaning funnel, what the data shows, weather and holidays with the three verdicts, the model stages, takeaways, from findings to Casama (reuse box with PH holidays), limits, references and credits (names on screen).
- [ ] **Step 4: Run** `npx tsc --noEmit`, `node check.mjs`, then `npx remotion still` for each scene at its midpoint. Read every still: no clipped text, labelled axes, numbers match the page.
- [ ] **Step 5: Render the full video** with `npx remotion render`. Verify with `ffprobe`: 1920x1080, 30 fps, duration 480 to 600 seconds, audio stream present. Extract frames at each scene boundary and read them.
- [ ] **Step 6: Checkpoint.** Give the user the file path and ask them to watch it once.

### Task 15: Stretch items, cleanup and handover

**Files:** Modify `explorer/charts.js`, `explorer/template.html` (state filter on section 05, month range filter, three question check yourself block), delete `src/legacy/` and `matplotlib` from `requirements.txt`, update `README.md` with the Drive link.

- [ ] **Step 1: Add the stretch items** only if the user has no near deadline; each filter reads the same `series.json`, with a test that filtering to one state matches `state_rain` for that state. Re run the Task 10 tests and the three width browser check.
- [ ] **Step 2: Delete `src/legacy/`**, drop `matplotlib` from `requirements.txt`, re run the whole test suite. Expected: all PASS.
- [ ] **Step 3: Clean clone check:** copy the repo to the scratchpad, delete `data/raw`, `output`, `explorer/index.html`, run the README commands. Expected: identical `findings.json` (byte for byte) and a built page.
- [ ] **Step 4: Ask the user to upload the MP4 to Google Drive and send the link;** put it in the README. The page is handed in by repo link.
- [ ] **Step 5: Final report** to the user: what exists, where, the three verdicts in plain words, and what was not done. Commit and push only if they ask. If they say "we are done here", follow their cleanup rule (delete `.env`, remind them to rotate the key).

---

## Self-review notes

Spec coverage: intent and questions (Tasks 5, 6, 8, 9), pipeline steps 1 to 8 (Tasks 2 to 10), page sections 01 to 10 and reuse box (Tasks 3, 10), video and narration (Tasks 12 to 14), references and licences (Task 11), definition of done (Tasks 9, 10, 14, 15), folder layout (Task 1). The AI folder is created in the AI plan.
