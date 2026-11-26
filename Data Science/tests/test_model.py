"""Task 8: three stage late parcel model, time split and the H3 comparison."""
import numpy as np
import pandas as pd
import pytest

from config import SPLIT_MONTH
from model import STAGES, auc_difference_ci, fit_stage, prepare_model_frame, split_by_time

OUTCOME_COLUMNS = {"delivery_days", "days_vs_estimate", "is_late", "is_late_timestamp", "order_delivered_customer_date"}


def synthetic(n=4000, seed=3):
    rng = np.random.default_rng(seed)
    frame = pd.DataFrame(
        {
            "purchase_month": rng.choice(["2017-03", "2017-11", "2018-02", "2018-05"], n),
            "estimated_days": rng.uniform(8, 35, n),
            "purchase_weekday": rng.integers(0, 7, n).astype(float),
            "purchase_hour": rng.integers(0, 24, n).astype(float),
            "month_of_year": rng.integers(1, 13, n).astype(float),
            "handoff_days": rng.uniform(0.2, 12, n),
            "heavy_rain_days": pd.array(rng.integers(0, 5, n), dtype="Int64"),
            "rain_mm_total": rng.uniform(0, 60, n),
            "holiday_in_window": pd.array(rng.random(n) < 0.15, dtype="boolean"),
        }
    )
    risk = 1 / (1 + np.exp(-(-3.2 + 0.35 * frame["handoff_days"].to_numpy())))
    frame["is_late"] = rng.random(n) < risk
    return frame


def test_split_has_no_overlap_and_respects_split_month():
    train, test = split_by_time(synthetic())
    assert (train["purchase_month"] < SPLIT_MONTH).all() and (test["purchase_month"] >= SPLIT_MONTH).all()
    assert set(train.index).isdisjoint(test.index) and len(train) and len(test)


def test_stages_nest_and_stage_three_adds_weather_and_holiday():
    assert set(STAGES["stage_1"]) < set(STAGES["stage_2"]) < set(STAGES["stage_3"])
    assert set(STAGES["stage_3"]) - set(STAGES["stage_2"]) == {"heavy_rain_days", "rain_mm_total", "holiday_in_window"}
    assert STAGES["stage_2"][-1] == "handoff_days"


def test_no_stage_uses_outcome_columns():
    for features in STAGES.values():
        assert OUTCOME_COLUMNS.isdisjoint(features)


def test_prepare_drops_na_rows_counts_them_and_casts_to_float():
    df = synthetic(n=500)
    df.loc[:9, "heavy_rain_days"] = pd.NA
    df.loc[10:14, "holiday_in_window"] = pd.NA
    df.loc[15:16, "handoff_days"] = np.nan
    prepared, dropped = prepare_model_frame(df)
    assert dropped == 17 and len(prepared) == 483
    assert all(prepared[c].dtype == "float64" for c in STAGES["stage_3"])


def test_fit_stage_returns_expected_keys_and_learns_the_signal():
    train, test = split_by_time(prepare_model_frame(synthetic())[0])
    result = fit_stage(train, test, STAGES["stage_2"])
    assert {"roc_auc", "average_precision", "alert_precision_pct", "alert_recall_pct", "importance", "roc_points", "risk_deciles", "scores", "truth"} <= set(result)
    assert result["roc_auc"] > 0.65
    assert set(result["importance"]) == set(STAGES["stage_2"])
    assert len(result["risk_deciles"]) == 10 and len(result["roc_points"]) == 101
    assert len(result["scores"]) == len(test)


def test_auc_difference_ci_zero_for_identical_scores():
    truth = np.random.default_rng(1).random(600) < 0.2
    scores = np.random.default_rng(2).random(600)
    assert auc_difference_ci(truth, scores, scores, n_boot=50) == (0.0, 0.0, 0.0)


def test_auc_difference_ci_detects_a_better_model():
    rng = np.random.default_rng(4)
    truth = rng.random(3000) < 0.2
    worse = rng.random(3000)
    better = truth * 0.6 + rng.random(3000) * 0.7
    diff, low, high = auc_difference_ci(truth, worse, better, n_boot=200)
    assert diff > 0.2 and 0 < low <= diff <= high


def test_metrics_are_returned_unrounded_so_display_rounds_only_once():
    from sklearn.metrics import roc_auc_score

    train, test = split_by_time(prepare_model_frame(synthetic())[0])
    result = fit_stage(train, test, STAGES["stage_2"])
    assert result["roc_auc"] == roc_auc_score(result["truth"], result["scores"])
    rng = np.random.default_rng(8)
    truth = rng.random(1500) < 0.25
    a, b = rng.random(1500), truth * 0.3 + rng.random(1500)
    diff, _, _ = auc_difference_ci(truth, a, b, n_boot=20)
    assert diff == roc_auc_score(truth, b) - roc_auc_score(truth, a)
