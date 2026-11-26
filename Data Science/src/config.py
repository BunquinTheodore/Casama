"""Shared paths and fixed analysis settings (see the design doc for why each value is fixed)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "data" / "raw"
CACHE_DIR = ROOT / "data" / "cache"
OUT_DIR = ROOT / "output"

SPLIT_MONTH = "2018-01"          # train before, test from
WINDOW_DAYS = 7                  # calendar days starting on the carrier handoff date
SENSITIVITY_DAYS = (10, 14)      # reported beside the 7 day headline
MIN_GROUP = 30                   # smaller groups get no interval
SEED = 7
N_BOOT = 2000

# A heavy rain day is a day with at least this much rain. Source: ETCCDI climate index R10mm,
# "count of days when PRCP >= 10mm", https://etccdi.pacificclimate.org/list_27_indices.shtml (accessed 2026-11-24).
# The page does not use the word "heavy"; calling such a day heavy is this project's label.
# Fixed before any rain result was computed.
HEAVY_RAIN_MM = 10.0
