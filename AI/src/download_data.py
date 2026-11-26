"""Download the CASAS four home dataset (CC BY 4.0) into AI/data/raw/casas, resuming a partial file.

Record: https://zenodo.org/records/17180309  (Cook, Crandall, Thomas and Krishnan, "CASAS: A smart home in a box")
Run: python src/download_data.py
"""

from __future__ import annotations

import hashlib
from pathlib import Path
from typing import Callable

from config import CASAS_DIR, CASAS_ZIP_BYTES, CASAS_ZIP_NAME, CASAS_ZIP_URL


def _fetch_with_resume(url: str, path: Path, start: int) -> None:
    import requests

    headers = {"Range": f"bytes={start}-"} if start else {}
    with requests.get(url, headers=headers, stream=True, timeout=60) as response:
        response.raise_for_status()
        mode = "ab" if start and response.status_code == 206 else "wb"
        with open(path, mode) as handle:
            for chunk in response.iter_content(chunk_size=1 << 20):
                handle.write(chunk)


def ensure_casas_zip(
    directory: Path = CASAS_DIR,
    expected_bytes: int = CASAS_ZIP_BYTES,
    fetch: Callable[[str, Path, int], None] = _fetch_with_resume,
) -> Path:
    """Return the path of the complete zip, downloading or resuming it when needed."""
    directory.mkdir(parents=True, exist_ok=True)
    path = directory / CASAS_ZIP_NAME
    have = path.stat().st_size if path.exists() else 0
    if have != expected_bytes:
        fetch(CASAS_ZIP_URL, path, have if have < expected_bytes else 0)
    got = path.stat().st_size if path.exists() else 0
    if got != expected_bytes:
        raise RuntimeError(f"expected {expected_bytes} bytes for {CASAS_ZIP_NAME}, got {got}; run again to resume")
    return path


def sha256_of(path: Path) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


if __name__ == "__main__":
    zip_path = ensure_casas_zip()
    print(f"{zip_path} ({zip_path.stat().st_size} bytes) sha256 {sha256_of(zip_path)}")
