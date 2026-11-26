# Casama Home Forecast (AI final project) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a small explainable "who is home when the parcel arrives" forecaster, evaluate it on real public occupancy data, integrate it into the Casama Flutter app's parcel board, and deliver a README and an 8 to 10 minute narrated video with citations.

**Architecture:** A Python reference algorithm (`AI/src/home_forecast.py`) is fitted and evaluated on CASAS occupancy data and exports parameters, a golden test file and a demo history. A pure Dart port in the app reproduces the reference numbers (parity test), learns each opted in member's weekly habit from the app's own Home and Out taps, and shows forecasts on the parcel card. One generated `metrics.json` feeds the README and the video.

**Tech Stack:** Python 3.12 (pandas, numpy, scikit-learn, pytest), Flutter 3.50.1 stable web only (installed outside the repo), Dart, Riverpod, HyperFrames (HTML and GSAP to video), ElevenLabs `eleven_multilingual_v2` (Brian, voice id `nPczCjzI2devNBz1zQrb`), ffmpeg, Node 24.

**Spec:** `docs/superpowers/specs/2026-11-25-ai-home-forecast-design.md` (approved by the user with "proceed" on 2026-11-25).

## Global Constraints

- Do not commit or push unless the user asks in that turn. Nothing in this plan commits.
- Slots: 168 hour of week slots, `slot = weekday*24 + hour`, Monday = 0, wall clock time, never converted between time zones. Age in hours is computed on wall clock fields (Dart: `DateTime.utc(y,m,d,h)`), so daylight saving never shifts a result.
- Probabilities are clipped to `[1e-6, 1-1e-6]` before `logit`. The forecast is `sigmoid(b0 + b1*logit(habit) + b2*(2n-1)*exp(-h/tau))` with `n` = 1 when home now.
- Bands: likely at 0.70 or more, maybe from 0.40 up to 0.70, unlikely under 0.40.
- The forecast is advice only. It never edits `expectedArrival` or `availableMemberNames`.
- Opt in is off by default per member. A member who has not opted in is never forecast, never recorded, and never counted. Opting out deletes that member's stored history. The seeded demo household has all four housemates opted in and says so wherever it is shown.
- Data gate: at least 2 CASAS homes with 42 or more usable days each. Fewer means stop and report to the user. Simulated data only for unit fixtures and the demo seed, never for a reported accuracy.
- CASAS licence is CC BY 4.0 (Zenodo record 17180309). Attribution on README, video and REFERENCES.
- Narration: ElevenLabs Brian, `eleven_multilingual_v2`, per character timings. Check credit with a dry run before any paid render. Group member names appear only on the credits card, never in text sent to ElevenLabs. A new key is needed and must go in the git ignored `C:\Casama\.env.local`, never printed.
- Sound effects are original synthesised sounds only (reuse the repo's own `Data Science/video/sfx` wavs and `make_sfx.py`), never the bundled third party clips.
- Copy rules: no dashes or numbering before labels, never hyphenate words, no invented facts, numbers or logos. README and video numbers come from `AI/output/metrics.json` only.
- Standing environment limits: about 1.8 GB free RAM, so renders and builds run one at a time and chunked. A background shell may be reaped under memory pressure; never restart a reaped job or render without being asked.
- Flutter lives in `C:\flutter-sdk` (outside the repo) and is removed at cleanup. The Dart changes to 3rd year files are additive and listed in the README.

## Deviations from the spec (decided while planning)

- The fitted parameters and the demo history ship as **generated Dart constants** (`forecast_params_data.dart`, `demo_presence_seed.dart`) instead of JSON assets. This avoids async asset loading, a load failure path and a `pubspec.yaml` edit. The JSON files in `AI/output/` stay the source of truth, and a test asserts the Dart constants equal them.

## Review Focus

- Slot math at the edges: Sunday 23:00 to Monday 00:00, a toggle in the middle of an hour, a spring forward or fall back day. Pinned in Task 3 (Python) and Task 6 (Dart).
- Sparse history: no observations, one observation, an hour with no data. No NaN, no exception, falls back to the prior. Pinned in Tasks 3 and 6.
- Numeric parity at the extremes (habit at 0 or 1, very large `h`). Python and Dart agree within 1e-9. Pinned in Task 6.
- Privacy: a member who opts out has their history deleted, and a member who is not opted in contributes nothing to anyone's forecast or window. Pinned in Task 7.
- Existing behaviour: all 78 existing Flutter tests still pass, the parcel card does not overflow at 320 px width with long names, and a household with nobody opted in shows no forecast row. Pinned in Task 8.

---

### Task 1: Environment and baseline (Flutter, Python, data download)

**Files:**
- Create: `AI/requirements.txt`, `AI/pytest.ini`, `AI/.gitignore` is not needed (root `.gitignore` gets the new lines)
- Modify: `.gitignore` (add `/AI/data/raw/`, `/AI/video/audio/`, `/AI/video/hyperframes/out/`, `/AI/video/hyperframes/node_modules/`)

**Interfaces:**
- Produces: `flutter` on PATH for the session via `C:\flutter-sdk\flutter\bin`; a green baseline of the existing app tests; `AI/data/raw/casas/new_labeled_data.zip` (SHA 256 recorded).

- [ ] **Step 1: Extract the downloaded SDK** (`C:\flutter-dl\flutter.zip`) to `C:\flutter-sdk`, then run `flutter --version`, `flutter config --enable-web`, `flutter config --no-analytics`. Expected: Flutter 3.50.1 and a Dart SDK that satisfies `sdk: ^3.13.2` from `pubspec.yaml`.
- [ ] **Step 2: Baseline.** In `C:\Casama` run `flutter pub get` then `flutter test`. Expected: all existing tests pass (the README says 78). Record the exact count in the ledger. If `pub get` needs a lockfile change, rule on the smallest change and ledger it.
- [ ] **Step 3: Python setup.** Write `AI/requirements.txt` (`pandas`, `numpy`, `scikit-learn`, `requests`, `python-dotenv`, `elevenlabs`, `pytest`) and `AI/pytest.ini` (`pythonpath = src`, `testpaths = tests`). Install what is missing.
- [ ] **Step 4: Finish the CASAS download** into `AI/data/raw/casas/` by resuming the partial file from the session scratchpad (`curl -C -` against `https://zenodo.org/records/17180309/files/new_labeled_data.zip?download=1`, target 33,021,523 bytes). Verify with `zipfile.testzip()` and write the SHA 256 to `AI/data/raw/casas/SHA256.txt`.
- [ ] **Step 5: Inspect the four home files** (names, columns, date ranges, activity labels such as leave home and enter home). Write the findings, not a guess, to the ledger.

### Task 2: Hourly home or away from CASAS, and the data gate

**Files:**
- Create: `AI/src/config.py`, `AI/src/download_data.py`, `AI/src/derive_hourly.py`, `AI/tests/test_derive_hourly.py`
- Output (git ignored under data): `AI/data/hourly/<home>.csv` with columns `hour_start,home` ; tracked: `AI/output/data_gate.json`

**Interfaces:**
- Produces: `derive_hourly.events_to_hourly(events: list[tuple[datetime, bool]], end: datetime) -> list[tuple[datetime, bool]]` (an hour is home when the member was home for 30 minutes or more of it; hours before the first event are dropped); `derive_hourly.home_hours_from_casas(path) -> list[tuple[datetime, bool]]` using the rule chosen in Step 3; `load_hourly(home_id) -> pandas.DataFrame`; `data_gate.json` = `{"passed": bool, "min_days": 42, "homes": [{"id", "days", "hours", "home_share", "usable": bool}]}`.

- [ ] **Step 1: Failing tests** with tiny fixtures: `test_hour_is_home_when_home_30_minutes_or_more`, `test_hour_is_out_when_home_under_30_minutes`, `test_toggle_mid_hour_splits_by_majority`, `test_hours_before_first_event_are_dropped`, `test_midnight_and_sunday_boundary_hours_are_kept`, `test_no_events_returns_empty_without_error`.
- [ ] **Step 2:** Run `pytest AI/tests/test_derive_hourly.py`. Expected: FAIL (module missing).
- [ ] **Step 3: Implement** `events_to_hourly` and `home_hours_from_casas`. The at home rule comes from the Step 5 findings of Task 1 (for example leave home and enter home activity labels, otherwise door events plus a motion gap rule). Write the rule as a docstring.
- [ ] **Step 4: Run the tests.** Expected: PASS.
- [ ] **Step 5: Run on the real data, write `data_gate.json`, and look at a printed sample of 3 days per home** to check the rule by eye. A home is usable at 42 or more days with at least 70 percent of hours covered.
- [ ] **Step 6: Gate.** Expected: `passed` is true with 2 or more usable homes. If not, **stop and report the options to the user**; do not continue to Task 3 with simulated data.

### Task 3: Reference algorithm (habit, forecast, fit)

**Files:**
- Create: `AI/src/home_forecast.py`, `AI/tests/test_home_forecast.py`

**Interfaces:**
- Consumes: hourly series from Task 2 as `list[Observation]`.
- Produces (exact names, Dart mirrors them): `Observation(at: datetime, home: bool)` frozen dataclass, `at` is the hour start in wall clock time; `Params(b0, b1, b2, tau_hours, half_life_days, prior_strength, prior: tuple[float, ...])` with `len(prior) == 168`; `EPS = 1e-6`; `slot_of(at) -> int`; `logit(p)`, `sigmoid(z)`; `habit(observations, now, slot, params) -> float` using only observations with `at < floor_hour(now)`; `forecast(observations, now, home_now, hours_ahead, params) -> float` (the target hour starts at `floor_hour(now) + hours_ahead` hours); `HabitState` incremental class with `add(obs)` and `value(now, slot)` equal to `habit` within 1e-12; `fit(series_by_home, grids) -> Params` with grids `half_life_days` in (7, 14, 28, 56), `prior_strength` in (1, 2, 4, 8), `tau_hours` in (1, 2, 3, 6, 12) (the builder may widen them); `population_prior(series_by_home) -> tuple[float, ...]`.

- [ ] **Step 1: Failing tests:** `test_slot_of_monday_midnight_is_0_and_sunday_2300_is_167`, `test_habit_with_no_observations_returns_prior_slot_value`, `test_habit_one_home_observation_moves_toward_one`, `test_older_observations_weigh_less` (half life halves the weight), `test_observation_at_or_after_now_is_ignored`, `test_forecast_with_zero_coefficients_is_half`, `test_persistence_term_decays_with_hours_ahead`, `test_extreme_habit_does_not_blow_up` (habit 0 and 1 give finite output), `test_incremental_habit_equals_reference_on_random_series` (seeded), `test_slot_math_unaffected_by_dst_day` (naive wall clock series across 2026-03-08), `test_fit_recovers_known_coefficients_on_synthetic_routine` (a synthetic series generated from a known routine, tolerance 0.15, fixture only).
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3: Implement** `home_forecast.py` as above. `fit` builds walk forward examples (forecast origin every hour from day 7, horizons 1, 3, 6, 12, 24 where the target hour exists), uses `HabitState` for speed, fits `LogisticRegression(penalty=None)` on `[logit(habit), (2n-1)*exp(-h/tau)]` for each grid point, and keeps the grid point with the lowest training log loss.
- [ ] **Step 4:** Run. Expected: PASS.

### Task 4: Evaluation, baselines and metrics.json

**Files:**
- Create: `AI/src/evaluate.py`, `AI/src/run_all.py`, `AI/tests/test_evaluate.py`
- Output: `AI/output/metrics.json`

**Interfaces:**
- Consumes: Task 2 and Task 3 interfaces.
- Produces: `evaluate.evaluate(series_by_home) -> dict` and `metrics.json` with keys `data` (per home id, days, hours, home_share, `multi_resident` flag from the dataset notes), `gate`, `horizons` (keys "1","3","6","12","24", each with `model`, `base_rate`, `slot_mean`, `persistence`, `gbm`, each `{auc, brier, log_loss, accuracy, n}`), `learning_curve` (keys "3","7","14","28" with `auc` and `brier` at horizon 3), `cold_start` (`with_prior`, `flat_prior`, first 7 days, horizon 3), `calibration` (bins of width 0.1 with predicted, observed, n), `params`, `caveats` (list of plain sentences), `questions` (the four from the spec with a one line answer each, written from the numbers).

- [ ] **Step 1: Failing tests** on synthetic fixtures: `test_walk_forward_never_uses_future_hours` (shuffle the future and check identical predictions for past origins), `test_leave_one_home_out_excludes_held_out_home_from_prior_and_fit`, `test_baselines_return_expected_values_on_constant_series`, `test_metrics_json_has_every_documented_key`, `test_learning_curve_truncates_history_to_n_days`, `test_with_only_two_homes_marks_results_fragile`, `test_metrics_are_deterministic_for_same_input`.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3: Implement** `evaluate.py`. The gradient boosting yardstick is `HistGradientBoostingClassifier` on slot, hour, weekday, horizon, home now and habit, also leave one home out. `run_all.py` runs gate, evaluation and export (Task 5) in order and refuses to run past a failed gate.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5: Run on real data** and read the numbers critically: the model must be compared honestly with the baselines, including if it does not win at some horizon. Write the `questions` answers from the numbers, not from the hope.

### Task 5: Export artifacts (params, golden, demo history, Dart constants)

**Files:**
- Create: `AI/src/export_artifacts.py`, `AI/tests/test_export_artifacts.py`
- Output: `AI/output/home_forecast.json`, `AI/output/golden.json`, `AI/output/demo_presence.json`; generated `lib/features/parcels/home_forecast/forecast_params_data.dart`, `lib/features/parcels/home_forecast/demo_presence_seed.dart`

**Interfaces:**
- Produces `home_forecast.json`: `{version: 1, slots: 168, eps: 1e-6, b0, b1, b2, tau_hours, half_life_days, prior_strength, prior: [168 floats], source: {dataset, record, licence}}`. `golden.json`: `{cases: [{name, observations: [["YYYY-MM-DDTHH:00", 0 or 1], ...], now: "YYYY-MM-DDTHH:00", home_now, hours_ahead, expected_habit, expected_forecast}], hourly_cases: [{name, events: [["YYYY-MM-DDTHH:MM", 0 or 1]], end, expected: [["YYYY-MM-DDTHH:00", 0 or 1]]}]}` with at least 12 cases including empty, one observation, Sunday to Monday, a DST day, extreme habit, and a 168 hour horizon. `demo_presence.json`: `{start: "YYYY-MM-DDTHH:00", members: {m0: "0101...", m1: ..., m2: ..., m3: ...}}` 21 days (504 characters) each, derived from different CASAS homes or time shifted copies, with a `label: "demo filler, not Filipino data"` field. Dart constants files expose `const Map<String, dynamic> forecastParamsJson` and `const Map<String, dynamic> demoPresenceSeedJson` with a header comment "generated by AI/src/export_artifacts.py, do not edit".

- [ ] **Step 1: Failing tests:** `test_params_json_has_168_prior_values_in_unit_interval`, `test_golden_expected_values_equal_reference_implementation`, `test_golden_covers_edge_cases_by_name`, `test_demo_seed_members_have_504_characters_of_zero_or_one`, `test_dart_constants_equal_json_files` (parse the generated Dart map back and compare), `test_export_is_byte_identical_on_second_run`.
- [ ] **Step 2:** Run. Expected: FAIL. **Step 3:** Implement. **Step 4:** Run. Expected: PASS.

### Task 6: Dart module (pure) and parity tests

**Files:**
- Create: `lib/features/parcels/home_forecast/forecast_params.dart`, `habit_profile.dart`, `home_forecaster.dart`, `presence_hours.dart`, `arrival_advisor.dart`; tests `test/ai/home_forecast_parity_test.dart`, `test/ai/arrival_advisor_test.dart`, `test/ai/presence_hours_test.dart`
- Imports: no Flutter imports in these five files.

**Interfaces:**
- Consumes: `forecastParamsJson` from Task 5.
- Produces: `ForecastParams.fromJson(Map)`; `HourObservation(DateTime at, bool home)`; `int slotOf(DateTime)`; `double habitProbability(List<HourObservation>, DateTime now, int slot, ForecastParams)`; `double forecastHome(List<HourObservation>, DateTime now, {required bool homeNow, required int hoursAhead, required ForecastParams params})`; `List<HourObservation> eventsToHourly(List<PresenceEvent> events, DateTime end)`; `enum HomeBand { likely, maybe, unlikely }`; `HomeBand bandOf(double p)`; `class MemberHistory {String memberId; String name; bool optedIn; bool homeNow; List<HourObservation> hours;}`; `class MemberForecast {String memberId; String name; double probability; HomeBand band; String why; int observedHours;}`; `class ArrivalAdvice {List<MemberForecast> ranked; double anyoneHomeProbability; DateTime? bestWindowStart; double bestWindowProbability; int optedInCount; int memberCount;}`; `ArrivalAdvice adviseArrival({required DateTime expectedArrival, required DateTime now, required List<MemberHistory> members, required ForecastParams params})` (anyone home = `1 - product(1 - p)` over opted in members, best window = best 2 hour window on the arrival day not before `now`, `why` such as "was home 9 of 12 recent Thursdays at 2 PM").

- [ ] **Step 1: Failing tests (Dart):** one parity test that reads `AI/output/golden.json` and `AI/output/home_forecast.json` and asserts every case within 1e-9; `eventsToHourly` runs the golden `hourly_cases`; advisor tests `empty history uses the prior`, `member not opted in is excluded from ranking and from anyone home`, `nobody opted in gives optedInCount 0 and no best window`, `ranking is sorted by probability descending`, `best window never starts before now`, `window probability equals one minus the product of the complements`, `band thresholds at 0.40 and 0.70`, `slot math at Sunday 23:00 and Monday 00:00`, `DST day does not shift the age`.
- [ ] **Step 2:** `flutter test test/ai`. Expected: FAIL (files missing).
- [ ] **Step 3: Implement** the five files, mirroring `AI/src/home_forecast.py` function by function (clip with the same `eps`, `DateTime.utc` for ages). `PresenceEvent` is added in Task 7; until then declare it in `presence_hours.dart` and move it in Task 7.
- [ ] **Step 4:** Run. Expected: PASS. Also run `flutter analyze lib/features/parcels/home_forecast`. Expected: no issues.

### Task 7: Repository integration (history, opt in, demo seed)

**Files:**
- Modify: `lib/data/models.dart` (add `PresenceEvent {String userId; DateTime at; bool isHome;}`), `lib/data/mock_repository.dart`
- Create: `test/ai/presence_repository_test.dart`

**Interfaces:**
- Produces on `MockRepository`: `bool isRoutineOptedIn(String userId)`; `void setRoutineOptIn(String userId, bool value)` (false deletes that member's history); `List<PresenceEvent> presenceHistoryFor(String userId)`; `List<MemberHistory> forecastInputs(DateTime now)` (builds from history with `eventsToHourly`); `updatePresence` appends a `PresenceEvent` only when the current user is opted in; a constructor path that seeds all four `_members` from `demoPresenceSeedJson` (members in order m0 to m3) as opted in.

- [ ] **Step 1: Failing tests:** `new account starts opted out`, `updatePresence does not record when opted out`, `updatePresence records when opted in`, `opting out deletes that members history`, `forecastInputs excludes members who are not opted in`, `demo household has four opted in members with 21 days of history`, `existing updatePresence behaviour (isHome, note, updatedAt) is unchanged`.
- [ ] **Step 2:** Run `flutter test test/ai/presence_repository_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement.** Additive edits only; keep every existing method and field.
- [ ] **Step 4:** Run the whole suite: `flutter test`. Expected: baseline count from Task 1 plus the new tests, all passing.

### Task 8: Parcel card, add parcel hint, settings switch, privacy sentence

**Files:**
- Modify: `lib/features/parcels/parcels_screen.dart` (forecast row in `_ParcelCard`, window hint in the add parcel sheet), `lib/features/settings/app_settings_screen.dart` (switch "Let Cas learn my routine"), `lib/features/legal/terms_privacy_screen.dart` (one sentence)
- Create: `lib/features/parcels/home_forecast/forecast_row.dart` (the widget), `test/ai/forecast_row_widget_test.dart`

**Interfaces:**
- Consumes: `repo.forecastInputs`, `adviseArrival`, `isRoutineOptedIn`, `setRoutineOptIn`.
- Produces: `ForecastRow({required ParcelItem parcel})` consumer widget. Shown only for upcoming parcels (`status == expected`) when `optedInCount > 0`. Text: a headline ("Cas thinks Alex is probably home (82%)" or "Cas thinks nobody is likely home then"), the `why` line, "Based on N of M housemates who turned this on", a best window line when it beats the arrival time, and "Learned from N hours of your taps" for the signed in member. No dashes before labels, no hyphenation, uses existing `CasamaColors` and `context.textColor` patterns.

- [ ] **Step 1: Failing widget tests:** `forecast row shows for an upcoming parcel in the demo household`, `forecast row is hidden when nobody opted in`, `forecast row is hidden for received and cancelled parcels`, `forecast row does not overflow at 320 px width with a long housemate name`, `settings switch toggles opt in and clears history`, `privacy screen contains the new sentence`, `availableMemberNames and isAllUnavailable are unchanged by showing a forecast`.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3: Implement** the widget and the three small edits. Read `_ParcelCard` (around line 350 to 500) and `_showAddParcelModal` first, and follow their style.
- [ ] **Step 4:** `flutter test` (whole suite) and `flutter analyze` on the touched files. Expected: all tests pass, no new analyzer issues (note the pre-existing count first).
- [ ] **Step 5: Run the app in Chrome** (`flutter build web` then serve `build/web`, or `flutter run -d chrome`), one process at a time because of RAM. Screenshot the parcel board at desktop and 390 px widths, the settings switch, and the add parcel sheet. **Look at the images** and fix layout problems. Save the final screenshots to `AI/output/screens/` for the video and README.

### Task 9: README, REFERENCES and number checks

**Files:**
- Create: `AI/README.template.md`, `AI/src/build_readme.py`, `AI/src/check_references.py`, `AI/REFERENCES.md`, `AI/tests/test_readme.py`
- Output: `AI/README.md`

**Interfaces:**
- Consumes: `metrics.json`. Reuse the placeholder engine design of `Data Science/src/build_readme.py` (copy and adapt, do not import across folders).
- Produces: `build_readme.render(template, metrics) -> str` and a check that every number in `README.md` appears in `metrics.json` or the template.

- [ ] **Step 1: Failing tests:** `test_every_placeholder_resolves`, `test_readme_numbers_match_metrics`, `test_readme_lists_every_touched_third_year_file` (compare against a list in the test), `test_no_dashes_before_labels_and_no_hyphenated_words_in_readme`, `test_references_file_has_a_checked_url_for_every_citation`.
- [ ] **Step 2:** Run. Expected: FAIL. **Step 3: Write** the template: the problem, the data and its limits, the algorithm explained step by step with the formula, results against baselines (from `metrics.json`), the integration (every touched file, how to run the tests and the app), privacy design, limits, how to rebuild, credits (group Theoraux, five names), references. Open and check every reference URL and licence with `check_references.py` and by reading the pages (CASAS record and paper, Kleiminger, Mattern and Santini 2014 DOI 10.1016/j.enbuild.2014.09.046, and any others cited). **Step 4:** Run. Expected: PASS.

### Task 10: Video script, beats, voice and sound

**Files:**
- Create: `AI/video/script.md`, `AI/video/narration.json`, `AI/video/beats.json`, `AI/video/scene_timings.json`, `AI/video/cues.json`, `AI/src/build_script.py`, `AI/src/make_voice.py`, `AI/src/make_sfx.py` (copied from the Data Science versions and adapted), `AI/video/sfx/*.wav`, `AI/video/tools/sfx-track.mjs`, `AI/video/tools/mix-sound.mjs`, `AI/video/tools/check.mjs`, `AI/tests/test_script.py`

**Interfaces:**
- Produces: about 1,200 to 1,400 words of narration for 8 to 10 minutes in the scene list of the spec; `beats.json` = `{sceneId: {key: {phrase, sfx?, shift?}}}`; `narration.json` = `[{id, text}]`; `cues.json` per scene character timings; `scene_timings.json` entries `{id, seconds, lead_seconds}` with lead 0.6 and tail 1.5 s; the mixed `sound.m4a`. `check.mjs` verifies every beat phrase occurs in its scene text and the total length is 8 to 10 minutes.

- [ ] **Step 1: Failing tests:** `test_every_number_in_script_comes_from_metrics`, `test_script_length_between_1200_and_1400_words`, `test_no_member_names_in_narration_text`, `test_every_beat_phrase_appears_once_in_its_scene`, `test_estimate_timings_cover_8_to_10_minutes`.
- [ ] **Step 2:** Run. Expected: FAIL. **Step 3:** Write the script from `metrics.json` (so numbers are generated, not typed), the beats table, and copy and adapt the voice and sound tools. Reuse the 7 original wavs.
- [ ] **Step 4: Estimate pass** (`make_voice.py --estimate`) builds timings from word count so the picture can be built before any paid call. **Step 5: Before the paid render:** `make_voice.py --dry-run` to print characters needed and the balance. Ask the user for a new ElevenLabs key if there is none, and if credit is short build silent and say so. **Step 6:** Render the narration once, cache by text hash, then `mix-sound.mjs`. Check loudness near -18 LUFS with no clipping.

### Task 11: HyperFrames video

**Files:**
- Create: `AI/video/hyperframes/` (project made with the HyperFrames CLI), scene HTML per scene, `AI/video/hyperframes/timeline.json` generated from `beats.json`, `scene_timings.json` and `cues.json`, `AI/video/render-final.mjs`
- Output: `AI/video/hyperframes/out/theoraux-ai-home-forecast.mp4` (git ignored)

**Interfaces:**
- Consumes: Task 9 and 10 outputs and the real app screenshots from Task 8. Load the `hyperframes`, `hyperframes-cli`, `hyperframes-core` and `hyperframes-animation` skills first and follow their render contract.
- Scenes (from the spec): problem on the parcel board; what a forecast is; the data and its limits; the algorithm in three animated steps (168 slot grid filling in, the forgetting curve, the combiner); results against baselines; integration on the real app; privacy; limits; credits and references.

- [ ] **Step 1: Failing check:** `node AI/video/tools/check.mjs` fails (no timeline yet). **Step 2:** Build every scene so each visual appears on its spoken phrase (the beats table), with charts drawn from `metrics.json`, the real screenshots, kinetic text, the CC BY 4.0 attribution and references on screen. Layout and taste: dark ink background and the Casama coral accent, Josefin Sans and Manrope as in the Data Science video, no dashes before labels.
- [ ] **Step 3:** Render stills of every scene and look at them. Fix overlaps, clipping and empty areas (the same review the Data Science video went through). **Step 4:** Chunked, memory safe render (one browser, chunks muxed with `sound.m4a`), never restarted without being asked. **Step 5: Verify** with `ffprobe` (1920x1080, 30 fps, 8 to 10 minutes), loudness, a contact sheet of sampled frames, and `check.mjs`. Report honestly that nobody has watched it.

### Task 12: Whole branch review and hand off

- [ ] **Step 1:** Run every suite: `pytest` in `AI`, `flutter test`, `flutter analyze` on touched files, `node AI/video/tools/check.mjs`, README number check.
- [ ] **Step 2:** One fresh reviewer on the most capable model reviews the whole change (package built with the review script) against the spec, the global constraints and the Review Focus list. Fix Critical and Important findings in one pass, each with a failing test first.
- [ ] **Step 3:** Update the project memory note, and report: what exists, what was verified and how, what was not (nobody has watched the video), what the user still has to do (watch it, upload to Google Drive and add the link, read the licences, decide on committing, rotate the new key).
