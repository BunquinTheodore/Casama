"""Rebuild every derived file from an empty data/ folder: python src/run_all.py (no API keys needed).

Order matters: the findings feed the page, the README and the narration, and the reuse pull feeds the page and the narration.
"""

from __future__ import annotations

import json
from typing import Callable

from config import OUT_DIR
from delivery_data import CUSTOMERS_CSV, ORDERS_CSV


def _download() -> None:
    if not (ORDERS_CSV.exists() and CUSTOMERS_CSV.exists()):
        from download_data import download_all

        download_all()


def _findings() -> None:
    from build_findings import build

    build()


def _reuse() -> None:
    from fetch_holidays import reuse_demo

    reuse_demo()


def _explorer() -> None:
    from build_explorer import build_explorer

    build_explorer()


def _readme() -> None:
    from build_readme import build_readme

    build_readme()


def _narration() -> None:
    from build_script import build_script

    build_script(json.loads((OUT_DIR / "findings.json").read_text(encoding="utf-8")))


def steps() -> list[tuple[str, Callable[[], None]]]:
    return [
        ("download", _download),
        ("findings", _findings),
        ("reuse", _reuse),
        ("explorer", _explorer),
        ("readme", _readme),
        ("narration", _narration),
    ]


def main() -> None:
    for name, step in steps():
        print(f"[{name}]", flush=True)
        step()


if __name__ == "__main__":
    main()
