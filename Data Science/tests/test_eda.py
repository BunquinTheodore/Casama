"""Task 7: every old chart becomes plain JSON rows (no plotting)."""
import json

import numpy as np
import pandas as pd
import pytest

from delivery_data import ORDERS_CSV, clean_delivered, delivered_orders, load_raw
from eda import SERIES_NAMES, cleaning_funnel, series

needs_data = pytest.mark.skipif(not ORDERS_CSV.exists(), reason="raw Kaggle files not downloaded")


def synthetic_raw(months=("2017-01", "2017-02", "2017-03"), per_month=320, seed=5):
    rng = np.random.default_rng(seed)
    rows = []
    for m_index, month in enumerate(months):
        for i in range(per_month):
            purchase = pd.Timestamp(f"{month}-01") + pd.Timedelta(days=int(rng.integers(0, 27)), hours=int(rng.integers(0, 24)))
            handoff = purchase + pd.Timedelta(days=float(rng.uniform(0.2, 9)))
            delivered = handoff + pd.Timedelta(days=float(rng.uniform(1, 18)))
            estimate = (purchase + pd.Timedelta(days=float(rng.uniform(8, 35)))).normalize()
            rows.append(
                {
                    "order_id": f"{month}-{i}", "customer_id": f"c{m_index}-{i}", "order_status": "delivered",
                    "order_purchase_timestamp": purchase, "order_approved_at": purchase + pd.Timedelta(hours=2),
                    "order_delivered_carrier_date": handoff, "order_delivered_customer_date": delivered,
                    "order_estimated_delivery_date": estimate,
                }
            )
    return pd.DataFrame(rows)


@pytest.fixture(scope="module")
def stages():
    raw = synthetic_raw()
    done = delivered_orders(raw)
    return raw, done, clean_delivered(done)


def test_series_names_cover_the_eleven_eda_charts():
    assert len(SERIES_NAMES) == 11 and len(set(SERIES_NAMES)) == 11


@pytest.mark.parametrize("name", SERIES_NAMES)
def test_every_series_returns_nonempty_json_serialisable_rows(name, stages):
    raw, done, clean = stages
    rows = series(name, clean, raw=raw, delivered=done)
    assert isinstance(rows, list) and rows and all(isinstance(r, dict) for r in rows)
    json.dumps(rows)  # raises if numpy types leak out


def test_late_by_month_uses_calendar_day_rule():
    # 320 parcels, each delivered at 2pm on the promised day: late by clock, not by calendar day
    purchase = pd.Timestamp("2017-02-01 09:00")
    raw = pd.DataFrame(
        {
            "order_id": [str(i) for i in range(320)], "customer_id": "c", "order_status": "delivered",
            "order_purchase_timestamp": purchase, "order_approved_at": purchase + pd.Timedelta(hours=1),
            "order_delivered_carrier_date": purchase + pd.Timedelta(days=2),
            "order_delivered_customer_date": pd.Timestamp("2017-02-18 14:00"),
            "order_estimated_delivery_date": pd.Timestamp("2017-02-18 00:00"),
        }
    )
    clean = clean_delivered(delivered_orders(raw))
    rows = series("late_by_month", clean)
    assert rows == [{"month": "2017-02", "late_pct": 0.0, "orders": 320}]


def test_order_rhythm_is_a_full_weekday_by_hour_grid(stages):
    rows = series("order_rhythm", stages[2])
    assert len(rows) == 7 * 24 and sum(r["orders"] for r in rows) == len(stages[2])


def test_promise_vs_actual_sample_is_capped_and_reproducible(stages):
    first, second = series("promise_vs_actual", stages[2]), series("promise_vs_actual", stages[2])
    assert len(first) <= 3000 and first == second


def test_unknown_series_name_raises(stages):
    with pytest.raises(KeyError):
        series("nope", stages[2])


@needs_data
def test_cleaning_funnel_counts_on_real_data():
    raw = load_raw()
    done = delivered_orders(raw)
    clean = clean_delivered(done)
    rows = cleaning_funnel(raw, done, clean)
    assert [r["orders"] for r in rows] == [99_441, 96_476, 95_736]
