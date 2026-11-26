"""The narration script, its beats table and the timeline built from them."""

import json

import pytest

from build_script import SCENE_IDS, build_script, parse_scenes
from build_timeline import build_timeline
from config import OUTPUT_DIR, ROOT
from make_voice import estimate_timings

METRICS = json.loads((OUTPUT_DIR / "metrics.json").read_text(encoding="utf-8"))
BEATS = json.loads((ROOT / "video" / "beats.json").read_text(encoding="utf-8"))
MEMBER_NAMES = ["Theodore", "Bunquin", "Christian", "Nayre", "Daniel", "Villanueva", "Alcaraz", "John", "Paul"]


@pytest.fixture(scope="module")
def scenes(tmp_path_factory):
    return build_script(METRICS, out_path=tmp_path_factory.mktemp("narration") / "narration.json")


def test_script_has_exactly_the_scenes_in_order(scenes):
    assert [s["id"] for s in scenes] == SCENE_IDS


def test_script_length_between_1200_and_1500_words(scenes):
    words = sum(len(s["text"].split()) for s in scenes)
    assert 1200 <= words <= 1500, words


def test_every_number_in_the_script_comes_from_the_metrics(scenes):
    text = " ".join(s["text"] for s in scenes)
    assert f"{METRICS['horizons']['3']['model']['brier']:.2f}" in text
    assert str(METRICS["data"][0]["days"]) in text
    assert f"{METRICS['params']['b1']:.2f}" in text
    assert "{{" not in text and "}}" not in text


def test_no_member_names_in_the_narration_text(scenes):
    text = " ".join(s["text"] for s in scenes)
    for name in MEMBER_NAMES:
        assert name not in text, f"{name} must appear on the credits card only"


def test_no_dashes_and_no_hyphenated_words_in_the_narration(scenes):
    text = " ".join(s["text"] for s in scenes)
    assert "-" not in text and "–" not in text and "—" not in text


def test_every_beat_phrase_appears_once_in_its_scene(scenes):
    for scene in scenes:
        assert scene["id"] in BEATS, scene["id"]
        for key, beat in BEATS[scene["id"]].items():
            assert scene["text"].count(beat["phrase"]) == 1, f"{scene['id']}.{key}: {beat['phrase']!r}"


def test_beats_only_use_effects_that_exist_and_one_riser(scenes):
    kinds = [b.get("sfx") for s in BEATS.values() for b in s.values()]
    assert set(filter(None, kinds)) <= {"pop", "tick", "swish", "thud", "rise", "whoosh"}
    assert kinds.count("rise") == 1


def test_estimate_timings_cover_8_to_10_minutes(scenes, tmp_path):
    timings = estimate_timings(scenes, timings_path=tmp_path / "scene_timings.json")
    minutes = sum(t["seconds"] for t in timings) / 60
    assert 8.0 <= minutes <= 10.0, minutes


def test_timeline_places_beats_inside_their_scenes_in_time_order(scenes, tmp_path):
    timings = estimate_timings(scenes, timings_path=tmp_path / "t.json")
    timeline = build_timeline(scenes, timings, BEATS)
    assert timeline["estimated"] is True
    starts = [s["start"] for s in timeline["scenes"]]
    assert starts == sorted(starts) and starts[0] == 0
    for s in timeline["scenes"]:
        for beat in s["beats"].values():
            assert 0 <= beat["at"] < s["duration"]


def test_timeline_uses_the_real_character_timings_when_given(scenes, tmp_path):
    timings = [
        {"id": s["id"], "file": f"audio/{s['id']}.mp3", "audio_seconds": 10.0, "lead_seconds": 0.6, "seconds": 12.1, "estimated": False}
        for s in scenes
    ]
    cues = {s["id"]: {"text": s["text"], "starts": [i * 0.01 for i in range(len(s["text"]))], "ends": [i * 0.01 + 0.01 for i in range(len(s["text"]))]} for s in scenes}
    timeline = build_timeline(scenes, timings, BEATS, cues)
    first = scenes[0]
    phrase = BEATS["title"]["name"]["phrase"]
    assert timeline["scenes"][0]["beats"]["name"]["at"] == pytest.approx(0.6 + first["text"].index(phrase) * 0.01, abs=1e-3)
    assert timeline["estimated"] is False


def test_a_phrase_that_is_not_spoken_fails_loudly(scenes, tmp_path):
    timings = estimate_timings(scenes, timings_path=tmp_path / "t.json")
    broken = {**BEATS, "title": {"x": {"phrase": "this is never said", "sfx": "pop"}}}
    with pytest.raises(KeyError, match="occurs 0 times"):
        build_timeline(scenes, timings, broken)


def test_parse_scenes_splits_on_level_two_headings():
    parsed = parse_scenes("preamble\n\n## a\n\nOne two.\n\n## b\n\nThree.\n")
    assert parsed == [("a", "One two."), ("b", "Three.")]
