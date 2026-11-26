"""Task 12: the narration is generated from a template and findings.json, so it cannot disagree with the page."""
import json
import re

import pytest

from build_script import SCENE_IDS, build_script
from config import OUT_DIR, ROOT

SCRIPT = ROOT / "video" / "script.md"
pytestmark = pytest.mark.skipif(
    not all((OUT_DIR / n).exists() for n in ("findings.json", "reuse_ph_2026.json")), reason="run build_findings first"
)
MEMBERS = ["theodore", "bunquin", "christian", "nayre", "daniel", "villanueva", "alcaraz", "john", "paul", "theoraux"]  # the spec keeps the group name out of the voice text too


@pytest.fixture(scope="module")
def findings():
    return json.loads((OUT_DIR / "findings.json").read_text(encoding="utf-8"))


@pytest.fixture(scope="module")
def scenes(findings, tmp_path_factory):
    return build_script(findings, out_path=tmp_path_factory.mktemp("n") / "narration.json")


def numbers_in(value):
    if isinstance(value, bool):
        return
    if isinstance(value, (int, float)):
        yield float(value)
    elif isinstance(value, dict):
        for v in value.values():
            yield from numbers_in(v)
    elif isinstance(value, list):
        for v in value:
            yield from numbers_in(v)


def test_scene_ids_match_the_list_in_order(scenes):
    assert [s["id"] for s in scenes] == SCENE_IDS == [
        "title", "question", "data", "cleaning", "shows", "weather", "model", "takeaways", "casama", "limits", "credits"
    ]


def test_total_words_between_1200_and_1450(scenes):
    words = sum(len(s["text"].split()) for s in scenes)
    assert 1200 <= words <= 1450, f"{words} words"


def test_template_has_no_hand_typed_digits():
    template = re.sub(r"\{\{[^}]+\}\}", "", SCRIPT.read_text(encoding="utf-8"))
    assert not re.search(r"\d", template), "write numbers as placeholders so they come from findings.json"


def test_every_number_in_narration_comes_from_findings(scenes, findings):
    from config import SPLIT_MONTH

    known = list(numbers_in(findings)) + [2026.0, 18.0]  # the reuse pull (year, holiday count) is checked in its own test
    known += [float(year) for year in re.findall(r"(?<!\d)(20\d\d)(?!\d)", json.dumps(findings))]  # years inside month strings such as 2018-03
    known.append(float(SPLIT_MONTH[:4]))
    for scene in scenes:
        for token in re.findall(r"\d[\d,]*\.?\d*", scene["text"]):
            token = token.rstrip(".,")
            value = float(token.replace(",", ""))
            places = len(token.split(".")[1]) if "." in token else 0
            assert any(round(k, places) == value for k in known), f"{token} in scene {scene['id']} is not a findings number"


def test_reuse_numbers_come_from_the_reuse_file(scenes):
    reuse = json.loads((OUT_DIR / "reuse_ph_2026.json").read_text(encoding="utf-8"))
    casama = next(s["text"] for s in scenes if s["id"] == "casama")
    assert str(reuse["holiday_count"]) in casama and str(reuse["year"]) in casama


def test_no_member_names_in_narration(scenes):
    text = " ".join(s["text"] for s in scenes).lower()
    assert not [name for name in MEMBERS if re.search(rf"\b{name}\b", text)]


def test_no_dashes_and_no_leftover_markup(scenes):
    for scene in scenes:
        assert not re.search(r"[-–—]|\{\{|\}\}|<", scene["text"]), scene["id"]


def test_unresolved_placeholder_raises(findings, tmp_path):
    bad = tmp_path / "script.md"
    bad.write_text("\n\n".join(f"## {i}\n\n{{{{no.such}}}}" for i in SCENE_IDS), encoding="utf-8")
    with pytest.raises(KeyError):
        build_script(findings, template=bad, out_path=tmp_path / "n.json")


def test_template_must_have_exactly_the_scene_ids(findings, tmp_path):
    bad = tmp_path / "script.md"
    bad.write_text("## title\n\nhello", encoding="utf-8")
    with pytest.raises(ValueError, match="scene"):
        build_script(findings, template=bad, out_path=tmp_path / "n.json")


def test_writes_narration_json(findings, tmp_path):
    out = tmp_path / "narration.json"
    scenes = build_script(findings, out_path=out)
    assert json.loads(out.read_text(encoding="utf-8")) == scenes
