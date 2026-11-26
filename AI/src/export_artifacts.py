"""Write the files the app, the Dart tests and the video consume.

AI/output/home_forecast.json   the fitted parameters (single source of truth for the app)
AI/output/golden.json          inputs with expected outputs, so the Dart port is tested against this code
AI/output/demo_presence.json   21 weeks of hourly demo history for the four demo housemates (demo filler)
lib/features/parcels/home_forecast/*_data.dart   the same JSON embedded as Dart (generated, do not edit)
"""

from __future__ import annotations

import json
from datetime import datetime, timedelta
from pathlib import Path
from typing import Mapping, Sequence

from config import CASAS_LICENCE, CASAS_RECORD_URL, OUTPUT_DIR, REPO_ROOT
from derive_hourly import events_to_hourly
from home_forecast import EPS, SLOTS, Observation, Params, forecast, habit, slot_of

DART_DIR = REPO_ROOT / "lib" / "features" / "parcels" / "home_forecast"
DART_FILES = {"home_forecast.json": "forecast_params_data.dart", "demo_presence.json": "demo_presence_seed.dart"}
DART_NAMES = {"home_forecast.json": "forecastParamsJson", "demo_presence.json": "demoPresenceSeedJson"}
DEMO_WEEKS = 3
DEMO_HOURS = DEMO_WEEKS * 7 * 24
SOURCE = {
    "dataset": "CASAS smart home dataset (Aruba, Cairo, Milan, Tulum), Washington State University",
    "record": CASAS_RECORD_URL,
    "licence": CASAS_LICENCE,
}
STAMP = "%Y-%m-%dT%H:%M"


def params_to_json(params: Params) -> dict:
    return {
        "version": 1,
        "slots": SLOTS,
        "eps": EPS,
        "b0": params.b0,
        "b1": params.b1,
        "b2": params.b2,
        "tau_hours": params.tau_hours,
        "half_life_days": params.half_life_days,
        "prior_strength": params.prior_strength,
        "prior": list(params.prior),
        "source": SOURCE,
    }


def _stamp(at: datetime) -> str:
    return at.strftime(STAMP)


def _series(start: datetime, hours: int, rule) -> list[Observation]:
    return [Observation(start + timedelta(hours=i), bool(rule(start + timedelta(hours=i), i))) for i in range(hours)]


def _case(name: str, params: Params, obs: Sequence[Observation], now: datetime, home_now: bool, hours_ahead: int, base: Params | None = None) -> dict:
    """One golden case. A case that uses other parameters than the file default carries them in a "params" key."""
    target = now.replace(minute=0, second=0, microsecond=0) + timedelta(hours=hours_ahead)
    case = {
        "name": name,
        "observations": [[_stamp(o.at), 1 if o.home else 0] for o in obs],
        "now": _stamp(now),
        "home_now": home_now,
        "hours_ahead": hours_ahead,
        "expected_habit": habit(obs, now, slot_of(target), params),
        "expected_forecast": forecast(obs, now, home_now, hours_ahead, params),
    }
    if base is not None and params is not base:
        case["params"] = params_to_json(params)
    return case


def build_golden(params: Params) -> dict:
    mon = datetime(2026, 3, 2)
    work_week = lambda t, i: not (t.weekday() < 5 and 9 <= t.hour < 17)  # out at work on weekdays
    hot = Params(**{**params.__dict__, "prior": tuple([1.0] * SLOTS), "prior_strength": 1e6})
    cold = Params(**{**params.__dict__, "prior": tuple([0.0] * SLOTS), "prior_strength": 1e6})
    cases = [
        _case("empty_history", params, [], datetime(2026, 3, 9, 8), True, 3),
        _case("one_observation", params, [Observation(mon + timedelta(hours=9), True)], mon + timedelta(days=7, hours=8), True, 1),
        _case("sunday_to_monday", params, _series(mon, 14 * 24, work_week), datetime(2026, 3, 15, 23, 30), True, 1),
        _case("dst_day", params, _series(datetime(2026, 3, 1), 14 * 24, work_week), datetime(2026, 3, 15, 10), False, 5),
        _case("extreme_habit_low", cold, _series(mon, 28 * 24, lambda t, i: False), mon + timedelta(days=28, hours=2), True, 24, params),
        _case("extreme_habit_high", hot, _series(mon, 28 * 24, lambda t, i: True), mon + timedelta(days=28, hours=2), False, 24, params),
        _case("horizon_168", params, _series(mon, 28 * 24, work_week), mon + timedelta(days=28, hours=9), True, 168),
        _case("home_now_false", params, _series(mon, 21 * 24, work_week), mon + timedelta(days=21, hours=10), False, 2),
        _case("mid_hour_now", params, _series(mon, 21 * 24, work_week), mon + timedelta(days=21, hours=9, minutes=47), True, 6),
        _case(
            "observation_at_now_ignored",
            params,
            _series(mon, 21 * 24, work_week) + [Observation(mon + timedelta(days=21, hours=10), False), Observation(mon + timedelta(days=22), False)],
            mon + timedelta(days=21, hours=10),
            True,
            3,
        ),
        _case(
            "recent_vs_old",
            params,
            [Observation(mon + timedelta(hours=12), True)] + [Observation(mon + timedelta(days=63, hours=12), False)],
            mon + timedelta(days=70, hours=11),
            True,
            1,
        ),
        _case("long_history_decay", params, _series(mon, 120 * 24, lambda t, i: work_week(t, i) if i < 60 * 24 else not work_week(t, i)), mon + timedelta(days=120, hours=7), True, 6),
    ]

    def hourly(name: str, events: list[tuple[datetime, bool]], end: datetime) -> dict:
        return {
            "name": name,
            "events": [[_stamp(t), 1 if v else 0] for t, v in events],
            "end": _stamp(end),
            "expected": [[_stamp(h), 1 if v else 0] for h, v in events_to_hourly(events, end)],
        }

    d = datetime(2026, 3, 2)
    hourly_cases = [
        hourly("toggle_mid_hour", [(d.replace(hour=9), True), (d.replace(hour=9, minute=40), False)], d.replace(hour=11)),
        hourly("exactly_30_minutes", [(d.replace(hour=9), False), (d.replace(hour=10, minute=30), True), (d.replace(hour=11), False)], d.replace(hour=12)),
        hourly("first_event_mid_hour", [(d.replace(hour=10, minute=30), True)], d.replace(hour=13)),
        hourly("empty", [], d.replace(hour=12)),
        hourly("sunday_boundary", [(datetime(2026, 3, 8, 22), True), (datetime(2026, 3, 9, 1), False)], datetime(2026, 3, 9, 3)),
        hourly("only_ended_hours", [(d.replace(hour=9), True)], d.replace(hour=11, minute=30)),
    ]
    return {"params": params_to_json(params), "cases": cases, "hourly_cases": hourly_cases}


