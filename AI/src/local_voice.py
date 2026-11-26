"""Narration made on this computer with Kokoro, an open weight speech model (Apache 2.0), through kokoro-onnx.

Used when a paid ElevenLabs plan is not available. Nothing is sent anywhere: the model files sit in video/models
(git ignored) and the speech is made offline. Kokoro does not report when each word is spoken, so the text is spoken
one sentence at a time, each sentence is trimmed of its silence, and the time of every character is spread over its
sentence by its length. That is exact at sentence starts and good to a fraction of a second inside a sentence,
which is all the pictures need.
"""

from __future__ import annotations

import io
import re
import subprocess
from pathlib import Path

import numpy as np

from config import ROOT

MODELS_DIR = ROOT / "video" / "models"
MODEL_FILE = "kokoro-v1.0.onnx"
VOICES_FILE = "voices-v1.0.bin"
DEFAULT_VOICE = "am_michael"   # the American male voice with the most training audio (grade C+ on the model card)
DEFAULT_SPEED = 0.92
SENTENCE_GAP_SECONDS = 0.30
SPACE_WEIGHT = 0.6             # a space takes less time than a letter when a sentence's time is spread over it
SILENCE_THRESHOLD = 0.01
EDGE_KEEP_SECONDS = 0.04


def sentence_spans(text: str) -> list[tuple[int, int]]:
    """Start and end of every sentence in `text`. A full stop inside a number such as 0.70 does not end one."""
    spans, cursor = [], 0
    for piece in re.split(r"(?<=[.!?])\s+", text):
        if not piece:
            continue
        start = text.index(piece, cursor)
        spans.append((start, start + len(piece)))
        cursor = start + len(piece)
    return spans


def trim_silence(samples: np.ndarray, rate: int, keep_seconds: float = EDGE_KEEP_SECONDS) -> np.ndarray:
    """Cut the quiet at both ends, keeping a short margin so no word is clipped."""
    loud = np.flatnonzero(np.abs(samples) > SILENCE_THRESHOLD)
    if loud.size == 0:
        return samples
    keep = round(keep_seconds * rate)
    return samples[max(0, loud[0] - keep) : min(len(samples), loud[-1] + 1 + keep)]


def assemble(chunks: list[np.ndarray], rate: int, gap: float = SENTENCE_GAP_SECONDS) -> np.ndarray:
    """The sentences in order with `gap` seconds of silence between them (none after the last)."""
    silence = np.zeros(round(gap * rate), dtype=np.float32)
    parts: list[np.ndarray] = []
    for index, chunk in enumerate(chunks):
        if index:
            parts.append(silence)
        parts.append(chunk.astype(np.float32))
    return np.concatenate(parts) if parts else np.zeros(0, dtype=np.float32)


def build_alignment(text: str, spans: list[tuple[int, int]], durations: list[float], gap: float = SENTENCE_GAP_SECONDS) -> dict:
    """The start and end second of every character, in the shape the ElevenLabs render also saves."""
    if len(spans) != len(durations):
        raise ValueError("one duration is needed for every sentence")
    starts = [0.0] * len(text)
    ends = [0.0] * len(text)
    clock = 0.0
    previous_end = 0.0
    cursor = 0
    for (first, last), duration in zip(spans, durations):
        for index in range(cursor, first):  # the spaces between sentences take no time
            starts[index] = ends[index] = previous_end
        weights = [SPACE_WEIGHT if text[index] == " " else 1.0 for index in range(first, last)]
        total = sum(weights)
        passed = 0.0
        for offset, weight in enumerate(weights):
            starts[first + offset] = clock + duration * passed / total
            passed += weight
            ends[first + offset] = clock + duration * passed / total
        previous_end = clock + duration
        clock = previous_end + gap
        cursor = last
    for index in range(cursor, len(text)):
        starts[index] = ends[index] = previous_end
    return {
        "characters": list(text),
        "starts": [round(value, 3) for value in starts],
        "ends": [round(value, 3) for value in ends],
    }


def load_kokoro(models_dir: Path = MODELS_DIR):
    from kokoro_onnx import Kokoro

    model, voices = models_dir / MODEL_FILE, models_dir / VOICES_FILE
    missing = [path.name for path in (model, voices) if not path.exists()]
    if missing:
        raise FileNotFoundError(f"missing in {models_dir}: {', '.join(missing)} (see video/README.md for where they come from)")
    return Kokoro(str(model), str(voices))


def render_scene(text: str, kokoro, voice: str = DEFAULT_VOICE, speed: float = DEFAULT_SPEED) -> tuple[np.ndarray, int, dict]:
    """Speak one scene. Returns the samples, the sample rate and the per character timings."""
    spans = sentence_spans(text)
    chunks, rate = [], 0
    for first, last in spans:
        samples, rate = kokoro.create(text[first:last], voice=voice, speed=speed, lang="en-us")
        chunks.append(trim_silence(np.asarray(samples, dtype=np.float32), rate))
    audio = assemble(chunks, rate)
    alignment = build_alignment(text, spans, [len(chunk) / rate for chunk in chunks])
    return audio, rate, alignment


def to_mp3(samples: np.ndarray, rate: int) -> bytes:
    """Encode with ffmpeg (already needed to mix the sound) at a quality close to the ElevenLabs files."""
    import soundfile

    wav = io.BytesIO()
    soundfile.write(wav, samples, rate, format="WAV", subtype="PCM_16")
    result = subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-f", "wav", "-i", "pipe:0", "-ar", "44100", "-ac", "1",
         "-codec:a", "libmp3lame", "-b:a", "128k", "-f", "mp3", "pipe:1"],
        input=wav.getvalue(), capture_output=True, check=True,
    )
    return result.stdout
