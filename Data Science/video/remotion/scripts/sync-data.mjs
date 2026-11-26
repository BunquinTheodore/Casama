// Copies the single sources of truth into public/ so the composition reads findings.json, series.json and the
// narration timings (and the audio and fonts) through staticFile(). Nothing is edited on the way.
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const project = path.resolve(here, "..");
const ds = path.resolve(project, "..", "..");
const jobs = [
  [path.join(ds, "output", "findings.json"), path.join(project, "public", "data", "findings.json")],
  [path.join(ds, "output", "series.json"), path.join(project, "public", "data", "series.json")],
  [path.join(ds, "output", "reuse_ph_2026.json"), path.join(project, "public", "data", "reuse.json")],
  [path.join(ds, "video", "scene_timings.json"), path.join(project, "public", "data", "timings.json")],
  [path.join(ds, "video", "cues.json"), path.join(project, "public", "data", "cues.json")],
];
const fontDir = path.join(ds, "explorer", "fonts");
for (const f of fs.readdirSync(fontDir).filter((n) => n.endsWith(".woff2"))) {
  jobs.push([path.join(fontDir, f), path.join(project, "public", "fonts", f)]);
}
const audioDir = path.join(ds, "video", "audio");
if (fs.existsSync(audioDir)) {
  for (const f of fs.readdirSync(audioDir).filter((n) => n.endsWith(".mp3") && n !== "sample.mp3")) {
    jobs.push([path.join(audioDir, f), path.join(project, "public", "audio", f)]);
  }
}
for (const [from, to] of jobs) {
  fs.mkdirSync(path.dirname(to), {recursive: true});
  fs.copyFileSync(from, to);
}
console.log(`synced ${jobs.length} files into public/`);
