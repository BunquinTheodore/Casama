"""Load and clean the Olist orders table (Kaggle: zeynepustun/customer-order-delivery-dataset).

Shared by the EDA, the model and the dashboard so every step uses the same
cleaning rules.
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd

RAW_CSV = (
    Path(__file__).resolve().parent.parent
    / "data/raw/datasets/zeynepustun/customer-order-delivery-dataset/versions/1/orders.csv"
)
TIME_COLUMNS = [
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
]
DAY = pd.Timedelta(days=1)


def load_raw(path: Path = RAW_CSV) -> pd.DataFrame:
    return pd.read_csv(path, parse_dates=TIME_COLUMNS)


def delivered_orders(raw: pd.DataFrame) -> pd.DataFrame:
    """Delivered orders with delivery timing features (days), no mutation of `raw`."""
    done = raw.dropna(subset=["order_delivered_customer_date"]).copy()
    purchase = done["order_purchase_timestamp"]
    done["delivery_days"] = (done["order_delivered_customer_date"] - purchase) / DAY
    done["estimated_days"] = (done["order_estimated_delivery_date"] - purchase) / DAY
    done["days_vs_estimate"] = (
        done["order_delivered_customer_date"] - done["order_estimated_delivery_date"]
    ) / DAY
    done["is_late"] = done["days_vs_estimate"] > 0
    done["approval_hours"] = (done["order_approved_at"] - purchase).dt.total_seconds() / 3600
    done["handoff_days"] = (done["order_delivered_carrier_date"] - purchase) / DAY
    done["purchase_month"] = purchase.dt.to_period("M").astype(str)
    done["purchase_weekday"] = purchase.dt.dayofweek
    done["purchase_hour"] = purchase.dt.hour
    return done


def clean_delivered(done: pd.DataFrame) -> pd.DataFrame:
    """Drop impossible rows (handoff after delivery, negative durations) and extreme outliers."""
    ok = (
        (done["delivery_days"] > 0)
        & (done["delivery_days"] <= 60)
        & (done["handoff_days"].isna() | (done["handoff_days"] >= 0))
        & (done["approval_hours"].isna() | (done["approval_hours"] >= 0))
        & (done["purchase_month"] >= "2017-01")
    )
    return done.loc[ok].reset_index(drop=True)
