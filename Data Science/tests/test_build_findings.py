"""Task 9: one findings.json and one series.json feed the page and the video (real data, run once)."""
import json

import pytest

from config import HEAVY_RAIN_MM
from delivery_data import CUSTOMERS_CSV, ORDERS_CSV
from eda import SERIES_NAMES
from stats import verdict

pytestmark = pytest.mark.skipif(not (ORDERS_CSV.exists() and CUSTOMERS_CSV.exists()), reason="raw Kaggle files not downloaded")

TOP_KEYS = {"data_note", "cleaning", "late", "delivery_days", "handoff", "h1", "h2", "h3", "sensitivity", "limits", "sources"}
EXTRA_SERIES = {"rain_dose", "holiday_effect", "state_rain", "roc_curves", "risk_deciles", "importance"}


@pytest.fixture(scope="module")
def built(tmp_path_factory):
    from build_findings import build

    out = tmp_path_factory.mktemp("out")
    findings, series = build(out_dir=out)
    return out, findings, series


def strict_load(path):
    def refuse(token):
        raise ValueError(f"non finite number in json: {token}")

    return json.loads(path.read_text(encoding="utf-8"), parse_constant=refuse)


def test_findings_has_required_keys_and_finite_json(built):
    out, findings, _ = built
    assert set(findings) == TOP_KEYS
    assert strict_load(out / "findings.json") == findings


def test_late_rate_matches_the_spec_on_real_data(built):
    findings = built[1]
    assert round(findings["late"]["rate_pct"], 2) == 6.51 and findings["late"]["late_parcels"] == 6229
    assert round(findings["data_note"]["late_pct_timestamp_rule"], 2) == 7.85
    assert findings["data_note"]["clock_only_late"] == 1290


def test_cleaning_counts(built):
    cleaning = built[1]["cleaning"]
    assert (cleaning["raw_orders"], cleaning["delivered_with_date"], cleaning["analysed"], cleaning["dropped"]) == (99441, 96476, 95736, 740)


def test_every_series_present_and_json_serialisable(built):
    out, _, series = built
    assert set(series) == set(SERIES_NAMES) | EXTRA_SERIES
    assert all(rows for rows in series.values())
    assert strict_load(out / "series.json") == series


def test_window_settings_are_recorded(built):
    h1 = built[1]["h1"]
    assert h1["window_days"] == 7 and h1["heavy_mm"] == HEAVY_RAIN_MM


def test_verdict_comes_from_the_rule_not_from_text(built):
    findings = built[1]
    assert findings["h1"]["verdict"] == verdict(findings["h1"]["adjusted_or"])
    assert findings["h2"]["verdict"] == verdict(findings["h2"]["adjusted_or"])


def test_h3_verdict_follows_the_interval(built):
    h3 = built[1]["h3"]
    expected = "improved" if h3["diff_ci_low"] > 0 else "worse" if h3["diff_ci_high"] < 0 else "no clear improvement"
    assert h3["verdict"] == expected
    assert h3["auc_stage_1"] < h3["auc_stage_2"]  # handoff time is a real signal


def test_dose_buckets_are_all_reliable(built):
    rows = built[2]["rain_dose"]
    assert [r["group"] for r in rows] == ["0", "1", "2", "3 or more"]
    assert all(r["reliable"] and r["ci_low"] is not None for r in rows)


def test_sensitivity_covers_ten_and_fourteen_days(built):
    sensitivity = built[1]["sensitivity"]
    assert set(sensitivity) == {"10", "14"}
    for result in sensitivity.values():
        assert {"h1_or", "h2_or", "h3_diff"} <= set(result)


def test_limits_report_exclusions(built):
    limits = built[1]["limits"]
    assert limits["window_features_missing"] == 1 and limits["states"] == 27


def test_values_are_stored_at_full_precision_and_rounded_once_at_display(built):
    findings = built[1]
    for section, key in [("h2", "late_pct_with_holiday"), ("h3", "diff"), ("late", "rate_pct")]:
        value = findings[section][key]
        assert round(value, 2) != value, f"{section}.{key} was rounded before display"
    # the two figures a double rounding used to print wrongly (677 of 13,682 is 4.948 percent; the gain is 0.03552)
    assert f"{findings['h2']['late_pct_with_holiday']:.1f}" == "4.9"
    assert f"{findings['h3']['diff']:.3f}" == "0.036"


def test_h3_names_the_added_signal_it_leans_on_most(built):
    h3 = built[1]["h3"]
    added = ["heavy_rain_days", "rain_mm_total", "holiday_in_window"]
    assert h3["top_added_feature"] in added
    assert h3["top_added_importance"] == max(h3["importance_stage_3"][name] for name in added)
    assert h3["importance_stage_3"][h3["top_added_feature"]] == h3["top_added_importance"]
