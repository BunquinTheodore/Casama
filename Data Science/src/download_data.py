"""Download the two Kaggle tables the analysis needs into data/raw (git ignored).

Orders: https://www.kaggle.com/datasets/zeynepustun/customer-order-delivery-dataset
Customers: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce (one file)
Run: python src/download_data.py
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Callable

from config import RAW_DIR

DATASETS = [
    ("zeynepustun/customer-order-delivery-dataset", None),
    ("olistbr/brazilian-ecommerce", "olist_customers_dataset.csv"),
]


def download_all(fetch: Callable | None = None, cache_dir: Path = RAW_DIR) -> list[str]:
    if fetch is None:
        import kagglehub

        os.environ["KAGGLEHUB_CACHE"] = str(cache_dir)
        fetch = kagglehub.dataset_download
    return [str(fetch(handle, path=path)) for handle, path in DATASETS]


if __name__ == "__main__":
    for location in download_all():
        print(f"Downloaded to {location}")
