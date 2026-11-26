"""Task 13: ElevenLabs narration, with a credits guard and estimated timings while credits are short."""
import base64
import json
import subprocess
from types import SimpleNamespace

import pytest

import make_voice
from config import ROOT

SCENES = [{"id": "title", "text": "Hello there."}, {"id": "question", "text": "A second scene, a bit longer."}]


def silence(path, seconds=2):
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=mono", "-t", str(seconds), "-q:a", "9", "-acodec", "libmp3lame", str(path)],
        check=True,
    )


class FakeTTS:
    def __init__(self, audio):
        self.audio, self.calls = audio, []

    def convert_with_timestamps(self, **kwargs):
        self.calls.append(kwargs)
        spoken = kwargs["text"]
        alignment = SimpleNamespace(
            characters=list(spoken),
            character_start_times_seconds=[i * 0.05 for i in range(len(spoken))],
            character_end_times_seconds=[(i + 1) * 0.05 for i in range(len(spoken))],
        )
        return SimpleNamespace(audio_base_64=base64.b64encode(self.audio).decode(), alignment=alignment)


class FakeClient:
    def __init__(self, audio, used=0, limit=10_000):
        self.text_to_speech = FakeTTS(audio)
        sub = type("Sub", (), {"character_count": used, "character_limit": limit})()
        self.user = type("User", (), {"subscription": type("S", (), {"get": staticmethod(lambda: sub)})()})()


@pytest.fixture()
def audio_bytes(tmp_path):
    path = tmp_path / "s.mp3"
    silence(path)
    return path.read_bytes()


def test_audio_seconds_on_generated_silence(tmp_path):
    silence(tmp_path / "two.mp3", 2)
    assert make_voice.audio_seconds(tmp_path / "two.mp3") == pytest.approx(2.0, abs=0.2)


def test_missing_key_raises_a_clear_error(monkeypatch, tmp_path):
    monkeypatch.delenv("ELEVENLABS_API_KEY", raising=False)
    with pytest.raises(make_voice.MissingKeyError, match=r"\.env\.local"):
        make_voice.load_client(env_file=tmp_path / "absent.env")


def test_dry_run_needs_no_key_and_lists_every_scene(monkeypatch, capsys):
    monkeypatch.setattr(make_voice, "load_client", lambda *a, **k: (_ for _ in ()).throw(AssertionError("a key was requested")))
    assert make_voice.main(["--dry-run"]) == 0
    out = capsys.readouterr().out
    assert all(scene_id in out for scene_id in ["title", "question", "credits"]) and "characters" in out


def test_timings_written_in_scene_order(audio_bytes, tmp_path):
    client = FakeClient(audio_bytes)
    timings = make_voice.synthesize(SCENES, voice_id="v", out_dir=tmp_path / "audio", client=client, timings_path=tmp_path / "t.json")
    assert [t["id"] for t in timings] == ["title", "question"]
    assert all((tmp_path / "audio" / f"{t['id']}.mp3").exists() and t["audio_seconds"] == pytest.approx(2.0, abs=0.2) for t in timings)
    assert json.loads((tmp_path / "t.json").read_text()) == timings
    assert client.text_to_speech.calls[0]["text"] == "Hello there." and client.text_to_speech.calls[0]["voice_id"] == "v"


def test_refuses_to_start_when_credits_are_short(audio_bytes, tmp_path):
    client = FakeClient(audio_bytes, used=9_990, limit=10_000)  # 10 characters left, the scenes need more
    with pytest.raises(make_voice.InsufficientCreditsError, match="characters"):
        make_voice.synthesize(SCENES, voice_id="v", out_dir=tmp_path / "audio", client=client, timings_path=tmp_path / "t.json")
    assert client.text_to_speech.calls == [] and not (tmp_path / "t.json").exists()


def test_estimated_timings_fit_the_eight_to_ten_minute_target(tmp_path):
    scenes = json.loads((ROOT / "video" / "narration.json").read_text(encoding="utf-8"))
    timings = make_voice.estimate_timings(scenes, timings_path=tmp_path / "t.json")
    total = sum(t["seconds"] for t in timings)
    assert 480 <= total <= 600
    assert all(t["estimated"] is True and t["file"] is None for t in timings)
    assert [t["id"] for t in timings] == [s["id"] for s in scenes]


def test_sample_renders_only_the_first_scene(audio_bytes, tmp_path, monkeypatch):
    client = FakeClient(audio_bytes)
    monkeypatch.setattr(make_voice, "AUDIO_DIR", tmp_path / "audio")
    monkeypatch.setattr(make_voice, "load_client", lambda *a, **k: client)
    monkeypatch.setattr(make_voice, "load_scenes", lambda: SCENES)
    assert make_voice.main(["--sample"]) == 0
    assert len(client.text_to_speech.calls) == 1 and (tmp_path / "audio" / "sample.mp3").exists()


def kwargs_for(tmp_path):
    return dict(voice_id="v", out_dir=tmp_path / "audio", timings_path=tmp_path / "t.json")


def test_rerun_skips_scenes_that_are_already_rendered(audio_bytes, tmp_path):
    client = FakeClient(audio_bytes)
    make_voice.synthesize(SCENES, client=client, **kwargs_for(tmp_path))
    assert len(client.text_to_speech.calls) == 2
    make_voice.synthesize(SCENES, client=client, **kwargs_for(tmp_path))
    assert len(client.text_to_speech.calls) == 2  # nothing was rendered, nothing was billed again
    changed = [SCENES[0], {"id": "question", "text": "A different second scene."}]
    make_voice.synthesize(changed, client=client, **kwargs_for(tmp_path))
    assert len(client.text_to_speech.calls) == 3  # only the scene whose text changed


