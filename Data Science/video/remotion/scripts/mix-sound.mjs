// The sound of the video without the picture: every scene's narration delayed to the start of its scene plus its lead in
// (the pictures are timed to the words from that moment), the sound effect track (scripts/sfx-track.mjs) mixed under it,
// padded to the full length and limited below full scale. Writes out/sound.m4a. Usage: npm run sound (after npm run sync)
import {spawnSync} from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";

const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const FPS = 30;
// The narration is recorded quietly (about -23 LUFS), so the whole mix is raised and a limiter holds the peaks just under full scale.
const MAKEUP_GAIN_DB = 6;
const PEAK_LIMIT = 0.89;
const timings = JSON.parse(fs.readFileSync(path.join(project, "public", "data", "timings.json"), "utf8"));
const frames = timings.map((t) => Math.ceil(t.seconds * FPS));
const total = frames.reduce((a, b) => a + b, 0);
const outDir = path.join(project, "out");
fs.mkdirSync(outDir, {recursive: true});
const sound = path.join(outDir, "sound.m4a");

const run = (command, args) => {
  const result = spawnSync(command, args, {stdio: "inherit", cwd: project});
  if (result.status !== 0) throw new Error(`${command} ${args.slice(0, 3).join(" ")} failed with status ${result.status}`);
};

const scenes = [];
let startFrame = 0;
timings.forEach((t, i) => {
  if (t.file) scenes.push({file: path.join(project, "public", t.file), startMs: Math.round((startFrame / FPS + (t.lead_seconds ?? 0)) * 1000)});
  startFrame += frames[i];
});

if (scenes.length === 0) {
  fs.rmSync(sound, {force: true});
  console.log("no audio in the timings: no sound written");
} else {
  run("node", ["scripts/sfx-track.mjs"]);
  const inputs = [...scenes.flatMap((s) => ["-i", s.file]), "-i", path.join(outDir, "sfx.wav")];
  const delays = scenes.map((s, i) => `[${i}:a]adelay=${s.startMs}|${s.startMs}[a${i}]`).join(";");
  // the mixed speech ends with the last word, so it is padded with silence to the full length of the picture
  // (otherwise -shortest would cut the pause and the hold on the references scene off the end of the video)
  const speech = `${scenes.map((_, i) => `[a${i}]`).join("")}amix=inputs=${scenes.length}:normalize=0:duration=longest[mix];[mix]apad=whole_dur=${(total / FPS).toFixed(3)}[speech]`;
  const together = `[speech][${scenes.length}:a]amix=inputs=2:normalize=0:duration=first[sum];[sum]volume=${MAKEUP_GAIN_DB}dB,alimiter=limit=${PEAK_LIMIT}:level=disabled[out]`;
  run("ffmpeg", ["-y", "-loglevel", "error", ...inputs, "-filter_complex", `${delays};${speech};${together}`, "-map", "[out]", "-ac", "2", "-t", String(total / FPS), "-c:a", "aac", "-b:a", "160k", sound]);
  console.log(`wrote ${scenes.length} narrated scenes and the sound effects to out/sound.m4a`);
}
