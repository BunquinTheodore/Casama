"""Task 3: Nager.Date holidays, caching and the Philippine reuse pull."""
import json
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer

import pytest

from fetch_holidays import ApiError, fetch_holidays, http_get_json, load_or_fetch_holidays, reuse_demo


def holiday(date, name, is_global=True, types=("Public",)):
    return {
        "date": date,
        "localName": name + " (local)",
        "name": name,
        "countryCode": "BR",
        "fixed": False,
        "global": is_global,
        "counties": None if is_global else ["BR-SP"],
        "launchYear": None,
        "types": list(types),
    }


def stub_for(payloads):
    """A get_json stub that answers by year found in the URL and records every call."""
    calls = []

    def get_json(url):
        calls.append(url)
        for year, payload in payloads.items():
            if f"/{year}/" in url:
                if isinstance(payload, Exception):
                    raise payload
                return payload
        raise AssertionError(f"unexpected url {url}")

    get_json.calls = calls
    return get_json


def test_keeps_only_nationwide_holidays():
    stub = stub_for({2017: [holiday("2017-01-01", "New Year"), holiday("2017-01-25", "City Day", is_global=False)]})
    frame = fetch_holidays("BR", [2017], get_json=stub)
    assert list(frame["name"]) == ["New Year"]
    assert str(frame["date"].iloc[0].date()) == "2017-01-01"
    assert set(frame.columns) >= {"date", "name", "local_name", "country", "nationwide", "types"}


def test_carnival_marked_bank_optional_is_kept():
    stub = stub_for({2017: [holiday("2017-02-28", "Carnival", types=("Bank", "Optional"))]})
    frame = fetch_holidays("BR", [2017], get_json=stub)
    assert list(frame["name"]) == ["Carnival"]
    assert frame["types"].iloc[0] == "Bank,Optional"


def test_error_response_raises_and_writes_no_cache(tmp_path):
    stub = stub_for({2016: [holiday("2016-01-01", "New Year")], 2017: ApiError("429 from nager")})
    with pytest.raises(ApiError):
        load_or_fetch_holidays("BR", [2016, 2017], get_json=stub, cache_dir=tmp_path)
    assert list(tmp_path.glob("holidays_*.csv")) == []


def test_non_list_response_raises():
    stub = stub_for({2017: {"error": "nope"}})
    with pytest.raises(ApiError):
        fetch_holidays("BR", [2017], get_json=stub)


def test_second_call_uses_cache_without_network(tmp_path):
    stub = stub_for({2017: [holiday("2017-01-01", "New Year")]})
    first = load_or_fetch_holidays("BR", [2017], get_json=stub, cache_dir=tmp_path)

    def explode(url):
        raise AssertionError("network used although a cache exists")

    second = load_or_fetch_holidays("BR", [2017], get_json=explode, cache_dir=tmp_path)
    assert list(second["name"]) == list(first["name"])
    assert str(second["date"].iloc[0].date()) == "2017-01-01"


def test_reuse_demo_uses_country_code_only(tmp_path):
    stub = stub_for({2026: [holiday(f"2026-0{m}-01", f"Day {m}") for m in range(1, 7)]})
    out = tmp_path / "reuse.json"
    result = reuse_demo(get_json=stub, cache_dir=tmp_path, out_path=out)
    assert stub.calls == ["https://date.nager.at/api/v3/PublicHolidays/2026/PH"]
    assert result["country"] == "PH" and result["year"] == 2026
    assert result["holiday_count"] == 6 and result["first_five"] == [f"Day {m}" for m in range(1, 6)]
    assert json.loads(out.read_text()) == result


def test_http_get_json_raises_api_error_on_non_200():
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(500)
            self.end_headers()

        def log_message(self, *args):
            pass

    server = HTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    try:
        with pytest.raises(ApiError):
            http_get_json(f"http://127.0.0.1:{server.server_port}/x")
    finally:
        server.shutdown()
