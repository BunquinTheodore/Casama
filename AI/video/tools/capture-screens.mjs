// Takes screenshots of the real Casama web build with headless Chrome (DevTools protocol, no extra packages).
// Usage: node capture-screens.mjs <base url> <out dir> <shots.json>
// A shot: {name, hash, width, height, dpr, waitMs, steps: [{click:[x,y]} | {scroll:[x,y,deltaY]} | {wait:ms}]}
// Example: node capture-screens.mjs http://127.0.0.1:8099 ../../output/screens shots.json
import {spawn} from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const [, , baseUrl, outDir, shotsFile] = process.argv;
if (!baseUrl || !outDir || !shotsFile) throw new Error("usage: node capture-screens.mjs <base url> <out dir> <shots.json>");
const shots = JSON.parse(fs.readFileSync(shotsFile, "utf8"));
fs.mkdirSync(outDir, {recursive: true});

const chromePath = process.env.CHROME ?? "C:/Program Files/Google/Chrome/Application/chrome.exe";
const port = 9333;
const profile = fs.mkdtempSync(path.join(process.env.TEMP ?? ".", "capture-profile-"));
const chrome = spawn(chromePath, ["--headless=new", "--disable-gpu", "--hide-scrollbars", `--remote-debugging-port=${port}`, `--user-data-dir=${profile}`, "about:blank"], {stdio: "ignore"});
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function pageSocket() {
  for (let attempt = 0; attempt < 40; attempt += 1) {
    try {
      const list = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
      const page = list.find((t) => t.type === "page");
      if (page) return page.webSocketDebuggerUrl;
    } catch {
      /* Chrome is still starting */
    }
    await sleep(250);
  }
  throw new Error("Chrome did not start");
}

const socket = new WebSocket(await pageSocket());
await new Promise((resolve, reject) => {
  socket.onopen = resolve;
  socket.onerror = reject;
});
let nextId = 1;
const waiting = new Map();
socket.onmessage = (event) => {
  const message = JSON.parse(event.data);
  if (message.id && waiting.has(message.id)) {
    waiting.get(message.id)(message);
    waiting.delete(message.id);
  }
};
const send = (method, params = {}) =>
  new Promise((resolve, reject) => {
    const id = nextId++;
    waiting.set(id, (message) => (message.error ? reject(new Error(`${method}: ${message.error.message}`)) : resolve(message.result)));
    socket.send(JSON.stringify({id, method, params}));
  });

const click = async (x, y) => {
  for (const type of ["mousePressed", "mouseReleased"]) {
    await send("Input.dispatchMouseEvent", {type, x, y, button: "left", clickCount: 1});
  }
};

try {
  for (const shot of shots) {
    await send("Emulation.setDeviceMetricsOverride", {width: shot.width, height: shot.height, deviceScaleFactor: shot.dpr ?? 1, mobile: shot.width < 600});
    await send("Page.navigate", {url: "about:blank"});
    await send("Page.navigate", {url: `${baseUrl}/#${shot.hash}`});
    await sleep(shot.waitMs ?? 7000);
    for (const step of shot.steps ?? []) {
      if (step.click) await click(...step.click);
      if (step.scroll) await send("Input.dispatchMouseEvent", {type: "mouseWheel", x: step.scroll[0], y: step.scroll[1], deltaX: 0, deltaY: step.scroll[2]});
      await sleep(step.wait ?? 1500);
    }
    const {data} = await send("Page.captureScreenshot", {format: "png"});
    fs.writeFileSync(path.join(outDir, `${shot.name}.png`), Buffer.from(data, "base64"));
    console.log("saved", shot.name);
  }
} finally {
  socket.close();
  chrome.kill();
  await sleep(1500);
  try {
    fs.rmSync(profile, {recursive: true, force: true});
  } catch {
    /* Chrome may still hold the profile for a moment; the temp folder is harmless */
  }
}
