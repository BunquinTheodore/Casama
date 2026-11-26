"""Original, synthesized sound effects: audible, short, click free, reproducible and in a standard file format."""
import wave

import numpy as np
import pytest

from make_sfx import KINDS, SAMPLE_RATE, synth, write_all


@pytest.mark.parametrize("kind", KINDS)
def test_every_effect_is_audible_short_and_click_free(kind):
    samples = synth(kind)
    seconds = len(samples) / SAMPLE_RATE
    assert samples.ndim == 1 and 0.03 < seconds < 2.5
    assert 0.3 < np.max(np.abs(samples)) <= 1.0  # audible, never clipping
    assert abs(samples[0]) < 0.02 and abs(samples[-1]) < 0.02  # starts and ends at silence, so no click


def test_synthesis_is_reproducible():
    assert np.array_equal(synth("whoosh"), synth("whoosh"))
    assert not np.array_equal(synth("whoosh"), synth("swish"))


def test_unknown_effect_is_refused():
    with pytest.raises(KeyError, match="no such effect"):
        synth("applause")


def test_files_are_stereo_16_bit_48k(tmp_path):
    write_all(tmp_path)
    for kind in KINDS:
        with wave.open(str(tmp_path / f"{kind}.wav"), "rb") as wav:
            assert (wav.getnchannels(), wav.getsampwidth(), wav.getframerate()) == (2, 2, 48000)
            assert wav.getnframes() > 1000
