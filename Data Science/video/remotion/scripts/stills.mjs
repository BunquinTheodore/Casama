// Renders one still per scene (default: 92 percent of the way through, after every element has appeared) for review.
// Usage: node scripts/stills.mjs [fractions, comma separated] [scene ids, comma separated] [out dir]
// Example: node scripts/stills.mjs 0.25,0.6,0.95 title,question
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";
import {bundle} from "@remotion/bundler";
import {renderStill, selectComposition} from "@remotion/renderer";

const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const fractions = String(process.argv[2] ?? "0.92").split(",").map(Number);
const only = process.argv[3] ? process.argv[3].split(",") : null;
const outDir = path.resolve(process.argv[4] ?? path.join(project, "out", "stills"));
fs.mkdirSync(outDir, {recursive: true});

const timings = JSON.parse(fs.readFileSync(path.join(project, "public", "data", "timings.json"), "utf8"));
const serveUrl = await bundle({entryPoint: path.join(project, "src", "index.ts")});
const composition = await selectComposition({serveUrl, id: "Explorer"});
let start = 0;
for (const t of timings) {
  const frames = Math.ceil(t.seconds * 30);
  for (const fraction of only && !only.includes(t.id) ? [] : fractions) {
    const frame = start + Math.min(frames - 1, Math.floor(frames * fraction));
    await renderStill({composition, serveUrl, frame, output: path.join(outDir, `${t.id}-${Math.round(fraction * 100)}.png`), imageFormat: "png"});
    console.log(`${t.id} at ${Math.round(fraction * 100)} percent: frame ${frame}`);
  }
  start += frames;
}
