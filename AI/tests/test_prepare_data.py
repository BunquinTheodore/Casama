"""Download check, hourly csv files and loading them back as forecaster observations."""

from datetime import datetime, timedelta

import pytest

from download_data import ensure_casas_zip
from prepare_data import load_series, write_hourly_csv
from home_forecast import Observation


def test_download_is_skipped_when_the_zip_is_already_complete(tmp_path):
    zip_path = tmp_path / "new_labeled_data.zip"
    zip_path.write_bytes(b"x" * 10)
    calls = []
    got = ensure_casas_zip(tmp_path, expected_bytes=10, fetch=lambda *a, **k: calls.append(a))
    assert got == zip_path and calls == []


def test_download_resumes_a_partial_zip(tmp_path):
    zip_path = tmp_path / "new_labeled_data.zip"
    zip_path.write_bytes(b"x" * 4)
    seen = {}

    def fake_fetch(url, path, start):
        seen["start"] = start
        path.write_bytes(path.read_bytes() + b"y" * 6)

    ensure_casas_zip(tmp_path, expected_bytes=10, fetch=fake_fetch)
    assert seen["start"] == 4
    assert zip_path.stat().st_size == 10


def test_download_fails_loudly_when_the_size_is_wrong(tmp_path):
    with pytest.raises(RuntimeError, match="expected 10 bytes"):
        ensure_casas_zip(tmp_path, expected_bytes=10, fetch=lambda url, path, start: path.write_bytes(b"x" * 3))


def test_hourly_csv_round_trips_through_load_series(tmp_path):
    start = datetime(2026, 3, 2)
    hours = [(start + timedelta(hours=i), i % 3 == 0) for i in range(48)]
    write_hourly_csv(tmp_path, "demo", hours)
    series = load_series(tmp_path)
    assert list(series) == ["demo"]
    assert series["demo"][0] == Observation(start, True)
    assert [o.home for o in series["demo"]] == [h for _, h in hours]
    assert [o.at for o in series["demo"]] == [t for t, _ in hours]
