"""Task 10: the explorer page is built from the template and the two JSON files, offline and without invented numbers."""
import html as htmllib
import json
import re
from html.parser import HTMLParser

import pytest

from build_explorer import TEMPLATE, build_explorer, display_fields, render_placeholders, select_variants
from config import OUT_DIR, ROOT
from test_number_parity import run_js

needs_outputs = pytest.mark.skipif(
    not all((OUT_DIR / n).exists() for n in ("findings.json", "series.json", "reuse_ph_2026.json")),
    reason="run build_findings first",
)
DASHES = ("-", "–", "—")


def test_unresolved_placeholder_raises_keyerror_naming_the_path():
    with pytest.raises(KeyError, match="no.such"):
        render_placeholders("a {{no.such}} b", {"a": 1})


def test_placeholder_formats():
    data = {"n": 95736, "pct": 6.51, "x": {"or": 0.54623}, "word": "a & b", "year": 2026}
    assert render_placeholders("{{n}}|{{pct|2}}|{{x.or|2}}|{{x.or|3}}|{{pct|1}}|{{word}}", data) == "95,736|6.51|0.55|0.546|6.5|a &amp; b"
    assert render_placeholders("{{year|raw}}", data) == "2026"


def test_display_fields_derive_month_names_from_the_data():
    data = {"late": {"worst_month": "2018-03"}, "limits": {"first_purchase_month": "2017-01", "last_purchase_month": "2018-08"}}
    out = display_fields(data)
    assert out["late"]["worst_month_name"] == "March 2018"
    assert out["limits"]["first_month_name"] == "January 2017" and out["limits"]["last_month_name"] == "August 2018"
    assert out["limits"]["split_month_name"] == "January 2018"  # from config.SPLIT_MONTH
    assert "worst_month_name" not in data["late"]  # the input is not mutated


def test_variant_selection_keeps_only_the_matching_branch():
    text = "{{#if h.verdict=no clear effect}}KEEP{{/if}}{{#if h.verdict=supported}}DROP{{/if}}{{#if h.verdict=opposite}}DROP{{/if}}"
    assert select_variants(text, {"h": {"verdict": "no clear effect"}}) == "KEEP"


def test_variant_with_unknown_path_raises():
    with pytest.raises(KeyError):
        select_variants("{{#if h.verdict=x}}a{{/if}}", {"h": {}})


class TextCollector(HTMLParser):
    """Collects text per tag name, ignoring script and style."""

    def __init__(self):
        super().__init__()
        self.stack, self.texts, self.hr, self.ids = [], [], 0, []

    def handle_starttag(self, tag, attrs):
        self.stack.append(tag)
        if tag == "hr":
            self.hr += 1
        self.ids += [v for k, v in attrs if k == "id"]

    def handle_endtag(self, tag):
        if tag in self.stack:
            while self.stack.pop() != tag:
                pass

    def handle_data(self, data):
        if data.strip() and not {"script", "style"} & set(self.stack):
            self.texts.append((self.stack[-1] if self.stack else "", data.strip(), tuple(self.stack)))


def collect(markup):
    parser = TextCollector()
    parser.feed(markup)
    return parser


@pytest.fixture(scope="module")
def page(tmp_path_factory):
    out = tmp_path_factory.mktemp("page") / "index.html"
    build_explorer(out_path=out)
    return out.read_text(encoding="utf-8")


@needs_outputs
def test_sections_s01_to_s10_present_in_order(page):
    ids = [i for i in collect(page).ids if re.fullmatch(r"s\d\d", i)]
    assert ids == [f"s{n:02d}" for n in range(1, 11)]


@needs_outputs
def test_page_makes_no_external_requests(page):
    assert not re.search(r"<script[^>]+src=", page) and not re.search(r"<link\b", page)
    assert not re.search(r"<img[^>]+src=[\"']?https?:", page) and "@import" not in page and "url(http" not in page


@needs_outputs
def test_no_leading_dash_or_rule_before_labels(page):
    parser = collect(page)
    assert parser.hr == 0
    labelled = [t for tag, t, _ in parser.texts if tag in {"h1", "h2", "h3", "dt", "th", "figcaption", "label", "a"}]
    assert labelled and not [t for t in labelled if t.startswith(DASHES)]


def test_every_number_in_prose_has_a_placeholder():
    prose_tags = {"p", "li", "td", "dd", "figcaption", "b", "span"}
    template = TEMPLATE.read_text(encoding="utf-8")
    template = re.sub(r"\{\{#if [^}]+\}\}|\{\{/if\}\}", "", template)
    template = re.sub(r"\{\{[^}]+\}\}", "", template).replace("R10mm", "")  # R10mm is the name of a published climate index
    bare = [
        t for tag, t, stack in collect(template).texts
        if tag in prose_tags and "label" not in tag and re.search(r"\d", t)
        and not any(c in {"label"} for c in stack)
    ]
    assert not bare, f"digits written by hand in prose: {bare[:3]}"


@needs_outputs
def test_headline_numbers_come_from_findings(page):
    findings = json.loads((OUT_DIR / "findings.json").read_text(encoding="utf-8"))
    assert f"{findings['late']['rate_pct']:.2f}" in page
    assert f"{findings['cleaning']['analysed']:,}" in page


