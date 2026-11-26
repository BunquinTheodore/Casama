// The sound effect track: where every effect lands and that the rendered track is what the cue list says.
// Run: npm test   (node --test tests/)
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import {fileURLToPath} from "node:url";
import {RATE, SFX_GAIN_DB, readWav, renderTrack, sfxCues} from "../scripts/sfx-track.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const ds = path.resolve(here, "..", "..", "..");
const sfxDir = path.join(ds, "video", "sfx");

const cue = (text) => ({text, starts: [...text].map((_, i) => i * 0.1), ends: [...text].map((_, i) => i * 0.1 + 0.1)});
const fixtureBeats = {
  one: {a: {phrase: "alpha", sfx: "pop"}, b: {phrase: "beta", sfx: "tick"}, c: {phrase: "gamma"}},
  two: {w: {phrase: "wave", sfx: "whoosh"}, p: {phrase: "pop", sfx: "pop", shift: 0.5}},
};
const fixtureTimings = [
  {id: "one", seconds: 10, lead_seconds: 0.5},
  {id: "two", seconds: 8, lead_seconds: 0.5},
];
const fixtureCues = {one: cue("alpha beta gamma"), two: cue("a wave then pop")};
const beatTime = (sceneId, key, scene, lead) => {
  const b = fixtureBeats[sceneId][key];
  return lead + scene.starts[scene.text.indexOf(b.phrase)] + (b.shift ?? 0);
};
const build = () => sfxCues(fixtureTimings, fixtureCues, {beats: fixtureBeats, beatTime, fps: 30});

test("an effect lands at the scene start plus the lead in plus the moment the phrase starts", () => {
  const popA = build().find((c) => c.source === "one.a");
  assert.equal(popA.kind, "pop");
  assert.ok(Math.abs(popA.at - 0.5) < 1e-9, `got ${popA.at}`);
  const tick = build().find((c) => c.source === "one.b");
  assert.ok(Math.abs(tick.at - (0.5 + 0.6)) < 1e-9, `got ${tick.at}`);
});

test("the second scene starts after the first one, and its beat time includes the shift", () => {
  const pop = build().find((c) => c.source === "two.p");
  assert.ok(Math.abs(pop.at - (10 + 0.5 + 0.1 * "a wave then ".length + 0.5)) < 1e-9, `got ${pop.at}`);
});

test("a beat without a sound makes no effect", () => {
  assert.equal(build().some((c) => c.source === "one.c"), false);
});

test("every scene after the first opens with a whoosh, the first scene does not", () => {
  const transitions = build().filter((c) => c.source.startsWith("scene:"));
  assert.deepEqual(transitions.map((c) => c.source), ["scene:two"]);
  assert.ok(transitions[0].at < 10 && transitions[0].at > 9.8, "the whoosh leads the wipe slightly");
});

test("a second whoosh right after the scene whoosh is dropped, not stacked", () => {
  const cues = build();
  const whooshes = cues.filter((c) => c.kind === "whoosh");
  assert.equal(whooshes.length, 1, "scene whoosh and a beat whoosh half a second later must not double up");
  assert.equal(cues.some((c) => c.source === "two.w"), false);
});

test("cues are in time order and carry the gain of their kind", () => {
  const cues = build();
  for (let i = 1; i < cues.length; i += 1) assert.ok(cues[i].at >= cues[i - 1].at);
  for (const c of cues) assert.equal(c.gainDb, SFX_GAIN_DB[c.kind]);
});

test("every kind that beats.ts can ask for has a gain and a wav file", async () => {
  const {BEATS} = await import("../src/beats.ts");
  const kinds = new Set(Object.values(BEATS).flatMap((scene) => Object.values(scene).map((b) => b.sfx).filter(Boolean)));
  kinds.add("whoosh");
  for (const kind of kinds) {
    assert.equal(typeof SFX_GAIN_DB[kind], "number", `no gain for ${kind}`);
    assert.ok(fs.existsSync(path.join(sfxDir, `${kind}.wav`)), `missing ${kind}.wav (run python src/make_sfx.py)`);
  }
});

test("the real cue list fits inside the real video", async () => {
  const timings = JSON.parse(fs.readFileSync(path.join(ds, "video", "scene_timings.json"), "utf8"));
  const cues = JSON.parse(fs.readFileSync(path.join(ds, "video", "cues.json"), "utf8"));
  const total = timings.reduce((sum, t) => sum + Math.ceil(t.seconds * 30) / 30, 0);
  const list = sfxCues(timings, cues);
  assert.ok(list.length > 60, `only ${list.length} effects`);
  for (const c of list) assert.ok(c.at >= 0 && c.at < total, `${c.source} at ${c.at} is outside ${total}`);
});

test("the rendered track is silent between effects and carries the effect at its time with its gain", () => {
  const raw = readWav(path.join(sfxDir, "pop.wav"));
  const track = renderTrack([{at: 1, kind: "pop", gainDb: -20, source: "test"}], 3, sfxDir);
  assert.equal(track.length, 3 * RATE * 2);
  const before = track.slice(0, RATE * 2 - 2);
  assert.equal(before.every((s) => s === 0), true, "silence before the effect");
  let rawPeak = 0;
  for (const s of raw.samples) rawPeak = Math.max(rawPeak, Math.abs(s));
  let peak = 0;
  for (const s of track) peak = Math.max(peak, Math.abs(s));
  const expected = rawPeak * 10 ** (-20 / 20);
  assert.ok(Math.abs(peak - expected) / expected < 0.02, `peak ${peak} expected about ${expected}`);
  const after = track.slice((1 + raw.samples.length / 2 / RATE + 0.05) * RATE * 2 | 0);
  assert.equal(after.every((s) => s === 0), true, "silence after the effect ends");
});

test("effects that overlap are added and never wrap around", () => {
  const cues = Array.from({length: 40}, () => ({at: 0.5, kind: "thud", gainDb: 6, source: "loud"}));
  const track = renderTrack(cues, 2, sfxDir);
  let peak = 0;
  for (const s of track) peak = Math.max(peak, Math.abs(s));
  assert.ok(peak <= 32767, "stays inside 16 bits");
  assert.ok(peak >= 32000, "saturates instead of wrapping to a small value");
});
