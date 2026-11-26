"""The README is generated from metrics.json, so it cannot disagree with the data."""

import json
import re

import pytest

from build_readme import PLACEHOLDER, build_readme, format_value, lookup, placeholders, render
from check_references import extract_urls
from config import OUTPUT_DIR, ROOT, REPO_ROOT

METRICS = json.loads((OUTPUT_DIR / "metrics.json").read_text(encoding="utf-8"))
TEMPLATE = (ROOT / "README.template.md").read_text(encoding="utf-8")

# Every file of the 3rd year team that this project changed (see the README section Integration).
TOUCHED_THIRD_YEAR_FILES = [
    "lib/data/mock_repository.dart",
    "lib/features/parcels/parcels_screen.dart",
    "lib/features/settings/app_settings_screen.dart",
    "lib/features/legal/terms_privacy_screen.dart",
    "test/widget_test.dart",
    "pubspec.lock",
]


def test_every_placeholder_resolves():
    render(TEMPLATE, METRICS)  # raises KeyError naming the placeholder that does not resolve
    assert len(placeholders(TEMPLATE)) > 40


def test_unknown_placeholder_fails_loudly():
    with pytest.raises(KeyError, match="does not resolve"):
        render("{{horizons.3.model.nonsense|3}}", METRICS)


def test_format_value_decimals_percent_and_none():
    assert format_value(0.12345, "3") == "0.123"
    assert format_value(0.864, "pct") == "86"
    assert format_value(None, "3") == "n/a"
    assert format_value("aruba", None) == "aruba"


def test_readme_numbers_match_metrics(tmp_path):
    out = build_readme(tmp_path / "README.md")
    text = out.read_text(encoding="utf-8")
    assert not PLACEHOLDER.search(text), "an unfilled placeholder is left"
    allowed = set()

    def collect(value):
        if isinstance(value, dict):
            for v in value.values():
                collect(v)
        elif isinstance(value, list):
            for v in value:
                collect(v)
        elif isinstance(value, (int, float)) and not isinstance(value, bool):
            for places in range(0, 4):
                allowed.add(f"{float(value):.{places}f}")
            allowed.add(str(round(float(value) * 100)))

    collect(METRICS)
    prose = re.sub(r"```.*?```", "", text, flags=re.S)
    prose = re.sub(r"https?://\S+|`[^`]*`", "", prose)
    from_template = set(re.findall(r"\d+(?:\.\d+)?", TEMPLATE))
    for number in re.findall(r"(?<![\w.])\d+\.\d+(?![\w.])", prose):
        assert number in allowed or number in from_template, f"{number} is not in metrics.json or the template"


def test_readme_lists_every_touched_third_year_file():
    for path in TOUCHED_THIRD_YEAR_FILES:
        assert path in TEMPLATE, f"{path} is not listed in the README"
        assert (REPO_ROOT / path).exists(), f"{path} does not exist"


def test_no_dashes_before_labels_and_no_hyphenated_words_in_readme(tmp_path):
    text = build_readme(tmp_path / "README.md").read_text(encoding="utf-8")
    prose = re.sub(r"```.*?```", "", text, flags=re.S)
    prose = re.sub(r"https?://\S+|`[^`]*`", "", prose)
    prose = re.sub(r"\]\([^)]*\)", "]", prose)  # image and link targets are file names, not prose
    assert not re.search(r"[–—]", prose), "no en or em dashes"
    assert not re.search(r"\b[A-Za-z]+-[A-Za-z]+\b", prose), re.findall(r"\b[A-Za-z]+-[A-Za-z]+\b", prose)
    for line in prose.splitlines():
        assert not re.match(r"^\s*[-]\s", line.replace("* ", "")) or line.lstrip().startswith("|"), f"dash before a label: {line}"


def test_references_file_has_a_url_for_every_cited_source_in_the_readme():
    urls = extract_urls(ROOT / "REFERENCES.md")
    assert "https://zenodo.org/records/17180309" in urls
    assert any("10.1109/MC.2012.328" in u for u in urls)
    assert any("enbuild.2014.09.046" in u for u in urls)
    readme_urls = set(re.findall(r"https?://[^\s)>\]]+", TEMPLATE))
    for url in readme_urls:
        assert url.rstrip(".,;:") in urls or url.rstrip(".,;:") .startswith("https://zenodo.org/records/17180309"), url
