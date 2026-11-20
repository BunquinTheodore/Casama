"""Download the Kaggle dataset used by the analysis into data/raw (not committed to git).

Dataset: https://www.kaggle.com/datasets/zeynepustun/customer-order-delivery-dataset
Run: python analysis/download_data.py
"""

from __future__ import annotations

import os
from pathlib import Path

import kagglehub

RAW_DIR = Path(__file__).resolve().parent.parent / "data/raw"


def main() -> None:
    os.environ["KAGGLEHUB_CACHE"] = str(RAW_DIR)
    path = kagglehub.dataset_download("zeynepustun/customer-order-delivery-dataset")
    print(f"Downloaded to {path}")


if __name__ == "__main__":
    main()
