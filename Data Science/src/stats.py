"""Intervals, adjusted effects and the verdict rule for the hypotheses (fixed before any result was read)."""

from __future__ import annotations

from typing import Literal, Mapping, Sequence

import numpy as np
import pandas as pd
import statsmodels.formula.api as smf

from config import MIN_GROUP, N_BOOT, SEED

Verdict = Literal["supported", "no clear effect", "opposite"]


def wilson_interval(late: int, n: int, z: float = 1.96) -> tuple[float, float]:
    """Wilson 95% interval for a proportion; unlike a bootstrap it stays sensible when nothing (or everything) is late."""
    p = late / n
    denominator = 1 + z * z / n
    centre = (p + z * z / (2 * n)) / denominator
    half = z * np.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / denominator
    return max(0.0, float(centre - half)), min(1.0, float(centre + half))


def late_rate_ci(df: pd.DataFrame, by: str, n_boot: int = N_BOOT, seed: int = SEED, min_group: int = MIN_GROUP) -> pd.DataFrame:
    """Late rate per group with a 95% interval; groups under `min_group` get no interval.

    For a yes/no outcome a bootstrap resample's late count is Binomial(n, observed rate), so that is what is drawn.
    A group with no late parcels (or only late ones) has no spread to resample, so it gets a Wilson interval instead.
    """
    rows = []
    for i, (group, part) in enumerate(df.dropna(subset=[by]).groupby(by, sort=True)):
        n, rate = len(part), float(part["is_late"].mean())
        reliable = n >= min_group
        low = high = np.nan
        if reliable and rate in (0.0, 1.0):
            low, high = wilson_interval(int(part["is_late"].sum()), n)
        elif reliable:
            draws = np.random.default_rng([seed, i]).binomial(n, rate, size=n_boot) / n
            low, high = np.percentile(draws, [2.5, 97.5])
        rows.append({"group": group, "n": n, "late_rate": rate, "ci_low": low, "ci_high": high, "reliable": reliable})
    return pd.DataFrame(rows, columns=["group", "n", "late_rate", "ci_low", "ci_high", "reliable"])


def adjusted_odds_ratios(df: pd.DataFrame, exposures: Sequence[str], cluster: str | None = None) -> pd.DataFrame:
    """Odds ratio of being late per exposure, controlling for purchase month and state (logistic regression).

    With `cluster` the intervals are cluster robust: parcels in the same cluster (for example the same handoff week)
    share exposures and shocks, so treating them as independent would make the intervals too narrow.

    Rows with a missing exposure are dropped; their count is returned in `result.attrs["dropped"]`.
    """
    usable = df.dropna(subset=list(exposures))
    data = pd.DataFrame({"is_late": usable["is_late"].astype(int).to_numpy()})
    for name in exposures:
        data[name] = usable[name].astype(float).to_numpy()
    data["purchase_month"] = usable["purchase_month"].to_numpy()
    data["customer_state"] = usable["customer_state"].to_numpy()
    formula = "is_late ~ " + " + ".join(exposures) + " + C(purchase_month) + C(customer_state)"
    options: dict = {"disp": False}
    if cluster:
        options.update(cov_type="cluster", cov_kwds={"groups": pd.factorize(usable[cluster])[0]})
    fit = smf.logit(formula, data=data).fit(**options)
    interval = np.exp(fit.conf_int())
    result = pd.DataFrame(
        {
            "term": list(exposures),
            "odds_ratio": [float(np.exp(fit.params[t])) for t in exposures],
            "ci_low": [float(interval.loc[t, 0]) for t in exposures],
            "ci_high": [float(interval.loc[t, 1]) for t in exposures],
        }
    )
    result.attrs["dropped"] = int(len(df) - len(usable))
    return result


def verdict(row: Mapping[str, float]) -> Verdict:
    """supported if the interval is entirely above 1, opposite if entirely below, otherwise no clear effect."""
    if row["ci_low"] > 1:
        return "supported"
    if row["ci_high"] < 1:
        return "opposite"
    return "no clear effect"
