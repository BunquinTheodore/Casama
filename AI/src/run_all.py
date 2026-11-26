"""Rebuild every output of the AI project from the CASAS download: gate, evaluation, parameters, test files.

Run: python src/run_all.py
It refuses to go past a failed data gate. Output: AI/output/*.json and lib/features/parcels/home_forecast/*_data.dart.
"""

from __future__ import annotations

import json
import sys

from config import HOURLY_DIR, OUTPUT_DIR
from derive_hourly import data_gate, gate_entry
from evaluate import _summary, evaluate
from export_artifacts import write_all
from home_forecast import Observation, fit
from prepare_data import build, write_hourly_csv

HOME_NOTES = {
    "aruba": {"multi_resident": False, "resident_note": "one resident, an older adult (CASAS listing)"},
    "tulum1": {"multi_resident": True, "resident_note": "reported to have two residents (CASAS listing, not stated in the Zenodo record)"},
    "tulum2": {"multi_resident": True, "resident_note": "reported to have two residents (CASAS listing, not stated in the Zenodo record)"},
}


def main() -> int:
    hours_by_home, rejected = build()
    gate = data_gate(hours_by_home, rejected)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUTPUT_DIR / "data_gate.json").write_text(json.dumps(gate, indent=1) + "\n", encoding="utf8")
    if not gate["passed"]:
        print("DATA GATE FAILED: fewer than", gate["min_homes"], "usable homes. Stopping.", file=sys.stderr)
        return 1
    usable = [h["id"] for h in gate["homes"] if h["usable"]]
    series = {}
    for home_id in usable:
        write_hourly_csv(HOURLY_DIR, home_id, hours_by_home[home_id])
        series[home_id] = [Observation(at, home) for at, home in hours_by_home[home_id]]
    print("usable homes:", usable)

    metrics = evaluate(series, notes=HOME_NOTES)
    (OUTPUT_DIR / "metrics.json").write_text(json.dumps(metrics, indent=1) + "\n", encoding="utf8")

    params = fit(series, flat_prior=(metrics["prior"]["mode"] == "flat"))
    assert _summary(params) == metrics["params"], "the exported parameters must be the ones evaluated"
    write_all(params, series)
    print("wrote metrics.json, home_forecast.json, golden.json, demo_presence.json and the Dart constants")
    for q in metrics["questions"]:
        print("-", q["answer"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
