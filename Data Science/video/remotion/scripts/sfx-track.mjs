// Builds the sound effect track of the video from the same table that drives the pictures (src/beats.ts).
// Every effect is placed at the moment its phrase is spoken, plus one whoosh as each scene after the first wipes in.
// Output: out/sfx.wav (48 kHz stereo, the full length of the video) and out/sfx-cues.json (the cue sheet).
// The effects themselves are original sounds synthesised by src/make_sfx.py (no third party recordings).
// Usage: node scripts/sfx-track.mjs   (after npm run sync)
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath, pathToFileURL} from "node:url";
import {BEATS, beatTime as defaultBeatTime} from "../src/beats.ts";

export const RATE = 48000;
const CHANNELS = 2;
/** The scene whoosh starts just before the wipe so the sound arrives with the picture, not after it. */
const SCENE_WHOOSH_LEAD_SECONDS = 0.05;
/** Level of each effect before mixing. The narration peaks near full scale, so the effects sit well under it. */
export const SFX_GAIN_DB = {whoosh: -17, swish: -19, pop: -16, tick: -19, chime: -18, thud: -17, rise: -20};
/** Two effects of one kind closer than this are one effect heard twice, so the later one is dropped. */
const MIN_GAP_SECONDS = {whoosh: 0.9, swish: 0.4, rise: 1.0, chime: 0.8, thud: 0.5, pop: 0.25, tick: 0.2};

const here = path.dirname(fileURLToPath(import.meta.url));

/** The list of effects with their absolute times in the video, in time order. */
export const sfxCues = (timings, cues, {beats = BEATS, beatTime = defaultBeatTime, fps = 30} = {}) => {
  const list = [];
  let start = 0;
  timings.forEach((scene, index) => {
    if (index > 0) {
      list.push({at: Math.max(0, start - SCENE_WHOOSH_LEAD_SECONDS), kind: "whoosh", gainDb: SFX_GAIN_DB.whoosh, source: `scene:${scene.id}`});
    }
    for (const [key, beat] of Object.entries(beats[scene.id] ?? {})) {
      if (!beat.sfx) continue;
      const at = start + beatTime(scene.id, key, cues[scene.id], scene.lead_seconds ?? 0);
      list.push({at, kind: beat.sfx, gainDb: SFX_GAIN_DB[beat.sfx], source: `${scene.id}.${key}`});
    }
    start += Math.ceil(scene.seconds * fps) / fps;
  });
  list.sort((a, b) => a.at - b.at);
  const lastOfKind = new Map();
  return list.filter((c) => {
    const previous = lastOfKind.get(c.kind);
    if (previous !== undefined && c.at - previous < (MIN_GAP_SECONDS[c.kind] ?? 0.25)) return false;
    lastOfKind.set(c.kind, c.at);
    return true;
  });
};

/** Reads a 16 bit stereo PCM wav into interleaved samples. */
export const readWav = (file) => {
  const buffer = fs.readFileSync(file);
  if (buffer.toString("ascii", 0, 4) !== "RIFF" || buffer.toString("ascii", 8, 12) !== "WAVE") throw new Error(`${file} is not a wav file`);
  let format = null;
  for (let at = 12; at + 8 <= buffer.length; ) {
    const id = buffer.toString("ascii", at, at + 4);
    const size = buffer.readUInt32LE(at + 4);
    if (id === "fmt ") {
      format = {tag: buffer.readUInt16LE(at + 8), channels: buffer.readUInt16LE(at + 10), rate: buffer.readUInt32LE(at + 12), bits: buffer.readUInt16LE(at + 22)};
    } else if (id === "data") {
      if (!format || format.tag !== 1 || format.bits !== 16 || format.channels !== CHANNELS || format.rate !== RATE) {
        throw new Error(`${file} must be 16 bit stereo PCM at ${RATE} Hz, got ${JSON.stringify(format)}`);
      }
      const bytes = buffer.subarray(at + 8, at + 8 + size);
      return {samples: new Int16Array(bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.length))};
    }
    at += 8 + size + (size % 2);
  }
  throw new Error(`${file} has no audio data`);
};

/** Mixes every cue into one interleaved 16 bit stereo track of the given length. Overlaps add and saturate, never wrap. */
export const renderTrack = (cues, totalSeconds, sfxDir) => {
  const out = new Int16Array(Math.ceil(totalSeconds * RATE) * CHANNELS);
  const wavs = new Map();
  for (const cue of cues) {
    if (!wavs.has(cue.kind)) wavs.set(cue.kind, readWav(path.join(sfxDir, `${cue.kind}.wav`)).samples);
    const samples = wavs.get(cue.kind);
    const gain = 10 ** (cue.gainDb / 20);
    const offset = Math.round(cue.at * RATE) * CHANNELS;
    for (let i = 0; i < samples.length && offset + i < out.length; i += 1) {
      const mixed = out[offset + i] + Math.round(samples[i] * gain);
      out[offset + i] = mixed > 32767 ? 32767 : mixed < -32767 ? -32767 : mixed; // symmetric, so the loudest negative sample equals the loudest positive one
    }
  }
  return out;
};

export const writeWav = (file, samples) => {
  const header = Buffer.alloc(44);
  const bytes = samples.length * 2;
  header.write("RIFF", 0, "ascii");
  header.writeUInt32LE(36 + bytes, 4);
  header.write("WAVEfmt ", 8, "ascii");
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20);
  header.writeUInt16LE(CHANNELS, 22);
  header.writeUInt32LE(RATE, 24);
  header.writeUInt32LE(RATE * CHANNELS * 2, 28);
  header.writeUInt16LE(CHANNELS * 2, 32);
  header.writeUInt16LE(16, 34);
  header.write("data", 36, "ascii");
  header.writeUInt32LE(bytes, 40);
  fs.writeFileSync(file, Buffer.concat([header, Buffer.from(samples.buffer, samples.byteOffset, bytes)]));
};

const main = () => {
  const project = path.resolve(here, "..");
  const dataDir = path.join(project, "public", "data");
  const timings = JSON.parse(fs.readFileSync(path.join(dataDir, "timings.json"), "utf8"));
  const cues = JSON.parse(fs.readFileSync(path.join(dataDir, "cues.json"), "utf8"));
  const total = timings.reduce((sum, t) => sum + Math.ceil(t.seconds * 30) / 30, 0);
  const list = sfxCues(timings, cues);
  const sfxDir = path.resolve(project, "..", "sfx");
  const outDir = path.join(project, "out");
  fs.mkdirSync(outDir, {recursive: true});
  writeWav(path.join(outDir, "sfx.wav"), renderTrack(list, total, sfxDir));
  fs.writeFileSync(path.join(outDir, "sfx-cues.json"), JSON.stringify(list.map((c) => ({...c, at: Math.round(c.at * 1000) / 1000})), null, 2));
  console.log(`sfx track: ${list.length} effects over ${total.toFixed(1)} s written to out/sfx.wav (cue sheet: out/sfx-cues.json)`);
};

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) main();
