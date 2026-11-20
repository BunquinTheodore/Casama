"""Exploratory data analysis for the delivery dataset. Writes charts and findings.json
to analysis/output. Run: python analysis/eda_delivery.py
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

OUT = Path(__file__).resolve().parent / "output"
INK, MID, SOFT, PAPER = "#0A0A0A", "#6B6B6B", "#D9D9D9", "#FFFFFF"
ACCENT = "#E4572E"


def style() -> None:
    plt.rcParams.update(
        {
            "figure.facecolor": PAPER,
            "axes.facecolor": PAPER,
            "savefig.facecolor": PAPER,
            "font.family": "sans-serif",
            "font.sans-serif": ["Manrope", "Segoe UI", "DejaVu Sans"],
            "text.color": INK,
            "axes.edgecolor": INK,
            "axes.labelcolor": MID,
            "xtick.color": MID,
            "ytick.color": MID,
            "axes.spines.top": False,
            "axes.spines.right": False,
            "axes.titlesize": 15,
            "axes.titleweight": "bold",
            "axes.titlelocation": "left",
            "axes.titlepad": 22,
            "axes.labelsize": 10,
            "axes.grid": True,
            "axes.axisbelow": True,
            "grid.color": SOFT,
            "grid.linewidth": 0.6,
            "xtick.major.size": 0,
            "ytick.major.size": 0,
            "figure.dpi": 150,
        }
    )


OUTLINE_PADDING = 28
OUTLINE_WIDTH = 3


def add_outline(path: Path) -> None:
    """Pad the saved chart and draw a solid box outline around it."""
    from PIL import Image, ImageDraw, ImageOps

    padded = ImageOps.expand(Image.open(path).convert("RGB"), border=OUTLINE_PADDING, fill=PAPER)
    width, height = padded.size
    ImageDraw.Draw(padded).rectangle(
        (0, 0, width - 1, height - 1), outline=INK, width=OUTLINE_WIDTH
    )
    padded.save(path)


def finish(fig, ax, name: str, title: str, subtitle: str) -> None:
    ax.grid(axis="x", visible=False)
    ax.set_title(title)
    ax.text(0, 1.03, subtitle, transform=ax.transAxes, fontsize=9.5, color=MID, va="bottom")
    fig.tight_layout()
    target = OUT / f"{name}.png"
    fig.savefig(target, bbox_inches="tight")
    plt.close(fig)
    add_outline(target)


def pct_axis(ax) -> None:
    ax.yaxis.set_major_formatter(lambda v, _: f"{v:.0f}%")


def chart_delivery_time(df: pd.DataFrame) -> dict:
    median = df["delivery_days"].median()
    fig, ax = plt.subplots(figsize=(8, 4.6))
    ax.hist(df["delivery_days"], bins=np.arange(0, 61, 1), color=INK, edgecolor=PAPER, linewidth=0.5)
    ax.axvline(median, color=ACCENT, linewidth=2)
    ax.annotate(f"median {median:.1f} days", (median, ax.get_ylim()[1] * 0.92),
                xytext=(8, 0), textcoords="offset points", color=ACCENT, fontweight="bold")
    ax.set_xlabel("Days from purchase to delivery")
    ax.set_ylabel("Orders")
    finish(fig, ax, "01_delivery_time", "Most parcels take 1 to 2 weeks",
           f"{len(df):,} delivered orders, 2017 to 2018")
    return {"median_days": round(median, 1), "mean_days": round(df["delivery_days"].mean(), 1),
            "p90_days": round(df["delivery_days"].quantile(0.9), 1)}


def chart_estimate_padding(df: pd.DataFrame) -> dict:
    gap = df.loc[df["days_vs_estimate"].between(-40, 20), "days_vs_estimate"]
    fig, ax = plt.subplots(figsize=(8, 4.6))
    _, bins, patches = ax.hist(gap, bins=np.arange(-40, 21, 1), edgecolor=PAPER, linewidth=0.5)
    for left, patch in zip(bins[:-1], patches):
        patch.set_facecolor(ACCENT if left >= 0 else INK)
    ax.set_xlabel("Days delivered before (negative) or after (positive) the estimate")
    ax.set_ylabel("Orders")
    late = df["is_late"].mean() * 100
    finish(fig, ax, "02_estimate_gap", "Estimates are padded, only a few parcels are late",
           f"{late:.1f}% arrive after the promised date. The typical parcel arrives "
           f"{-df['days_vs_estimate'].median():.0f} days early")
    return {"late_rate_pct": round(late, 1),
            "median_days_early": round(-df["days_vs_estimate"].median(), 1)}


def chart_monthly_late(df: pd.DataFrame) -> dict:
    monthly = df.groupby("purchase_month")["is_late"].agg(["mean", "size"])
    monthly = monthly[monthly["size"] >= 300]
    rates = monthly["mean"] * 100
    fig, ax = plt.subplots(figsize=(9, 4.6))
    colors = [ACCENT if r >= 10 else INK for r in rates]
    ax.bar(range(len(rates)), rates, color=colors, width=0.7)
    ax.set_xticks(range(len(rates)))
    ax.set_xticklabels([m[2:] for m in rates.index], rotation=45, ha="right")
    ax.set_ylabel("Late parcels")
    pct_axis(ax)
    worst = rates.idxmax()
    finish(fig, ax, "03_late_by_month", "Lateness spikes in peak shopping months",
           f"Share of parcels delivered after the estimate. Worst month: {worst} at {rates.max():.0f}%")
    return {"worst_month": worst, "worst_month_late_pct": round(rates.max(), 1),
            "best_month_late_pct": round(rates.min(), 1)}


def bucket_rate(df: pd.DataFrame, column: str, bins: list, labels: list) -> pd.Series:
    bucket = pd.cut(df[column], bins=bins, labels=labels, right=False)
    return df.groupby(bucket, observed=True)["is_late"].mean() * 100


def chart_handoff(df: pd.DataFrame) -> dict:
    sub = df.dropna(subset=["handoff_days"])
    labels = ["Under 1 day", "1 to 2 days", "2 to 4 days", "4 to 7 days", "7+ days"]
    rates = bucket_rate(sub, "handoff_days", [0, 1, 2, 4, 7, 999], labels)
    fig, ax = plt.subplots(figsize=(8, 4.6))
    ax.bar(rates.index.astype(str), rates.values,
           color=[SOFT, SOFT, MID, INK, ACCENT], width=0.65)
    for i, v in enumerate(rates.values):
        ax.text(i, v + 0.6, f"{v:.0f}%", ha="center", color=INK, fontweight="bold")
    ax.set_xlabel("Days until the seller hands the parcel to the carrier")
    ax.set_ylabel("Late parcels")
    pct_axis(ax)
    finish(fig, ax, "04_late_by_handoff", "Slow seller handoff is the strongest warning sign",
           "Late rate by how long the seller took to ship")
    return {"late_pct_fast_handoff": round(rates.iloc[0], 1),
            "late_pct_slow_handoff": round(rates.iloc[-1], 1)}


def chart_estimate_length(df: pd.DataFrame) -> dict:
    labels = ["Under 10 days", "10 to 15", "15 to 20", "20 to 30", "30+ days"]
    rates = bucket_rate(df, "estimated_days", [0, 10, 15, 20, 30, 999], labels)
    fig, ax = plt.subplots(figsize=(8, 4.6))
    ax.bar(rates.index.astype(str), rates.values, color=INK, width=0.65)
    for i, v in enumerate(rates.values):
        ax.text(i, v + 0.3, f"{v:.0f}%", ha="center", color=INK, fontweight="bold")
    ax.set_xlabel("Estimated delivery window promised at purchase")
    ax.set_ylabel("Late parcels")
    pct_axis(ax)
    finish(fig, ax, "05_late_by_estimate", "Short promises are the ones that get broken",
           "Late rate by how many days were promised")
    return {"late_pct_shortest_promise": round(rates.iloc[0], 1),
            "late_pct_longest_promise": round(rates.iloc[-1], 1)}


def chart_weekday_hour(df: pd.DataFrame) -> dict:
    grid = df.pivot_table(index="purchase_weekday", columns="purchase_hour",
                          values="order_id", aggfunc="count").fillna(0)
    fig, ax = plt.subplots(figsize=(9, 3.8))
    ax.imshow(grid.values, aspect="auto", cmap="Greys")
    ax.set_yticks(range(7))
    ax.set_yticklabels(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
    ax.set_xticks(range(0, 24, 3))
    ax.set_xticklabels([f"{h}:00" for h in range(0, 24, 3)])
    ax.grid(False)
    ax.set_xlabel("Hour of purchase")
    finish(fig, ax, "06_order_rhythm", "People shop in the afternoon and evening",
           "Number of orders by weekday and hour")
    peak = grid.stack().idxmax()
    return {"busiest_weekday": int(peak[0]), "busiest_hour": int(peak[1])}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    style()
    raw = load_raw()
    df = clean_delivered(delivered_orders(raw))
    findings = {
        "raw_orders": int(len(raw)),
        "delivered_orders_used": int(len(df)),
        "cancelled_or_unavailable": int(raw["order_status"].isin(["canceled", "unavailable"]).sum()),
    }
    for chart in (chart_delivery_time, chart_estimate_padding, chart_monthly_late,
                  chart_handoff, chart_estimate_length, chart_weekday_hour):
        findings.update(chart(df))
    (OUT / "findings.json").write_text(json.dumps(findings, indent=2), encoding="utf-8")
    print(json.dumps(findings, indent=2))


if __name__ == "__main__":
    main()
