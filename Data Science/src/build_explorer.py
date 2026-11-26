"""Build explorer/index.html: one self contained page (fonts, styles, scripts and data inlined) that opens offline.

Every number in the prose is a placeholder such as {{late.rate_pct|2}} that is filled from findings.json, so the page
cannot disagree with the data. {{#if h1.verdict=supported}}...{{/if}} keeps only the sentence that matches a verdict.
"""

from __future__ import annotations

import base64
import html
import json
import re
from pathlib import Path
from typing import Any

from config import OUT_DIR, ROOT, SPLIT_MONTH

ADDED_LABELS = {
    "rain_mm_total": "total rain in the window",
    "heavy_rain_days": "the count of heavy rain days",
    "holiday_in_window": "the holiday flag",
}
EXPLORER = ROOT / "explorer"
TEMPLATE = EXPLORER / "template.html"
PLACEHOLDER = re.compile(r"\{\{\s*([A-Za-z0-9_.]+)(?:\|(\d+|raw))?\s*\}\}")
MONTH_NAMES = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
VARIANT = re.compile(r"\{\{#if ([A-Za-z0-9_.]+)=([^}]+)\}\}(.*?)\{\{/if\}\}", re.S)
FONTS = {"JosefinSans.woff2": ("Josefin Sans", "300"), "Manrope.woff2": ("Manrope", "400 700")}


def _lookup(data: dict, path: str) -> Any:
    value: Any = data
    for part in path.split("."):
        if not isinstance(value, dict) or part not in value:
            raise KeyError(f"placeholder path not found: {path}")
        value = value[part]
    return value


def _format(value: Any, decimals: str | None) -> str:
    if isinstance(value, bool) or isinstance(value, (list, dict)) or value is None:
        raise TypeError(f"cannot print {value!r} as text")
    if isinstance(value, str):
        return html.escape(value)
    if decimals == "raw":
        return str(value)
    if decimals is None and isinstance(value, float):
        raise TypeError(f"{value!r} is a float: write the placeholder with decimals, such as |2, or |raw")
    if decimals is not None:
        text = f"{value:,.{int(decimals)}f}"
        return text[1:] if text.startswith("-") and not text.strip("-0.,") else text  # no "-0.0"
    return f"{value:,}" if isinstance(value, int) else repr(value)


def render_placeholders(text: str, data: dict) -> str:
    return PLACEHOLDER.sub(lambda m: _format(_lookup(data, m.group(1)), m.group(2)), text)


def select_variants(text: str, data: dict) -> str:
    def pick(match: re.Match) -> str:
        return match.group(3) if str(_lookup(data, match.group(1))) == match.group(2) else ""

    return VARIANT.sub(pick, text)


def month_name(period: str) -> str:
    """'2018-03' becomes 'March 2018' so prose never contains a hyphenated date."""
    year, month = period.split("-")
    return f"{MONTH_NAMES[int(month) - 1]} {year}"


def display_fields(data: dict) -> dict:
    """A copy of the findings with readable month names derived from the data (nothing new is measured)."""
    out = {key: dict(value) if isinstance(value, dict) else value for key, value in data.items()}
    out["late"]["worst_month_name"] = month_name(data["late"]["worst_month"])
    out["limits"]["first_month_name"] = month_name(data["limits"]["first_purchase_month"])
    out["limits"]["last_month_name"] = month_name(data["limits"]["last_purchase_month"])
    out["limits"]["split_month_name"] = month_name(SPLIT_MONTH)
    if "top_added_feature" in out.get("h3", {}):
        out["h3"] = {**out["h3"], "top_added_label": ADDED_LABELS[out["h3"]["top_added_feature"]]}
    return out


def page_data(findings: dict, reuse: dict) -> dict:
    """Everything a template may quote: the findings, readable month names and the Philippine reuse pull."""
    return display_fields({**findings, "reuse": {**reuse, "first_five_text": ", ".join(reuse["first_five"])}})


def state_options_html(series: dict) -> str:
    """One option per state, the state with the most parcels first, so the first choice is the best sampled one."""
    totals: dict[str, int] = {}
    for row in series["state_rain"]:
        totals[row["state"]] = totals.get(row["state"], 0) + row["n"]
    ordered = sorted(totals, key=lambda state: (-totals[state], state))
    return "".join(f'<option value="{state}">{state}</option>' for state in ordered)


def month_options_html(series: dict, select_last: bool) -> str:
    months = [row["month"] for row in series["late_by_month"]]
    options = []
    for i, month in enumerate(months):
        year, number = month.split("-")
        mark = " selected" if select_last and i == len(months) - 1 else ""
        options.append(f'<option value="{month}"{mark}>{MONTH_NAMES[int(number) - 1][:3]} {year}</option>')
    return "".join(options)


def sources_html(findings: dict) -> str:
    items = "".join(
        f'<li><a href="{html.escape(s["url"])}">{html.escape(s["name"])}</a>, accessed {html.escape(s["accessed"])}</li>'
        for s in findings["sources"]
    )
    return f"<ul class=\"refs\">{items}</ul>"


def fonts_css() -> str:
    faces = []
    for filename, (family, weight) in FONTS.items():
        data = base64.b64encode((EXPLORER / "fonts" / filename).read_bytes()).decode()
        faces.append(
            f"@font-face{{font-family:'{family}';font-weight:{weight};font-style:normal;font-display:swap;"
            f"src:url(data:font/woff2;base64,{data}) format('woff2')}}"
        )
    return "".join(faces)


def _json_blob(payload: Any) -> str:
    return json.dumps(payload, ensure_ascii=False, allow_nan=False).replace("<", "\\u003c")


def build_explorer(
    findings: dict | None = None,
    series: dict | None = None,
    reuse: dict | None = None,
    out_path: Path = EXPLORER / "index.html",
) -> Path:
    findings = findings or json.loads((OUT_DIR / "findings.json").read_text(encoding="utf-8"))
    series = series or json.loads((OUT_DIR / "series.json").read_text(encoding="utf-8"))
    reuse = reuse or json.loads((OUT_DIR / "reuse_ph_2026.json").read_text(encoding="utf-8"))
    data = page_data(findings, reuse)

    body = (
        TEMPLATE.read_text(encoding="utf-8")
        .replace("{{@sources}}", sources_html(findings))
        .replace("{{@state_options}}", state_options_html(series))
        .replace("{{@month_options_from}}", month_options_html(series, select_last=False))
        .replace("{{@month_options_to}}", month_options_html(series, select_last=True))
    )
    body = render_placeholders(select_variants(body, data), data)
    head, visible = body.split("<body>", 1)
    body = head + "<body>" + visible.replace("Open-Meteo", '<span class="nb">Open-Meteo</span>')  # never break a name at its hyphen
    css = fonts_css() + (EXPLORER / "style.css").read_text(encoding="utf-8")
    page = (
        body.replace("/*@css*/", css)
        .replace("/*@js*/", (EXPLORER / "charts.js").read_text(encoding="utf-8"))
        .replace("/*@findings*/", _json_blob(findings))
        .replace("/*@series*/", _json_blob(series))
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(page, encoding="utf-8")
    return out_path


if __name__ == "__main__":
    print(build_explorer())
