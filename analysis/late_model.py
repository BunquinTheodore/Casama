"""Predict whether a parcel will arrive after its estimated date.

Two honest stages, split by what is known when:
  Stage 1 at purchase: promised days, weekday, hour, month of year.
  Stage 2 after the seller ships: adds handoff days (the strongest signal).

Train on 2017 orders, test on 2018 orders (time based split, no leakage).
Run: python analysis/late_model.py
"""

from __future__ import annotations

import json
from pathlib import Path

import joblib
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.inspection import permutation_importance
from sklearn.metrics import average_precision_score, precision_score, recall_score, roc_auc_score

from delivery_data import clean_delivered, delivered_orders, load_raw
from eda_delivery import ACCENT, INK, MID, SOFT, finish, pct_axis, style

OUT = Path(__file__).resolve().parent / "output"
SPLIT_MONTH = "2018-01"
STAGE_1 = ["estimated_days", "purchase_weekday", "purchase_hour", "month_of_year"]
STAGE_2 = STAGE_1 + ["handoff_days"]
LABELS = {
    "estimated_days": "Days promised",
    "purchase_weekday": "Weekday",
    "purchase_hour": "Hour",
    "month_of_year": "Month of year",
    "handoff_days": "Seller handoff days",
}
HIDDEN = ("model", "features", "scores", "truth")


def fit_stage(train: pd.DataFrame, test: pd.DataFrame, features: list[str]) -> dict:
    model = HistGradientBoostingClassifier(
        max_depth=4, learning_rate=0.08, max_iter=200, class_weight="balanced", random_state=7
    )
    model.fit(train[features], train["is_late"])
    scores = model.predict_proba(test[features])[:, 1]
    truth = test["is_late"].to_numpy()
    cut = float(np.quantile(scores, 1 - truth.mean() * 1.5))
    flagged = scores >= cut
    importance = permutation_importance(
        model, test[features], truth, scoring="roc_auc", n_repeats=5, random_state=7
    )
    return {
        "model": model,
        "features": features,
        "scores": scores,
        "truth": truth,
        "roc_auc": round(float(roc_auc_score(truth, scores)), 3),
        "average_precision": round(float(average_precision_score(truth, scores)), 3),
        "base_late_rate_pct": round(float(truth.mean() * 100), 1),
        "alert_cutoff": round(cut, 3),
        "alert_precision_pct": round(float(precision_score(truth, flagged) * 100), 1),
        "alert_recall_pct": round(float(recall_score(truth, flagged) * 100), 1),
        "importance": dict(zip(features, importance.importances_mean.round(4))),
    }


def chart_importance(stage: dict) -> None:
    items = sorted(stage["importance"].items(), key=lambda kv: kv[1])
    fig, ax = plt.subplots(figsize=(8, 4))
    names = [LABELS[k] for k, _ in items]
    values = [v for _, v in items]
    ax.barh(names, values, color=[ACCENT if n == "Seller handoff days" else INK for n in names])
    ax.grid(axis="y", visible=False)
    ax.grid(axis="x", visible=True)
    ax.set_xlabel("Drop in model accuracy (AUC) when the signal is hidden")
    finish(fig, ax, "07_model_importance", "What the model relies on",
           "Permutation importance on 2018 test orders")
    ax.grid(axis="x", visible=True)


def chart_roc(stage1: dict, stage2: dict) -> None:
    from sklearn.metrics import roc_curve

    fig, ax = plt.subplots(figsize=(6, 5.4))
    ax.plot([0, 1], [0, 1], color=SOFT, linewidth=1.8, linestyle="--")
    for stage, color, name in ((stage1, MID, "At purchase"), (stage2, ACCENT, "After shipping")):
        fpr, tpr, _ = roc_curve(stage["truth"], stage["scores"])
        ax.plot(fpr, tpr, color=color, linewidth=2.6, label=f"{name}, AUC {stage['roc_auc']}")
    ax.set_xlabel("Share of on time parcels wrongly flagged")
    ax.set_ylabel("Share of late parcels caught")
    ax.legend(frameon=False, loc="lower right")
    ax.grid(True)
    finish(fig, ax, "13_roc", "The model beats guessing, but not by a lot",
           "Dashed line is random guessing")


def chart_lift(stage2: dict) -> None:
    frame = pd.DataFrame({"score": stage2["scores"], "late": stage2["truth"]})
    frame["decile"] = pd.qcut(frame["score"].rank(method="first"), 10, labels=False) + 1
    rates = frame.groupby("decile")["late"].mean() * 100
    fig, ax = plt.subplots(figsize=(8, 4.6))
    ax.bar(rates.index, rates.values, color=[INK if d < 10 else ACCENT for d in rates.index], width=0.7)
    ax.axhline(frame["late"].mean() * 100, color=MID, linestyle="--", linewidth=1.5)
    ax.text(0.6, frame["late"].mean() * 100 + 0.6, "average", color=MID)
    ax.set_xticks(rates.index)
    ax.set_xlabel("Parcels ranked by predicted risk, 1 is safest and 10 is riskiest")
    ax.set_ylabel("Actually late")
    pct_axis(ax)
    finish(fig, ax, "14_risk_deciles", "The riskiest tenth of parcels is late far more often",
           f"Top decile is late {rates.iloc[-1]:.0f}% of the time, against {rates.iloc[0]:.0f}% for the safest")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    style()
    df = clean_delivered(delivered_orders(load_raw()))
    df["month_of_year"] = df["order_purchase_timestamp"].dt.month
    df = df.dropna(subset=["handoff_days"])
    train = df[df["purchase_month"] < SPLIT_MONTH]
    test = df[df["purchase_month"] >= SPLIT_MONTH]

    stage1 = fit_stage(train, test, STAGE_1)
    stage2 = fit_stage(train, test, STAGE_2)
    chart_importance(stage2)
    chart_roc(stage1, stage2)
    chart_lift(stage2)
    joblib.dump({"model": stage2["model"], "features": STAGE_2, "cutoff": stage2["alert_cutoff"]},
                OUT / "late_model.joblib")

    report = {
        "train_orders": int(len(train)),
        "test_orders": int(len(test)),
        "split": f"train before {SPLIT_MONTH}, test from {SPLIT_MONTH}",
        "stage_1_at_purchase": {k: v for k, v in stage1.items() if k not in HIDDEN},
        "stage_2_after_shipping": {k: v for k, v in stage2.items() if k not in HIDDEN},
    }
    (OUT / "model_metrics.json").write_text(json.dumps(report, indent=2, default=float), encoding="utf-8")
    print(json.dumps(report, indent=2, default=float))


if __name__ == "__main__":
    main()
