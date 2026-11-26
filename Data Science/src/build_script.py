"""Turn video/script.md into narration.json, one entry per scene, with every number filled from findings.json.

Only this text is sent to the voice service. Member names stay on the credits card and never appear here.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from build_explorer import page_data, render_placeholders, select_variants
from config import OUT_DIR, ROOT

SCRIPT = ROOT / "video" / "script.md"
NARRATION = ROOT / "video" / "narration.json"
SCENE_IDS = ["title", "question", "data", "cleaning", "shows", "weather", "model", "takeaways", "casama", "limits", "credits"]
HEADING = re.compile(r"^## (\w+)\s*$", re.M)


def parse_scenes(text: str) -> list[tuple[str, str]]:
    parts = HEADING.split(text)  # ["preamble", id, body, id, body, ...]
    return [(parts[i], " ".join(parts[i + 1].split())) for i in range(1, len(parts), 2)]


def build_script(
    findings: dict,
    template: Path = SCRIPT,
    out_path: Path = NARRATION,
    reuse: dict | None = None,
) -> list[dict]:
    reuse = reuse or json.loads((OUT_DIR / "reuse_ph_2026.json").read_text(encoding="utf-8"))
    data = page_data(findings, reuse)
    parsed = parse_scenes(template.read_text(encoding="utf-8"))
    if [scene_id for scene_id, _ in parsed] != SCENE_IDS:
        raise ValueError(f"the script must have exactly these scenes in order: {SCENE_IDS}")
    scenes = [
        {"id": scene_id, "text": " ".join(render_placeholders(select_variants(body, data), data).split())}
        for scene_id, body in parsed
    ]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(scenes, indent=2, ensure_ascii=False), encoding="utf-8")
    return scenes


if __name__ == "__main__":
    result = build_script(json.loads((OUT_DIR / "findings.json").read_text(encoding="utf-8")))
    print(sum(len(s["text"].split()) for s in result), "words in", len(result), "scenes")
