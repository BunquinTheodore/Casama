# Data Science explorer video (Remotion)

The 1920 by 1080, 30 fps video for group Theoraux. Every number on screen is read from `findings.json` and `series.json`,
and every scene is as long as its narration (`video/scene_timings.json`). Nothing is typed by hand.

```bash
npm install
npm run sync          # copies the findings, series, timings, fonts and audio into public/ (git ignored copies)
npm run check         # 1920 by 1080, 30 fps, 8 to 10 minutes, a scene component for every scene id, every beat phrase is spoken in its scene
npm test              # the sound effect track: where every effect lands, no clipping, silence between effects
npm run sfx           # out/sfx.wav and out/sfx-cues.json from src/beats.ts and the word timings
npm run sound         # out/sound.m4a: Brian's narration (aligned to the pictures) with the effects under it
npm run dev           # Remotion Studio
npm run render:final  # chunked render plus narration and sound effects, gentle on memory: writes out/theoraux-data-science.mp4
npm run render:video  # plain single pass render (needs more memory, no narration mixing)
node scripts/stills.mjs 0.3,0.9 title,data      # review stills at fractions of chosen scenes, in out/stills
node scripts/stills-beats.mjs model all 1.6     # one still 1.6 s after each spoken beat of a scene
```

How the pictures follow the voice: `src/beats.ts` lists, per scene, every visual that appears (`key`), the phrase of the
narration that triggers it and an optional sound effect. `python src/make_voice.py` stores the time of every character
(`video/cues.json`), so a phrase gives an exact time. The same table drives the animation (`src/cues.tsx`, `useBeat`), the
sound effects (`scripts/sfx-track.mjs`) and the check that every phrase really is spoken in its scene (`npm run check`).

Timings come from `python src/make_voice.py` (real audio) or `python src/make_voice.py --estimate` (word count, silent draft).
Remotion is free for individuals, teams of up to three people, and non-profit or educational organisations: see
REFERENCES.md in the project folder before publishing the video widely.
