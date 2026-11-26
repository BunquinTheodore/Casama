# AI final project: Casama Home Forecast

Status: draft for approval. Date: 2026-11-25. Scope: the AI project only. The Data Science project is finished and closed.

## Intent and why

This is a group graded final project for the AI class, built in the same fork of the 3rd year Casama repo (`origin` is `BunquinTheodore/Casama`, a fork of `pol-xy/Casama`). Group Theoraux: Theodore Von Joshua M. Bunquin, Christian B. Nayre, Daniel B. Villanueva, John C. Alcaraz, Paul C. Alcaraz.

The brief, as given: an AI **algorithm** that is **integrated** into the 3rd year app, a **README** document that explains it, and a **video of 8 to 10 minutes** with citations. It must not become a new app. Asked which kind of algorithm the instructor expects, the user said: any technique is fine as long as it is integrated and explained.

The problem comes from Casama itself. The parcel board asks each housemate to tap "available" for every parcel, and a conflict alert appears only after everyone has tapped unavailable. Nothing tells the buyer, before the courier comes, whether anybody is likely to be home. The question this project answers:

**Given what each housemate's own Home and Out history looks like, who is likely to be home when a parcel is expected, and which window is the safest?**

## Goals, non goals, anti goals

Goals
- A small, explainable forecasting algorithm that learns each housemate's weekly routine, with every number in the README and video traceable to a generated file.
- A real integration: the forecast appears on the parcel board of the Casama app, learns from the Home and Out toggles the app already has, and is covered by tests that run.
- Honest evaluation against simple baselines on real occupancy data, including negative results and limits.
- Citations that were checked, and dataset licences that were read.

Non goals
- No new app, no new backend, no cloud model, no paid API at run time.
- No GPS, no background tracking, no new data collected from anyone.
- No claims about Filipino households. The public data used to evaluate the algorithm is not Filipino.

Anti goals (a failure even if it technically works)
- A feature that contradicts the app's own privacy promise ("Your presence is 100% manually updated by you. Casama NEVER monitors background GPS", Terms and Privacy screens).
- Showing an exact schedule of when someone is away. Forecasts are bands and probabilities, and a wrong forecast must never read as a fact.
- A README or video that disagrees with the generated metrics, or invented numbers, quotes and logos.

## Constraints (checked on 2026-11-25)

- **The app runs on `MockRepository` only.** `lib/data/mock_repository.dart` is an in memory `ChangeNotifier`. A `supabase_config.dart` exists but no Supabase repository is implemented, so the integration lives in the mock layer and the screens.
- **The app stores only the current presence** (`MemberPresence`: `isHome`, `note`, `updatedAt`). There is no history. The integration has to add a history, and `updatePresence` has to record into it.
- **Availability today is manual.** `toggleParcelAvailability` flips "You" in `availableMemberNames`, and `isAllUnavailable` is set when the list is empty. The forecast only suggests, it never changes this list by itself.
- **Flutter and Dart are not installed on this machine** (no `flutter` or `dart` on PATH, none in the usual folders). Without them nothing in `lib/` can be compiled, analysed or tested, and the video could not show the real app. C: has 28 GB free and about 1.8 GB of free RAM.
- **Presence data.** The only openly licensed real occupancy data found so far is the CASAS smart home collection on Zenodo, record 17180309: four homes (Aruba, Cairo, Milan, Tulum), motion and door sensors with activity labels, **CC BY 4.0**, one 33 MB zip. From here the download runs at about 10 KB/s and is still in progress. **Not yet verified:** that the labels or sensors give a clean at home versus away signal for these homes. The repo script `scripts/presence_events_from_kaggle.py` points at a Kaggle occupancy dataset whose columns I could not confirm. The ECO dataset (Swiss households) is request based, so it is out.
- The CASAS homes are in the United States with older adult or small household residents, not Filipino students. This is a domain shift and is stated as a limit.
- Standing rules from the user: do not commit or push unless asked in that turn; no dashes before labels; never hyphenate words; verify UI changes in a real browser; the video is built with HyperFrames, narrated with ElevenLabs (a new key is needed, the earlier ones are deleted), original sound effects only.

## Approaches considered

| | What | Trade off |
|---|---|---|
| A | Keep manual "available" taps, add reminders | No AI, does not answer the brief |
| B | Habit profile only: per person, 168 hour of week slots, smoothed average of past Home hours | Explainable, runs on the phone, needs no outside data. No cold start help and no "where they are right now" signal |
| **C (chosen)** | B plus a three coefficient logistic regression that combines the habit, the current state and the hours ahead, with a population prior for new members, fitted offline on public occupancy data and run in pure Dart | Explainable in one scene per idea, evaluated against baselines, small enough to ship as a JSON asset. Accuracy is limited by thin public data |
| D | A heavier model (gradient boosted trees or a neural net) through a plugin or a server | Possibly a little more accurate, but adds a dependency or backend, breaks "on the device, no cloud", and is hard to explain in 8 to 10 minutes. We still fit one gradient boosted model offline as a yardstick, so the README can say how much accuracy the small model gives up |
| E | An LLM assistant that answers "who is home?" | Needs network, a key and sending household data to a third party. Rejected on privacy |

