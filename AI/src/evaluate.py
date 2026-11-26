"""Walk forward, leave one home out evaluation of the Home Forecast against simple baselines.

For each home in turn: the prior and the coefficients are fitted on the OTHER homes only, then the held
out home is forecast hour by hour using only earlier hours. Results are pooled over the folds.
Output: the dict written to AI/output/metrics.json (the single source of truth for README and video).
"""

from __future__ import annotations

import math
from datetime import timedelta
from typing import Mapping, Sequence

import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.metrics import roc_auc_score

from derive_hourly import data_gate
from home_forecast import (
    EPS,
    HORIZONS,
    HOUR,
    SLOTS,
    WARMUP_DAYS,
    Grids,
    Observation,
    Params,
    _logit_array,
    fit,
    slot_of,
    walk_forward_examples,
)

LEARNING_DAYS = (3, 7, 14, 28)
COLD_START_DAYS = 7
COLD_START_HORIZON = 3
FLAT_PRIOR = [0.5] * SLOTS
PLAIN = (1e9, 1e-9, FLAT_PRIOR)  # no forgetting, no smoothing: the plain hour of week average
MODELS = ("model", "base_rate", "slot_mean", "persistence", "gbm")


def predict(params: Params, habit: np.ndarray, state: np.ndarray, ahead: np.ndarray) -> np.ndarray:
    z = params.b0 + params.b1 * _logit_array(habit) + params.b2 * state * np.exp(-ahead / params.tau_hours)
    return 1.0 / (1.0 + np.exp(-np.clip(z, -35.0, 35.0)))


def _round(value: float | None) -> float | None:
    return None if value is None else round(float(value), 6)


def metrics_of(y: np.ndarray, p: np.ndarray) -> dict:
    p = np.clip(np.asarray(p, dtype=float), EPS, 1.0 - EPS)
    y = np.asarray(y, dtype=float)
    two_classes = len(np.unique(y)) == 2
    return {
        "auc": _round(roc_auc_score(y, p)) if two_classes else None,
        "brier": _round(np.mean((p - y) ** 2)),
        "log_loss": _round(-np.mean(y * np.log(p) + (1 - y) * np.log(1 - p))),
        "accuracy": _round(np.mean((p >= 0.5) == (y == 1.0))),
        "n": int(len(y)),
    }


def baseline_predictions(train: tuple, test: tuple, plain: tuple | None = None) -> dict[str, np.ndarray]:
    """base_rate: the training share of home hours. slot_mean: the plain hour of week average.
    persistence: the training chance of being home h hours after being home (or out) now."""
    _, train_state, train_ahead, train_y = train[:4]
    _, test_state, test_ahead, _ = test[:4]
    rate = float(np.clip(train_y.mean(), EPS, 1.0 - EPS)) if len(train_y) else 0.5
    table: dict[tuple[float, float], float] = {}
    for h in np.unique(test_ahead):
        for s in (1.0, -1.0):
            mask = (train_ahead == h) & (train_state == s)
            table[(float(h), s)] = float(np.clip(train_y[mask].mean(), EPS, 1.0 - EPS)) if mask.any() else rate
    persistence = np.array([table[(float(h), float(s))] for h, s in zip(test_ahead, test_state)])
    slot_mean = np.clip(plain[0] if plain is not None else test[0], EPS, 1.0 - EPS)
    return {"base_rate": np.full(len(test_ahead), rate), "slot_mean": slot_mean, "persistence": persistence}


