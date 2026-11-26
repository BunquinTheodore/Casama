"""Walk forward, leave one home out evaluation against baselines. Fixtures only (no real data)."""

import json
import random
from datetime import datetime, timedelta

import numpy as np
import pytest

import evaluate as ev
from home_forecast import HORIZONS, Grids, Observation, walk_forward_examples

MONDAY = datetime(2026, 3, 2)
SMALL = Grids(half_life_days=(14.0,), prior_strength=(2.0,), tau_hours=(3.0,))


def routine_home(seed: int, days: int = 60):
    rng = random.Random(seed)
    out, state = [], True
    for i in range(days * 24):
        t = MONDAY + timedelta(hours=i)
        target = 0.12 if (t.weekday() < 5 and 9 <= t.hour < 17) else 0.92
        state = rng.random() < (0.55 * target + 0.45 * (1.0 if state else 0.0))
        out.append(Observation(t, state))
    return out


HOMES = {"h1": routine_home(1), "h2": routine_home(2), "h3": routine_home(3)}


def run(homes=HOMES):
    return ev.evaluate(homes, grids=SMALL, notes={})


def test_walk_forward_never_uses_future_hours():
    base = routine_home(5, 40)
    cut = 30 * 24
    rng = random.Random(9)
    changed = base[:cut] + [Observation(o.at, rng.random() < 0.5) for o in base[cut:]]
    a = walk_forward_examples({"x": base}, 14.0, 2.0, [0.5] * 168)
    b = walk_forward_examples({"x": changed}, 14.0, 2.0, [0.5] * 168)
    n = (26 - 7) * 24 * len(HORIZONS)  # origins before day 26 have their targets (up to 72 hours later) inside the identical first 30 days
    for left, right in zip(a, b):
        assert np.array_equal(left[:n], right[:n])


def test_leave_one_home_out_excludes_held_out_home_from_prior_and_fit(monkeypatch):
    calls = []
    real_fit = ev.fit

    def spy(series, grids=None, **kwargs):
        calls.append(sorted(series))
        return real_fit(series, grids, **kwargs)

    monkeypatch.setattr(ev, "fit", spy)
    run()
    folds = [c for c in calls if len(c) == 2]
    assert len(folds) == 3
    assert {tuple(c) for c in folds} == {("h2", "h3"), ("h1", "h3"), ("h1", "h2")}
    assert ["h1", "h2", "h3"] in calls  # the final fit for the app uses every home


def test_baselines_return_expected_values_on_constant_series():
    ones = {"a": [Observation(MONDAY + timedelta(hours=i), True) for i in range(30 * 24)]}
    habit_v, state, ahead, y = walk_forward_examples(ones, 14.0, 2.0, [1.0] * 168)
    base = ev.baseline_predictions(train=(habit_v, state, ahead, y), test=(habit_v, state, ahead, y))
    for name in ("base_rate", "slot_mean", "persistence"):
        assert np.allclose(base[name], 1.0, atol=1e-3), name
    result = ev.metrics_of(y, base["base_rate"])
    assert result["accuracy"] == 1.0 and result["auc"] is None


def test_metrics_of_handles_single_class_and_perfect_prediction():
    y = np.array([1.0, 1.0, 0.0, 0.0])
    perfect = ev.metrics_of(y, np.array([0.99, 0.98, 0.01, 0.02]))
    assert perfect["auc"] == 1.0 and perfect["accuracy"] == 1.0 and perfect["n"] == 4
    assert ev.metrics_of(np.ones(3), np.array([0.9, 0.8, 0.7]))["auc"] is None


def test_metrics_json_has_every_documented_key():
    m = run()
    for key in ("data", "gate", "fragile", "horizons", "learning_curve", "cold_start", "calibration", "params", "caveats", "questions"):
        assert key in m, key
    assert set(m["horizons"]) == {"1", "3", "6", "12", "24", "48", "72"}
    for horizon in m["horizons"].values():
        for model in ("model", "base_rate", "slot_mean", "persistence", "gbm"):
            assert set(horizon[model]) >= {"auc", "brier", "log_loss", "accuracy", "n"}
    assert set(m["learning_curve"]) == {"3", "7", "14", "28"}
    assert set(m["cold_start"]) == {"with_prior", "flat_prior"}
    assert [d["id"] for d in m["data"]] == ["h1", "h2", "h3"]
    assert len(m["questions"]) == 4
    json.dumps(m)  # serialisable


def test_learning_curve_truncates_history_to_n_days():
    # Home for the first 20 days at every hour, then a routine. With a window of 3 days only the routine counts.
    old = [Observation(MONDAY + timedelta(hours=i), True) for i in range(20 * 24)]
    new = routine_home(4, 20)
    series = old + [Observation(MONDAY + timedelta(days=20, hours=i), o.home) for i, o in enumerate(new)]
    params = ev.fit({"a": series, "b": routine_home(6, 40)}, SMALL)
    short = ev.truncated_habit_examples({"a": series}, params, max_days=3, horizons=(3,))
    full = ev.truncated_habit_examples({"a": series}, params, max_days=60, horizons=(3,))
    assert len(short[0]) == len(full[0]) > 0
    assert not np.allclose(short[0], full[0]), "a 3 day window must not see the first 20 days"


def test_with_fewer_than_four_homes_results_are_marked_fragile():
    assert run()["fragile"] is True
    two = {"h1": HOMES["h1"], "h2": HOMES["h2"]}
    assert run(two)["fragile"] is True


def test_metrics_are_deterministic_for_same_input():
    assert json.dumps(run(), sort_keys=True) == json.dumps(run(), sort_keys=True)


def test_questions_are_answered_from_the_numbers():
    m = run()
    for q in m["questions"]:
        assert set(q) >= {"id", "question", "answer"}
        assert any(ch.isdigit() for ch in q["answer"]), q["id"]


def test_choose_prior_mode_goes_flat_only_when_it_clearly_wins():
    def cold(with_prior, flat):
        return {"with_prior": {"brier": with_prior}, "flat_prior": {"brier": flat}}

    assert ev.choose_prior_mode(cold(0.21, 0.17)) == "flat"
    assert ev.choose_prior_mode(cold(0.17, 0.21)) == "population"
    assert ev.choose_prior_mode(cold(0.1705, 0.1700)) == "population"  # within 0.001, keep the default


def test_base_rate_auc_is_reported_as_one_half():
    m = run()
    assert all(h["base_rate"]["auc"] == 0.5 for h in m["horizons"].values())


def test_prior_mode_is_recorded_and_both_cold_start_numbers_are_kept():
    m = ev.evaluate(HOMES, grids=SMALL, notes={}, prior_mode="flat")
    assert m["prior"]["mode"] == "flat"
    assert m["prior"]["cold_start_brier_with_population_prior"] is not None
    assert m["prior"]["cold_start_brier_flat_prior"] is not None
    assert "flat 50 percent" in m["questions"][2]["answer"]


def test_caveats_say_what_the_evaluation_cannot_show():
    text = " ".join(run()["caveats"])
    assert "same CASAS testbed" in text, "Tulum 1 and Tulum 2 may be one household"
    assert "yes or no choice" in text, "the flat prior was chosen by looking at held out forecasts"
    assert "1 to 72 hours" in text, "the evaluated range is stated"
    assert "coefficients fitted with the population prior" in text


def test_fold_spread_is_recorded_for_the_readme():
    m = run()
    assert len(m["fold_params"]) == 3
    assert all("b1" in f for f in m["fold_params"])
