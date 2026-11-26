"""Turn presence events into hourly home or away, the shape the forecaster learns from.

An hour counts as home when the person was home for 30 minutes or more of it. Hours before the
first event are unknown, so the series starts at the first whole hour at or after the first event,
and it ends with the last hour that has fully ended before `end`.
"""

from __future__ import annotations

import re
from datetime import datetime, timedelta
from pathlib import Path
from typing import Mapping, Sequence

from config import MIN_COVERAGE, MIN_USABLE_DAYS, MIN_USABLE_HOMES

HOME_SECONDS_NEEDED = 30 * 60
HOUR = timedelta(hours=1)


def _floor_hour(at: datetime) -> datetime:
    return at.replace(minute=0, second=0, microsecond=0)


def events_to_hourly(events: Sequence[tuple[datetime, bool]], end: datetime) -> list[tuple[datetime, bool]]:
    """`events` are state changes (time, is_home). Returns [(hour_start, is_home)] in time order."""
    if not events:
        return []
    ordered = sorted(events, key=lambda e: e[0])
    first = ordered[0][0]
    start = _floor_hour(first)
    if start < first:
        start += HOUR
    last_hour = _floor_hour(end)  # an hour counts only once it has fully ended
    if start >= last_hour:
        return []

    home_seconds: dict[datetime, float] = {}
    for index, (begins, is_home) in enumerate(ordered):
        stops = ordered[index + 1][0] if index + 1 < len(ordered) else end
        if not is_home or stops <= begins:
            continue
        cursor = max(begins, start)
        stops = min(stops, last_hour)
        while cursor < stops:
            hour = _floor_hour(cursor)
            slice_end = min(stops, hour + HOUR)
            home_seconds[hour] = home_seconds.get(hour, 0.0) + (slice_end - cursor).total_seconds()
            cursor = slice_end

    hours: list[tuple[datetime, bool]] = []
    hour = start
    while hour < last_hour:
        hours.append((hour, home_seconds.get(hour, 0.0) >= HOME_SECONDS_NEEDED))
        hour += HOUR
    return hours


# ---- CASAS smart home files ---------------------------------------------------------------------------------
# A line is "date time sensor value [activity begin|end]", separated by spaces or tabs. The activity labels
# Leave_Home and Enter_Home are written at the moment of leaving and of coming back (seconds long), so a home
# is away from a Leave_Home begin until the next Enter_Home begin. Homes without Enter_Home labels (Cairo,
# Milan) give no return time and are not used.

_CASAS_LINE = re.compile(r"^(\d{4}-\d{2}-\d{2})[ \t]+(\d{2}:\d{2}:\d{2}(?:\.\d+)?)(.*)$")
_CASAS_MARK = re.compile(r"(Leave_Home|Enter_Home)[ \t]+begin\s*$")


def _scan_casas(path: Path) -> tuple[list[tuple[datetime, bool]], datetime | None, bool]:
    events: list[tuple[datetime, bool]] = []
    last: datetime | None = None
    saw_enter = False
    with open(path, encoding="utf8", errors="replace") as handle:
        for line in handle:
            match = _CASAS_LINE.match(line.rstrip("\r\n"))
            if not match:
                continue
            try:
                at = datetime.fromisoformat(f"{match.group(1)} {match.group(2)}")
            except ValueError:
                continue
            last = at if last is None or at > last else last
            mark = _CASAS_MARK.search(match.group(3))
            if mark:
                is_enter = mark.group(1) == "Enter_Home"
                saw_enter = saw_enter or is_enter
                events.append((at, is_enter))
    return events, last, saw_enter


def casas_events(path: Path) -> list[tuple[datetime, bool]]:
    """[(time, is_home)]: False at each Leave_Home begin, True at each Enter_Home begin."""
    return _scan_casas(Path(path))[0]


def home_hours_from_casas(path: Path) -> list[tuple[datetime, bool]]:
    events, last, saw_enter = _scan_casas(Path(path))
    if not saw_enter:
        raise ValueError(f"{Path(path).name} has no Enter_Home labels, so the time of return is unknown")
    if last is None:
        return []
    return events_to_hourly(events, last)


def gate_entry(home_id: str, hours: Sequence[tuple[datetime, bool]]) -> dict:
    """Size and coverage of one home's hourly series, and whether it is usable for the evaluation."""
    count = len(hours)
    if count == 0:
        return {"id": home_id, "days": 0, "hours": 0, "home_share": 0.0, "coverage": 0.0, "usable": False}
    first, last = hours[0][0], hours[-1][0]
    span = int((last - first).total_seconds() // 3600) + 1
    coverage = count / span
    days = count // 24
    return {
        "id": home_id,
        "days": days,
        "hours": count,
        "first_hour": first.isoformat(timespec="minutes"),
        "last_hour": last.isoformat(timespec="minutes"),
        "home_share": sum(1 for _, home in hours if home) / count,
        "coverage": coverage,
        "usable": days >= MIN_USABLE_DAYS and coverage >= MIN_COVERAGE,
    }


def data_gate(series_by_home: Mapping[str, Sequence[tuple[datetime, bool]]], rejected: Mapping[str, str] | None = None) -> dict:
    homes = [gate_entry(name, hours) for name, hours in sorted(series_by_home.items())]
    homes += [{"id": name, "usable": False, "reason": reason} for name, reason in (rejected or {}).items()]
    usable = sum(1 for h in homes if h["usable"])
    return {
        "passed": usable >= MIN_USABLE_HOMES,
        "min_days": MIN_USABLE_DAYS,
        "min_coverage": MIN_COVERAGE,
        "min_homes": MIN_USABLE_HOMES,
        "usable_homes": usable,
        "homes": homes,
    }
