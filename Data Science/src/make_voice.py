"""Generate the narration audio with ElevenLabs, one mp3 per scene, and write scene_timings.json.

The key comes from ELEVENLABS_API_KEY in the git ignored .env.local at the repository root. It is never printed.
Only the narration text is sent to ElevenLabs. A full render is refused up front when the account has too few
characters left, so a render never stops half way. --estimate writes timings from the word count instead, so the
video can be built while credits are short.

Usage (from the Data Science folder):
  python src/make_voice.py --dry-run     characters per scene, no key needed
  python src/make_voice.py --sample      render only the first scene to audio/sample.mp3
  python src/make_voice.py               render every scene (scenes already rendered for the same text are skipped)
  python src/make_voice.py --estimate    timings from word count, no audio and no key
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import subprocess
from pathlib import Path

from elevenlabs.core.api_error import ApiError

from config import ROOT

AUDIO_DIR = ROOT / "video" / "audio"
TIMINGS = ROOT / "video" / "scene_timings.json"
NARRATION = ROOT / "video" / "narration.json"
DEFAULT_VOICE = "nPczCjzI2devNBz1zQrb"  # Brian, the premade ElevenLabs narrator voice the user prefers
MODEL = "eleven_multilingual_v2"
WORDS_PER_MINUTE = 150
SCENE_GAP_SECONDS = 0.6          # used by the word count estimate only
SCENE_LEAD_SECONDS = 0.6         # the scene moves before the voice starts
SCENE_TAIL_SECONDS = 1.5         # silence after each real scene
LAST_SCENE_EXTRA_SECONDS = 6.0   # extra hold on the references and credits scene


class MissingKeyError(RuntimeError):
    pass


class InsufficientCreditsError(RuntimeError):
    pass


def load_scenes() -> list[dict]:
    return json.loads(NARRATION.read_text(encoding="utf-8"))


def load_client(env_file: Path | None = None):
    from dotenv import find_dotenv, load_dotenv
    from elevenlabs.client import ElevenLabs

    load_dotenv(env_file if env_file else find_dotenv(".env.local"))
    key = os.getenv("ELEVENLABS_API_KEY")
    if not key:
        raise MissingKeyError("ELEVENLABS_API_KEY is not set. Put it in .env.local at the repository root (git ignored).")
    return ElevenLabs(api_key=key)


def audio_seconds(path: Path) -> float:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        capture_output=True, text=True, check=True,
    )
    return float(out.stdout.strip())


def check_credits(client, needed: int) -> int | None:
    """Refuse a render the account cannot finish. A restricted key without the user_read permission cannot read the
    balance, so the check is skipped for it (progress is still saved after every scene) and None is returned."""
    try:
        sub = client.user.subscription.get()
    except ApiError as error:
        if error.status_code == 401 and "missing_permissions" in str(error.body):
            print("note: this key cannot read the account balance (it lacks the user_read permission), so the credit check is skipped.")
            return None
        raise
    remaining = sub.character_limit - sub.character_count
    if needed > remaining:
        raise InsufficientCreditsError(
            f"the narration needs {needed} characters but the account has {remaining} left of {sub.character_limit}"
        )
    return remaining


def _render(client, text: str, voice_id: str) -> tuple[bytes, dict]:
    """Speak `text` and return the mp3 bytes with the start and end second of every character."""
    from elevenlabs import VoiceSettings

    result = client.text_to_speech.convert_with_timestamps(
        text=text,
        voice_id=voice_id,
        model_id=MODEL,
        output_format="mp3_44100_128",
        voice_settings=VoiceSettings(stability=0.5, similarity_boost=0.75, style=0.0, use_speaker_boost=True, speed=1.0),
    )
    heard = result.alignment
    alignment = {
        "characters": list(heard.characters),
        "starts": [round(float(x), 3) for x in heard.character_start_times_seconds],
        "ends": [round(float(x), 3) for x in heard.character_end_times_seconds],
    }
    return base64.b64decode(result.audio_base_64), alignment


def build_cues(scenes: list[dict], out_dir: Path, cues_path: Path) -> dict:
    """One file with the time of every spoken character, so the picture can follow the words that are said."""
    cues = {}
    for scene in scenes:
        saved = json.loads((out_dir / f"{scene['id']}.alignment.json").read_text(encoding="utf-8"))
        if "".join(saved["characters"]) != scene["text"]:
            raise ValueError(f"the saved timing for scene {scene['id']} does not match its text; render it again")
        cues[scene["id"]] = {"text": scene["text"], "starts": saved["starts"], "ends": saved["ends"]}
    cues_path.write_text(json.dumps(cues), encoding="utf-8")
    return cues


def phrase_time(cue: dict, phrase: str) -> float:
    """The second at which `phrase` starts to be spoken in one scene."""
    index = cue["text"].find(phrase)
    if index < 0:
        raise KeyError(f"{phrase!r} is not in the narration")
    return cue["starts"][index]


def _digest(text: str, voice_id: str) -> str:
    return hashlib.sha256(f"{voice_id}|{MODEL}|{text}".encode("utf-8")).hexdigest()


def synthesize(
    scenes: list[dict],
    voice_id: str = DEFAULT_VOICE,
    out_dir: Path = AUDIO_DIR,
    client=None,
    timings_path: Path = TIMINGS,
    cues_path: Path | None = None,
) -> list[dict]:
    """Render every scene that is not already rendered for exactly this text and voice, and write the timings.

    A manifest of text hashes sits next to the mp3 files and is saved after each scene, so a dropped connection
    keeps what is finished and a re-run bills only the scenes that are missing or whose text changed.
    """
    out_dir.mkdir(parents=True, exist_ok=True)
    cues_path = cues_path or out_dir.parent / "cues.json"
    manifest_path = out_dir / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}

    def is_cached(scene: dict) -> bool:
        entry = manifest.get(scene["id"])
        done = (out_dir / f"{scene['id']}.mp3").exists() and (out_dir / f"{scene['id']}.alignment.json").exists()
        return bool(entry) and entry["digest"] == _digest(scene["text"], voice_id) and done

    todo = [scene for scene in scenes if not is_cached(scene)]
    if todo:
        client = client or load_client()
        check_credits(client, sum(len(scene["text"]) for scene in todo))  # refuse before spending anything
    for scene in todo:
        target = out_dir / f"{scene['id']}.mp3"
        audio, alignment = _render(client, scene["text"], voice_id)
        target.write_bytes(audio)
        (out_dir / f"{scene['id']}.alignment.json").write_text(json.dumps(alignment), encoding="utf-8")
        manifest[scene["id"]] = {"digest": _digest(scene["text"], voice_id), "seconds": round(audio_seconds(target), 2)}
        manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    timings = []
    for index, scene in enumerate(scenes):
        audio = manifest[scene["id"]]["seconds"]
        # a breath after every scene, and a longer hold on the last one so the references can be read
        tail = SCENE_TAIL_SECONDS + (LAST_SCENE_EXTRA_SECONDS if index == len(scenes) - 1 else 0.0)
        timings.append(
            {
                "id": scene["id"], "file": f"audio/{scene['id']}.mp3", "audio_seconds": audio,
                "lead_seconds": SCENE_LEAD_SECONDS, "seconds": round(SCENE_LEAD_SECONDS + audio + tail, 2), "estimated": False,
            }
        )
    timings_path.write_text(json.dumps(timings, indent=2), encoding="utf-8")
    build_cues(scenes, out_dir, cues_path)
    return timings


def estimate_timings(scenes: list[dict], timings_path: Path = TIMINGS) -> list[dict]:
    timings = [
        {"id": s["id"], "file": None, "seconds": round(len(s["text"].split()) / WORDS_PER_MINUTE * 60 + SCENE_GAP_SECONDS, 2), "estimated": True}
        for s in scenes
    ]
    timings_path.write_text(json.dumps(timings, indent=2), encoding="utf-8")
    return timings


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--sample", action="store_true")
    parser.add_argument("--estimate", action="store_true")
    parser.add_argument("--force", action="store_true", help="let --estimate overwrite real audio timings")
    parser.add_argument("--voice", default=DEFAULT_VOICE)
    args = parser.parse_args(argv)
    scenes = load_scenes()

    if args.dry_run:
        for scene in scenes:
            print(f"{scene['id']:<10} {len(scene['text']):>5} characters, {len(scene['text'].split()):>4} words")
        print(f"{'total':<10} {sum(len(s['text']) for s in scenes):>5} characters")
        return 0
    if args.estimate:
        existing = json.loads(TIMINGS.read_text(encoding="utf-8")) if TIMINGS.exists() else []
        if any(not t.get("estimated", True) for t in existing) and not args.force:
            print("scene_timings.json holds real audio timings. --estimate would replace them with a silent draft; add --force to do that.")
            return 1
        total = sum(t["seconds"] for t in estimate_timings(scenes, timings_path=TIMINGS))
        print(f"estimated timings written, about {total / 60:.1f} minutes")
        return 0
    if args.sample:
        client = load_client()
        check_credits(client, len(scenes[0]["text"]))
        AUDIO_DIR.mkdir(parents=True, exist_ok=True)
        (AUDIO_DIR / "sample.mp3").write_bytes(_render(client, scenes[0]["text"], args.voice)[0])
        print(f"sample written: {AUDIO_DIR / 'sample.mp3'}")
        return 0
    timings = synthesize(scenes, voice_id=args.voice, out_dir=AUDIO_DIR, timings_path=TIMINGS)
    print(f"rendered {len(timings)} scenes, {sum(t['seconds'] for t in timings) / 60:.1f} minutes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
