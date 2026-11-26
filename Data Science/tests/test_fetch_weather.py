"""Task 4: state capital coordinates and daily weather from Open-Meteo."""
from urllib.parse import parse_qs, urlparse

import pandas as pd
import pytest

from delivery_data import CUSTOMERS_CSV, load_customers
from fetch_holidays import ApiError
from fetch_weather import STATE_CAPITALS, fetch_capital_coords, fetch_weather

BRAZIL_LAT, BRAZIL_LON = (-34.0, 6.0), (-74.0, -34.0)


def decoy_table(only_state=None):
    """Geocoder answers per capital: a bigger decoy town plus the true PPLA/PPLC seat."""
    table = {}
    for i, (uf, capital) in enumerate(sorted(STATE_CAPITALS.items())):
        if only_state and uf != only_state:
            continue
        table[capital] = [
            {"name": capital, "country_code": "MX", "feature_code": "PPL", "population": 9_999_999, "latitude": 19.0, "longitude": -99.0},
            {"name": capital, "country_code": "BR", "feature_code": "PPL", "population": 900_000, "latitude": -1.0, "longitude": -40.0},
            {"name": capital, "country_code": "BR", "feature_code": "PPLA", "population": 300_000, "latitude": -10.0 - i * 0.1, "longitude": -45.0 - i * 0.1},
        ]
    return table


def geocode_stub(table):
    def get_json(url):
        name = parse_qs(urlparse(url).query)["name"][0]
        results = table.get(name)
        return {"results": results} if results else {"generationtime_ms": 0.1}

    return get_json


def test_state_capitals_has_27_states_and_unique_names():
    assert len(STATE_CAPITALS) == 27
    assert len(set(STATE_CAPITALS.values())) == 27


def test_capital_coords_pick_the_state_seat_not_the_decoys(tmp_path):
    coords = fetch_capital_coords(get_json=geocode_stub(decoy_table()), cache_dir=tmp_path)
    assert len(coords) == 27
    assert set(coords.columns) == {"state", "capital", "lat", "lon"}
    assert (coords["lat"].between(*BRAZIL_LAT) & coords["lon"].between(*BRAZIL_LON)).all()
    assert coords["lat"].lt(-9.9).all()  # the PPLA rows, never the -1.0 or +19.0 decoys


def test_capital_not_found_raises_naming_the_state(tmp_path):
    table = decoy_table()
    del table["Natal"]
    with pytest.raises(ApiError, match="RN"):
        fetch_capital_coords(get_json=geocode_stub(table), cache_dir=tmp_path)
    assert list(tmp_path.glob("state_capitals.csv")) == []


def test_coordinates_outside_brazil_raise(tmp_path):
    table = decoy_table()
    table["Natal"] = [{"name": "Natal", "country_code": "BR", "feature_code": "PPLA", "population": 1, "latitude": 48.8, "longitude": 2.3}]
    with pytest.raises(ApiError, match="outside Brazil"):
        fetch_capital_coords(get_json=geocode_stub(table), cache_dir=tmp_path)


def make_coords(n):
    return pd.DataFrame(
        {"state": [f"S{i}" for i in range(n)], "capital": [f"C{i}" for i in range(n)], "lat": [-10.0 - i for i in range(n)], "lon": [-45.0 - i for i in range(n)]}
    )


def weather_stub(days, fail_on_call=None, drop_daily=False, null_first_precip=False):
    calls = []

    def get_json(url):
        calls.append(url)
        if fail_on_call == len(calls):
            raise ApiError("429 from open-meteo")
        query = parse_qs(urlparse(url).query)
        lats = query["latitude"][0].split(",")
        entries = []
        for _ in lats:
            daily = {
                "time": days,
                "precipitation_sum": [1.0 * i for i in range(len(days))],
                "temperature_2m_mean": [20.0 for _ in days],
            }
            if null_first_precip:
                daily["precipitation_sum"][0] = None
            entries.append({} if drop_daily else {"daily": daily})
        return entries[0] if len(entries) == 1 else entries  # the real API returns a bare object for one location

    get_json.calls = calls
    return get_json


DAYS = ["2017-01-01", "2017-01-02", "2017-01-03"]


def test_fetch_weather_batches_and_returns_one_row_per_state_day(tmp_path):
    stub = weather_stub(DAYS)
    frame = fetch_weather(make_coords(5), "2017-01-01", "2017-01-03", get_json=stub, batch_size=2, cache_dir=tmp_path)
    assert len(stub.calls) == 3  # batches of 2, 2 and 1 (the last answers with a bare object)
    assert len(frame) == 5 * 3
    assert list(frame.columns) == ["state", "date", "precip_mm", "temp_mean_c"]
    assert frame.loc[frame["state"] == "S4", "date"].tolist() == [pd.Timestamp(d) for d in DAYS]


def test_null_precipitation_stays_missing_not_zero(tmp_path):
    frame = fetch_weather(make_coords(1), "2017-01-01", "2017-01-03", get_json=weather_stub(DAYS, null_first_precip=True), cache_dir=tmp_path)
    assert frame["precip_mm"].isna().sum() == 1


def test_partial_failure_raises_and_writes_no_cache(tmp_path):
    stub = weather_stub(DAYS, fail_on_call=2)
    with pytest.raises(ApiError):
        fetch_weather(make_coords(5), "2017-01-01", "2017-01-03", get_json=stub, batch_size=2, cache_dir=tmp_path)
    assert list(tmp_path.glob("weather_*.csv")) == []


def test_missing_daily_key_raises(tmp_path):
    with pytest.raises(ApiError, match="daily"):
        fetch_weather(make_coords(2), "2017-01-01", "2017-01-03", get_json=weather_stub(DAYS, drop_daily=True), cache_dir=tmp_path)


def test_second_call_uses_cache_without_network(tmp_path):
    first = fetch_weather(make_coords(2), "2017-01-01", "2017-01-03", get_json=weather_stub(DAYS), cache_dir=tmp_path)

    def explode(url):
        raise AssertionError("network used although a cache exists")

    second = fetch_weather(make_coords(2), "2017-01-01", "2017-01-03", get_json=explode, cache_dir=tmp_path)
    assert len(second) == len(first)
    assert second["date"].dtype == first["date"].dtype


@pytest.mark.skipif(not CUSTOMERS_CSV.exists(), reason="raw Kaggle files not downloaded")
def test_capitals_cover_every_state_in_customers():
    assert set(load_customers()["customer_state"].unique()) <= set(STATE_CAPITALS)
