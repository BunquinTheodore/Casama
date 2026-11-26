"""Where every sound effect lands, and that the rendered track is what the cue list says."""

import numpy as np
import pytest

from config import ROOT
from mix_sound import GAIN_DB, RATE, read_wav, render_track, sfx_cues

SFX_DIR = ROOT / "video" / "sfx"


def timeline(*beats_per_scene):
    scenes, start = [], 0.0
    for index, beats in enumerate(beats_per_scene):
        scenes.append({"id": f"s{index}", "start": start, "duration": 10.0, "lead": 0.6, "audio": f"audio/s{index}.mp3", "beats": beats})
        start += 10.0
    return {"fps": 30, "total": start, "scenes": scenes}


def test_an_effect_lands_at_the_scene_start_plus_the_beat_time():
    cues = sfx_cues(timeline({"a": {"at": 1.5, "sfx": "pop"}}, {"b": {"at": 2.0, "sfx": "tick"}}))
    pop = next(c for c in cues if c["source"] == "s0.a")
    tick = next(c for c in cues if c["source"] == "s1.b")
    assert pop["at"] == pytest.approx(1.5) and pop["kind"] == "pop"
    assert tick["at"] == pytest.approx(12.0)


def test_a_beat_without_a_sound_makes_no_effect():
    cues = sfx_cues(timeline({"a": {"at": 1.0, "sfx": None}}))
    assert cues == []


def test_every_scene_after_the_first_opens_with_a_whoosh_just_before_the_wipe():
    cues = sfx_cues(timeline({}, {}, {}))
    scene = [c for c in cues if c["source"].startswith("scene:")]
    assert [c["source"] for c in scene] == ["scene:s1", "scene:s2"]
    assert scene[0]["at"] == pytest.approx(10.0 - 0.05)


def test_two_effects_of_one_kind_too_close_are_one_effect_heard_twice():
    cues = sfx_cues(timeline({"a": {"at": 1.0, "sfx": "pop"}, "b": {"at": 1.1, "sfx": "pop"}, "c": {"at": 1.5, "sfx": "pop"}}))
    assert [c["source"] for c in cues] == ["s0.a", "s0.c"]


def test_cues_are_in_time_order_and_carry_the_gain_of_their_kind():
    cues = sfx_cues(timeline({"a": {"at": 4.0, "sfx": "tick"}, "b": {"at": 1.0, "sfx": "pop"}}))
    assert [c["at"] for c in cues] == sorted(c["at"] for c in cues)
    for c in cues:
        assert c["gain_db"] == GAIN_DB[c["kind"]]


def test_the_real_beats_only_use_kinds_that_have_a_wav_and_a_gain():
    import json

    beats = json.loads((ROOT / "video" / "beats.json").read_text(encoding="utf-8"))
    kinds = {b["sfx"] for s in beats.values() for b in s.values() if b.get("sfx")} | {"whoosh"}
    for kind in kinds:
        assert kind in GAIN_DB
        assert (SFX_DIR / f"{kind}.wav").exists()


def test_the_rendered_track_is_silent_between_effects_and_has_the_effect_at_its_time():
    raw = read_wav(SFX_DIR / "pop.wav")
    track = render_track([{"at": 1.0, "kind": "pop", "gain_db": -20.0, "source": "t"}], 3.0, SFX_DIR)
    assert track.shape == (3 * RATE, 2)
    assert not track[: RATE - 2].any()
    expected = np.abs(raw).max() * 10 ** (-20 / 20)
    assert abs(np.abs(track).max() - expected) / expected < 0.02
    after = int((1.0 + len(raw) / RATE + 0.05) * RATE)
    assert not track[after:].any()


def test_overlapping_effects_add_and_saturate_instead_of_wrapping():
    cues = [{"at": 0.5, "kind": "thud", "gain_db": 6.0, "source": "x"} for _ in range(40)]
    track = render_track(cues, 2.0, SFX_DIR)
    assert np.abs(track).max() <= 32767
    assert np.abs(track).max() >= 32000
