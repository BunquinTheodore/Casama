#!/usr/bin/env python3
"""Convert the Kaggle "Smart Home Energy Usage" occupancy data into Casama
presence_events seed rows.

Source dataset:
  https://www.kaggle.com/datasets/smayanj/smart-home-energy-usage-dataset

Target table (supabase/migrations/20261109000001_initial_schema.sql):
  presence_events(household_id, user_id, is_home, note, created_at)

The dataset records occupancy per household, not per person, and is not
Filipino data. The output is DEMO FILLER: each demo housemate gets a stream
derived from a different source household (or a time shifted, jittered copy
when the CSV has too few households). Treat it as synthetic history.

Usage:
  python scripts/presence_events_from_kaggle.py --csv path/to/data.csv \
      --out presence_seed.sql [--days 7] [--seed 42]

The output is a single INSERT that uses the PL/pgSQL variables from
supabase/seed.sql (v_household_id, v_user_jp, ...). Paste it inside the DO
block, after the household_members insert.

Only the standard library is used.
"""

from __future__ import annotations

import argparse
import csv
import random
import sys
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path

MEMBERS = ("v_user_jp", "v_user_maria", "v_user_alex", "v_user_ria")

HOME_VALUES = {"1", "true", "yes", "y", "occupied", "home", "present", "in"}
OUT_VALUES = {"0", "false", "no", "n", "vacant", "away", "out", "absent", "unoccupied"}

HOME_NOTES = ("Studying", "Home (Sleeping / Do Not Disturb)", "Cooking dinner", None, None)
OUT_NOTES = ("In class", "Out for groceries", "At work", None, None)

TIME_FORMATS = (
    "%Y-%m-%d %H:%M:%S",
    "%Y-%m-%dT%H:%M:%S",
    "%Y-%m-%d %H:%M",
    "%Y-%m-%d",
    "%m/%d/%Y %H:%M",
    "%d/%m/%Y %H:%M",
    "%m/%d/%Y",
)


@dataclass(frozen=True)
class Reading:
    household: str
    at: datetime
    is_home: bool


def parse_time(raw: str) -> datetime | None:
    text = raw.strip()
    for fmt in TIME_FORMATS:
        try:
            return datetime.strptime(text, fmt)
        except ValueError:
            continue
    try:
        return datetime.fromisoformat(text)
    except ValueError:
        return None


def parse_occupancy(raw: str) -> bool | None:
    value = raw.strip().lower()
    if value in HOME_VALUES:
        return True
    if value in OUT_VALUES:
        return False
    return None


def find_column(header: list[str], needles: tuple[str, ...]) -> str | None:
    for needle in needles:
        for name in header:
            if needle in name.lower():
                return name
    return None


def read_readings(csv_path: Path) -> list[Reading]:
    with csv_path.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        header = list(reader.fieldnames or [])
        occ_col = find_column(header, ("occupancy_status", "occupancy", "occupied"))
        time_col = find_column(header, ("timestamp", "datetime", "date_time", "time", "date"))
        house_col = find_column(header, ("household_id", "home_id", "household", "house_id"))
        if occ_col is None or time_col is None:
            sys.exit(
                "Could not find occupancy/time columns. Header was: "
                + ", ".join(header)
                + ". Edit find_column needles to match the real file."
            )

        readings: list[Reading] = []
        for row in reader:
            at = parse_time(row.get(time_col) or "")
            is_home = parse_occupancy(row.get(occ_col) or "")
            if at is None or is_home is None:
                continue
            household = (row.get(house_col) or "all") if house_col else "all"
            readings.append(Reading(household, at, is_home))
    if not readings:
        sys.exit("No usable rows found (check time and occupancy formats).")
    return readings


def transitions(readings: list[Reading]) -> list[Reading]:
    """Keep only rows where the status changed (an event log, not samples)."""
    ordered = sorted(readings, key=lambda r: r.at)
    events: list[Reading] = []
    for reading in ordered:
        if not events or events[-1].is_home != reading.is_home:
            events.append(reading)
    return events


def build_streams(readings: list[Reading], count: int) -> list[list[Reading]]:
    by_house: dict[str, list[Reading]] = {}
    for reading in readings:
        by_house.setdefault(reading.household, []).append(reading)
    ranked = sorted(by_house.values(), key=len, reverse=True)
    return [transitions(ranked[i % len(ranked)]) for i in range(count)]


def rebase(
    events: list[Reading], days: int, now: datetime, rng: random.Random, member_index: int
) -> list[tuple[timedelta, Reading]]:
    """Map the most recent `days` of the stream to end at `now`, jittered per member."""
    if not events:
        return []
    last = events[-1].at
    window_start = last - timedelta(days=days)
    jitter_minutes = member_index * 17
    rebased: list[tuple[timedelta, Reading]] = []
    for event in events:
        if event.at < window_start:
            continue
        age = (last - event.at) + timedelta(minutes=jitter_minutes + rng.randint(0, 20))
        rebased.append((age, event))
    return rebased


def sql_note(note: str | None) -> str:
    return "NULL" if note is None else "'" + note.replace("'", "''") + "'"


def build_sql(readings: list[Reading], days: int, seed: int) -> str:
    rng = random.Random(seed)
    streams = build_streams(readings, len(MEMBERS))
    now = datetime.now()
    rows: list[str] = []
    for index, (member, stream) in enumerate(zip(MEMBERS, streams)):
        for age, event in rebase(stream, days, now, rng, index):
            note = rng.choice(HOME_NOTES if event.is_home else OUT_NOTES)
            minutes = int(age.total_seconds() // 60)
            rows.append(
                f"        (v_household_id, {member}, "
                f"{'true' if event.is_home else 'false'}, {sql_note(note)}, "
                f"NOW() - INTERVAL '{minutes} minutes')"
            )
    if not rows:
        sys.exit("No events fell inside the requested window.")
    header = (
        "    -- Presence history generated from Kaggle smart-home occupancy data\n"
        "    -- (demo filler: per-person streams are derived, not real).\n"
        "    INSERT INTO presence_events (household_id, user_id, is_home, note, created_at)\n"
        "    VALUES\n"
    )
    return header + ",\n".join(rows) + ";\n"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--csv", type=Path, required=True, help="Downloaded Kaggle CSV")
    parser.add_argument("--out", type=Path, default=Path("presence_seed.sql"))
    parser.add_argument("--days", type=int, default=7, help="History window in days")
    parser.add_argument("--seed", type=int, default=42, help="RNG seed for repeatable output")
    args = parser.parse_args()

    readings = read_readings(args.csv)
    sql = build_sql(readings, args.days, args.seed)
    args.out.write_text(sql, encoding="utf-8")
    print(f"Wrote {sql.count(chr(10)) - 4} presence events to {args.out}")


if __name__ == "__main__":
    main()