The user said any technique is fine, so C is my pick.

## Design

### Questions, declared before looking

1. Does a per person habit profile forecast who is home better than the base rate, an unsmoothed hour of week average, and "same as right now"?
2. How many days of history does it need? (learning curve at 3, 7, 14 and 28 days)
3. Does the population prior help a brand new member in their first week?
4. How much does the heavier gradient boosted yardstick improve on the small model?

The answers are reported whatever they turn out to be.

### The algorithm

A slot is an hour of the week (0 to 167, local time). For one member:

- **Habit.** Each past hour with a known state is an observation `y` (1 home, 0 out), weighted `w = 0.5^(age in days / H)` so recent weeks count more. For slot `s`: `habit(s) = (sum(w*y over slot s) + k*prior(s)) / (sum(w over slot s) + k)`. `prior(s)` is the population profile, `k` is the prior strength in pseudo hours.
- **Forecast** for a time `h` hours ahead, given the member is home now (`n` = 1) or out (`n` = 0): `p = sigmoid(b0 + b1*logit(habit(s)) + b2*(2n-1)*exp(-h/tau))`. The last term is "people tend to stay as they are, for a while".
- Fitted offline: `b0, b1, b2`, `tau` (small grid), `H` and `k` (small grids), `prior`. Output is `AI/output/home_forecast.json`, shipped to the app as `assets/ai/home_forecast.json`.
- Evaluation is walk forward by day inside each home (never shuffled), with leave one home out for the combiner and the prior. Metrics: AUC, Brier score, log loss, accuracy at 0.5, and a calibration table, at horizons 1, 3, 6, 12 and 24 hours.
- The Python reference implementation (`AI/src/home_forecast.py`) is the definition. The Dart version must reproduce its numbers.

### Data pipeline (Python, `AI/src/`)

Download CASAS (script with size and SHA 256 check, cached under `AI/data/raw`, git ignored), turn each home's events into hourly at home or away, then fit, evaluate, and write `AI/output/metrics.json` (the single source of truth for README and video), `home_forecast.json`, a small `golden.json` (inputs with expected outputs for the parity test) and `demo_presence.json`. **Data gate (the first task of the plan).** The signal counts as usable when at least 2 homes each give 42 or more days of hourly at home or away (28 days of learning curve plus 14 days of walk forward test), derived by a written rule that I check by eye on a sample of days. With 2 or 3 passing homes the leave one home out results are reported as fragile. With fewer than 2, the work stops and I bring the user the options. Simulated data is allowed only for unit test fixtures and the in app demo seed, never for any reported accuracy.

### What is evaluated and what is not

CASAS gives one "someone is home" series per household, and two of the four homes have more than one resident. So each CASAS home is treated as one pseudo member, and the README states the multi resident caveat. The accuracy claims cover that single series forecast only.

Two features sit on top of it and are described but **not separately evaluated**, and the README and video say so:
- **Ranking housemates** for an expected arrival is sorting by each member's own forecast.
- **Best two hour window** for a parcel is the window with the highest chance that at least one opted in member is home, `1 - product(1 - p_i)`, which assumes the members are independent. The hint shows "based on N of M housemates" when some have not opted in, so it never claims more than it knows.

### The demo household

The mock repository has one signed in user, and the other three housemates cannot tap. The demo is therefore seeded, and that is stated where it is shown:
- The seeded household has all four demo housemates already opted in (their consent is demo state). A new account starts opted out.
- Demo history for each housemate is a derived stream from a CASAS home, labelled demo filler (not Filipino and not student routines), as the repo's existing Kaggle script does.
- Opting in starts recording; opting out stops recording and deletes that member's stored history. `updatePresence` records nothing for a member who has not opted in.
- The history lives in memory like the rest of the mock, so it resets when the app restarts. The Supabase schema already has a `presence_events` table, which is where a real repository would keep it.
- "Learns from your taps" is shown honestly: after "You" taps Home or Out, a line under the forecast reads "Learned from N hours of your taps" and the count goes up. One tap does not visibly change a weeks long profile, and the video does not pretend it does. The learning curve from the Python evaluation carries that scene.

### Integration (Dart, additive, in the app)

New pure Dart code (no Flutter imports) in `lib/features/parcels/home_forecast/`: `forecast_params.dart` (parses the JSON asset), `habit_profile.dart`, `home_forecaster.dart`, `arrival_advisor.dart` (ranks housemates for an expected arrival, finds the best two hour window that day, produces the "why" sentence).

