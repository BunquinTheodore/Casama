"""Task 5: rain and holiday exposure in the days after carrier handoff (H1 and H2 inputs)."""
import pandas as pd
import pytest

from config import HEAVY_RAIN_MM
from window_features import add_window_features

NAT = pd.NaT


def weather(start, end, heavy=(), state="SP", precip_default=0.0):
    dates = pd.date_range(start, end, freq="D")
    frame = pd.DataFrame({"state": state, "date": dates, "precip_mm": precip_default, "temp_mean_c": 20.0})
    for d in heavy:
        frame.loc[frame["date"] == pd.Timestamp(d), "precip_mm"] = HEAVY_RAIN_MM + 5
    return frame


def orders(handoff, state="SP"):
    return pd.DataFrame({"order_delivered_carrier_date": [pd.Timestamp(handoff) if handoff else NAT], "customer_state": [state]})


def holidays(*dates):
    return pd.DataFrame({"date": pd.to_datetime(list(dates))})


NO_HOLIDAYS = holidays("2017-01-01", "2017-12-25")
W = weather("2017-02-20", "2017-03-31", heavy=["2017-02-28", "2017-03-01", "2017-03-07", "2017-03-08"])


def test_counts_heavy_days_inside_window_only():
    out = add_window_features(orders("2017-03-01 15:30:00"), W, NO_HOLIDAYS)
    assert out.loc[0, "heavy_rain_days"] == 2  # 03-01 and 03-07; 02-28 and 03-08 are outside


def test_handoff_day_is_day_one():
    only_first = add_window_features(orders("2017-03-01"), weather("2017-02-20", "2017-03-31", heavy=["2017-03-01"]), NO_HOLIDAYS)
    only_last = add_window_features(orders("2017-03-01"), weather("2017-02-20", "2017-03-31", heavy=["2017-03-07"]), NO_HOLIDAYS)
    just_after = add_window_features(orders("2017-03-01"), weather("2017-02-20", "2017-03-31", heavy=["2017-03-08"]), NO_HOLIDAYS)
    assert (only_first.loc[0, "heavy_rain_days"], only_last.loc[0, "heavy_rain_days"], just_after.loc[0, "heavy_rain_days"]) == (1, 1, 0)


def test_rain_mm_total_sums_the_window():
    out = add_window_features(orders("2017-03-01"), W, NO_HOLIDAYS)
    assert out.loc[0, "rain_mm_total"] == pytest.approx(2 * (HEAVY_RAIN_MM + 5))


def test_holiday_on_handoff_day_counts():
    out = add_window_features(orders("2017-03-01"), W, holidays("2017-03-01", "2017-12-25"))
    assert out.loc[0, "holiday_in_window"] is True or bool(out.loc[0, "holiday_in_window"]) is True


def test_holiday_outside_window_does_not_count():
    out = add_window_features(orders("2017-03-01"), W, holidays("2017-03-08", "2017-12-25"))
    assert bool(out.loc[0, "holiday_in_window"]) is False


def test_window_crossing_year_boundary():
    w = weather("2017-12-01", "2018-01-31")
    out = add_window_features(orders("2017-12-29"), w, holidays("2017-12-25", "2018-01-01"))
    assert bool(out.loc[0, "holiday_in_window"]) is True
    assert out.loc[0, "heavy_rain_days"] == 0


def test_missing_handoff_gives_na_not_zero():
    out = add_window_features(orders(None), W, NO_HOLIDAYS)
    assert pd.isna(out.loc[0, "heavy_rain_days"]) and pd.isna(out.loc[0, "rain_mm_total"]) and pd.isna(out.loc[0, "holiday_in_window"])


@pytest.mark.parametrize("state", ["ZZ", None])
def test_unknown_state_gives_na(state):
    out = add_window_features(orders("2017-03-01", state=state), W, NO_HOLIDAYS)
    assert pd.isna(out.loc[0, "heavy_rain_days"])


def test_window_past_last_weather_date_gives_na():
    w = weather("2017-02-20", "2017-03-10")
    inside = add_window_features(orders("2017-03-04"), w, NO_HOLIDAYS)  # window ends 03-10, covered
    past = add_window_features(orders("2017-03-08"), w, NO_HOLIDAYS)  # window ends 03-14, not covered
    assert inside.loc[0, "heavy_rain_days"] == 0 and pd.isna(past.loc[0, "heavy_rain_days"])


def test_window_before_first_weather_date_gives_na():
    out = add_window_features(orders("2017-02-10"), W, NO_HOLIDAYS)
    assert pd.isna(out.loc[0, "heavy_rain_days"])


def test_window_past_covered_holiday_years_gives_na():
    w = weather("2017-12-01", "2018-01-31")
    out = add_window_features(orders("2017-12-30"), w, holidays("2017-12-25"))  # only 2017 holidays are known
    assert pd.isna(out.loc[0, "holiday_in_window"]) and out.loc[0, "heavy_rain_days"] == 0


def test_days_parameter_changes_window():
    w = weather("2017-02-20", "2017-03-31", heavy=["2017-03-09"])  # day 9 after handoff on 03-01
    seven = add_window_features(orders("2017-03-01"), w, NO_HOLIDAYS, days=7)
    ten = add_window_features(orders("2017-03-01"), w, NO_HOLIDAYS, days=10)
    assert seven.loc[0, "heavy_rain_days"] == 0 and ten.loc[0, "heavy_rain_days"] == 1


def test_input_frame_is_not_mutated():
    frame = orders("2017-03-01")
    before = frame.copy()
    add_window_features(frame, W, NO_HOLIDAYS)
    pd.testing.assert_frame_equal(frame, before)


def test_feature_dtypes_are_nullable_types():
    out = add_window_features(orders("2017-03-01"), W, NO_HOLIDAYS)
    assert str(out["heavy_rain_days"].dtype) == "Int64"
    assert str(out["rain_mm_total"].dtype) == "float64"
    assert str(out["holiday_in_window"].dtype) == "boolean"
