# References

Everything cited by the explorer page, the README and the video. Links were checked on 2026-11-24 (`python src/check_references.py`).

## Data sources

**Olist orders** (Kaggle, dataset by zeynepustun): 99,441 marketplace orders with purchase, approval, handoff, delivery and estimated dates. https://www.kaggle.com/datasets/zeynepustun/customer-order-delivery-dataset. Accessed 2026-11-24. Licence: not verified. Kaggle does not expose the licence text to an automated fetch, so it must be read on the dataset page before the raw file is redistributed. The raw files are not stored in this repository (`data/raw` is git ignored) and are used here for a non commercial class project.

**Olist customers** (Kaggle, Olist, Brazilian e-commerce public dataset): only the file `olist_customers_dataset.csv`, used to get each customer's state. https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce. Accessed 2026-11-24. Licence: not verified, for the same reason as above. Not redistributed.

**Open-Meteo Historical Weather API**: daily precipitation and temperature. https://open-meteo.com/en/docs/historical-weather-api. Accessed 2026-11-24. Licence: the free API is for non commercial use and its terms accept the CC BY 4.0 licence (terms read on 2026-11-24 at https://open-meteo.com/en/terms). Weather data by Open-Meteo.com.

**Open-Meteo Geocoding API**: used once to find the coordinates of each state capital. https://open-meteo.com/en/docs/geocoding-api. Accessed 2026-11-24. Licence: same terms as the Open-Meteo APIs above.

**Nager.Date public holidays API**: nationwide public holidays for Brazil (analysis) and the Philippines (reuse demonstration). https://date.nager.at/Api. Accessed 2026-11-24. Licence: the project is MIT licensed (https://github.com/nager/Nager.Date/blob/main/LICENSE).

## Method and definitions

- Heavy rain day, at least 10 mm in a day: ETCCDI climate index R10mm, "count of days when PRCP >= 10mm". https://etccdi.pacificclimate.org/list_27_indices.shtml. Accessed 2026-11-24. The page does not use the word "heavy", so calling such a day heavy is this project's label.
- Efron, B. (1979). Bootstrap methods: another look at the jackknife. The Annals of Statistics, 7(1), 1 to 26. https://doi.org/10.1214/aos/1176344552
- Hanley, J. A., and McNeil, B. J. (1982). The meaning and use of the area under a receiver operating characteristic (ROC) curve. Radiology, 143(1), 29 to 36. https://doi.org/10.1148/radiology.143.1.7063747
- Cameron, A. C., and Miller, D. L. (2015). A practitioner's guide to cluster-robust inference. Journal of Human Resources, 50(2), 317 to 372. https://doi.org/10.3368/jhr.50.2.317
- Friedman, J. H. (2001). Greedy function approximation: a gradient boosting machine. The Annals of Statistics, 29(5), 1189 to 1232. https://doi.org/10.1214/aos/1013203451

## Software

- pandas: https://pandas.pydata.org/
- NumPy: https://numpy.org/
- scikit-learn, including the histogram gradient boosting classifier used here: https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.HistGradientBoostingClassifier.html
- statsmodels, logistic regression for the adjusted odds ratios: https://www.statsmodels.org/stable/index.html
- Requests: https://requests.readthedocs.io/
- kagglehub: https://github.com/Kaggle/kagglehub
- Remotion, used to render the video: https://www.remotion.dev/. Licence terms read on 2026-11-24 at https://www.remotion.dev/docs/license/faq: the free licence covers an individual, a team of up to three people, and non-profit or educational organisations. This project is a five person student group, and it is not decided here whether that counts as free use, so the group should check Remotion's eligibility page before publishing the video widely.
- ElevenLabs, used for the narration voice (the premade voice Brian) and for the word by word timings that the pictures are synchronised to: https://elevenlabs.io/docs
- The sound effects are original sounds synthesised with NumPy by `src/make_sfx.py` (no third party recordings), so they carry no extra licence.

## Fonts

Josefin Sans and Manrope, served from Google Fonts and embedded in the page. Both sit in the SIL Open Font License folder of the Google Fonts repository: https://github.com/google/fonts/tree/main/ofl. Specimens: https://fonts.google.com/specimen/Josefin+Sans and https://fonts.google.com/specimen/Manrope
