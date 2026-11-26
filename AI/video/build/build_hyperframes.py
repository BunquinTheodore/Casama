"""Write the HyperFrames project (index.html and one composition per scene) from timeline.json and metrics.json.

Every picture lands on the word that says it: the beat times come from timeline.json, which is built from the
narration timings. Run again after the real narration is rendered and the timings change.

Run: python video/build/build_hyperframes.py   (from the AI folder, after src/build_timeline.py)
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from common import scene_file  # noqa: E402
from scenes_a import data, idea, problem, title  # noqa: E402
from scenes_b import algorithm, app, results  # noqa: E402
from scenes_c import credits, limits, privacy  # noqa: E402

AI = HERE.parents[1]
VIDEO = AI / "video"
PROJECT = VIDEO / "hyperframes"
BUILDERS = {
    "title": title, "problem": problem, "idea": idea, "data": data, "algorithm": algorithm,
    "results": results, "app": app, "privacy": privacy, "limits": limits, "credits": credits,
}

# One day in Aruba (2011-04-17), hour by hour, from the real derived series: H at home, . away. Checked against the raw labels.
ARUBA_DAY = "HHHHHHHHHH..HHHHHHHHHHHH"


def habit_grid(seed: dict) -> list[float]:
    """The week grid of one demo housemate: mean of the three demo weeks for each of the 168 slots."""
    best, best_spread = None, -1.0
    for text in seed["members"].values():
        weeks = [text[i * 168:(i + 1) * 168] for i in range(len(text) // 168)]
        values = [sum(int(week[s]) for week in weeks) / len(weeks) for s in range(168)]
        spread = max(values) - min(values)
        mean = sum(values) / 168
        variance = sum((v - mean) ** 2 for v in values)
        if variance > best_spread:
            best, best_spread = values, variance
    return best


INDEX = """<!doctype html>
<html lang="en" data-resolution="landscape">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=1920, height=1080" />
    <script src="https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/gsap.min.js"></script>
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body { margin: 0; width: 1920px; height: 1080px; overflow: hidden; background: #FFF8F1; }
    </style>
  </head>
  <body>
    <div id="root" data-composition-id="main" data-start="0" data-duration="__TOTAL__" data-width="1920" data-height="1080">
__HOSTS__
__AUDIO__
    </div>
    <script>
      const tl = gsap.timeline({ paused: true });
      window.__timelines["main"] = tl;
      tl.seek(0);
    </script>
  </body>
</html>
"""


def main() -> None:
    timeline = json.loads((VIDEO / "timeline.json").read_text(encoding="utf-8"))
    metrics = json.loads((AI / "output" / "metrics.json").read_text(encoding="utf-8"))
    seed = json.loads((AI / "output" / "demo_presence.json").read_text(encoding="utf-8"))
    ctx = {"metrics": metrics, "grid": habit_grid(seed), "aruba_day": [c == "H" for c in ARUBA_DAY]}

    (PROJECT / "compositions").mkdir(parents=True, exist_ok=True)
    hosts = []
    for index, scene in enumerate(timeline["scenes"]):
        body, css, js = BUILDERS[scene["id"]](scene, ctx)
        (PROJECT / "compositions" / f"{scene['id']}.html").write_text(scene_file(scene, body, css, js, first=index == 0), encoding="utf-8")
        hosts.append(
            f'      <div id="{scene["id"]}" data-composition-id="{scene["id"]}" data-composition-src="compositions/{scene["id"]}.html" '
            f'data-start="{scene["start"]}" data-duration="{scene["duration"]}" data-track-index="{index + 1}" data-track-kind="graphics" '
            f'data-width="1920" data-height="1080"></div>'
        )
    audio = ""
    if (PROJECT / "assets" / "sound.m4a").exists():
        audio = f'      <audio id="sound" src="assets/sound.m4a" data-start="0" data-duration="{timeline["total"]}" data-volume="1"></audio>'
    html = INDEX.replace("__TOTAL__", str(timeline["total"])).replace("__HOSTS__", "\n".join(hosts)).replace("__AUDIO__", audio)
    (PROJECT / "index.html").write_text(html, encoding="utf-8")
    state = "estimated timings" if timeline["estimated"] else "real narration timings"
    print(f"wrote index.html and {len(hosts)} scenes, {timeline['total'] / 60:.2f} minutes ({state})")


if __name__ == "__main__":
    main()
