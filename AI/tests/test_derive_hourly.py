"""Turning presence events into hourly home or away, the common ground of the Python and Dart code."""

from datetime import datetime

from derive_hourly import events_to_hourly


def at(day: int, hour: int, minute: int = 0) -> datetime:
    return datetime(2026, 3, day, hour, minute)  # 2026-03-02 is a Monday


def test_hour_is_home_when_home_30_minutes_or_more():
    events = [(at(2, 9, 0), False), (at(2, 10, 15), True), (at(2, 12, 0), False)]
    hours = dict(events_to_hourly(events, at(2, 13)))
    assert hours[at(2, 9)] is False
    assert hours[at(2, 10)] is True  # home for 45 of 60 minutes
    assert hours[at(2, 11)] is True
    assert hours[at(2, 12)] is False


def test_exactly_30_minutes_counts_as_home():
    events = [(at(2, 9), False), (at(2, 10, 30), True), (at(2, 11), False)]
    hours = dict(events_to_hourly(events, at(2, 12)))
    assert hours[at(2, 10)] is True


def test_hour_is_out_when_home_under_30_minutes():
    events = [(at(2, 9), True), (at(2, 9, 20), False)]
    hours = dict(events_to_hourly(events, at(2, 11)))
    assert hours[at(2, 9)] is False


def test_toggle_mid_hour_splits_by_majority():
    events = [(at(2, 9), True), (at(2, 9, 40), False)]
    hours = dict(events_to_hourly(events, at(2, 11)))
    assert hours[at(2, 9)] is True


def test_hours_before_first_event_are_dropped():
    events = [(at(2, 10, 30), True)]
    hours = events_to_hourly(events, at(2, 13))
    assert [h for h, _ in hours] == [at(2, 11), at(2, 12)]


def test_midnight_and_sunday_boundary_hours_are_kept():
    events = [(datetime(2026, 3, 8, 22, 0), True), (datetime(2026, 3, 9, 1, 0), False)]
    hours = dict(events_to_hourly(events, datetime(2026, 3, 9, 3)))
    assert hours[datetime(2026, 3, 8, 23)] is True
    assert hours[datetime(2026, 3, 9, 0)] is True
    assert hours[datetime(2026, 3, 9, 1)] is False


def test_no_events_returns_empty_without_error():
    assert events_to_hourly([], at(2, 12)) == []


def test_only_hours_that_have_fully_ended_are_returned():
    events = [(at(2, 9), True)]
    hours = events_to_hourly(events, at(2, 11, 30))
    assert [h for h, _ in hours] == [at(2, 9), at(2, 10)]


def test_unsorted_events_are_sorted_first():
    events = [(at(2, 10), False), (at(2, 9), True)]
    hours = dict(events_to_hourly(events, at(2, 11)))
    assert hours[at(2, 9)] is True
    assert hours[at(2, 10)] is False
