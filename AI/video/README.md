# The video

Eight to ten minutes, narrated with Kokoro (an open source speech model, voice am_michael, made on this computer), original sound effects, drawn with HyperFrames. Every picture appears on the word that says it.

## How it is built

```
script.md          the narration, one section per scene, numbers filled from ../output/metrics.json
beats.json         the phrase that each picture and each sound effect is tied to
src/build_script.py      script.md  ->  narration.json
src/make_voice.py        narration.json  ->  audio_local/<scene>.mp3 and the time of every spoken character (cues.json)
src/build_timeline.py    scene timings + cues + beats  ->  timeline.json (when every beat happens)
src/mix_sound.py         narration + original sound effects  ->  sound.m4a
build/build_hyperframes.py   timeline.json + metrics.json  ->  hyperframes/index.html and one composition per scene
tools/capture-screens.mjs    screenshots of the real app (Chrome, DevTools protocol)
```

The voice is Kokoro 82M (Apache 2.0, https://huggingface.co/hexgrad/Kokoro-82M) run through kokoro-onnx (MIT, https://github.com/thewh1teagle/kokoro-onnx). Nothing is sent anywhere. Its two model files go in `video/models/` (git ignored, about 350 MB): `kokoro-v1.0.onnx` and `voices-v1.0.bin` from the `model-files-v1.0` release of kokoro-onnx, and `pip install kokoro-onnx soundfile`. Kokoro does not report when each word is spoken, so `src/local_voice.py` speaks one sentence at a time and spreads each sentence's time over its characters: sentence starts are exact and words inside a sentence are close to a fraction of a second. ElevenLabs (the premade voice Brian) is also supported by `make_voice.py` and gives true word times, but needs credits.

Run from the `AI` folder:

```
python src/build_script.py
python src/make_voice.py --dry-run      # characters needed, no key
python src/make_voice.py --estimate     # draft timings from the word count, no key, no cost
python src/make_voice.py --engine local   # the narration, made on this computer (Kokoro, no key, no cost)
python src/make_voice.py                # or ElevenLabs instead (needs ELEVENLABS_API_KEY in ../.env.local and credits)
python src/build_timeline.py
python src/mix_sound.py                 # video/sound.m4a
python video/build/build_hyperframes.py
cp video/sound.m4a video/hyperframes/assets/sound.m4a   # then build again so the project plays it
cd video/hyperframes && npx hyperframes check && npx hyperframes render
```

With the draft timings the picture is complete but silent. When the real narration is rendered the beats move to the real word times and the project is built again, so the pictures follow the voice.

## Sounds and fonts

The sound effects are original sounds made by `src/make_sfx.py` from NumPy (no recordings). There is no music bed because no music source was available. Fonts are Josefin Sans and Manrope (SIL Open Font License, see `../REFERENCES.md`), and Montserrat resolved by HyperFrames.

## What was checked, and what was not

`npx hyperframes check` is clean (no errors, no warnings except that the draft is silent). Stills of every scene were looked at. Nobody has watched the finished video or listened to it.
