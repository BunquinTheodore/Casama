"""The local narration engine: sentence splitting, silence trimming and the per character timings."""

import numpy as np
import pytest

from local_voice import assemble, build_alignment, sentence_spans, trim_silence

TEXT = "First one. Second sentence has 0.70 in it! Third?"
RATE = 24000


def test_spans_split_on_sentence_ends_but_not_on_decimals():
    spans = sentence_spans(TEXT)
    assert [TEXT[a:b] for a, b in spans] == ["First one.", "Second sentence has 0.70 in it!", "Third?"]


def test_alignment_keeps_the_text_and_never_runs_backwards():
    alignment = build_alignment(TEXT, sentence_spans(TEXT), [1.0, 2.0, 0.5], gap=0.25)
    assert "".join(alignment["characters"]) == TEXT
    assert len(alignment["starts"]) == len(TEXT) == len(alignment["ends"])
    assert all(a <= b for a, b in zip(alignment["starts"], alignment["ends"]))
    assert all(alignment["starts"][i] <= alignment["starts"][i + 1] for i in range(len(TEXT) - 1))


def test_each_sentence_starts_after_the_one_before_plus_the_gap():
    spans = sentence_spans(TEXT)
    alignment = build_alignment(TEXT, spans, [1.0, 2.0, 0.5], gap=0.25)
    assert alignment["starts"][spans[0][0]] == pytest.approx(0.0)
    assert alignment["starts"][spans[1][0]] == pytest.approx(1.25)
    assert alignment["starts"][spans[2][0]] == pytest.approx(3.5)
    assert alignment["ends"][spans[2][1] - 1] == pytest.approx(4.0)


def test_a_longer_word_gets_more_time_inside_its_sentence():
    text = "Hi extraordinarily."
    alignment = build_alignment(text, sentence_spans(text), [2.0], gap=0.0)
    short_word = alignment["ends"][1] - alignment["starts"][0]
    long_word = alignment["ends"][-1] - alignment["starts"][3]
    assert long_word > 3 * short_word


def test_assemble_puts_the_gap_between_sentences_only():
    chunks = [np.ones(RATE, dtype=np.float32), np.ones(RATE // 2, dtype=np.float32)]
    audio = assemble(chunks, RATE, gap=0.25)
    assert len(audio) == RATE + RATE // 2 + RATE // 4
    assert audio[RATE : RATE + RATE // 4].max() == 0.0


def test_trim_silence_keeps_a_short_margin_either_side_of_the_speech():
    samples = np.concatenate([np.zeros(2400), 0.5 * np.ones(4800), np.zeros(2400)]).astype(np.float32)
    trimmed = trim_silence(samples, RATE, keep_seconds=0.02)
    assert len(trimmed) == 4800 + 2 * 480


def test_trim_silence_leaves_pure_silence_alone():
    silence = np.zeros(1000, dtype=np.float32)
    assert len(trim_silence(silence, RATE)) == 1000


def test_synthesize_with_a_local_renderer_needs_no_key_and_does_not_render_twice(tmp_path):
    from local_voice import to_mp3
    from make_voice import synthesize

    scenes = [{"id": "a", "text": "One. Two."}, {"id": "b", "text": "Three."}]
    calls = []

    def render(text):
        calls.append(text)
        tone = (0.3 * np.sin(np.linspace(0, 400, RATE))).astype(np.float32)
        spans = sentence_spans(text)
        return to_mp3(tone, RATE), build_alignment(text, spans, [1.0] * len(spans))

    options = dict(out_dir=tmp_path / "audio_local", timings_path=tmp_path / "timings.json", render=render, voice_id="kokoro:test")
    timings = synthesize(scenes, **options)
    assert [t["file"] for t in timings] == ["audio_local/a.mp3", "audio_local/b.mp3"]
    assert all(not t["estimated"] for t in timings)
    assert (tmp_path / "cues.json").exists()
    synthesize(scenes, **options)
    assert len(calls) == 2  # the second run found both scenes already rendered
