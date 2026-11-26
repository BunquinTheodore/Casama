"""The sound of the video without the picture.

Every scene's narration is delayed to the start of its scene plus its lead in (the pictures are timed to the words
from that moment), the sound effect track is mixed under it, padded to the full length and limited below full
scale. Output: video/sound.m4a and video/sfx-cues.json. The effects are original sounds from src/make_sfx.py.

Run: python src/mix_sound.py   (after build_timeline.py and the narration render)
"""

from __future__ import annotations

import json
import subprocess
import wave
from pathlib import Path

import numpy as np

from config import ROOT

RATE = 48000
CHANNELS = 2
VIDEO = ROOT / "video"
SFX_DIR = VIDEO / "sfx"
SCENE_WHOOSH_LEAD_SECONDS = 0.05  # the whoosh starts just before the wipe so the sound arrives with the picture
# Level of each effect before mixing. The narration peaks near full scale, so the effects sit well under it.
GAIN_DB = {"whoosh": -17.0, "swish": -19.0, "pop": -16.0, "tick": -19.0, "chime": -18.0, "thud": -17.0, "rise": -20.0}
MIN_GAP_SECONDS = {"whoosh": 0.9, "swish": 0.4, "rise": 1.0, "chime": 0.8, "thud": 0.5, "pop": 0.25, "tick": 0.2}
MAKEUP_GAIN_DB = 6.0  # the narration is recorded quietly, so the whole mix is raised and a limiter holds the peaks
PEAK_LIMIT = 0.89


def sfx_cues(timeline: dict) -> list[dict]:
    """The list of effects with their absolute times in the video, in time order, with too close repeats dropped."""
    cues = []
    for index, scene in enumerate(timeline["scenes"]):
        if index > 0:
            cues.append({"at": max(0.0, scene["start"] - SCENE_WHOOSH_LEAD_SECONDS), "kind": "whoosh", "gain_db": GAIN_DB["whoosh"], "source": f"scene:{scene['id']}"})
        for key, beat in scene["beats"].items():
            if beat.get("sfx"):
                cues.append({"at": scene["start"] + beat["at"], "kind": beat["sfx"], "gain_db": GAIN_DB[beat["sfx"]], "source": f"{scene['id']}.{key}"})
    cues.sort(key=lambda c: c["at"])
    last: dict[str, float] = {}
    kept = []
    for cue in cues:
        previous = last.get(cue["kind"])
        if previous is not None and cue["at"] - previous < MIN_GAP_SECONDS.get(cue["kind"], 0.25):
            continue
        last[cue["kind"]] = cue["at"]
        kept.append(cue)
    return kept


def read_wav(path: Path) -> np.ndarray:
    """A 16 bit stereo PCM wav at 48 kHz as an array of shape (frames, 2)."""
    with wave.open(str(path), "rb") as handle:
        if (handle.getnchannels(), handle.getsampwidth(), handle.getframerate()) != (CHANNELS, 2, RATE):
            raise ValueError(f"{path} must be 16 bit stereo PCM at {RATE} Hz")
        data = np.frombuffer(handle.readframes(handle.getnframes()), dtype="<i2")
    return data.reshape(-1, CHANNELS).astype(np.int32)


def render_track(cues: list[dict], total_seconds: float, sfx_dir: Path = SFX_DIR) -> np.ndarray:
    """Mixes every cue into one stereo 16 bit track of the given length. Overlaps add and saturate, never wrap."""
    out = np.zeros((int(np.ceil(total_seconds * RATE)), CHANNELS), dtype=np.int64)
    cache: dict[str, np.ndarray] = {}
    for cue in cues:
        if cue["kind"] not in cache:
            cache[cue["kind"]] = read_wav(sfx_dir / f"{cue['kind']}.wav")
        samples = cache[cue["kind"]]
        start = int(round(cue["at"] * RATE))
        scaled = np.round(samples * 10 ** (cue["gain_db"] / 20)).astype(np.int64)
        end = min(start + len(scaled), len(out))
        if start < end:
            out[start:end] += scaled[: end - start]
    return np.clip(out, -32767, 32767).astype(np.int16)


def write_wav(path: Path, samples: np.ndarray) -> None:
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(CHANNELS)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes(samples.astype("<i2").tobytes())


def mix(timeline: dict, audio_dir: Path = VIDEO, out: Path = VIDEO / "sound.m4a") -> int:
    """Narration at its scene starts plus the effect track, written as aac. Returns the number of narrated scenes."""
    cues = sfx_cues(timeline)
    sfx_path = out.with_name("sfx.wav")
    write_wav(sfx_path, render_track(cues, timeline["total"]))
    (out.with_name("sfx-cues.json")).write_text(json.dumps([{**c, "at": round(c["at"], 3)} for c in cues], indent=1), encoding="utf-8")
    scenes = [(audio_dir / s["audio"], round((s["start"] + s["lead"]) * 1000)) for s in timeline["scenes"] if s["audio"]]
    if not scenes:
        out.unlink(missing_ok=True)
        print("no narration audio in the timeline: only sfx.wav was written")
        return 0
    inputs = [arg for path, _ in scenes for arg in ("-i", str(path))] + ["-i", str(sfx_path)]
    delays = ";".join(f"[{i}:a]adelay={ms}|{ms}[a{i}]" for i, (_, ms) in enumerate(scenes))
    speech = "".join(f"[a{i}]" for i in range(len(scenes))) + f"amix=inputs={len(scenes)}:normalize=0:duration=longest[mix];[mix]apad=whole_dur={timeline['total']:.3f}[speech]"
    together = f"[speech][{len(scenes)}:a]amix=inputs=2:normalize=0:duration=first[sum];[sum]volume={MAKEUP_GAIN_DB}dB,alimiter=limit={PEAK_LIMIT}:level=disabled[out]"
    command = ["ffmpeg", "-y", "-loglevel", "error", *inputs, "-filter_complex", f"{delays};{speech};{together}", "-map", "[out]", "-ac", "2", "-t", f"{timeline['total']:.3f}", "-c:a", "aac", "-b:a", "160k", str(out)]
    subprocess.run(command, check=True)
    return len(scenes)


if __name__ == "__main__":
    timeline = json.loads((VIDEO / "timeline.json").read_text(encoding="utf-8"))
    narrated = mix(timeline)
    print(f"wrote {len(sfx_cues(timeline))} sound effects and {narrated} narrated scenes to video/sound.m4a")
