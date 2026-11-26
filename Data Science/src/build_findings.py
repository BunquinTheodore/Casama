"""Build output/findings.json (every number) and output/series.json (every chart) from the raw sources.

The explorer page, the narration script and the video read only these two files, so they cannot disagree.
Hypotheses, the 7 day window, the 10 mm heavy rain day and the verdict rule were fixed before any result was read.
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
import pandas as pd

from config import HEAVY_RAIN_MM, MIN_GROUP, OUT_DIR, SENSITIVITY_DAYS, WINDOW_DAYS
from delivery_data import add_state, clean_delivered, delivered_orders, load_customers, load_raw
from eda import SERIES_NAMES, series as eda_series
from fetch_holidays import load_or_fetch_holidays
from fetch_weather import fetch_capital_coords, fetch_weather
from model import STAGES, auc_difference_ci, fit_stage, prepare_model_frame, split_by_time
from stats import adjusted_odds_ratios, late_rate_ci, verdict
from window_features import add_window_features

WEATHER_START, WEATHER_END = "2016-09-01", "2018-12-31"
HOLIDAY_YEARS = [2016, 2017, 2018]
ACCESSED = "2026-11-24"
SOURCES = [
    {"name": "Olist orders (Kaggle, zeynepustun)", "url": "https://www.kaggle.com/datasets/zeynepustun/customer-order-delivery-dataset"},
    {"name": "Olist customers (Kaggle, olistbr)", "url": "https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce"},
    {"name": "Open-Meteo Historical Weather API", "url": "https://open-meteo.com/en/docs/historical-weather-api"},
    {"name": "Nager.Date public holidays API", "url": "https://date.nager.at/Api"},
]


def _plain(value):
    """numpy to python, NaN to None, so the JSON is strict."""
    if isinstance(value, dict):
        return {k: _plain(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_plain(v) for v in value]
    if isinstance(value, np.bool_):
        return bool(value)
    if isinstance(value, np.integer):
        return int(value)
    if isinstance(value, (float, np.floating)):
        return None if np.isnan(value) else float(value)
    return value


def _ci_rows(table: pd.DataFrame, extra: dict | None = None) -> list[dict]:
    rows = []
    for r in table.itertuples():
        rows.append(
            {
                **(extra or {}),
                "group": str(r.group),
                "n": int(r.n),
                "late_pct": r.late_rate * 100,
                "ci_low": None if pd.isna(r.ci_low) else r.ci_low * 100,
                "ci_high": None if pd.isna(r.ci_high) else r.ci_high * 100,
                "reliable": bool(r.reliable),
            }
        )
    return rows


def load_analysis_inputs() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    raw = load_raw()
    delivered = delivered_orders(raw)
    clean = add_state(clean_delivered(delivered), load_customers())
    weather = fetch_weather(fetch_capital_coords(), WEATHER_START, WEATHER_END)
    holidays = load_or_fetch_holidays("BR", HOLIDAY_YEARS)
    return raw, delivered, clean, weather, holidays


def _exposure(df: pd.DataFrame) -> dict:
    # Parcels handed over in the same week share their weather and holidays, so intervals allow for clustering by week.
    by_week = df.assign(handoff_week=df["handoff_date"].dt.to_period("W").astype(str))
    ors = adjusted_odds_ratios(by_week, ["heavy_rain_days", "holiday_in_window"], cluster="handoff_week").set_index("term")

    def row(term: str) -> dict:
        r = ors.loc[term]
        return {
            "odds_ratio": float(r["odds_ratio"]),
            "ci_low": float(r["ci_low"]),
            "ci_high": float(r["ci_high"]),
        }

    return {"h1": row("heavy_rain_days"), "h2": row("holiday_in_window"), "excluded_rows": ors.attrs["dropped"]}


def _rain_bucket(heavy: pd.Series) -> pd.Series:
    return heavy.map(lambda v: None if pd.isna(v) else ("3 or more" if v >= 3 else str(int(v))))


def _exposure_series(df: pd.DataFrame) -> dict:
    work = df.assign(
        rain_bucket=_rain_bucket(df["heavy_rain_days"]),
        holiday_label=df["holiday_in_window"].map(lambda v: None if pd.isna(v) else ("Holiday in window" if v else "No holiday")),
        rain_any=df["heavy_rain_days"].map(lambda v: None if pd.isna(v) else ("rainy" if v >= 1 else "dry")),
    )
    state_rows = []
    for state, part in work.dropna(subset=["customer_state"]).groupby("customer_state"):
        state_rows += _ci_rows(late_rate_ci(part, "rain_any"), {"state": state})
    return {
        "rain_dose": _ci_rows(late_rate_ci(work, "rain_bucket")),
        "holiday_effect": _ci_rows(late_rate_ci(work, "holiday_label")),
        "state_rain": state_rows,
    }


def _fit_stages(df: pd.DataFrame, stage_names: list[str]) -> dict:
    frame, excluded = prepare_model_frame(df)
    train, test = split_by_time(frame)
    fits = {name: fit_stage(train, test, STAGES[name]) for name in stage_names}
    fits["_meta"] = {"model_rows": len(frame), "excluded": excluded, "train": len(train), "test": len(test)}
    return fits


def _h3(fits: dict) -> dict:
    s1, s2, s3, meta = fits["stage_1"], fits["stage_2"], fits["stage_3"], fits["_meta"]
    diff, low, high = auc_difference_ci(s2["truth"], s2["scores"], s3["scores"])
    outcome = "improved" if low > 0 else "worse" if high < 0 else "no clear improvement"
    added = [f for f in STAGES["stage_3"] if f not in STAGES["stage_2"]]
    top_added = max(added, key=lambda f: s3["importance"][f])
    return {
        "auc_stage_1": s1["roc_auc"],
        "auc_stage_2": s2["roc_auc"],
        "auc_stage_3": s3["roc_auc"],
        "diff": diff,
        "diff_ci_low": low,
        "diff_ci_high": high,
        "verdict": outcome,
        "alert_precision_stage_2": s2["alert_precision_pct"],
        "alert_recall_stage_2": s2["alert_recall_pct"],
        "alert_precision_stage_3": s3["alert_precision_pct"],
        "alert_recall_stage_3": s3["alert_recall_pct"],
        "top_feature_stage_3": max(s3["importance"], key=s3["importance"].get),
        "top_added_feature": top_added,
        "top_added_importance": s3["importance"][top_added],
        "importance_stage_3": s3["importance"],
        "model_rows": meta["model_rows"],
        "excluded_rows": meta["excluded"],
        "train_orders": meta["train"],
        "test_orders": meta["test"],
        "test_late_rate_pct": s3["base_late_rate_pct"],
    }


def _model_series(fits: dict) -> dict:
    stages = [n for n in fits if n != "_meta"]
    return {
        "roc_curves": [{"stage": n, **p} for n in stages for p in fits[n]["roc_points"]],
        "risk_deciles": [{"stage": n, **d} for n in ("stage_2", "stage_3") for d in fits[n]["risk_deciles"]],
        "importance": [{"stage": n, "feature": f, "value": v} for n in stages for f, v in fits[n]["importance"].items()],
    }


def _sensitivity(clean: pd.DataFrame, weather: pd.DataFrame, holidays: pd.DataFrame) -> dict:
    out = {}
    for days in SENSITIVITY_DAYS:
        df = add_window_features(clean, weather, holidays, days=days)
        fits = _fit_stages(df, ["stage_2", "stage_3"])
        diff, low, high = auc_difference_ci(fits["stage_2"]["truth"], fits["stage_2"]["scores"], fits["stage_3"]["scores"])
        e = _exposure(df)
        out[str(days)] = {"h1_or": e["h1"], "h2_or": e["h2"], "h3_diff": {"diff": diff, "ci_low": low, "ci_high": high}}
    return out


def _eda_facts(clean: pd.DataFrame, series: dict) -> tuple[dict, dict, dict]:
    month, handoff, promise = series["late_by_month"], series["late_by_handoff"], series["late_by_promise"]
    spread, rhythm, volume = series["delivery_spread"], series["order_rhythm"], series["volume_vs_late"]
    corr = {(r["row"], r["col"]): r["value"] for r in series["correlation"]}
    worst = max(month, key=lambda r: r["late_pct"])
    peak = max(rhythm, key=lambda r: r["orders"])
    volume_corr = np.corrcoef([r["orders"] for r in volume], [r["late_pct"] for r in volume])[0, 1]
    late = {
        "rate_pct": float(clean["is_late"].mean()) * 100,
        "late_parcels": int(clean["is_late"].sum()),
        "median_days_early": float(-clean["days_vs_estimate"].median()),
        "worst_month": worst["month"],
        "worst_month_late_pct": worst["late_pct"],
        "best_month_late_pct": min(r["late_pct"] for r in month),
        "late_pct_shortest_promise": promise[0]["late_pct"],
        "late_pct_longest_promise": promise[-1]["late_pct"],
        "volume_late_correlation": float(volume_corr),
    }
    days = {
        "median": float(clean["delivery_days"].median()),
        "mean": float(clean["delivery_days"].mean()),
        "p90": float(clean["delivery_days"].quantile(0.9)),
        "busiest_weekday": peak["weekday"],
        "busiest_hour": peak["hour"],
    }
    hand = {
        "late_pct_fast": handoff[0]["late_pct"],
        "late_pct_slow": handoff[-1]["late_pct"],
        "median_total_days_fast": spread[0]["median"],
        "median_total_days_slow": spread[-1]["median"],
        "corr_handoff_late": corr[("Seller handoff days", "Is late")],
    }
    return late, days, hand


def _hypotheses(series: dict, exposure: dict, window_n: int) -> tuple[dict, dict]:
    dose = {r["group"]: r for r in series["rain_dose"]}
    holiday = {r["group"]: r for r in series["holiday_effect"]}
    h1 = {
        "window_days": WINDOW_DAYS,
        "heavy_mm": HEAVY_RAIN_MM,
        "parcels": window_n,
        "dose": series["rain_dose"],
        "late_pct_no_heavy_rain": dose["0"]["late_pct"],
        "late_pct_three_or_more": dose["3 or more"]["late_pct"],
        "adjusted_or": exposure["h1"],
        "verdict": verdict(exposure["h1"]),
    }
    h2 = {
        "window_days": WINDOW_DAYS,
        "parcels_with_holiday": holiday["Holiday in window"]["n"],
        "late_pct_with_holiday": holiday["Holiday in window"]["late_pct"],
        "late_pct_without": holiday["No holiday"]["late_pct"],
        "adjusted_or": exposure["h2"],
        "verdict": verdict(exposure["h2"]),
    }
    return h1, h2


def _write(out_dir: Path, findings: dict, series: dict) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, payload in (("findings.json", findings), ("series.json", series)):
        (out_dir / name).write_text(json.dumps(payload, indent=2, ensure_ascii=False, allow_nan=False), encoding="utf-8")


def build(out_dir: Path = OUT_DIR) -> tuple[dict, dict]:
    raw, delivered, clean, weather, holidays = load_analysis_inputs()
    df = add_window_features(clean, weather, holidays, days=WINDOW_DAYS)
    series = {name: eda_series(name, clean, raw=raw, delivered=delivered) for name in SERIES_NAMES}
    series.update(_exposure_series(df))
    fits = _fit_stages(df, list(STAGES))
    series.update(_model_series(fits))
    late, days, hand = _eda_facts(clean, series)
    window_n = int(df["heavy_rain_days"].notna().sum())
    h1, h2 = _hypotheses(series, _exposure(df), window_n)
    timestamp_late = int(clean["is_late_timestamp"].sum())
    clock_only = int((clean["is_late_timestamp"] & ~clean["is_late"]).sum())
    findings = {
        "data_note": {
            "late_rule": "delivered on a later calendar day than the estimated date",
            "late_parcels_timestamp_rule": timestamp_late,
            "late_pct_timestamp_rule": timestamp_late / len(clean) * 100,
            "clock_only_late": clock_only,
            "clock_only_share_pct": clock_only / timestamp_late * 100,
        },
        "cleaning": {
            "raw_orders": len(raw),
            "delivered_with_date": len(delivered),
            "analysed": len(clean),
            "dropped": len(delivered) - len(clean),
            "undelivered": len(raw) - len(delivered),
            "kept_pct": len(clean) / len(raw) * 100,
        },
        "late": late,
        "delivery_days": days,
        "handoff": hand,
        "h1": h1,
        "h2": h2,
        "h3": _h3(fits),
        "sensitivity": _sensitivity(clean, weather, holidays),
        "limits": {
            "states": int(clean["customer_state"].nunique()),
            "weather_points": int(weather["state"].nunique()),
            "analysed": len(clean),
            "window_features_missing": len(df) - window_n,
            "min_group": MIN_GROUP,
            "first_purchase_month": str(clean["purchase_month"].min()),
            "last_purchase_month": str(clean["purchase_month"].max()),
        },
        "sources": [{**s, "accessed": ACCESSED} for s in SOURCES],
    }
    findings, series = _plain(findings), _plain(series)
    _write(out_dir, findings, series)
    return findings, series


if __name__ == "__main__":
    build()
