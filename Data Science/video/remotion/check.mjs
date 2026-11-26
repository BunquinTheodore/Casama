// The video's contract: 1920 by 1080 at 30 fps, 8 to 10 minutes, durations taken from scene_timings.json,
// and a scene component for every scene id. Run: npm run check (after npm run sync).
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath, pathToFileURL} from "node:url";
import {bundle} from "@remotion/bundler";
import {selectComposition} from "@remotion/renderer";

const here = path.dirname(fileURLToPath(import.meta.url));
const timings = JSON.parse(fs.readFileSync(path.join(here, "public", "data", "timings.json"), "utf8"));
const scenesSource = fs.readFileSync(path.join(here, "src", "scenes.tsx"), "utf8");
for (const {id} of timings) {
  assert.match(scenesSource, new RegExp(`^\\s+${id}:`, "m"), `no scene component registered for "${id}"`);
}

// every picture is anchored to a phrase of the narration: the phrase must exist and happen inside its scene
const {BEATS, beatTime} = await import(pathToFileURL(path.join(here, "src", "beats.ts")).href);
const cues = JSON.parse(fs.readFileSync(path.join(here, "public", "data", "cues.json"), "utf8"));
let beatCount = 0;
for (const t of timings) {
  assert.ok(BEATS[t.id], `no beats for scene ${t.id}`);
  for (const key of Object.keys(BEATS[t.id])) {
    const seconds = beatTime(t.id, key, cues[t.id], t.lead_seconds ?? 0); // throws when the phrase is not spoken in that scene
    assert.ok(seconds >= 0 && seconds < t.seconds, `beat ${t.id}.${key} at ${seconds}s is outside its scene (${t.seconds}s)`);
    beatCount += 1;
  }
}

const serveUrl = await bundle({entryPoint: path.join(here, "src", "index.ts")});
const composition = await selectComposition({serveUrl, id: "Explorer"});
assert.equal(composition.width, 1920);
assert.equal(composition.height, 1080);
assert.equal(composition.fps, 30);
const expected = timings.reduce((sum, t) => sum + Math.ceil(t.seconds * 30), 0);
assert.equal(composition.durationInFrames, expected, "duration must equal the sum of the scene timings");
const minutes = composition.durationInFrames / 30 / 60;
assert.ok(minutes >= 8 && minutes <= 10, `video is ${minutes.toFixed(2)} minutes, the target is 8 to 10`);
console.log(`ok: ${composition.width}x${composition.height} at ${composition.fps} fps, ${minutes.toFixed(2)} minutes, ${timings.length} scenes, ${beatCount} beats tied to spoken phrases`);
