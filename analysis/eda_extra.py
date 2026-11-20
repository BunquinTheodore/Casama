"""Extra chart types for the presentation: funnel, combo, box plot, density scatter, heatmap.
Run: python analysis/eda_extra.py  (writes charts and extra_findings.json to analysis/output)
"""

from __future__ import annotations

import json
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from delivery_data import clean_delivered, delivered_orders, load_raw
from eda_delivery import ACCENT, INK, MID, PAPER, SOFT, finish, pct_axis, style

OUT = Path(__file__).resolve().parent / "output"


def chart_cleaning_funnel(raw: pd.DataFrame, delivered: pd.DataFrame, clean: pd.DataFrame) -> dict:
    steps = [
        ("All orders", len(raw)),
        ("Delivered with a date", len(delivered)),
        ("After removing impossible and extreme rows", len(clean)),
    ]
    fig, ax = plt.subplots(figsize=(8, 3.6))
    labels = [s[0] for s in steps][::-1]
    values = [s[1] for s in steps][::-1]
    ax.barh(labels, values, color=[ACCENT, MID, INK], height=0.55)
    for i, v in enumerate(values):
        ax.text(v + len(raw) * 0.01, i, f"{v:,}", va="center", fontweight="bold")
    ax.set_xlim(0, len(raw) * 1.15)
    ax.set_xlabel("Orders")
    ax.grid(axis="y", visible=False)
    finish(fig, ax, "08_cleaning_funnel", "Cleaning kept 96% of the orders",
           "Orders left after each cleaning step")
    dropped = len(delivered) - len(clean)
    return {"dropped_in_cleaning": int(dropped), "kept_pct": round(len(clean) / len(raw) * 100, 1),
            "undelivered_orders": int(len(raw) - len(delivered))}


def chart_volume_and_late(clean: pd.DataFrame) -> dict:
    monthly = clean.groupby("purchase_month").agg(orders=("order_id", "size"), late=("is_late", "mean"))
    monthly = monthly[monthly["orders"] >= 300]
    x = np.arange(len(monthly))
    fig, ax = plt.subplots(figsize=(9, 4.6))
    ax.bar(x, monthly["orders"], color=SOFT, width=0.7)
    ax.set_ylabel("Orders per month")
    ax.set_xticks(x)
    ax.set_xticklabels([m[2:] for m in monthly.index], rotation=45, ha="right")
    twin = ax.twinx()
    twin.plot(x, monthly["late"] * 100, color=ACCENT, linewidth=2.6, marker="o", markersize=5)
    twin.set_ylabel("Late parcels")
    twin.set_yticks(range(0, 25, 5))
    twin.set_ylim(0, 24)
    twin.yaxis.set_major_formatter(lambda v, _: f"{v:.0f}%")
    twin.spines["right"].set_visible(False)
    twin.grid(False)
    finish(fig, ax, "09_volume_vs_late", "Busier months tend to be later months",
           "Grey bars are monthly orders. The orange line is the share that arrived late")
    corr = float(np.corrcoef(monthly["orders"], monthly["late"])[0, 1])
    return {"volume_late_correlation": round(corr, 2)}


def chart_box_by_handoff(clean: pd.DataFrame) -> dict:
    sub = clean.dropna(subset=["handoff_days"])
    labels = ["Under 1 day", "1 to 2", "2 to 4", "4 to 7", "7+ days"]
    bucket = pd.cut(sub["handoff_days"], [0, 1, 2, 4, 7, 999], labels=labels, right=False)
    groups = [sub.loc[bucket == b, "delivery_days"].to_numpy() for b in labels]
    fig, ax = plt.subplots(figsize=(8, 4.6))
    box = ax.boxplot(groups, tick_labels=labels, patch_artist=True, showfliers=False, widths=0.55,
                     medianprops={"color": ACCENT, "linewidth": 2.4},
                     whiskerprops={"color": MID}, capprops={"color": MID})
    for patch in box["boxes"]:
        patch.set(facecolor=SOFT, edgecolor=INK)
    ax.set_xlabel("Days until the seller hands the parcel to the carrier")
    ax.set_ylabel("Total days to deliver")
    finish(fig, ax, "10_delivery_spread", "A slow seller delays the whole journey",
           "Box shows the middle 50% of parcels. The orange line is the median")
    return {"median_total_days_fast_seller": round(float(np.median(groups[0])), 1),
            "median_total_days_slow_seller": round(float(np.median(groups[-1])), 1)}


def chart_promise_vs_actual(clean: pd.DataFrame) -> dict:
    sub = clean[(clean["estimated_days"] <= 50) & (clean["delivery_days"] <= 50)]
    fig, ax = plt.subplots(figsize=(6.4, 5.6))
    hb = ax.hexbin(sub["estimated_days"], sub["delivery_days"], gridsize=45, cmap="Greys",
                   mincnt=1, bins="log")
    ax.plot([0, 50], [0, 50], color=ACCENT, linewidth=2.2)
    ax.text(31, 36, "Late side", color=ACCENT, fontweight="bold")
    ax.text(31, 14, "Early side", color=INK, fontweight="bold")
    ax.set_xlim(0, 50)
    ax.set_ylim(0, 50)
    ax.set_xlabel("Days promised at purchase")
    ax.set_ylabel("Days it actually took")
    fig.colorbar(hb, ax=ax, label="Orders (log scale)", shrink=0.8)
    ax.grid(True)
    finish(fig, ax, "11_promise_vs_actual", "Most parcels land well under the promise",
           "Each cell groups orders. Above the orange line means late")
    return {}


def chart_correlation(clean: pd.DataFrame) -> dict:
    cols = {"estimated_days": "Days promised", "handoff_days": "Seller handoff days",
            "approval_hours": "Approval hours", "purchase_hour": "Hour",
            "purchase_weekday": "Weekday", "delivery_days": "Delivery days", "is_late": "Is late"}
    data = clean[list(cols)].assign(is_late=clean["is_late"].astype(int)).dropna().rename(columns=cols)
    corr = data.corr()
    fig, ax = plt.subplots(figsize=(7.4, 6))
    im = ax.imshow(corr.values, cmap="Greys", vmin=-1, vmax=1)
    ax.set_xticks(range(len(corr)))
    ax.set_xticklabels(corr.columns, rotation=40, ha="right")
    ax.set_yticks(range(len(corr)))
    ax.set_yticklabels(corr.index)
    for i in range(len(corr)):
        for j in range(len(corr)):
            v = corr.values[i, j]
            ax.text(j, i, f"{v:.2f}", ha="center", va="center",
                    color=PAPER if abs(v) > 0.55 else INK, fontsize=8.5)
    ax.grid(False)
    fig.colorbar(im, ax=ax, shrink=0.8)
    finish(fig, ax, "12_correlation", "Which signals move together",
           "Correlation from -1 to 1. Darker means a stronger link")
    return {"corr_handoff_late": round(float(corr.loc["Seller handoff days", "Is late"]), 2),
            "corr_promised_late": round(float(corr.loc["Days promised", "Is late"]), 2)}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    style()
    raw = load_raw()
    delivered = delivered_orders(raw)
    clean = clean_delivered(delivered)
    result: dict = {}
    result.update(chart_cleaning_funnel(raw, delivered, clean))
    for chart in (chart_volume_and_late, chart_box_by_handoff, chart_promise_vs_actual, chart_correlation):
        result.update(chart(clean))
    (OUT / "extra_findings.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
