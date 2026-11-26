"""Load and clean the Olist orders and customers tables.

Orders: Kaggle zeynepustun/customer-order-delivery-dataset.
Customers: Kaggle olistbr/brazilian-ecommerce (olist_customers_dataset.csv), joined on customer_id.

Late means delivered on a later calendar day than the estimated date. The estimate is stored at
midnight, so judging by clock time would count a 2pm delivery on the promised day as late.
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd

from config import RAW_DIR

ORDERS_CSV = RAW_DIR / "datasets/zeynepustun/customer-order-delivery-dataset/versions/1/orders.csv"
CUSTOMERS_CSV = RAW_DIR / "datasets/olistbr/brazilian-ecommerce/versions/2/olist_customers_dataset.csv"
TIME_COLUMNS = [
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
]
DAY = pd.Timedelta(days=1)


def load_raw(path: Path = ORDERS_CSV) -> pd.DataFrame:
    return pd.read_csv(path, parse_dates=TIME_COLUMNS)


def load_customers(path: Path = CUSTOMERS_CSV) -> pd.DataFrame:
    return pd.read_csv(path, usecols=["customer_id", "customer_state", "customer_city"])


def delivered_orders(raw: pd.DataFrame) -> pd.DataFrame:
    """Delivered orders with timing features (days) and both lateness rules; `raw` is not mutated."""
    done = raw.dropna(subset=["order_delivered_customer_date"]).copy()
    purchase = done["order_purchase_timestamp"]
    delivered = done["order_delivered_customer_date"]
    estimate = done["order_estimated_delivery_date"]
    done["delivery_days"] = (delivered - purchase) / DAY
    done["estimated_days"] = (estimate - purchase) / DAY
    done["days_vs_estimate"] = (delivered - estimate) / DAY
    done["is_late_timestamp"] = done["days_vs_estimate"] > 0
    done["is_late"] = delivered.dt.normalize() > estimate.dt.normalize()
    done["approval_hours"] = (done["order_approved_at"] - purchase).dt.total_seconds() / 3600
    done["handoff_days"] = (done["order_delivered_carrier_date"] - purchase) / DAY
    done["handoff_date"] = done["order_delivered_carrier_date"].dt.normalize()
    done["purchase_month"] = purchase.dt.to_period("M").astype(str)
    done["purchase_weekday"] = purchase.dt.dayofweek
    done["purchase_hour"] = purchase.dt.hour
    done["month_of_year"] = purchase.dt.month
    return done


def clean_delivered(done: pd.DataFrame) -> pd.DataFrame:
    """Drop rows with a step recorded before the purchase, a delivery time of zero or less, a journey over 60 days,
    or a purchase before 2017. Parcels whose handoff is recorded after delivery (a handful) are kept: the rest of
    their timings are valid and the weather window starts on the handoff date."""
    ok = (
        (done["delivery_days"] > 0)
        & (done["delivery_days"] <= 60)
        & (done["handoff_days"].isna() | (done["handoff_days"] >= 0))
        & (done["approval_hours"].isna() | (done["approval_hours"] >= 0))
        & (done["purchase_month"] >= "2017-01")
    )
    return done.loc[ok].reset_index(drop=True)


def add_state(orders: pd.DataFrame, customers: pd.DataFrame) -> pd.DataFrame:
    """Left join the customer state onto orders; unknown customers keep a null state."""
    return orders.merge(
        customers[["customer_id", "customer_state"]].drop_duplicates("customer_id"),
        on="customer_id",
        how="left",
    )
