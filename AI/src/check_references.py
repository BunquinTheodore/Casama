"""Check that every link cited in REFERENCES.md really resolves. DOIs are checked against the doi.org handle service."""

from __future__ import annotations

import re
import time
from pathlib import Path

import requests

URL = re.compile(r"https?://[^\s)>\]]+")
HEADERS = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0 Safari/537.36"}
DOI_PREFIX = "https://doi.org/"
ATTEMPTS = 3
RETRY_DELAY = 5.0


def extract_urls(path: Path) -> list[str]:
    seen: list[str] = []
    for url in URL.findall(path.read_text(encoding="utf-8")):
        url = url.rstrip(".,;:")
        if url not in seen:
            seen.append(url)
    return seen


def _status(url: str) -> int:
    try:
        if url.startswith(DOI_PREFIX):
            reply = requests.get(f"{DOI_PREFIX}api/handles/{url[len(DOI_PREFIX):]}", headers=HEADERS, timeout=25)
            return 200 if reply.status_code == 200 and reply.json().get("responseCode") == 1 else 404
        for attempt in range(1, ATTEMPTS + 1):
            reply = requests.get(url, headers=HEADERS, timeout=25, allow_redirects=True, stream=True)
            reply.close()
            if reply.status_code != 429 or attempt == ATTEMPTS:
                return reply.status_code
            time.sleep(RETRY_DELAY * attempt)  # rate limited, not broken: wait and ask again
        return 0
    except (requests.RequestException, ValueError):
        return 0


def check_references(path: Path) -> list[tuple[str, int]]:
    return [(url, _status(url)) for url in extract_urls(path)]


if __name__ == "__main__":
    from config import ROOT

    bad = 0
    for link, code in check_references(ROOT / "REFERENCES.md"):
        print(code, link)
        bad += 0 if 200 <= code < 400 else 1
    raise SystemExit(1 if bad else 0)
