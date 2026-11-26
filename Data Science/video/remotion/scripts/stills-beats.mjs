// Renders a still shortly after chosen beats of one scene, to check that the picture matches the words being spoken.
// Usage: node scripts/stills-beats.mjs <scene id> <beat keys, comma separated or "all"> [seconds after the beat, default 1.4] [out dir]
// Example: node scripts/stills-beats.mjs model gain,signals,forecast 1.6
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath, pathToFileURL} from "node:url";
import {bundle} from "@remotion/bundler";
import {renderStill, selectComposition} from "@remotion/renderer";

const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const sceneId = process.argv[2];
const wanted = process.argv[3] ?? "all";
const after = Number(process.argv[4] ?? 1.4);
const outDir = path.resolve(process.argv[5] ?? path.join(project, "out", "stills"));
if (!sceneId) throw new Error("usage: node scripts/stills-beats.mjs <scene id> <beat keys|all> [seconds after] [out dir]");
fs.mkdirSync(outDir, {recursive: true});

const {BEATS, beatTime} = await import(pathToFileURL(path.join(project, "src", "beats.ts")).href);
const timings = JSON.parse(fs.readFileSync(path.join(project, "public", "data", "timings.json"), "utf8"));
const cues = JSON.parse(fs.readFileSync(path.join(project, "public", "data", "cues.json"), "utf8"));
const keys = wanted === "all" ? Object.keys(BEATS[sceneId]) : wanted.split(",");

let start = 0;
let scene = null;
for (const t of timings) {
  if (t.id === sceneId) {
    scene = t;
    break;
  }
  start += Math.ceil(t.seconds * 30);
}
if (!scene) throw new Error(`no scene ${sceneId}`);
const frames = Math.ceil(scene.seconds * 30);

const serveUrl = await bundle({entryPoint: path.join(project, "src", "index.ts")});
const composition = await selectComposition({serveUrl, id: "Explorer"});
for (const key of keys) {
  const seconds = beatTime(sceneId, key, cues[sceneId], scene.lead_seconds ?? 0) + after;
  const frame = start + Math.min(frames - 1, Math.round(seconds * 30));
  await renderStill({composition, serveUrl, frame, output: path.join(outDir, `${sceneId}-b-${key}.png`), imageFormat: "png"});
  console.log(`${sceneId}.${key} at ${seconds.toFixed(2)}s: frame ${frame}`);
}
