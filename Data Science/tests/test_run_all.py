"""Task 15: one command rebuilds every derived file, and the narration cannot drift from the findings."""
import json

import pytest

import run_all
from build_script import build_script
from config import OUT_DIR, ROOT


def test_run_all_builds_every_derived_output_in_order():
    assert [name for name, _ in run_all.steps()] == ["download", "findings", "reuse", "explorer", "readme", "narration"]


@pytest.mark.skipif(not (OUT_DIR / "findings.json").exists(), reason="run build_findings first")
def test_committed_narration_matches_the_script_and_the_findings(tmp_path):
    findings = json.loads((OUT_DIR / "findings.json").read_text(encoding="utf-8"))
    rebuilt = build_script(findings, out_path=tmp_path / "narration.json")
    assert json.loads((ROOT / "video" / "narration.json").read_text(encoding="utf-8")) == rebuilt, (
        "video/narration.json is stale: run python src/build_script.py (or src/run_all.py) before rendering the voice"
    )