def test_cached_scenes_need_no_credits_and_no_key(audio_bytes, tmp_path, monkeypatch):
    make_voice.synthesize(SCENES, client=FakeClient(audio_bytes), **kwargs_for(tmp_path))
    monkeypatch.setattr(make_voice, "load_client", lambda *a, **k: (_ for _ in ()).throw(AssertionError("a key was requested")))
    timings = make_voice.synthesize(SCENES, client=None, **kwargs_for(tmp_path))
    assert [t["id"] for t in timings] == ["title", "question"]


def test_failed_render_keeps_finished_scenes_and_resumes(audio_bytes, tmp_path):
    class Flaky(FakeTTS):
        def convert_with_timestamps(self, **kwargs):
            if len(self.calls) == 1:
                self.calls.append(kwargs)
                raise ConnectionError("network dropped")
            return super().convert_with_timestamps(**kwargs)

    client = FakeClient(audio_bytes)
    client.text_to_speech = Flaky(audio_bytes)
    with pytest.raises(ConnectionError):
        make_voice.synthesize(SCENES, client=client, **kwargs_for(tmp_path))
    assert (tmp_path / "audio" / "title.mp3").exists() and not (tmp_path / "t.json").exists()
    make_voice.synthesize(SCENES, client=client, **kwargs_for(tmp_path))
    assert len(client.text_to_speech.calls) == 3  # one success, one failure, then only the missing scene


def test_estimate_refuses_to_overwrite_real_timings(tmp_path, monkeypatch):
    timings = tmp_path / "t.json"
    timings.write_text(json.dumps([{"id": "title", "file": "audio/title.mp3", "seconds": 5.0, "estimated": False}]))
    monkeypatch.setattr(make_voice, "TIMINGS", timings)
    monkeypatch.setattr(make_voice, "load_scenes", lambda: SCENES)
    assert make_voice.main(["--estimate"]) == 1
    assert json.loads(timings.read_text())[0]["estimated"] is False
    assert make_voice.main(["--estimate", "--force"]) == 0
    assert json.loads(timings.read_text())[0]["estimated"] is True


def forbidden_balance(status="missing_permissions", code=401):
    from elevenlabs.core.api_error import ApiError

    def raiser():
        raise ApiError(status_code=code, body={"detail": {"status": status, "message": "the key lacks a permission"}})

    return raiser


def test_restricted_key_without_balance_permission_still_renders(audio_bytes, tmp_path):
    client = FakeClient(audio_bytes)
    client.user.subscription.get = forbidden_balance()
    timings = make_voice.synthesize(SCENES, client=client, **kwargs_for(tmp_path))
    assert len(client.text_to_speech.calls) == 2 and [t["id"] for t in timings] == ["title", "question"]


def test_other_balance_errors_still_stop_the_render(audio_bytes, tmp_path):
    from elevenlabs.core.api_error import ApiError

    client = FakeClient(audio_bytes)
    client.user.subscription.get = forbidden_balance(status="internal_error", code=500)
    with pytest.raises(ApiError):
        make_voice.synthesize(SCENES, client=client, **kwargs_for(tmp_path))
    assert client.text_to_speech.calls == []


def test_each_scene_gets_a_pause_and_the_last_one_a_longer_hold(audio_bytes, tmp_path):
    timings = make_voice.synthesize(SCENES, client=FakeClient(audio_bytes), **kwargs_for(tmp_path))
    first, last = timings
    lead, tail = make_voice.SCENE_LEAD_SECONDS, make_voice.SCENE_TAIL_SECONDS
    assert first["lead_seconds"] == lead  # the picture moves for a moment before the voice starts
    assert first["seconds"] == pytest.approx(lead + first["audio_seconds"] + tail)
    assert last["seconds"] == pytest.approx(lead + last["audio_seconds"] + tail + make_voice.LAST_SCENE_EXTRA_SECONDS)


def test_default_voice_is_brian():
    assert make_voice.DEFAULT_VOICE == "nPczCjzI2devNBz1zQrb"


def test_alignment_is_saved_next_to_each_scene(audio_bytes, tmp_path):
    make_voice.synthesize(SCENES, client=FakeClient(audio_bytes), **kwargs_for(tmp_path))
    saved = json.loads((tmp_path / "audio" / "title.alignment.json").read_text(encoding="utf-8"))
    assert saved["characters"] == list("Hello there.")
    assert len(saved["starts"]) == len(saved["ends"]) == len("Hello there.")


def test_scene_rendered_before_alignment_existed_is_rendered_again(audio_bytes, tmp_path):
    client = FakeClient(audio_bytes)
    make_voice.synthesize(SCENES, client=client, **kwargs_for(tmp_path))
    (tmp_path / "audio" / "title.alignment.json").unlink()  # audio from an older run that kept no timing
    make_voice.synthesize(SCENES, client=client, **kwargs_for(tmp_path))
    assert len(client.text_to_speech.calls) == 3  # only the scene that lost its alignment


def test_cues_give_every_character_a_time_and_phrases_can_be_found(audio_bytes, tmp_path):
    make_voice.synthesize(SCENES, client=FakeClient(audio_bytes), **kwargs_for(tmp_path))
    cues = json.loads((tmp_path / "cues.json").read_text(encoding="utf-8"))
    question = cues["question"]
    assert question["text"] == SCENES[1]["text"] and len(question["starts"]) == len(question["text"])
    assert make_voice.phrase_time(question, "bit longer") == pytest.approx(question["starts"][question["text"].index("bit longer")])
    with pytest.raises(KeyError, match="not in the narration"):
        make_voice.phrase_time(question, "a phrase nobody says")
