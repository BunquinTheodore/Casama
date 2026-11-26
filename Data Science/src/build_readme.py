"""Write README.md from README.template.md and findings.json, so the README cannot disagree with the data."""

from __future__ import annotations

import json
from pathlib import Path

from build_explorer import display_fields, render_placeholders, select_variants
from config import OUT_DIR, ROOT


def build_readme(out_path: Path = ROOT / "README.md") -> Path:
    findings = display_fields(json.loads((OUT_DIR / "findings.json").read_text(encoding="utf-8")))
    template = (ROOT / "README.template.md").read_text(encoding="utf-8")
    out_path.write_text(render_placeholders(select_variants(template, findings), findings), encoding="utf-8")
    return out_path


if __name__ == "__main__":
    print(build_readme())
