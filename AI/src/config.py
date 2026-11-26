"""Paths and constants shared by the AI project scripts."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw"
CASAS_DIR = RAW_DIR / "casas"
HOURLY_DIR = ROOT / "data" / "hourly"
OUTPUT_DIR = ROOT / "output"
REPO_ROOT = ROOT.parent

CASAS_RECORD_URL = "https://zenodo.org/records/17180309"
CASAS_ZIP_URL = "https://zenodo.org/records/17180309/files/new_labeled_data.zip?download=1"
CASAS_ZIP_NAME = "new_labeled_data.zip"
CASAS_ZIP_BYTES = 33_021_523
CASAS_LICENCE = "CC BY 4.0"

MIN_USABLE_DAYS = 42
MIN_COVERAGE = 0.70
MIN_USABLE_HOMES = 2
