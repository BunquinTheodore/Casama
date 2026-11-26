"""Reference algorithm for the Casama Home Forecast.

The Dart port in lib/features/parcels/home_forecast must reproduce these numbers (golden.json).

A slot is an hour of the week: weekday * 24 + hour, Monday = 0, wall clock time, never converted
between time zones. For one person:

    habit(slot)   = (sum(w * home) + k * prior(slot)) / (sum(w) + k)         w = 0.5 ** (age_days / half_life)
    forecast      = sigmoid(b0 + b1 * logit(habit(target slot)) + b2 * (2n - 1) * exp(-h / tau))

n is 1 when the person is home now, h is the hours between now and the start of the target hour.
"""

from __future__ import annotations

import math
import warnings
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Iterable, Mapping, Sequence

import numpy as np
from sklearn.linear_model import LogisticRegression

SLOTS = 168
EPS = 1e-6
HOUR = timedelta(hours=1)
HORIZONS = (1, 3, 6, 12, 24, 48, 72)
WARMUP_DAYS = 7


@dataclass(frozen=True)
class Observation:
    at: datetime  # start of the hour, wall clock
    home: bool


@dataclass(frozen=True)
class Params:
    b0: float
    b1: float
    b2: float
    tau_hours: float
    half_life_days: float
    prior_strength: float
    prior: tuple[float, ...]


@dataclass(frozen=True)
class Grids:
    half_life_days: tuple[float, ...] = (7.0, 14.0, 28.0, 56.0)
    prior_strength: tuple[float, ...] = (1.0, 2.0, 4.0, 8.0)
    tau_hours: tuple[float, ...] = (1.0, 2.0, 3.0, 6.0, 12.0)


def floor_hour(at: datetime) -> datetime:
    return at.replace(minute=0, second=0, microsecond=0)


def slot_of(at: datetime) -> int:
    return at.weekday() * 24 + at.hour


def clip(p: float) -> float:
    return min(max(p, EPS), 1.0 - EPS)


def logit(p: float) -> float:
    p = clip(p)
    return math.log(p / (1.0 - p))


def sigmoid(z: float) -> float:
    if z >= 0:
        return 1.0 / (1.0 + math.exp(-z)) if z < 700 else 1.0
    e = math.exp(z) if z > -700 else 0.0
    return e / (1.0 + e)


def habit(observations: Iterable[Observation], now: datetime, slot: int, params: Params) -> float:
    """Recency weighted, prior smoothed share of past hours in this slot that the person was home."""
    cutoff = floor_hour(now)
    numerator = 0.0
    denominator = 0.0
    for o in observations:
        if o.at >= cutoff or slot_of(o.at) != slot:
            continue
        age_days = (cutoff - o.at).total_seconds() / 86400.0
        weight = 0.5 ** (age_days / params.half_life_days)
        numerator += weight * (1.0 if o.home else 0.0)
        denominator += weight
    k = params.prior_strength
    return (numerator + k * params.prior[slot]) / (denominator + k)


def forecast(observations: Iterable[Observation], now: datetime, home_now: bool, hours_ahead: int, params: Params) -> float:
    """Probability the person is home for the hour that starts `hours_ahead` hours after the hour of `now`."""
    target = floor_hour(now) + hours_ahead * HOUR
    h = habit(observations, now, slot_of(target), params)
    n = 1.0 if home_now else -1.0
    z = params.b0 + params.b1 * logit(h) + params.b2 * n * math.exp(-hours_ahead / params.tau_hours)
    return sigmoid(z)


class HabitState:
    """The same habit values as `habit`, built incrementally so long histories stay fast.

    Observations must be added in time order. `value(now, slot)` assumes every added observation
    is earlier than the hour of `now`.
    """

    def __init__(self, params: Params):
        self._params = params
        self._num = [0.0] * SLOTS
        self._den = [0.0] * SLOTS
        self._ref: list[datetime | None] = [None] * SLOTS
        self._latest: datetime | None = None

    def _decay_factor(self, since: datetime, until: datetime) -> float:
        return 0.5 ** (((until - since).total_seconds() / 86400.0) / self._params.half_life_days)

    def add(self, obs: Observation) -> None:
        if self._latest is not None and obs.at < self._latest:
            raise ValueError("observations must be added in time order")
        self._latest = obs.at
        s = slot_of(obs.at)
        ref = self._ref[s]
        if ref is not None and obs.at > ref:
            factor = self._decay_factor(ref, obs.at)
            self._num[s] *= factor
            self._den[s] *= factor
        self._ref[s] = obs.at
        self._num[s] += 1.0 if obs.home else 0.0
        self._den[s] += 1.0

    def value(self, now: datetime, slot: int) -> float:
        num, den, ref = self._num[slot], self._den[slot], self._ref[slot]
        if ref is not None:
            factor = self._decay_factor(ref, floor_hour(now))
            num *= factor
            den *= factor
        k = self._params.prior_strength
        return (num + k * self._params.prior[slot]) / (den + k)