def build_demo_presence(series_by_home: Mapping[str, Sequence[Observation]]) -> dict:
    """Four demo housemates, each a three week stretch (Monday to Sunday) of a CASAS home's hourly series.

    This is demo filler for the mock app, not Filipino data and not student routines.
    """
    runs: list[tuple[str, datetime]] = []
    for home in sorted(series_by_home):
        known = {o.at: o.home for o in series_by_home[home]}
        for at in sorted(known):
            if at.weekday() == 0 and at.hour == 0 and all(at + timedelta(hours=i) in known for i in range(DEMO_HOURS)):
                runs.append((home, at))
    if not runs:
        raise ValueError(f"no home has {DEMO_WEEKS} contiguous weeks starting on a Monday")
    chosen: list[tuple[str, datetime]] = []
    for home in sorted({h for h, _ in runs}):  # one run per home first, so the members differ
        chosen.append(next(r for r in runs if r[0] == home))
    for run in runs:  # then more runs, skipping overlaps with ones already chosen for the same home
        if len(chosen) >= 4:
            break
        if run not in chosen and all(not (h == run[0] and abs((a - run[1]).days) < DEMO_WEEKS * 7) for h, a in chosen):
            chosen.append(run)
    if len(chosen) < 4:
        raise ValueError("not enough distinct three week stretches for four demo housemates")
    members: dict[str, str] = {}
    for index, (home, at) in enumerate(chosen[:4]):
        known = {o.at: o.home for o in series_by_home[home]}
        members[f"m{index}"] = "".join("1" if known[at + timedelta(hours=i)] else "0" for i in range(DEMO_HOURS))
    return {
        "label": "demo filler derived from CASAS homes, not Filipino data and not student routines",
        "start": "2026-03-02T00:00",  # a Monday; the app moves the three weeks so they end at its most recent Monday
        "weeks": DEMO_WEEKS,
        "members": members,
        "source": SOURCE,
    }


def dart_constants_text(name: str, data: dict, note: str) -> str:
    text = json.dumps(data, indent=1, sort_keys=False)
    if "'''" in text:
        raise ValueError("JSON contains a triple quote, cannot embed it as a raw Dart string")
    return (
        f"// {note}\n"
        "// generated by AI/src/export_artifacts.py, do not edit by hand.\n"
        "import 'dart:convert';\n\n"
        f"final Map<String, dynamic> {name} = jsonDecode(r'''{text}''') as Map<String, dynamic>;\n"
    )


def _dump(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=1) + "\n", encoding="utf8")


def write_all(params: Params, series_by_home: Mapping[str, Sequence[Observation]], out_dir: Path = OUTPUT_DIR, dart_dir: Path = DART_DIR) -> None:
    files = {
        "home_forecast.json": params_to_json(params),
        "golden.json": build_golden(params),
        "demo_presence.json": build_demo_presence(series_by_home),
    }
    for name, data in files.items():
        _dump(out_dir / name, data)
    dart_dir.mkdir(parents=True, exist_ok=True)
    notes = {"home_forecast.json": "Fitted Home Forecast parameters.", "demo_presence.json": "Demo presence history (demo filler)."}
    for json_name, dart_name in DART_FILES.items():
        text = dart_constants_text(DART_NAMES[json_name], files[json_name], notes[json_name])
        (dart_dir / dart_name).write_text(text, encoding="utf8", newline="\n")
