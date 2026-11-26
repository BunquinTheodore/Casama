"""The old charts 01 to 12 as plain JSON rows (no plotting). The page and the video draw them from these rows.

Late means delivered on a later calendar day than the estimate (see delivery_data). Rows are rounded to one decimal.
"""

from __future__ import annotations

from typing import Callable

import numpy as np
import pandas as pd

from config import SEED

MIN_MONTH_ORDERS = 300
PROMISE_SAMPLE = 3000
HANDOFF_EDGES, HANDOFF_LABELS = [0, 1, 2, 4, 7, 999], ["Under 1 day", "1 to 2 days", "2 to 4 days", "4 to 7 days", "7+ days"]
PROMISE_EDGES, PROMISE_LABELS = [0, 10, 15, 20, 30, 999], ["Under 10 days", "10 to 15", "15 to 20", "20 to 30", "30+ days"]
CORRELATION_COLUMNS = {
    "estimated_days": "Days promised", "handoff_days": "Seller handoff days", "approval_hours": "Approval hours",
    "purchase_hour": "Hour", "purchase_weekday": "Weekday", "delivery_days": "Delivery days", "is_late": "Is late",
}


def _hist(values: pd.Series, start: int, stop: int) -> list[dict]:
    counts, edges = np.histogram(values, bins=np.arange(start, stop + 1, 1))
    return [{"bin_start": int(e), "orders": int(c)} for e, c in zip(edges[:-1], counts)]


def _bucket_late(df: pd.DataFrame, column: str, edges: list, labels: list) -> list[dict]:
    sub = df.dropna(subset=[column])
    bucket = pd.cut(sub[column], bins=edges, labels=labels, right=False)
    grouped = sub.groupby(bucket, observed=True)["is_late"].agg(["mean", "size"])
    return [{"bucket": str(b), "late_pct": float(r["mean"]) * 100, "orders": int(r["size"])} for b, r in grouped.iterrows()]


def _monthly(df: pd.DataFrame) -> pd.DataFrame:
    monthly = df.groupby("purchase_month").agg(orders=("order_id", "size"), late=("is_late", "mean"))
    return monthly[monthly["orders"] >= MIN_MONTH_ORDERS]


def delivery_hist(df, **_) -> list[dict]:
    return _hist(df["delivery_days"], 0, 60)


def estimate_gap_hist(df, **_) -> list[dict]:
    return _hist(df.loc[df["days_vs_estimate"].between(-40, 20), "days_vs_estimate"], -40, 20)


def late_by_month(df, **_) -> list[dict]:
    m = _monthly(df)
    return [{"month": str(i), "late_pct": float(r["late"]) * 100, "orders": int(r["orders"])} for i, r in m.iterrows()]


def late_by_handoff(df, **_) -> list[dict]:
    return _bucket_late(df, "handoff_days", HANDOFF_EDGES, HANDOFF_LABELS)


def late_by_promise(df, **_) -> list[dict]:
    return _bucket_late(df, "estimated_days", PROMISE_EDGES, PROMISE_LABELS)


def order_rhythm(df, **_) -> list[dict]:
    grid = df.pivot_table(index="purchase_weekday", columns="purchase_hour", values="order_id", aggfunc="count")
    grid = grid.reindex(index=range(7), columns=range(24)).fillna(0)
    return [{"weekday": int(d), "hour": int(h), "orders": int(grid.loc[d, h])} for d in range(7) for h in range(24)]


def volume_vs_late(df, **_) -> list[dict]:
    m = _monthly(df)
    return [{"month": str(i), "orders": int(r["orders"]), "late_pct": float(r["late"]) * 100} for i, r in m.iterrows()]


def delivery_spread(df, **_) -> list[dict]:
    sub = df.dropna(subset=["handoff_days"])
    bucket = pd.cut(sub["handoff_days"], bins=HANDOFF_EDGES, labels=HANDOFF_LABELS, right=False)
    rows = []
    for label in HANDOFF_LABELS:
        values = sub.loc[bucket == label, "delivery_days"].to_numpy()
        if len(values) == 0:
            continue
        q1, median, q3 = np.percentile(values, [25, 50, 75])
        fence = 1.5 * (q3 - q1)
        rows.append(
            {
                "bucket": label, "q1": float(q1), "median": float(median), "q3": float(q3),
                "whisker_low": float(values[values >= q1 - fence].min()),
                "whisker_high": float(values[values <= q3 + fence].max()), "orders": int(len(values)),
            }
        )
    return rows


def promise_vs_actual(df, **_) -> list[dict]:
    sub = df[(df["estimated_days"] <= 50) & (df["delivery_days"] <= 50)]
    if len(sub) > PROMISE_SAMPLE:
        sub = sub.sample(PROMISE_SAMPLE, random_state=SEED)
    return [{"promised": round(float(p), 1), "actual": round(float(a), 1)} for p, a in zip(sub["estimated_days"], sub["delivery_days"])]


def correlation(df, **_) -> list[dict]:
    data = df[list(CORRELATION_COLUMNS)].assign(is_late=df["is_late"].astype(int)).dropna().rename(columns=CORRELATION_COLUMNS)
    corr = data.corr()
    return [{"row": r, "col": c, "value": float(corr.loc[r, c])} for r in corr.index for c in corr.columns]


def cleaning_funnel(raw: pd.DataFrame, delivered: pd.DataFrame, clean: pd.DataFrame) -> list[dict]:
    return [
        {"step": "All orders", "orders": int(len(raw))},
        {"step": "Delivered with a date", "orders": int(len(delivered))},
        {"step": "After removing impossible and extreme rows", "orders": int(len(clean))},
    ]


def _funnel(df, raw=None, delivered=None, **_) -> list[dict]:
    if raw is None or delivered is None:
        raise ValueError("cleaning_funnel needs raw= and delivered=")
    return cleaning_funnel(raw, delivered, df)


_SERIES: dict[str, Callable[..., list[dict]]] = {
    "delivery_hist": delivery_hist, "estimate_gap_hist": estimate_gap_hist, "late_by_month": late_by_month,
    "late_by_handoff": late_by_handoff, "late_by_promise": late_by_promise, "order_rhythm": order_rhythm,
    "cleaning_funnel": _funnel, "volume_vs_late": volume_vs_late, "delivery_spread": delivery_spread,
    "promise_vs_actual": promise_vs_actual, "correlation": correlation,
}
SERIES_NAMES = list(_SERIES)


def series(name: str, df: pd.DataFrame, raw: pd.DataFrame | None = None, delivered: pd.DataFrame | None = None) -> list[dict]:
    """Rows for one chart. `df` is the cleaned delivered frame; the funnel also needs `raw` and `delivered`."""
    return _SERIES[name](df, raw=raw, delivered=delivered)
