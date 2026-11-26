"""Public holidays from the free Nager.Date API (https://date.nager.at), cached as small CSVs.

The same call serves the analysis (BR) and the reuse demonstration (PH): only the country code changes.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Callable, Sequence

import pandas as pd
import requests

from config import CACHE_DIR, OUT_DIR

URL = "https://date.nager.at/api/v3/PublicHolidays/{year}/{country}"


class ApiError(Exception):
    """A public API answered badly or not at all."""


def http_get_json(url: str, timeout: int = 20) -> Any:
    try:
        response = requests.get(url, timeout=timeout)
    except requests.RequestException as exc:
        raise ApiError(f"request failed for {url}: {exc}") from exc
    if response.status_code != 200:
        raise ApiError(f"{response.status_code} from {url}")
    return response.json()


def fetch_holidays(country: str, years: Sequence[int], get_json: Callable[[str], Any] = http_get_json) -> pd.DataFrame:
    rows = []
    for year in years:
        payload = get_json(URL.format(year=year, country=country))
        if not isinstance(payload, list):
            raise ApiError(f"unexpected response for {country} {year}: {str(payload)[:80]}")
        for item in payload:
            if item.get("global"):
                rows.append(
                    {
                        "date": pd.Timestamp(item["date"]),
                        "name": item["name"],
                        "local_name": item["localName"],
                        "country": item["countryCode"],
                        "nationwide": True,
                        "types": ",".join(item.get("types") or []),
                    }
                )
    columns = ["date", "name", "local_name", "country", "nationwide", "types"]
    return pd.DataFrame(rows, columns=columns).sort_values("date").reset_index(drop=True)


def cache_path(country: str, years: Sequence[int], cache_dir: Path = CACHE_DIR) -> Path:
    return cache_dir / f"holidays_{country}_{min(years)}_{max(years)}.csv"


def load_or_fetch_holidays(
    country: str,
    years: Sequence[int],
    get_json: Callable[[str], Any] = http_get_json,
    cache_dir: Path = CACHE_DIR,
) -> pd.DataFrame:
    path = cache_path(country, years, cache_dir)
    if path.exists():
        return pd.read_csv(path, parse_dates=["date"], keep_default_na=False, dtype={"types": str})
    frame = fetch_holidays(country, years, get_json)  # raises before anything is written
    cache_dir.mkdir(parents=True, exist_ok=True)
    frame.to_csv(path, index=False)
    return frame


def reuse_demo(
    get_json: Callable[[str], Any] = http_get_json,
    cache_dir: Path = CACHE_DIR,
    out_path: Path = OUT_DIR / "reuse_ph_2026.json",
) -> dict:
    """Run the very same holiday pull for the Philippines, for the page's reuse box."""
    frame = load_or_fetch_holidays("PH", [2026], get_json=get_json, cache_dir=cache_dir)
    result = {
        "country": "PH",
        "year": 2026,
        "holiday_count": int(len(frame)),
        "first_five": [str(name) for name in frame["name"].head(5)],
        "source": "https://date.nager.at/api/v3/PublicHolidays/2026/PH",
    }
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")
    return result
