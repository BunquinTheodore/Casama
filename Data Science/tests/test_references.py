"""Task 11: cited sources are real, cover what the project uses, and the README matches findings.json."""
import json

import pytest

from check_references import check_references, extract_urls
from config import OUT_DIR, ROOT

REFERENCES = ROOT / "REFERENCES.md"
README = ROOT / "README.md"
REQUIRED = [
    "zeynepustun", "olistbr", "open-meteo.com", "date.nager.at", "pandas", "scikit-learn", "statsmodels",
    "remotion", "elevenlabs", "etccdi", "geocoding", "10.1214/aos/1176344552", "doi.org",
]


def test_references_cover_required_sources():
    text = REFERENCES.read_text(encoding="utf-8").lower()
    missing = [needle for needle in REQUIRED if needle.lower() not in text]
    assert not missing, f"not cited: {missing}"


def test_extract_urls_finds_markdown_and_bare_links(tmp_path):
    sample = tmp_path / "x.md"
    sample.write_text("See [a](https://example.org/a) and https://example.org/b.\n", encoding="utf-8")
    assert extract_urls(sample) == ["https://example.org/a", "https://example.org/b"]


@pytest.mark.network
def test_every_reference_link_resolves():
    results = check_references(REFERENCES)
    assert results
    broken = [(url, status) for url, status in results if not 0 < status < 400]
    assert not broken, f"broken links: {broken}"


def test_every_data_source_has_a_licence_line():
    text = REFERENCES.read_text(encoding="utf-8")
    for source in ("Olist orders", "Olist customers", "Open-Meteo", "Nager.Date"):
        block = text[text.index(source):]
        assert "Licence" in block.split("\n\n")[0], f"no licence line for {source}"


@pytest.mark.skipif(not (OUT_DIR / "findings.json").exists(), reason="run build_findings first")
def test_readme_numbers_come_from_findings_and_nothing_is_left_over():
    from build_readme import build_readme

    build_readme()
    findings = json.loads((OUT_DIR / "findings.json").read_text(encoding="utf-8"))
    text = README.read_text(encoding="utf-8")
    assert f"{findings['late']['rate_pct']:.2f}" in text and "{{" not in text
    assert "run_all.py" in text and "REFERENCES.md" in text


def test_status_retries_after_rate_limiting(monkeypatch):
    import threading
    from http.server import BaseHTTPRequestHandler, HTTPServer

    import check_references as cr

    calls = []

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            calls.append(1)
            self.send_response(429 if len(calls) == 1 else 200)
            self.end_headers()

        def log_message(self, *args):
            pass

    server = HTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    monkeypatch.setattr(cr, "RETRY_DELAY", 0)
    try:
        assert cr._status(f"http://127.0.0.1:{server.server_port}/x") == 200
        assert len(calls) == 2
    finally:
        server.shutdown()