def truncated_habit_examples(
    series_by_home: Mapping[str, Sequence[Observation]],
    params: Params,
    max_days: float,
    horizons: Sequence[int] = (3,),
    warmup_days: int = WARMUP_DAYS,
):
    """Like walk_forward_examples, but the habit only sees the last `max_days` days before each forecast.

    The target hour's slot repeats every 168 hours, so the observations of that slot before the origin are
    exactly the hours target - 168 * j (j = 1, 2, ...), and their age at the origin is 168 * j - h hours.
    """
    habit_v, state_v, ahead_v, y_v = [], [], [], []
    limit_hours = max_days * 24
    for series in series_by_home.values():
        ordered = sorted(series, key=lambda o: o.at)
        if not ordered:
            continue
        known = {o.at: o.home for o in ordered}
        origin = ordered[0].at + timedelta(days=warmup_days)
        while origin <= ordered[-1].at:
            previous = known.get(origin - HOUR)
            if previous is not None:
                for h in horizons:
                    outcome = known.get(origin + h * HOUR)
                    if outcome is None:
                        continue
                    target = origin + h * HOUR
                    numerator = denominator = 0.0
                    j = 1
                    while 168 * j - h <= limit_hours:
                        seen = known.get(target - 168 * j * HOUR)
                        if seen is not None:
                            weight = 0.5 ** (((168 * j - h) / 24.0) / params.half_life_days)
                            numerator += weight * (1.0 if seen else 0.0)
                            denominator += weight
                        j += 1
                    k = params.prior_strength
                    habit_v.append((numerator + k * params.prior[slot_of(target)]) / (denominator + k))
                    state_v.append(1.0 if previous else -1.0)
                    ahead_v.append(float(h))
                    y_v.append(1.0 if outcome else 0.0)
            origin += HOUR
    return np.array(habit_v), np.array(state_v), np.array(ahead_v), np.array(y_v)


