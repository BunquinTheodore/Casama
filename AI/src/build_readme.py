"""Write README.md from README.template.md and output/metrics.json, so the README cannot disagree with the data.

Placeholders look like {{horizons.3.model.brier|3}}: a dotted path into metrics.json (dict keys or list
indexes) and an optional format, a number of decimals or `pct` (a fraction shown as a whole percent).
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from config import OUTPUT_DIR, ROOT

PLACEHOLDER = re.compile(r"\{\{\s*([A-Za-z0-9_.]+)\s*(?:\|\s*([A-Za-z0-9]+)\s*)?\}\}")


DISPLAY_NAMES = {"aruba": "Aruba", "tulum1": "Tulum 1", "tulum2": "Tulum 2", "cairo": "Cairo", "milan": "Milan"}


def facts(metrics: dict) -> dict:
    """The metrics plus a few derived numbers the template needs."""
    n = len(metrics["data"])
    data = [{**home, "name": DISPLAY_NAMES.get(home["id"], home["id"])} for home in metrics["data"]]
    b1 = [f["b1"] for f in metrics.get("fold_params", [])] or [metrics["params"]["b1"]]
    return {**metrics, "data": data, "n_homes": n, "fold_homes": max(n - 1, 0), "fold_b1_min": min(b1), "fold_b1_max": max(b1)}


def lookup(data: Any, path: str) -> Any:
    value = data
    for part in path.split("."):
        value = value[int(part)] if isinstance(value, list) else value[part]
    return value


def format_value(value: Any, spec: str | None) -> str:
    if value is None:
        return "n/a"
    if spec == "pct":
        return str(round(float(value) * 100))
    if spec and spec.isdigit():
        return f"{float(value):.{int(spec)}f}"
    return str(value)


def placeholders(template: str) -> list[str]:
    return [m.group(1) for m in PLACEHOLDER.finditer(template)]


def render(template: str, metrics: dict) -> str:
    data = facts(metrics)

    def fill(match: re.Match) -> str:
        try:
            return format_value(lookup(data, match.group(1)), match.group(2))
        except (KeyError, IndexError, ValueError) as error:
            raise KeyError(f"README placeholder {match.group(0)} does not resolve in metrics.json ({error!r})") from error

    return PLACEHOLDER.sub(fill, template)


def build_readme(out_path: Path = ROOT / "README.md") -> Path:
    metrics = json.loads((OUTPUT_DIR / "metrics.json").read_text(encoding="utf-8"))
    template = (ROOT / "README.template.md").read_text(encoding="utf-8")
    out_path.write_text(render(template, metrics), encoding="utf-8")
    return out_path


if __name__ == "__main__":
    print(build_readme())