@needs_outputs
def test_reuse_box_shows_ph_2026_values(page):
    reuse = json.loads((OUT_DIR / "reuse_ph_2026.json").read_text(encoding="utf-8"))
    section = page[page.index('id="s08"'):page.index('id="s09"')]
    assert str(reuse["holiday_count"]) in section
    assert all(htmllib.escape(name) in section for name in reuse["first_five"])


@needs_outputs
def test_json_blobs_are_embedded_and_safe(page):
    match = re.search(r'<script id="findings" type="application/json">(.*?)</script>', page, re.S)
    assert match and json.loads(match.group(1))["late"]["rate_pct"]
    assert re.search(r'<script id="series" type="application/json">', page)


@needs_outputs
def test_hyphenated_names_never_break_across_lines(page):
    body = page[page.index("<body>"): page.index('<script id="findings"')]
    bare = re.findall(r'(?<!<span class="nb">)Open-Meteo', body)
    assert not bare, f"{len(bare)} unprotected Open-Meteo in the visible page"
    assert '.nb{white-space:nowrap}' in page


def load_series():
    return json.loads((OUT_DIR / "series.json").read_text(encoding="utf-8"))


@needs_outputs
def test_state_filter_lists_every_state_most_parcels_first(page):
    select = re.search(r'<select id="state-filter"[^>]*>(.*?)</select>', page, re.S).group(1)
    codes = re.findall(r'<option value="([A-Z]{2})"', select)
    totals = {}
    for row in load_series()["state_rain"]:
        totals[row["state"]] = totals.get(row["state"], 0) + row["n"]
    assert len(codes) == 27 and codes == sorted(totals, key=lambda s: (-totals[s], s))


@needs_outputs
def test_month_filter_covers_every_month_and_defaults_to_the_full_range(page):
    months = [r["month"] for r in load_series()["late_by_month"]]
    start = re.search(r'<select id="month-from"[^>]*>(.*?)</select>', page, re.S).group(1)
    end = re.search(r'<select id="month-to"[^>]*>(.*?)</select>', page, re.S).group(1)
    assert re.findall(r'<option value="([\d-]+)"', start) == months == re.findall(r'<option value="([\d-]+)"', end)
    assert f'<option value="{months[-1]}" selected>' in end and "selected" not in start


@needs_outputs
def test_quiz_has_three_questions_with_data_driven_answers(page):
    assert page.count('<fieldset class="q"') == 3
    assert 'id="quiz-result"' in page


@needs_outputs
def test_filter_logic_matches_python_filtering():
    source = (ROOT / "explorer" / "charts.js").read_text(encoding="utf-8")
    block = re.search(r"// FILTER START(.*?)// FILTER END", source, re.S)
    assert block, "charts.js must keep its filter logic between FILTER START and FILTER END markers"
    series = load_series()
    months = [r["month"] for r in series["late_by_month"]]
    program = f"""
const f = new Function({json.dumps(block.group(1))} + "; return {{stateRainRows, monthRange}};")();
const s = JSON.parse(await new Promise(r => {{ let t=''; process.stdin.on('data', d => t += d); process.stdin.on('end', () => r(t)); }}));
const states = [...new Set(s.state_rain.map(r => r.state))];
console.log(JSON.stringify({{states: Object.fromEntries(states.map(st => [st, f.stateRainRows(s.state_rain, st)])), months: [[0, s.late_by_month.length - 1], [3, 9], [5, 5]].map(([a, b]) => f.monthRange(s.late_by_month, s.late_by_month[a].month, s.late_by_month[b].month))}}));
"""
    got = run_js(program, series)
    for state, rows in got["states"].items():
        expected = [{k: r[k] for k in ("group", "n", "late_pct", "ci_low", "ci_high", "reliable")} for r in series["state_rain"] if r["state"] == state]
        assert rows == expected
    for (a, b), rows in zip([(0, len(months) - 1), (3, 9), (5, 5)], got["months"]):
        assert [r["month"] for r in rows] == months[a : b + 1]


@needs_outputs
def test_cleaning_text_only_claims_filters_that_exist(page):
    assert "handoff after delivery" not in page
    assert "handoff after delivery" not in (ROOT / "src" / "delivery_data.py").read_text(encoding="utf-8")


def test_reveal_observer_fires_even_for_very_tall_sections():
    source = (ROOT / "explorer" / "charts.js").read_text(encoding="utf-8")
    assert re.search(r"IntersectionObserver\(.*?\{\s*threshold:\s*0\s*\}", source, re.S), (
        "a section taller than the screen never reaches a positive threshold, so it would stay invisible"
    )


def test_float_placeholder_without_decimals_is_refused():
    with pytest.raises(TypeError, match="decimals"):
        render_placeholders("{{x}}", {"x": 6.5064})
    assert render_placeholders("{{x|2}}|{{n}}|{{x|raw}}", {"x": 6.5064, "n": 12}) == "6.51|12|6.5064"


def test_display_fields_label_the_top_added_signal_in_words():
    data = {
        "late": {"worst_month": "2018-03"},
        "limits": {"first_purchase_month": "2017-01", "last_purchase_month": "2018-08"},
        "h3": {"top_added_feature": "rain_mm_total"},
    }
    assert display_fields(data)["h3"]["top_added_label"] == "total rain in the window"
    assert "top_added_label" not in data["h3"]