def _gbm_features(habit: np.ndarray, state: np.ndarray, ahead: np.ndarray, slot: np.ndarray) -> np.ndarray:
    return np.column_stack([slot % 24, slot // 24, ahead, state, habit])


def _calibration(y: np.ndarray, p: np.ndarray) -> list[dict]:
    rows = []
    for k in range(10):
        low, high = k / 10, (k + 1) / 10
        mask = (p >= low) & ((p < high) if k < 9 else (p <= high))
        if mask.any():
            rows.append({"bin_low": low, "bin_high": high, "predicted": _round(p[mask].mean()), "observed": _round(y[mask].mean()), "n": int(mask.sum())})
    return rows


def _fmt(value: float | None) -> str:
    return "n/a" if value is None else f"{value:.3f}"


def answer_questions(horizons: dict, learning: dict, cold: dict, mode: str = "population") -> list[dict]:
    """The four questions of the design, answered in one line each from the numbers."""
    h3 = horizons["3"]
    wins = sum(
        1
        for h in horizons.values()
        if all(h["model"]["brier"] < h[b]["brier"] for b in ("base_rate", "slot_mean", "persistence"))
    )
    auc_wins = sum(
        1
        for h in horizons.values()
        if all(h["model"]["auc"] >= h[b]["auc"] for b in ("base_rate", "slot_mean", "persistence"))
    )
    q1 = (
        f"The model has the lowest Brier score of the three simple forecasts at {wins} of {len(horizons)} horizons "
        f"and the highest AUC at {auc_wins} of {len(horizons)}. "
        f"At 3 hours ahead: model {_fmt(h3['model']['brier'])} (AUC {_fmt(h3['model']['auc'])}), "
        f"plain hour of week average {_fmt(h3['slot_mean']['brier'])} (AUC {_fmt(h3['slot_mean']['auc'])}), "
        f"same as right now {_fmt(h3['persistence']['brier'])} (AUC {_fmt(h3['persistence']['auc'])}), "
        f"base rate {_fmt(h3['base_rate']['brier'])}."
    )
    q2 = "AUC at 3 hours ahead when the forecast sees only the last N days of history: " + ", ".join(
        f"{n} days {_fmt(v['auc'])}" for n, v in learning.items()
    ) + "."
    w, f = cold["with_prior"]["brier"], cold["flat_prior"]["brier"]
    verdict = "helps" if w < f - 0.001 else ("hurts" if w > f + 0.001 else "makes no clear difference")
    shipped = " The model therefore starts every member from a flat 50 percent." if mode == "flat" else ""
    q3 = f"In a new home's first {COLD_START_DAYS} days the population prior {verdict}: Brier {_fmt(w)} with it, {_fmt(f)} with a flat 0.5 prior.{shipped}"
    g = h3["gbm"]
    q4 = (
        f"The gradient boosted yardstick scores Brier {_fmt(g['brier'])} (AUC {_fmt(g['auc'])}) at 3 hours ahead "
        f"against {_fmt(h3['model']['brier'])} (AUC {_fmt(h3['model']['auc'])}) for the small model."
    )
    return [
        {"id": "q1", "question": "Does a per person habit profile forecast better than the simple baselines?", "answer": q1},
        {"id": "q2", "question": "How many days of history does it need?", "answer": q2},
        {"id": "q3", "question": "Does the population prior help a brand new member in their first week?", "answer": q3},
        {"id": "q4", "question": "How much does a heavier model improve on the small one?", "answer": q4},
    ]


def _run_folds(series_by_home: Mapping[str, Sequence[Observation]], grids: Grids | None, flat_prior: bool) -> dict:
    """Leave one home out: fit on the others, forecast the held out home, and pool the results."""
    pooled = {name: [] for name in MODELS}
    pooled_y, pooled_ahead = [], []
    learning = {str(n): ([], []) for n in LEARNING_DAYS}
    cold = {"with_prior": ([], []), "flat_prior": ([], [])}
    fold_params = []

    for held in sorted(series_by_home):
        train = {k: v for k, v in series_by_home.items() if k != held}
        params = fit(train, grids, flat_prior=flat_prior)
        fold_params.append({"held_out": held, **_summary(params)})
        train_ex = walk_forward_examples(train, params.half_life_days, params.prior_strength, params.prior, with_slots=True)
        test_ex = walk_forward_examples({held: series_by_home[held]}, params.half_life_days, params.prior_strength, params.prior, with_slots=True)
        plain = walk_forward_examples({held: series_by_home[held]}, *PLAIN)
        if len(test_ex[0]) == 0:
            continue
        habit, state, ahead, y, slot = test_ex
        base = baseline_predictions(train_ex[:4], test_ex[:4], plain)
        gbm = HistGradientBoostingClassifier(max_iter=150, max_depth=4, early_stopping=False, random_state=0)
        gbm.fit(_gbm_features(train_ex[0], train_ex[1], train_ex[2], train_ex[4]), train_ex[3])
        predictions = {"model": predict(params, habit, state, ahead), **base, "gbm": gbm.predict_proba(_gbm_features(habit, state, ahead, slot))[:, 1]}
        for name in MODELS:
            pooled[name].append(predictions[name])
        pooled_y.append(y)
        pooled_ahead.append(ahead)

        for n in LEARNING_DAYS:
            lh, ls, la, ly = truncated_habit_examples({held: series_by_home[held]}, params, n)
            if len(ly):
                learning[str(n)][0].append(ly)
                learning[str(n)][1].append(predict(params, lh, ls, la))
        for label, prior in (("with_prior", params.prior), ("flat_prior", FLAT_PRIOR)):
            ch, cs, ca, cy = walk_forward_examples(
                {held: series_by_home[held]}, params.half_life_days, params.prior_strength, prior,
                horizons=(COLD_START_HORIZON,), warmup_days=0, until_days=COLD_START_DAYS,
            )
            if len(cy):
                cold[label][0].append(cy)
                cold[label][1].append(predict(params, ch, cs, ca))

    return {
        "y": np.concatenate(pooled_y),
        "ahead": np.concatenate(pooled_ahead),
        "p": {name: np.concatenate(pooled[name]) for name in MODELS},
        "learning": {n: _short(np.concatenate(ys), np.concatenate(ps)) for n, (ys, ps) in learning.items()},
        "cold": {label: _short(np.concatenate(ys), np.concatenate(ps)) for label, (ys, ps) in cold.items()},
        "fold_params": fold_params,
    }


def choose_prior_mode(cold_start: dict) -> str:
    """flat when starting a new home from 0.5 beats the population profile by more than 0.001 Brier."""
    with_prior, flat = cold_start["with_prior"]["brier"], cold_start["flat_prior"]["brier"]
    return "flat" if flat + 0.001 < with_prior else "population"


def _horizon_metrics(name: str, y: np.ndarray, p: np.ndarray) -> dict:
    m = metrics_of(y, p)
    if name == "base_rate":
        m["auc"] = 0.5  # a constant forecast cannot rank hours; pooling per fold constants would give a meaningless AUC
    return m


def evaluate(
    series_by_home: Mapping[str, Sequence[Observation]],
    grids: Grids | None = None,
    notes: Mapping[str, dict] | None = None,
    prior_mode: str = "auto",
) -> dict:
    """Metrics for the README and video. prior_mode is auto (decided by the cold start check), flat or population."""
    notes = notes or {}
    ids = sorted(series_by_home)
    first = _run_folds(series_by_home, grids, flat_prior=False)
    mode = prior_mode if prior_mode in ("flat", "population") else choose_prior_mode(first["cold"])
    run = _run_folds(series_by_home, grids, flat_prior=True) if mode == "flat" else first
    horizons = {
        str(h): {name: _horizon_metrics(name, run["y"][run["ahead"] == h], run["p"][name][run["ahead"] == h]) for name in MODELS}
        for h in HORIZONS
    }
    readable = {k: [(o.at, o.home) for o in v] for k, v in series_by_home.items()}
    final = fit(dict(series_by_home), grids, flat_prior=(mode == "flat"))
    return {
        "data": [
            {
                "id": k,
                "days": len(series_by_home[k]) // 24,
                "hours": len(series_by_home[k]),
                "home_share": _round(sum(1 for o in series_by_home[k] if o.home) / len(series_by_home[k])),
                **notes.get(k, {}),
            }
            for k in ids
        ],
        "gate": data_gate(readable),
        "fragile": len(ids) < 4,
        "prior": {
            "mode": mode,
            "cold_start_brier_with_population_prior": first["cold"]["with_prior"]["brier"],
            "cold_start_brier_flat_prior": first["cold"]["flat_prior"]["brier"],
        },
        "horizons": horizons,
        "learning_curve": run["learning"],
        "cold_start": first["cold"],
        "calibration": _calibration(run["y"], run["p"]["model"]),
        "params": _summary(final),
        "fold_params": run["fold_params"],
        "caveats": caveats(len(ids)),
        "questions": answer_questions(horizons, run["learning"], first["cold"], mode),
    }


def _short(y: np.ndarray, p: np.ndarray) -> dict:
    m = metrics_of(y, p)
    return {"auc": m["auc"], "brier": m["brier"], "log_loss": m["log_loss"], "n": m["n"]}


def _summary(params: Params) -> dict:
    return {
        "b0": _round(params.b0),
        "b1": _round(params.b1),
        "b2": _round(params.b2),
        "tau_hours": params.tau_hours,
        "half_life_days": params.half_life_days,
        "prior_strength": params.prior_strength,
    }


def caveats(home_count: int) -> list[str]:
    return [
        f"Only {home_count} homes were usable, so each fold trains on {max(home_count - 1, 0)} and the results are fragile.",
        "Tulum 1 and Tulum 2 are two periods of the same CASAS testbed and may be one household. Holding one out leaves the other in training, so the evaluation is closer to two independent households than three.",
        "The homes come from the CASAS research project. None is a Filipino household, and the forecast was not tested on housemates sharing a flat.",
        "A label marks a household leaving or coming back, not a person. Some of these homes are reported to have two residents.",
        "An hour counts as home when the labels say someone was home for 30 minutes or more of it.",
        "Every forecast uses only earlier hours, and the held out home never influenced its own coefficients. One yes or no choice, the flat prior, was made by comparing held out first week forecasts, so the headline numbers are slightly optimistic.",
        "Both sides of the first week comparison use coefficients fitted with the population prior.",
        "Forecasts were evaluated from 1 to 72 hours ahead only, and the app shows nothing further out.",
        "Ranking housemates and the best two hour window are built on this forecast but are not evaluated separately.",
    ]
