"""The page prose (Python), the page charts (JS) and the video (TypeScript) must print every number identically."""
import json
import re
import shutil
import subprocess

import pytest

from build_explorer import _format
from config import OUT_DIR, ROOT

FORMAT_TS = ROOT / "video" / "remotion" / "src" / "format.ts"
CHARTS_JS = ROOT / "explorer" / "charts.js"
TIES = [0.25, 0.5, 1.5, 2.5, 4.5, 6.5, 0.125, 0.375, 0.625, 8.25, 0.0355, 1.005, 0.585, -0.0084, -0.004, 12345.678, 95736.0]

pytestmark = pytest.mark.skipif(shutil.which("node") is None, reason="node is not installed")


def collect_numbers():
    found = set(TIES)

    def walk(x):
        if isinstance(x, bool):
            return
        if isinstance(x, (int, float)):
            found.add(float(x))
        elif isinstance(x, dict):
            [walk(v) for v in x.values()]
        elif isinstance(x, list):
            [walk(v) for v in x]

    for name in ("findings.json", "series.json"):
        path = OUT_DIR / name
        if path.exists():
            walk(json.loads(path.read_text(encoding="utf-8")))
    return sorted(found)


def run_js(program, numbers):
    done = subprocess.run(["node", "--input-type=module", "-e", program], input=json.dumps(numbers), capture_output=True, text=True)
    assert done.returncode == 0, done.stderr[-800:]
    return json.loads(done.stdout)


def python_rows(numbers, decimals):
    return [[_format(v, str(d)) for d in decimals] for v in numbers]


def test_video_format_matches_python_on_every_number():
    numbers = collect_numbers()
    program = f"""
import {{num}} from {json.dumps(FORMAT_TS.as_uri())};
const nums = JSON.parse(await new Promise(r => {{ let s=''; process.stdin.on('data', d => s += d); process.stdin.on('end', () => r(s)); }}));
console.log(JSON.stringify(nums.map(v => [0,1,2,3].map(d => num(v, d)))));
"""
    assert run_js(program, numbers) == python_rows(numbers, range(4))


def test_chart_format_matches_python_on_every_number():
    source = CHARTS_JS.read_text(encoding="utf-8")
    match = re.search(r"// FORMAT START(.*?)// FORMAT END", source, re.S)
    assert match, "charts.js must keep its number formatting between FORMAT START and FORMAT END markers"
    numbers = [n for n in collect_numbers()]
    program = f"""
const fixed = new Function({json.dumps(match.group(1))} + "; return fixed;")();
const nums = JSON.parse(await new Promise(r => {{ let s=''; process.stdin.on('data', d => s += d); process.stdin.on('end', () => r(s)); }}));
console.log(JSON.stringify(nums.map(v => [0,1,2,3].map(d => fixed(v, d)))));
"""
    plain = [[row.replace(",", "") for row in line] for line in python_rows(numbers, range(4))]
    assert run_js(program, numbers) == plain
