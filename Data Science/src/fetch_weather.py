"""State capital coordinates and daily weather from the free Open-Meteo APIs.

Geocoding: https://geocoding-api.open-meteo.com   Historical weather: https://archive-api.open-meteo.com
Weather is taken at the destination state capital, one point per state (a stated limit of the analysis).
"""

from __future__ import annotations

from pathlib import Path
from typing import Any, Callable
from urllib.parse import quote

import pandas as pd

from config import CACHE_DIR
from fetch_holidays import ApiError, http_get_json

STATE_CAPITALS = {
    "AC": "Rio Branco", "AL": "Maceió", "AP": "Macapá", "AM": "Manaus", "BA": "Salvador",
    "CE": "Fortaleza", "DF": "Brasília", "ES": "Vitória", "GO": "Goiânia", "MA": "São Luís",
    "MT": "Cuiabá", "MS": "Campo Grande", "MG": "Belo Horizonte", "PA": "Belém", "PB": "João Pessoa",
    "PR": "Curitiba", "PE": "Recife", "PI": "Teresina", "RJ": "Rio de Janeiro", "RN": "Natal",
    "RS": "Porto Alegre", "RO": "Porto Velho", "RR": "Boa Vista", "SC": "Florianópolis", "SP": "São Paulo",
    "SE": "Aracaju", "TO": "Palmas",
}
GEOCODE_URL = "https://geocoding-api.open-meteo.com/v1/search?name={name}&count=10&language=en&format=json&country_code=BR"
ARCHIVE_URL = (
    "https://archive-api.open-meteo.com/v1/archive?latitude={lats}&longitude={lons}"
    "&start_date={start}&end_date={end}&daily=precipitation_sum,temperature_2m_mean&timezone=auto"
)
SEATS = ("PPLA", "PPLC")  # GeoNames codes: seat of a first order division, or the national capital
BRAZIL_LAT, BRAZIL_LON = (-34.0, 6.0), (-74.0, -34.0)


def fetch_capital_coords(get_json: Callable[[str], Any] = http_get_json, cache_dir: Path = CACHE_DIR) -> pd.DataFrame:
    path = cache_dir / "state_capitals.csv"
    if path.exists():
        return pd.read_csv(path)
    rows = []
    for uf, capital in STATE_CAPITALS.items():
        payload = get_json(GEOCODE_URL.format(name=quote(capital)))
        seats = [
            r for r in (payload.get("results") or [])
            if r.get("feature_code") in SEATS and r.get("country_code", "BR") == "BR"
        ]
        if not seats:
            raise ApiError(f"no state seat found for {uf} ({capital})")
        best = max(seats, key=lambda r: r.get("population") or 0)
        lat, lon = float(best["latitude"]), float(best["longitude"])
        if not (BRAZIL_LAT[0] <= lat <= BRAZIL_LAT[1] and BRAZIL_LON[0] <= lon <= BRAZIL_LON[1]):
            raise ApiError(f"{uf} ({capital}): coordinates outside Brazil: {lat}, {lon}")
        rows.append({"state": uf, "capital": capital, "lat": lat, "lon": lon})
    frame = pd.DataFrame(rows)
    cache_dir.mkdir(parents=True, exist_ok=True)
    frame.to_csv(path, index=False)
    return frame


def fetch_weather(
    coords: pd.DataFrame,
    start: str,
    end: str,
    get_json: Callable[[str], Any] = http_get_json,
    batch_size: int = 10,
    cache_dir: Path = CACHE_DIR,
) -> pd.DataFrame:
    path = cache_dir / f"weather_{start}_{end}.csv"
    if path.exists():
        return pd.read_csv(path, parse_dates=["date"]).astype({"date": "datetime64[ns]"})
    frames = []
    for i in range(0, len(coords), batch_size):
        batch = coords.iloc[i : i + batch_size]
        url = ARCHIVE_URL.format(
            lats=",".join(str(v) for v in batch["lat"]), lons=",".join(str(v) for v in batch["lon"]), start=start, end=end
        )
        payload = get_json(url)
        entries = payload if isinstance(payload, list) else [payload]  # one location comes back as a bare object
        if len(entries) != len(batch):
            raise ApiError(f"expected {len(batch)} locations, got {len(entries)}")
        for state, entry in zip(batch["state"], entries):
            daily = entry.get("daily") if isinstance(entry, dict) else None
            if not daily or "precipitation_sum" not in daily:
                raise ApiError(f"no daily weather returned for {state}")
            frames.append(
                pd.DataFrame(
                    {
                        "state": state,
                        "date": pd.to_datetime(daily["time"]).astype("datetime64[ns]"),
                        "precip_mm": pd.to_numeric(pd.Series(daily["precipitation_sum"], dtype="object")),
                        "temp_mean_c": pd.to_numeric(pd.Series(daily["temperature_2m_mean"], dtype="object")),
                    }
                )
            )
    frame = pd.concat(frames, ignore_index=True)
    cache_dir.mkdir(parents=True, exist_ok=True)
    frame.to_csv(path, index=False)
    return frame
