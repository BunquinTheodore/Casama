# Casama Home Forecast, the film (SPEC)

GOAL: the viewer understands, in about nine minutes, how a four number model forecasts who is home for a parcel, how well it works and where it fails, and sees it running in the real Casama app.
OUTPUT: HyperFrames, 1920 x 1080, 30 fps. Narrated (Kokoro, voice am_michael, made on this computer), original sound effects, no music bed (no music source available).
TIME: about 8.6 minutes = 15,500 frames. The voice is the clock: every visual lands on the word that says it (`../beats.json`, built into `timeline.json`). A scene opens 0.6 s before the first word and holds 1.5 s after the last (the last scene holds 7.5 s).

LOOK: the Casama app's own brand, because the film lives inside the app.
- ground #FFF8F1 (the app's cream), ink #1B2A4A, one accent coral #E8776A (the app's coral), support dusty blue #4F6580 and leaf green #2E7D32 for "good" only.
- display: Josefin Sans 700, 96 to 120 px, uppercase, tracking +1%. body: Manrope 500, 34 px (never under 28 px). numbers: Josefin Sans 700.
- medium: printed card stock. Panels are solid ink or solid white rectangles with 28 px radius and a 2 px #1B2A4A line, offset shadow 10 px right and down in solid #1B2A4A at 12% (no blur, no glow). Real app screenshots sit in a phone frame (10 px ink bezel, 44 px radius).
- the coral appears on one focus per frame (the number, the bar, the stamp), never as a background wash.

OBJECTS: the real app (screenshots from the web build, `assets/screens`), the 168 slot week grid (7 columns Monday to Sunday, 24 rows, drawn from the demo household's real derived hours), the decay curve, the formula, bar and line charts drawn from `output/metrics.json`. No stock imagery, no invented logos.

MOTION: enter = power3.out 0.5 s with 28 px rise; stamps = back.out(2) scale from 1.6 to 1 over 0.35 s with a 3 degree rotation settling to 0; bars grow with power2.out 0.8 s; counters count up over 0.9 s; scene change = a coral block wipes left to right over 0.55 s (the whoosh) and the new scene's headline rises behind it. Nothing keeps drifting after it lands. Camera: none, except one 1.0 to 1.25 push on the forecast box in the app scene.

SHOTS (scene, beats are in `beats.json`):
1. title: the real parcel board in a phone frame at right (height 900), title stacked left; group stamp; "who is probably home" underlined in coral; "measured on real data" stamp.
2. problem: the old board (the real screenshot with the forecast box masked out) with avatar chips tapping available; a red conflict banner after the last tap; then the question card.
3. idea: the 168 slot grid fills slot by slot; one Thursday 2 PM cell is highlighted; older weeks fade; the cell value is the habit.
4. data: five home tiles, three light up with days; a day strip shows away hours between Leave_Home and Enter_Home; gate stamp; three limit stamps.
5. algorithm: three panels build left to right (decay curve, fading present curve, the formula with the three fitted numbers); "the whole model" stamp.
6. results: bars at 3 hours, five horizon lines, learning curve, gradient boosting bar, the failed prior stamp.
7. app: phone with the real forecast row, push in on the row, the add parcel sheet, parity badge, "advice only" stamp.
8. privacy: the real settings switch and privacy card, five safeguards as a ruled list.
9. limits: calibration bars (predicted vs observed), four limit lines.
10. credits: the group, the data, the tools, the references file.

BANNED (this film must not become): a dark void ground; glow or bloom; glass cards; purple or blue gradients; three cards in a row; bullet slides; everything centred; everything fading in at once; text that keeps moving after it lands; corner labels or frame borders; a logo docked in a corner; a slide of bullets that the narrator repeats word for word.

QA: after every build, `npx hyperframes check`, a still at each beat of the densest scenes (algorithm, results, app), a contact sheet of the whole film, and `ffprobe` and loudness on the render. Nobody has watched it until the user does.
