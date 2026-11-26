"""Original sound effects, synthesized from scratch (no recordings, so no rights to clear): python src/make_sfx.py

Seven short, soft effects for the explainer video: whoosh and swish for movement, pop and tick for things appearing,
chime for a verdict, thud for an emphasis, rise for a build up. The video places them on the words they belong to.
"""

from __future__ import annotations

import wave
from pathlib import Path

import numpy as np

from config import ROOT

SAMPLE_RATE = 48000
SFX_DIR = ROOT / "video" / "sfx"
KINDS = ["whoosh", "swish", "pop", "tick", "chime", "thud", "rise"]
EDGE_SECONDS = 0.004  # fade in and out so an effect never starts or stops with a click


def _time(seconds: float) -> np.ndarray:
    return np.arange(int(seconds * SAMPLE_RATE)) / SAMPLE_RATE


def _sweep(t: np.ndarray, start_hz: float, end_hz: float) -> np.ndarray:
    """A sine whose pitch glides from start_hz to end_hz over the whole length."""
    frequency = np.linspace(start_hz, end_hz, len(t))
    return np.sin(2 * np.pi * np.cumsum(frequency) / SAMPLE_RATE)


def _band_noise(rng: np.random.Generator, n: int, low_hz: float, high_hz: float) -> np.ndarray:
    """Noise whose brightness glides from low_hz to high_hz (a one pole low pass with a moving cut off)."""
    noise = rng.standard_normal(n)
    cutoff = np.linspace(low_hz, high_hz, n)
    alpha = 1 - np.exp(-2 * np.pi * cutoff / SAMPLE_RATE)
    out = np.empty(n)
    state = 0.0
    for i in range(n):
        state += alpha[i] * (noise[i] - state)
        out[i] = state
    return out


def _normalise(x: np.ndarray, peak: float = 0.8) -> np.ndarray:
    x = x - np.mean(x)
    x = x / np.max(np.abs(x)) * peak
    edge = max(1, int(EDGE_SECONDS * SAMPLE_RATE))
    x[:edge] *= np.linspace(0, 1, edge)
    x[-edge:] *= np.linspace(1, 0, edge)
    return x


def synth(kind: str) -> np.ndarray:
    if kind not in KINDS:
        raise KeyError(f"no such effect: {kind}")
    rng = np.random.default_rng(7)  # the same samples every time
    if kind in ("whoosh", "swish"):
        seconds, low, high = (0.75, 250.0, 3800.0) if kind == "whoosh" else (0.32, 900.0, 5200.0)
        t = _time(seconds)
        body = _band_noise(rng, len(t), low, high) * np.sin(np.pi * np.minimum(t / seconds * 1.15, 1.0)) ** 2
        return _normalise(body)
    if kind == "pop":
        t = _time(0.16)
        return _normalise(_sweep(t, 980, 430) * np.exp(-t / 0.035) + 0.15 * rng.standard_normal(len(t)) * np.exp(-t / 0.004))
    if kind == "tick":
        t = _time(0.06)
        click = np.diff(rng.standard_normal(len(t) + 1)) * np.exp(-t / 0.009)
        return _normalise(click)
    if kind == "chime":
        t = _time(1.1)
        partials = sum(a * np.sin(2 * np.pi * f * t) for f, a in ((880, 1.0), (1320, 0.5), (1760, 0.28), (2640, 0.12)))
        return _normalise(partials * np.minimum(t / 0.006, 1.0) * np.exp(-t / 0.32))
    if kind == "thud":
        t = _time(0.45)
        return _normalise(_sweep(t, 125, 52) * np.exp(-t / 0.11) + 0.2 * _band_noise(rng, len(t), 200, 120) * np.exp(-t / 0.05))
    t = _time(1.4)  # rise: a swell that climbs in pitch and brightness, then stops cleanly
    swell = (t / 1.4) ** 2.2 * (1 - np.exp(-(1.4 - t) / 0.03))
    return _normalise((0.7 * _sweep(t, 220, 1250) + 0.5 * _band_noise(rng, len(t), 300, 3500)) * swell)


def write_all(out_dir: Path = SFX_DIR) -> list[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    written = []
    for kind in KINDS:
        mono = (synth(kind) * 32767).astype("<i2")
        stereo = np.repeat(mono[:, None], 2, axis=1)
        target = out_dir / f"{kind}.wav"
        with wave.open(str(target), "wb") as wav:
            wav.setnchannels(2)
            wav.setsampwidth(2)
            wav.setframerate(SAMPLE_RATE)
            wav.writeframes(stereo.tobytes())
        written.append(target)
    return written


if __name__ == "__main__":
    for file in write_all():
        print(file.name, f"{file.stat().st_size / 1024:.0f} KB")
