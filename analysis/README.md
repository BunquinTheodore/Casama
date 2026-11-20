# Casama delivery analytics (Data Science and AI)

Exploratory analysis and a small late parcel model built on the Kaggle
[Customer Order Delivery Dataset](https://www.kaggle.com/datasets/zeynepustun/customer-order-delivery-dataset)
(99,441 real marketplace orders, 2016 to 2018). The goal is to learn when parcels arrive late so
Casama's parcel board can warn housemates earlier.

## Run it

```bash
pip install -r analysis/requirements.txt
python analysis/download_data.py       # downloads orders.csv into data/raw (git ignored)
cd analysis
python eda_delivery.py                 # charts 01 to 06 and findings.json
python eda_extra.py                    # charts 08 to 12 and extra_findings.json
python late_model.py                   # charts 07, 13, 14, model_metrics.json
python build_dashboard.py              # output/dashboard.html (open in a browser)
```

## Files

| File | Purpose |
|---|---|
| `delivery_data.py` | Loads and cleans the data, shared by every script |
| `eda_delivery.py`, `eda_extra.py` | Exploratory charts and findings |
| `late_model.py` | Gradient boosting model, trained on 2017 and tested on 2018 |
| `build_dashboard.py` | Builds the presentation page |
| `qualitative.json` | Optional interview quotes shown in the dashboard (empty by default) |
| `output/` | Generated charts, metrics and `dashboard.html` |

## Results in short

* 7.9% of delivered parcels arrive after the estimate, and the median parcel takes 10.2 days.
* A slow seller handoff is the strongest warning sign (23% late when it takes 7 or more days).
* The model is modest: AUC 0.59 at purchase and 0.65 after the seller ships.

## Limits

The data is Brazilian, not Philippine, and has timestamps only (no courier, payment type or COD
amount). Treat the model as a nudge, not an accurate predictor.
