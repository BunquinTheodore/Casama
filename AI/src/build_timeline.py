"""Turn the scene timings, the narration and the beats table into video/timeline.json for the video.

For every scene: when it starts in the video, how long it lasts, and for every beat the second (inside the scene)
at which its phrase starts to be spoken. With real narration the second comes from the per character timings
(video/cues.json). Before the narration is rendered, it is spread over the draft audio length by character position.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

from config import ROOT

VIDEO = ROOT / "video"
FPS = 30


def frames(seconds: float) -> int:
    return math.ceil(seconds * FPS)


def phrase_index(text: str, phrase: str, scene: str, key: str) -> int:
    count = text.count(phrase)
    if count != 1:
        raise KeyError(f"beat {scene}.{key}: the phrase {phrase!r} occurs {count} times in the narration, it must occur once")
    return text.index(phrase)


def beat_seconds(scene: dict, timing: dict, cue: dict | None, phrase: str, key: str, shift: float = 0.0) -> float:
    index = phrase_index(scene["text"], phrase, scene["id"], key)
    lead = timing.get("lead_seconds", 0.0)
    if cue is not None:
        return round(lead + cue["starts"][index] + shift, 3)
    return round(lead + timing["audio_seconds"] * index / max(len(scene["text"]), 1) + shift, 3)


def build_timeline(
    narration: list[dict], timings: list[dict], beats: dict, cues: dict | None = None
) -> dict:
    by_id = {t["id"]: t for t in timings}
    scenes, start = [], 0
    for scene in narration:
        timing = by_id[scene["id"]]
        cue = None if timing.get("estimated", True) or not cues else cues[scene["id"]]
        if cue is not None and "".join(cue["text"]) != scene["text"]:
            raise ValueError(f"the saved timing for scene {scene['id']} does not match its narration; render it again")
        duration_frames = frames(timing["seconds"])
        scene_beats = {}
        for key, beat in beats[scene["id"]].items():
            at = beat_seconds(scene, timing, cue, beat["phrase"], key, beat.get("shift", 0.0))
            if not 0 <= at < duration_frames / FPS:
                raise ValueError(f"beat {scene['id']}.{key} at {at}s is outside its scene ({duration_frames / FPS}s)")
            scene_beats[key] = {"at": at, "sfx": beat.get("sfx")}
        scenes.append(
            {
                "id": scene["id"],
                "start": round(start / FPS, 4),
                "duration": round(duration_frames / FPS, 4),
                "lead": timing.get("lead_seconds", 0.0),
                "audio": timing.get("file"),
                "beats": scene_beats,
            }
        )
        start += duration_frames
    return {"fps": FPS, "total": round(start / FPS, 4), "estimated": any(t.get("estimated", True) for t in timings), "scenes": scenes}


def main() -> None:
    narration = json.loads((VIDEO / "narration.json").read_text(encoding="utf-8"))
    timings = json.loads((VIDEO / "scene_timings.json").read_text(encoding="utf-8"))
    beats = json.loads((VIDEO / "beats.json").read_text(encoding="utf-8"))
    cues_path = VIDEO / "cues.json"
    cues = json.loads(cues_path.read_text(encoding="utf-8")) if cues_path.exists() else None
    timeline = build_timeline(narration, timings, beats, cues)
    (VIDEO / "timeline.json").write_text(json.dumps(timeline, indent=1), encoding="utf-8")
    kind = "estimated" if timeline["estimated"] else "from the real narration"
    print(f"timeline: {timeline['total'] / 60:.2f} minutes, {len(timeline['scenes'])} scenes, "
          f"{sum(len(s['beats']) for s in timeline['scenes'])} beats ({kind})")


if __name__ == "__main__":
    main()
