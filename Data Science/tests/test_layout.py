"""Task 1: the project folders exist and the old analysis folder is gone."""
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1]
REPO = PROJECT.parent


def test_expected_folders_exist():
    for name in ["src", "tests", "data/raw", "data/cache", "output", "explorer", "video"]:
        assert (PROJECT / name).is_dir(), f"missing folder: {name}"
    assert not (REPO / "analysis").exists(), "old analysis/ folder should be moved away"
