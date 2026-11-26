"""Task 6: bootstrap intervals, adjusted odds ratios and the pre declared verdict rule."""
import numpy as np
import pandas as pd
import pytest

from stats import adjusted_odds_ratios, late_rate_ci, verdict


def frame(n_by_group, rate=0.5, seed=1):
    rng = np.random.default_rng(seed)
    parts = []
    for group, n in n_by_group.items():
        late = np.zeros(n, dtype=bool)
        late[: int(round(n * rate))] = True
        rng.shuffle(late)
        parts.append(pd.DataFrame({"g": group, "is_late": late}))
    return pd.concat(parts, ignore_index=True)


def test_ci_contains_true_rate_on_known_sample():
    row = late_rate_ci(frame({"a": 200}), "g").iloc[0]
    assert row["late_rate"] == 0.5 and row["n"] == 200
    assert row["ci_low"] < 0.5 < row["ci_high"]
    assert row["ci_high"] - row["ci_low"] < 0.2


def test_same_seed_same_interval_and_different_seed_differs():
    df = frame({"a": 3001}, rate=0.37)
    one, again = late_rate_ci(df, "g", seed=3).iloc[0], late_rate_ci(df, "g", seed=3).iloc[0]
    assert (one["ci_low"], one["ci_high"]) == (again["ci_low"], again["ci_high"])
    distinct = {tuple(late_rate_ci(df, "g", seed=s).iloc[0][["ci_low", "ci_high"]]) for s in (3, 4, 5, 6)}
    assert len(distinct) > 1  # the seed really drives the draw


def test_group_under_min_is_unreliable_with_nan_interval():
    out = late_rate_ci(frame({"big": 40, "small": 10}), "g", min_group=30).set_index("group")
    assert bool(out.loc["big", "reliable"]) and not bool(out.loc["small", "reliable"])
    assert pd.isna(out.loc["small", "ci_low"]) and pd.isna(out.loc["small", "ci_high"])
    assert out.loc["small", "late_rate"] == 0.5  # the rate is still shown, only the interval is withheld


def test_rows_with_missing_group_are_ignored():
    df = pd.concat([frame({"a": 60}), pd.DataFrame({"g": [None] * 5, "is_late": [True] * 5})], ignore_index=True)
    assert list(late_rate_ci(df, "g")["group"]) == ["a"]


def logistic_frame(n=6000, holiday_or=1.0, seed=11):
    rng = np.random.default_rng(seed)
    df = pd.DataFrame(
        {
            "purchase_month": rng.choice(["2017-01", "2017-02", "2017-03"], n),
            "customer_state": rng.choice(["SP", "RJ", "MG"], n),
            "heavy_rain_days": pd.array(rng.integers(0, 4, n), dtype="Int64"),
            "holiday_in_window": pd.array(rng.random(n) < 0.3, dtype="boolean"),
        }
    )
    logit = -2.0 + np.log(holiday_or) * df["holiday_in_window"].astype(float).to_numpy()
    df["is_late"] = rng.random(n) < 1 / (1 + np.exp(-logit))
    return df


def test_adjusted_or_near_one_for_noise_exposure():
    out = adjusted_odds_ratios(logistic_frame(), ["heavy_rain_days", "holiday_in_window"]).set_index("term")
    assert out.loc["heavy_rain_days", "ci_low"] < 1 < out.loc["heavy_rain_days", "ci_high"]
    assert out.loc["holiday_in_window", "ci_low"] < 1 < out.loc["holiday_in_window", "ci_high"]


def test_adjusted_or_detects_a_planted_effect():
    out = adjusted_odds_ratios(logistic_frame(holiday_or=2.0), ["holiday_in_window"]).set_index("term")
    assert out.loc["holiday_in_window", "ci_low"] > 1
    assert out.loc["holiday_in_window", "odds_ratio"] == pytest.approx(2.0, rel=0.25)
    assert verdict(out.loc["holiday_in_window"]) == "supported"


def test_rows_with_na_exposure_are_dropped_and_counted():
    df = logistic_frame(n=3000)
    df.loc[:49, "heavy_rain_days"] = pd.NA
    out = adjusted_odds_ratios(df, ["heavy_rain_days"])
    assert out.attrs["dropped"] == 50


@pytest.mark.parametrize(
    "low, high, expected",
    [(1.05, 1.40, "supported"), (0.90, 1.30, "no clear effect"), (0.60, 0.95, "opposite"), (1.0, 1.2, "no clear effect")],
)
def test_verdict_rules(low, high, expected):
    assert verdict({"ci_low": low, "ci_high": high}) == expected


def test_group_with_no_late_parcels_gets_a_real_interval_not_zero_to_zero():
    df = pd.DataFrame({"g": ["a"] * 60, "is_late": [False] * 60})
    row = late_rate_ci(df, "g").iloc[0]
    assert row["late_rate"] == 0.0 and row["reliable"]
    assert row["ci_low"] == 0.0 and 0.04 < row["ci_high"] < 0.08  # Wilson upper bound for 0 of 60 is about 0.060


def test_group_with_only_late_parcels_gets_a_real_interval_not_one_to_one():
    df = pd.DataFrame({"g": ["a"] * 60, "is_late": [True] * 60})
    row = late_rate_ci(df, "g").iloc[0]
    assert row["ci_high"] == pytest.approx(1.0) and 0.92 < row["ci_low"] < 0.96


def test_cluster_robust_intervals_are_wider_when_parcels_in_a_cluster_are_alike():
    rng = np.random.default_rng(5)
    clusters, per = 80, 60
    cluster_id = np.repeat(np.arange(clusters), per)
    shock = rng.normal(0, 0.8, clusters)  # parcels sent in the same week share a shock
    exposure = np.repeat(rng.random(clusters) < 0.5, per)  # and the same exposure
    probability = 1 / (1 + np.exp(-(-2 + shock[cluster_id])))
    df = pd.DataFrame(
        {
            "purchase_month": rng.choice(["2017-01", "2017-02"], len(cluster_id)),
            "customer_state": rng.choice(["SP", "RJ"], len(cluster_id)),
            "is_late": rng.random(len(cluster_id)) < probability,
            "holiday_in_window": pd.array(exposure, dtype="boolean"),
            "week": cluster_id,
        }
    )
    naive = adjusted_odds_ratios(df, ["holiday_in_window"]).iloc[0]
    robust = adjusted_odds_ratios(df, ["holiday_in_window"], cluster="week").iloc[0]
    assert robust["odds_ratio"] == pytest.approx(naive["odds_ratio"])  # the estimate itself does not change
    assert robust["ci_high"] - robust["ci_low"] > 1.5 * (naive["ci_high"] - naive["ci_low"])
