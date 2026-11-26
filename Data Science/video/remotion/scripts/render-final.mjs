// Memory friendly final render: the picture in chunks (one browser worker, finished chunks are kept), the narration
// built separately (scripts/mix-sound.mjs: narration plus sound effects), then both joined. Safe to run again after an
// interruption.
// Usage: npm run render:final   (after python src/make_voice.py and npm run sync)
import {spawnSync} from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";

const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const FPS = 30;
const CHUNK_FRAMES = 2500;
const timings = JSON.parse(fs.readFileSync(path.join(project, "public", "data", "timings.json"), "utf8"));
const frames = timings.map((t) => Math.ceil(t.seconds * FPS));
const total = frames.reduce((a, b) => a + b, 0);
const outDir = path.join(project, "out");
const chunkDir = path.join(outDir, "chunks");
fs.mkdirSync(chunkDir, {recursive: true});
const slash = (p) => p.replaceAll("\\", "/");

const run = (command, args, shell = false) => {
  const result = spawnSync(command, args, {stdio: "inherit", cwd: project, shell});
  if (result.status !== 0) throw new Error(`${command} ${args.slice(0, 3).join(" ")} failed with status ${result.status}`);
};

// 1. the picture, chunk by chunk (a half written chunk never counts: it is renamed only when finished)
const parts = [];
for (let start = 0, index = 0; start < total; start += CHUNK_FRAMES, index += 1) {
  const end = Math.min(start + CHUNK_FRAMES, total) - 1;
  const file = path.join(chunkDir, `part-${String(index).padStart(2, "0")}.mp4`);
  parts.push(file);
  if (fs.existsSync(file)) {
    console.log(`chunk ${index}: already rendered, skipping`);
    continue;
  }
  const temporary = file.replace(/\.mp4$/, ".tmp.mp4");
  console.log(`chunk ${index}: frames ${start} to ${end}`);
  // the shell would split a path containing a space ("Data Science"), so Remotion gets a path relative to the project
  run("npx", ["remotion", "render", "Explorer", slash(path.relative(project, temporary)), `--frames=${start}-${end}`, "--muted", "--concurrency=1", "--crf=24"], true);
  fs.renameSync(temporary, file);
}
const list = path.join(chunkDir, "list.txt");
fs.writeFileSync(list, parts.map((p) => `file '${slash(p)}'`).join("\n"));
const silent = path.join(outDir, "video-only.mp4");
run("ffmpeg", ["-y", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", list, "-c", "copy", silent]);

// 2. the sound: narration (Brian) aligned to the pictures, with the sound effect track under it (scripts/mix-sound.mjs)
const final = path.join(outDir, "theoraux-data-science.mp4");
const sound = path.join(outDir, "sound.m4a");
run("node", ["scripts/mix-sound.mjs"]);
if (fs.existsSync(sound)) {
  run("ffmpeg", ["-y", "-loglevel", "error", "-i", silent, "-i", sound, "-c:v", "copy", "-c:a", "copy", "-shortest", final]);
} else {
  fs.copyFileSync(silent, final);
  console.log("no audio in the timings: wrote a silent video");
}
console.log(`done: ${final}`);
