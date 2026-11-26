# References

Everything cited by the README and the video. Links were checked on 2026-11-25 (`python src/check_references.py`).

## Data

**CASAS smart home dataset (Aruba, Cairo, Milan, Tulum)**, Zenodo record by Diane Cook, Washington State University: ambient motion, door and temperature sensor logs with activity labels, one file per home. https://zenodo.org/records/17180309 (DOI https://doi.org/10.5281/zenodo.17180309). Accessed 2026-11-25. Licence: CC BY 4.0, read on the record page and in its metadata on 2026-11-25. Attribution is given in the README and in the video. The raw files are not stored in this repository (`AI/data/raw` is git ignored).

**Companion CASAS record** (189 homes), cited by the record above for site information: https://zenodo.org/records/15708568. Licence CC BY 4.0. Not used for any number in this project.

**How the dataset asks to be cited:** Cook, D. J., Crandall, A. S., Thomas, B. L., and Krishnan, N. C. (2013). CASAS: A smart home in a box. IEEE Computer, 46(7). https://doi.org/10.1109/MC.2012.328

**Resident counts.** The Zenodo record does not say how many people live in each home. The README says that Aruba has one resident and that the Tulum homes have two, as reported by a dataset listing found by web search on 2026-11-25 (its table was garbled in the search result), so those counts are reported, not confirmed against a primary source.

## Method and definitions

- Predicting household occupancy from past behaviour, the problem this project solves for parcels: Kleiminger, W., Mattern, F., and Santini, S. (2014). Predicting household occupancy for smart heating control: A comparative performance analysis of state-of-the-art approaches. Energy and Buildings, 85, 493 to 505. https://doi.org/10.1016/j.enbuild.2014.09.046
- Brier score, the mean squared error of a probability forecast, as implemented in scikit-learn: https://scikit-learn.org/stable/modules/generated/sklearn.metrics.brier_score_loss.html
- Hanley, J. A., and McNeil, B. J. (1982). The meaning and use of the area under a receiver operating characteristic (ROC) curve. Radiology, 143(1), 29 to 36. https://doi.org/10.1148/radiology.143.1.7063747
- Friedman, J. H. (2001). Greedy function approximation: a gradient boosting machine. The Annals of Statistics, 29(5), 1189 to 1232. https://doi.org/10.1214/aos/1013203451 (the gradient boosted yardstick).
- Logistic regression, the combiner: https://scikit-learn.org/stable/modules/linear_model.html#logistic-regression
- Pedregosa, F. et al. (2011). Scikit-learn: Machine learning in Python. Journal of Machine Learning Research, 12, 2825 to 2830. https://jmlr.org/papers/v12/pedregosa11a.html

## Software

- Casama, the app this feature is added to (the 3rd year team's repository the group forked): https://github.com/pol-xy/Casama
- Flutter and Dart: https://flutter.dev/ and https://dart.dev/
- Riverpod: https://riverpod.dev/
- scikit-learn, including the histogram gradient boosting classifier used as a yardstick: https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.HistGradientBoostingClassifier.html
- NumPy: https://numpy.org/
- Requests: https://requests.readthedocs.io/
- HyperFrames, used to render the video: https://github.com/heygen-com/hyperframes
- Kokoro 82M, the open weight speech model (Apache 2.0) that speaks the narration: https://huggingface.co/hexgrad/Kokoro-82M
- kokoro-onnx, the Python package (MIT) that runs Kokoro on this computer: https://github.com/thewh1teagle/kokoro-onnx
- ffmpeg, used to mix and check the audio: https://ffmpeg.org/
- The sound effects are original sounds synthesised with NumPy by `src/make_sfx.py` (no third party recordings), so they carry no extra licence.

## Fonts

Josefin Sans and Manrope, served from Google Fonts. Both sit in the SIL Open Font License folder of the Google Fonts repository: https://github.com/google/fonts/tree/main/ofl. Specimens: https://fonts.google.com/specimen/Josefin+Sans and https://fonts.google.com/specimen/Manrope
