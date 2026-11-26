"""Rain and holiday exposure in the days after carrier handoff (inputs for hypotheses H1 and H2).

The window is `days` calendar days starting on the handoff date (the handoff day is day one), the same length for
every parcel and known at handoff time, so no outcome leaks in. A feature is missing (NA, never zero) when the
handoff date or state is missing, or when any day of the window falls outside the weather or holiday coverage.
"""

from __future__ import annotations

import pandas as pd

from config import HEAVY_RAIN_MM, WINDOW_DAYS

NS = "datetime64[ns]"


def _forward_sum(daily: pd.DataFrame | pd.Series, days: int):
    """Sum of the `days` values starting at each date; NaN if any value in that span is unknown."""
    return daily.rolling(days, min_periods=days).sum().shift(-(days - 1))


def _rain_by_state_date(weather: pd.DataFrame, heavy_mm: float, days: int) -> pd.DataFrame:
    precip = weather.assign(date=weather["date"].astype(NS)).pivot(index="date", columns="state", values="precip_mm")
    precip = precip.reindex(pd.date_range(precip.index.min(), precip.index.max(), freq="D")).rename_axis("date")
    heavy = (precip >= heavy_mm).astype(float).where(precip.notna())
    long = []
    for name, table in (("heavy_rain_days", heavy), ("rain_mm_total", precip)):
        rolled = _forward_sum(table, days)
        long.append(rolled.reset_index().melt(id_vars="date", var_name="state", value_name=name).set_index(["date", "state"]))
    return pd.concat(long, axis=1).reset_index()


def _holiday_in_window(handoff: pd.Series, holidays: pd.DataFrame, days: int) -> pd.Series:
    dates = holidays["date"].astype(NS)
    covered = pd.date_range(f"{dates.dt.year.min()}-01-01", f"{dates.dt.year.max()}-12-31", freq="D")
    flag = pd.Series(0.0, index=covered)
    flag.loc[flag.index.intersection(dates)] = 1.0
    window = _forward_sum(flag, days).rename("holiday_days").rename_axis("date").reset_index()
    return handoff.to_frame("date").merge(window, on="date", how="left")["holiday_days"]


def add_window_features(
    orders: pd.DataFrame,
    weather: pd.DataFrame,
    holidays: pd.DataFrame,
    days: int = WINDOW_DAYS,
    heavy_mm: float = HEAVY_RAIN_MM,
) -> pd.DataFrame:
    handoff = orders["order_delivered_carrier_date"].dt.normalize().astype(NS).reset_index(drop=True)
    keys = pd.DataFrame({"date": handoff, "state": orders["customer_state"].reset_index(drop=True)})
    rain = keys.merge(_rain_by_state_date(weather, heavy_mm, days), on=["date", "state"], how="left")
    holiday_days = _holiday_in_window(handoff, holidays, days)

    out = orders.copy()
    out["heavy_rain_days"] = pd.array(rain["heavy_rain_days"].round(), dtype="Int64")
    out["rain_mm_total"] = rain["rain_mm_total"].to_numpy()
    holiday = (holiday_days > 0).astype("boolean")
    holiday[holiday_days.isna()] = pd.NA
    out["holiday_in_window"] = pd.array(holiday, dtype="boolean")
    return out
