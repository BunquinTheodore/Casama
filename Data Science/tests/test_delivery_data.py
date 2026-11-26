"""Task 2: lateness by calendar day, loaders and the state join."""
import pandas as pd
import pytest

import download_data
from config import RAW_DIR
from delivery_data import (
    CUSTOMERS_CSV,
    ORDERS_CSV,
    add_state,
    clean_delivered,
    delivered_orders,
    load_customers,
    load_raw,
)

needs_data = pytest.mark.skipif(
    not (ORDERS_CSV.exists() and CUSTOMERS_CSV.exists()), reason="raw Kaggle files not downloaded"
)


def order(estimate, delivered, purchase="2017-10-01 10:00:00", carrier="2017-10-03 12:00:00", oid="o1", cid="c1"):
    p = pd.Timestamp(purchase)
    return {
        "order_id": oid,
        "customer_id": cid,
        "order_status": "delivered",
        "order_purchase_timestamp": p,
        "order_approved_at": p + pd.Timedelta(hours=1),
        "order_delivered_carrier_date": pd.Timestamp(carrier),
        "order_delivered_customer_date": pd.Timestamp(delivered),
        "order_estimated_delivery_date": pd.Timestamp(estimate),
    }


def test_delivery_at_2pm_on_estimate_day_is_not_late():
    done = delivered_orders(pd.DataFrame([order("2017-10-18 00:00:00", "2017-10-18 14:00:00")]))
    assert not done.loc[0, "is_late"]


def test_delivery_next_calendar_day_is_late():
    done = delivered_orders(pd.DataFrame([order("2017-10-18 00:00:00", "2017-10-19 00:01:00")]))
    assert done.loc[0, "is_late"]


def test_timestamp_rule_still_recorded():
    done = delivered_orders(pd.DataFrame([order("2017-10-18 00:00:00", "2017-10-18 14:00:00")]))
    assert done.loc[0, "is_late_timestamp"]


def test_handoff_date_and_month_of_year_columns():
    done = delivered_orders(pd.DataFrame([order("2017-10-18 00:00:00", "2017-10-18 14:00:00")]))
    assert done.loc[0, "handoff_date"] == pd.Timestamp("2017-10-03")
    assert done.loc[0, "month_of_year"] == 10


def test_add_state_keeps_every_order_and_nulls_unknown_customers():
    orders = pd.DataFrame({"order_id": ["a", "b"], "customer_id": ["known", "stranger"]})
    customers = pd.DataFrame(
        {"customer_id": ["known"], "customer_state": ["SP"], "customer_city": ["sao paulo"]}
    )
    out = add_state(orders, customers)
    assert len(out) == 2
    assert out.loc[0, "customer_state"] == "SP"
    assert pd.isna(out.loc[1, "customer_state"])


def test_download_all_requests_both_tables(tmp_path):
    asked = []

    def fake(handle, path=None):
        asked.append((handle, path))
        return str(tmp_path / (path or "x"))

    download_data.download_all(fetch=fake, cache_dir=tmp_path)
    assert ("zeynepustun/customer-order-delivery-dataset", None) in asked
    assert ("olistbr/brazilian-ecommerce", "olist_customers_dataset.csv") in asked


@needs_data
def test_real_counts():
    clean = clean_delivered(delivered_orders(load_raw()))
    assert len(clean) == 95_736
    assert int(clean["is_late"].sum()) == 6_229
    assert int(clean["is_late_timestamp"].sum()) == 7_519
    with_state = add_state(clean, load_customers())
    assert with_state["customer_state"].notna().all()
    assert with_state["customer_state"].nunique() == 27
    assert str(RAW_DIR) in str(ORDERS_CSV)