Small edits to existing 3rd year files, each listed in the README so their team can review:
- `lib/data/models.dart`: a `PresenceEvent` class.
- `lib/data/mock_repository.dart`: a presence history per member, seeded from `demo_presence.json` (clearly demo filler, like the existing Kaggle script), appended by `updatePresence`, a getter for it, and a per member opt in flag.
- `lib/features/parcels/parcels_screen.dart`: a forecast row on each upcoming parcel card ("Cas thinks Alex is probably home, 82%"), a short "why" line, and a best window hint in the add parcel sheet. It never edits `expectedArrival` or `availableMemberNames`.
- `lib/features/settings/app_settings_screen.dart`: the opt in switch "Let Cas learn my routine".
- `lib/features/legal/terms_privacy_screen.dart`: one added sentence saying the forecast uses only the Home and Out taps, stays on the device and in the household, and can be switched off.
- `pubspec.yaml`: the `assets/ai/` folder.

Tests (new files only): a parity test that reads `golden.json`, unit tests for the profile, forecaster and advisor (empty history, one observation, opt out, a member with no data), and a widget test for the parcel card row. Existing tests must still pass.

### Privacy by design

- Off by default, per member, switchable at any time. A member who has not opted in is never forecast, and their history is not used for anyone else's forecast.
- Learns only from the Home and Out taps the app already records. No location, no new permission.
- Computed on the device, shown only to housemates, shown as bands (likely, maybe, unlikely) with the percentage, never as an away schedule.
- The README and video say plainly that a routine forecast is sensitive and what the safeguards are.

### The video (`AI/video/`, HyperFrames)

8 to 10 minutes, same discipline as the Data Science video: a timed script, ElevenLabs narration (Brian, `eleven_multilingual_v2`, per character timings so every visual lands on its spoken phrase), original synthesised sound effects, citations on screen. Scenes: the problem on the parcel board, what a forecast is, the data and its limits, the algorithm in three animated steps (the 168 slot grid filling in, the forgetting curve, the combiner), how well it works against baselines, the integration shown on the real app, privacy, limits, credits and references. The app footage comes from the real app running in Chrome, which needs Flutter. Narration needs about 7,000 characters of ElevenLabs credit and a new key.

### Folder layout

```
AI/
  README.md            generated from README.template.md and metrics.json
  README.template.md
  REFERENCES.md
  requirements.txt
  src/                 download, derive, home_forecast.py (reference), evaluate, export, build_readme, make_voice, make_sfx
  tests/               pytest
  data/raw/            git ignored
  output/              metrics.json, home_forecast.json, golden.json, demo_presence.json
  video/               script.md, narration.json, audio/ (git ignored), sfx/, hyperframes project
assets/ai/             the two JSON files the app loads
lib/features/parcels/home_forecast/   the Dart module
test/ai/             Dart tests
```

## Definition of done

- `python -m pytest` in `AI/` passes, and the pipeline rebuilds every output from an empty `AI/data/raw`.
- `flutter analyze` is clean for the files touched, and `flutter test` passes (the existing 78 tests plus the new ones, including the parity test).
- The app runs in Chrome, a screenshot of the parcel card with the forecast exists, and I looked at it.
- README numbers equal `metrics.json` (checked by a script, as in Data Science). References were each opened and checked.
- The video is 8 to 10 minutes, every beat phrase is spoken in its scene, and I measured loudness and sampled frames. Nobody on the team has watched it until the user does.
- The Google Drive upload and the repo link stay with the user.

## Calls I made (the user can change these)

- Feature name "Home Forecast", spoken by Cas the owl. Algorithm C.
- Opt in, default off, per member. This is stricter than the app's current copy requires, because the feature predicts absence.
- Forecast is advice only and never writes to availability.
- Local time for slots is the device's time zone.
- CASAS is the training and evaluation data. If it fails the check above, I stop and report rather than fall back to simulated data presented as real.
- Python reference plus a Dart port with a golden file, rather than shipping a Python runtime or a TFLite model.
- Changes to the 3rd year files are additive and listed. No refactoring of their code.
- Build order and cut line: data gate, then Python algorithm and evaluation, then the Dart module with the parity test, then the parcel screen, then README, then the video, with the narration last. If time runs short, the video scenes for ranking and the add parcel hint are cut first, never the evaluation or the tests.
- Narration needs a new key and about 7,000 characters of credit. I check the balance before rendering. If there is not enough credit, I build the video silent with timings estimated from word count and tell the user, instead of splitting the narration across accounts.

## Left to the builder

Exact grids for `H`, `k`, `tau`; the hour boundary rule when a toggle falls mid hour (majority of the hour); chart styling; the scene wording.

## Settled by the user

- Any AI technique is fine if it is integrated and explained (2026-11-25).
- Deliverables: repo link and a Google Drive video link. Nothing is committed unless asked.

## Still open (needs the user)

1. Install the Flutter SDK for web only (about 1 GB download, an estimated 2 to 3 GB on disk, removed at cleanup). Without it the Dart code is unverified and the video cannot show the real app, so the README would say "not compiled". Recommended: yes.
2. A deadline, if there is one. It sets how much of the video can be polished.
3. When the narration is rendered: a new ElevenLabs key with enough credit (about 7,000 characters). Later, not now.

## Appendix: the brief as given

AI: "algorithm + integrate", a README document, a video of 8 to 10 minutes with citations, no new app, fork not clone, coordinate with the 3rd year team.