def population_prior(series_by_home: Mapping[str, Sequence[Observation]]) -> tuple[float, ...]:
    """Mean over homes of the share of hours at home in each slot; empty slots get the overall mean."""
    shares: list[list[float]] = [[] for _ in range(SLOTS)]
    everything: list[float] = []
    for series in series_by_home.values():
        count = [0] * SLOTS
        home = [0] * SLOTS
        for o in series:
            s = slot_of(o.at)
            count[s] += 1
            home[s] += 1 if o.home else 0
            everything.append(1.0 if o.home else 0.0)
        for s in range(SLOTS):
            if count[s]:
                shares[s].append(home[s] / count[s])
    overall = sum(everything) / len(everything) if everything else 0.5
    return tuple((sum(v) / len(v)) if v else overall for v in shares)


def walk_forward_examples(
    series_by_home: Mapping[str, Sequence[Observation]],
    half_life_days: float,
    prior_strength: float,
    prior: Sequence[float],
    horizons: Sequence[int] = HORIZONS,
    warmup_days: int = WARMUP_DAYS,
    with_slots: bool = False,
    until_days: float | None = None,
):
    """Forecast examples that only use hours before each forecast origin.

    Returns four numpy arrays: habit value, state (+1 home now, -1 out now), hours ahead, outcome (1 or 0).
    With `with_slots` a fifth array holds the target slot. `until_days` keeps only origins that are
    fewer than that many days after the first hour plus the warmup (used for the cold start check).
    """
    habit_v: list[float] = []
    state_v: list[float] = []
    ahead_v: list[float] = []
    y_v: list[float] = []
    slot_v: list[float] = []
    template = Params(0.0, 0.0, 0.0, 1.0, half_life_days, prior_strength, tuple(prior))
    for series in series_by_home.values():
        ordered = sorted(series, key=lambda o: o.at)
        if not ordered:
            continue
        known = {o.at: o.home for o in ordered}
        tracker = HabitState(template)
        i = 0
        origin = ordered[0].at + timedelta(days=warmup_days)
        last = ordered[-1].at
        if until_days is not None:
            last = min(last, ordered[0].at + timedelta(days=warmup_days + until_days))
        while origin <= last:
            while i < len(ordered) and ordered[i].at < origin:
                tracker.add(ordered[i])
                i += 1
            previous = known.get(origin - HOUR)
            if previous is not None:
                for h in horizons:
                    outcome = known.get(origin + h * HOUR)
                    if outcome is None:
                        continue
                    target_slot = slot_of(origin + h * HOUR)
                    habit_v.append(tracker.value(origin, target_slot))
                    state_v.append(1.0 if previous else -1.0)
                    ahead_v.append(float(h))
                    y_v.append(1.0 if outcome else 0.0)
                    slot_v.append(float(target_slot))
            origin += HOUR
    result = np.array(habit_v), np.array(state_v), np.array(ahead_v), np.array(y_v)
    return (*result, np.array(slot_v)) if with_slots else result


def _logit_array(values: np.ndarray) -> np.ndarray:
    clipped = np.clip(values, EPS, 1.0 - EPS)
    return np.log(clipped / (1.0 - clipped))


def _fit_logistic(x: np.ndarray, y: np.ndarray) -> LogisticRegression:
    model = LogisticRegression(C=np.inf, max_iter=500)
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        model.fit(x, y)
    return model


def fit(series_by_home: Mapping[str, Sequence[Observation]], grids: Grids | None = None, flat_prior: bool = False) -> Params:
    """Pick half life, prior strength and tau from the grids, and fit b0, b1, b2, by lowest training log loss.

    With `flat_prior` every slot starts from 0.5 instead of the population profile of the training homes.
    """
    grids = grids or Grids()
    prior = tuple([0.5] * SLOTS) if flat_prior else population_prior(series_by_home)
    best: tuple[float, Params] | None = None
    for half_life in grids.half_life_days:
        for strength in grids.prior_strength:
            habit_v, state_v, ahead_v, y = walk_forward_examples(series_by_home, half_life, strength, prior)
            if len(y) == 0 or len(set(y)) < 2:
                raise ValueError("not enough forecast examples to fit the model")
            logits = _logit_array(habit_v)
            for tau in grids.tau_hours:
                x = np.column_stack([logits, state_v * np.exp(-ahead_v / tau)])
                model = _fit_logistic(x, y)
                p = np.clip(model.predict_proba(x)[:, 1], EPS, 1.0 - EPS)
                loss = float(-np.mean(y * np.log(p) + (1 - y) * np.log(1 - p)))
                if best is None or loss < best[0]:
                    b1, b2 = (float(c) for c in model.coef_[0])
                    best = (loss, Params(float(model.intercept_[0]), b1, b2, tau, half_life, strength, prior))
    assert best is not None
    return best[1]
