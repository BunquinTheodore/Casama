"""Reading the CASAS files and the data gate that decides whether the evaluation can go ahead."""

import json
from datetime import datetime, timedelta

import pytest

from derive_hourly import casas_events, data_gate, gate_entry, home_hours_from_casas

SPACE = """\
2010-11-04 00:03:50.209589 M003 ON Sleeping begin
2010-11-04 00:03:57.399391 M003 OFF
2010-11-04 11:41:34.029848 M004 ON Leave_Home begin
2010-11-04 11:41:43.345957 M004 OFF Leave_Home end
2010-11-04 13:43:30.094537 D001 OPEN Enter_Home begin
2010-11-04 13:43:34.683398 D001 CLOSE Enter_Home end
2010-11-04 14:00:00.000000 M005 ON Relax begin
2010-11-04 15:30:10.000000 M005 OFF Relax end
"""

TABS = (
    "2009-04-02\t07:35:58.093929\tM001\tON\tLeave_Home begin\n"
    "2009-04-02\t07:38:32.282589\tM001\tOFF\tLeave_Home end\n"
    "2009-04-02\t18:32:03.025728\tD001\tOPEN\tEnter_Home begin\n"
    "2009-04-02\t19:00:00.000000\tM002\tON\n"
)


def write(tmp_path, text, name="home.txt"):
    path = tmp_path / name
    path.write_text(text, encoding="utf8")
    return path


def test_casas_events_reads_leave_as_away_and_enter_as_home(tmp_path):
    events = casas_events(write(tmp_path, SPACE))
    assert events == [(datetime(2010, 11, 4, 11, 41, 34, 29848), False), (datetime(2010, 11, 4, 13, 43, 30, 94537), True)]


def test_casas_events_handles_tab_separated_lines(tmp_path):
    events = casas_events(write(tmp_path, TABS))
    assert [e[1] for e in events] == [False, True]
    assert events[0][0].hour == 7 and events[1][0].hour == 18


def test_casas_events_ignores_end_markers_and_other_activities(tmp_path):
    events = casas_events(write(tmp_path, SPACE))
    assert len(events) == 2


def test_home_hours_end_at_the_last_row_of_the_file(tmp_path):
    hours = home_hours_from_casas(write(tmp_path, SPACE))
    # first event 11:41 (away) so the series starts at 12:00; home again from 13:43; the file ends 15:30,
    # so the last hour that has fully ended is 14:00 to 15:00
    by_hour = {h.hour: v for h, v in hours}
    assert sorted(by_hour) == [12, 13, 14]
    assert by_hour[12] is False  # away the whole hour
    assert by_hour[13] is False  # home only 17 of 60 minutes
    assert by_hour[14] is True


def test_homes_without_enter_home_labels_are_rejected(tmp_path):
    text = "2009-06-10 08:27:37.001867\tM001\tON\tLeave_Home begin\n2009-06-10 08:27:49.045791\tM001\tOFF\tLeave_Home end\n"
    with pytest.raises(ValueError, match="Enter_Home"):
        home_hours_from_casas(write(tmp_path, text))


def test_gate_entry_counts_days_coverage_and_home_share():
    start = datetime(2026, 1, 5)
    hours = [(start + timedelta(hours=i), i % 4 != 0) for i in range(50 * 24)]
    entry = gate_entry("x", hours)
    assert entry["days"] == 50 and entry["hours"] == 1200
    assert entry["home_share"] == pytest.approx(0.75)
    assert entry["usable"] is True


def test_gate_entry_rejects_short_and_gappy_series():
    start = datetime(2026, 1, 5)
    short = [(start + timedelta(hours=i), True) for i in range(30 * 24)]
    assert gate_entry("short", short)["usable"] is False
    gappy = [(start + timedelta(hours=i), True) for i in range(100 * 24) if (i // 24) % 3 == 0]
    entry = gate_entry("gappy", gappy)
    assert entry["usable"] is False
    assert entry["coverage"] < 0.70


def test_gate_passes_with_two_usable_homes_and_fails_with_one():
    start = datetime(2026, 1, 5)
    good = [(start + timedelta(hours=i), True) for i in range(60 * 24)]
    short = [(start + timedelta(hours=i), True) for i in range(10 * 24)]
    assert data_gate({"a": good, "b": good, "c": short})["passed"] is True
    assert data_gate({"a": good, "c": short})["passed"] is False
    report = data_gate({"a": good, "c": short}, rejected={"d": "no Enter_Home labels"})
    assert report["homes"][-1] == {"id": "d", "usable": False, "reason": "no Enter_Home labels"}
    json.dumps(report)  # serialisable
