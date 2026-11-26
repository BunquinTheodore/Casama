"""Unpack CASAS, derive hourly home or away for the homes that have usable labels, and write the data gate.

Output: AI/data/hourly/<home>.csv (git ignored) and AI/output/data_gate.json.
Run: python src/prepare_data.py
"""

from __future__ import annotations

import csv
import json
import zipfile
from datetime import datetime
from pathlib import Path
from typing import Mapping

from config import CASAS_DIR, HOURLY_DIR, OUTPUT_DIR
from derive_hourly import data_gate, home_hours_from_casas
from download_data import ensure_casas_zip
from home_forecast import Observation

HOME_FILES = {"aruba": "aruba.txt", "cairo": "cairo.txt", "milan": "milan.txt", "tulum1": "tulum1.txt", "tulum2": "tulum2.txt"}
STAMP = "%Y-%m-%dT%H:%M"


def write_hourly_csv(directory: Path, home_id: str, hours: list[tuple[datetime, bool]]) -> Path:
    directory.mkdir(parents=True, exist_ok=True)
    path = directory / f"{home_id}.csv"
    with open(path, "w", newline="", encoding="utf8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["hour_start", "home"])
        for at, home in hours:
            writer.writerow([at.strftime(STAMP), 1 if home else 0])
    return path


def load_series(directory: Path = HOURLY_DIR) -> dict[str, list[Observation]]:
    series: dict[str, list[Observation]] = {}
    for path in sorted(directory.glob("*.csv")):
        with open(path, newline="", encoding="utf8") as handle:
            rows = csv.DictReader(handle)
            series[path.stem] = [Observation(datetime.strptime(r["hour_start"], STAMP), r["home"] == "1") for r in rows]
    return series


def build(extract_dir: Path | None = None) -> tuple[Mapping[str, list[tuple[datetime, bool]]], Mapping[str, str]]:
    """Hourly series for the homes with Leave_Home and Enter_Home labels, and the reasons for the others."""
    zip_path = ensure_casas_zip()
    extract_dir = extract_dir or CASAS_DIR / "extracted"
    if not all((extract_dir / name).exists() for name in HOME_FILES.values()):
        with zipfile.ZipFile(zip_path) as archive:
            archive.extractall(extract_dir)
    series: dict[str, list[tuple[datetime, bool]]] = {}
    rejected: dict[str, str] = {}
    for home_id, file_name in HOME_FILES.items():
        try:
            series[home_id] = home_hours_from_casas(extract_dir / file_name)
        except ValueError as error:
            rejected[home_id] = str(error)
    return series, rejected


def main() -> None:
    series, rejected = build()
    for home_id, hours in series.items():
        write_hourly_csv(HOURLY_DIR, home_id, hours)
    report = data_gate(series, rejected)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUTPUT_DIR / "data_gate.json").write_text(json.dumps(report, indent=1) + "\n", encoding="utf8")
    for home in report["homes"]:
        print(home)
    print("gate passed:", report["passed"])


if __name__ == "__main__":
    main()
