"""Turn video/script.md into video/narration.json, one entry per scene, with every number filled from metrics.json.

Only this text is sent to the voice service. Member names stay on the credits card and never appear here.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from build_readme import render
from config import OUTPUT_DIR, ROOT

SCRIPT = ROOT / "video" / "script.md"
NARRATION = ROOT / "video" / "narration.json"
SCENE_IDS = ["title", "problem", "idea", "data", "algorithm", "results", "app", "privacy", "limits", "credits"]
HEADING = re.compile(r"^## (\w+)\s*$", re.M)


def parse_scenes(text: str) -> list[tuple[str, str]]:
    parts = HEADING.split(text)  # ["preamble", id, body, id, body, ...]
    return [(parts[i], " ".join(parts[i + 1].split())) for i in range(1, len(parts), 2)]


def build_script(metrics: dict, template: Path = SCRIPT, out_path: Path = NARRATION) -> list[dict]:
    parsed = parse_scenes(template.read_text(encoding="utf-8"))
    if [scene_id for scene_id, _ in parsed] != SCENE_IDS:
        raise ValueError(f"the script must have exactly these scenes in order: {SCENE_IDS}")
    scenes = [{"id": scene_id, "text": " ".join(render(body, metrics).split())} for scene_id, body in parsed]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(scenes, indent=2, ensure_ascii=False), encoding="utf-8")
    return scenes


if __name__ == "__main__":
    result = build_script(json.loads((OUTPUT_DIR / "metrics.json").read_text(encoding="utf-8")))
    print(sum(len(s["text"].split()) for s in result), "words,", sum(len(s["text"]) for s in result), "characters in", len(result), "scenes")
