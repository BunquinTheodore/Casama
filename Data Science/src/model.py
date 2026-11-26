"""Three stage late parcel model, trained on parcels bought before 2018-01 and tested from 2018-01.

stage_1 at purchase, stage_2 adds the seller handoff time, stage_3 adds the weather and holiday exposure after handoff.
Stage 3 uses observed weather, so it explains what happened and is not a deployable forecast.
"""

from __future__ import annotations

import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.inspection import permutation_importance
from sklearn.metrics import average_precision_score, precision_score, recall_score, roc_auc_score, roc_curve

from config import SEED, SPLIT_MONTH

STAGE_1 = ["estimated_days", "purchase_weekday", "purchase_hour", "month_of_year"]
STAGE_2 = STAGE_1 + ["handoff_days"]
STAGE_3 = STAGE_2 + ["heavy_rain_days", "rain_mm_total", "holiday_in_window"]
STAGES = {"stage_1": STAGE_1, "stage_2": STAGE_2, "stage_3": STAGE_3}


def split_by_time(df: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Train on purchases before SPLIT_MONTH, test from SPLIT_MONTH on (no shuffling, no leakage across time)."""
    return df[df["purchase_month"] < SPLIT_MONTH], df[df["purchase_month"] >= SPLIT_MONTH]


def prepare_model_frame(df: pd.DataFrame) -> tuple[pd.DataFrame, int]:
    """Keep rows where every stage 3 feature is known, as plain floats, so all stages score the same parcels."""
    needed = STAGE_3
    usable = df.dropna(subset=needed).copy()
    for name in needed:
        usable[name] = usable[name].astype(float)
    return usable, int(len(df) - len(usable))


def fit_stage(train: pd.DataFrame, test: pd.DataFrame, features: list[str]) -> dict:
    model = HistGradientBoostingClassifier(
        max_depth=4, learning_rate=0.08, max_iter=200, class_weight="balanced", random_state=SEED
    )
    model.fit(train[features], train["is_late"])
    scores = model.predict_proba(test[features])[:, 1]
    truth = test["is_late"].to_numpy().astype(bool)
    cut = float(np.quantile(scores, 1 - truth.mean() * 1.5))
    flagged = scores >= cut
    importance = permutation_importance(model, test[features], truth, scoring="roc_auc", n_repeats=5, random_state=SEED)
    fpr, tpr, _ = roc_curve(truth, scores)
    grid = np.linspace(0, 1, 101)
    deciles = pd.qcut(pd.Series(scores).rank(method="first"), 10, labels=False) + 1
    decile_rates = pd.Series(truth).groupby(deciles.to_numpy()).mean() * 100
    return {
        "features": list(features),
        "scores": scores,
        "truth": truth,
        "roc_auc": float(roc_auc_score(truth, scores)),
        "average_precision": float(average_precision_score(truth, scores)),
        "base_late_rate_pct": float(truth.mean() * 100),
        "alert_cutoff": cut,
        "alert_precision_pct": float(precision_score(truth, flagged) * 100),
        "alert_recall_pct": float(recall_score(truth, flagged) * 100),
        "importance": {f: float(v) for f, v in zip(features, importance.importances_mean)},
        "roc_points": [{"fpr": round(float(x), 2), "tpr": round(float(y), 3)} for x, y in zip(grid, np.interp(grid, fpr, tpr))],
        "risk_deciles": [{"decile": int(d), "late_pct": float(v)} for d, v in decile_rates.items()],
    }


def auc_difference_ci(
    truth: np.ndarray, scores_a: np.ndarray, scores_b: np.ndarray, n_boot: int = 500, seed: int = SEED
) -> tuple[float, float, float]:
    """AUC of b minus AUC of a on the same parcels, with a paired bootstrap 95% interval."""
    truth, scores_a, scores_b = np.asarray(truth), np.asarray(scores_a), np.asarray(scores_b)
    rng = np.random.default_rng(seed)
    n = len(truth)
    diffs = []
    for _ in range(n_boot):
        idx = rng.integers(0, n, n)
        if truth[idx].min() == truth[idx].max():
            continue
        diffs.append(roc_auc_score(truth[idx], scores_b[idx]) - roc_auc_score(truth[idx], scores_a[idx]))
    low, high = np.percentile(diffs, [2.5, 97.5])
    point = roc_auc_score(truth, scores_b) - roc_auc_score(truth, scores_a)
    return float(point), float(low), float(high)
