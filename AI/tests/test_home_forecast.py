"""The reference forecasting algorithm. The Dart port must reproduce these numbers (see golden.json)."""

import math
import random
from datetime import datetime, timedelta

import pytest

from home_forecast import (
    EPS,
    SLOTS,
    Grids,
    HabitState,
    Observation,
    Params,
    fit,
    forecast,
    habit,
    logit,
    population_prior,
    sigmoid,
    slot_of,
)

FLAT = tuple([0.5] * SLOTS)


def params(**over):
    base = dict(b0=0.0, b1=1.0, b2=1.0, tau_hours=3.0, half_life_days=14.0, prior_strength=2.0, prior=FLAT)
    base.update(over)
    return Params(**base)


def hourly(start: datetime, days: int, rule):
    return [Observation(start + timedelta(hours=i), bool(rule(start + timedelta(hours=i)))) for i in range(days * 24)]


MONDAY = datetime(2026, 3, 2)  # a Monday


def test_slot_of_monday_midnight_is_0_and_sunday_2300_is_167():
    assert slot_of(datetime(2026, 3, 2, 0)) == 0
    assert slot_of(datetime(2026, 3, 8, 23)) == 167
    assert slot_of(datetime(2026, 3, 5, 14)) == 3 * 24 + 14


def test_habit_with_no_observations_returns_prior_slot_value():
    prior = tuple(i / 200 for i in range(SLOTS))
    assert habit([], MONDAY, 10, params(prior=prior)) == pytest.approx(prior[10])


def test_habit_one_home_observation_moves_toward_one():
    obs = [Observation(MONDAY, True)]
    now = MONDAY + timedelta(days=7)
    value = habit(obs, now, slot_of(MONDAY), params(half_life_days=14.0, prior_strength=2.0))
    weight = 0.5 ** (7 / 14)
    assert value == pytest.approx((weight * 1 + 2 * 0.5) / (weight + 2))
    assert value > 0.5


def test_older_observations_weigh_less():
    old = Observation(MONDAY, True)
    recent = Observation(MONDAY + timedelta(days=7), False)
    now = MONDAY + timedelta(days=14)
    value = habit([old, recent], now, 0, params(half_life_days=7.0, prior_strength=1e-9))
    assert value == pytest.approx(0.25 / 0.75, abs=1e-6)  # weights 0.25 and 0.5, not equal weights


def test_observation_at_or_after_now_is_ignored():
    now = MONDAY + timedelta(days=7)
    base = habit([Observation(MONDAY, True)], now, 0, params())
    with_future = habit(
        [Observation(MONDAY, True), Observation(now, False), Observation(now + timedelta(days=7), False)], now, 0, params()
    )
    assert with_future == base


def test_only_the_matching_slot_counts():
    obs = [Observation(MONDAY + timedelta(hours=1), True)]
    now = MONDAY + timedelta(days=7)
    assert habit(obs, now, 0, params()) == pytest.approx(0.5)


def test_forecast_with_zero_coefficients_is_half():
    p = params(b0=0.0, b1=0.0, b2=0.0)
    assert forecast([], MONDAY, True, 3, p) == pytest.approx(0.5)


def test_persistence_term_decays_with_hours_ahead():
    p = params(b0=0.0, b1=0.0, b2=2.0, tau_hours=3.0)
    near = forecast([], MONDAY, True, 1, p)
    far = forecast([], MONDAY, True, 12, p)
    assert near > far > 0.5
    assert forecast([], MONDAY, False, 1, p) == pytest.approx(1 - near)


def test_forecast_target_is_hours_after_the_floored_now():
    hot = [0.0] * SLOTS
    hot[slot_of(MONDAY + timedelta(hours=5))] = 1.0
    p = params(b1=5.0, b2=0.0, prior=tuple(hot), prior_strength=1.0)
    high = forecast([], MONDAY + timedelta(minutes=40), True, 5, p)
    low = forecast([], MONDAY + timedelta(minutes=40), True, 4, p)
    assert high > 0.99 and low < 0.01


def test_extreme_habit_does_not_blow_up():
    for extreme in (0.0, 1.0):
        p = params(prior=tuple([extreme] * SLOTS), prior_strength=1e6, b1=3.0)
        value = forecast([], MONDAY, True, 168, p)
        assert math.isfinite(value) and 0.0 <= value <= 1.0
    assert math.isfinite(logit(0.0)) and math.isfinite(logit(1.0))
    assert logit(EPS) == pytest.approx(-logit(1 - EPS))


def test_sigmoid_is_stable_for_large_inputs():
    assert sigmoid(1000) == 1.0
    assert sigmoid(-1000) == 0.0


def test_slot_math_unaffected_by_dst_day():
    # Wall clock series across the US spring forward day: the clock still reads every hour 0 to 23.
    start = datetime(2026, 3, 1)
    obs = hourly(start, 14, lambda t: t.hour < 8)
    now = datetime(2026, 3, 15)
    slot = slot_of(datetime(2026, 3, 9, 3))
    value = habit(obs, now, slot, params(half_life_days=7.0, prior_strength=1e-9))
    assert value == pytest.approx(1.0, abs=1e-6)


def test_incremental_habit_equals_reference_on_random_series():
    rng = random.Random(7)
    start = datetime(2026, 1, 5)
    obs = hourly(start, 60, lambda t: rng.random() < 0.6)
    p = params(half_life_days=10.0, prior_strength=3.0, prior=tuple(rng.random() for _ in range(SLOTS)))
    for hours_after in (24 * 20 + 3, 24 * 40, 24 * 60):
        now = start + timedelta(hours=hours_after)
        state = HabitState(p)
        for o in obs:
            if o.at < now.replace(minute=0):
                state.add(o)
        for slot in range(0, SLOTS, 7):
            assert state.value(now, slot) == pytest.approx(habit(obs, now, slot, p), abs=1e-12)


def test_habit_state_rejects_observations_out_of_order():
    state = HabitState(params())
    state.add(Observation(MONDAY + timedelta(hours=5), True))
    with pytest.raises(ValueError):
        state.add(Observation(MONDAY, True))


def test_population_prior_is_mean_share_per_slot_and_fills_empty_slots():
    a = hourly(MONDAY, 14, lambda t: t.hour < 12)  # home in the morning only
    b = hourly(MONDAY, 14, lambda t: True)
    prior = population_prior({"a": a, "b": b})
    assert len(prior) == SLOTS
    assert prior[slot_of(MONDAY)] == pytest.approx(1.0)
    assert prior[slot_of(MONDAY + timedelta(hours=15))] == pytest.approx(0.5)
    sparse = population_prior({"c": [Observation(MONDAY, True)]})
    assert all(0.0 <= v <= 1.0 for v in sparse) and sparse[5] == pytest.approx(1.0)


def _routine_home(seed: int, days: int):
    """A weekday routine (out 9 to 17) with sticky random noise, generated without using the fitted model."""
    rng = random.Random(seed)
    out = []
    state = True
    for i in range(days * 24):
        t = MONDAY + timedelta(hours=i)
        weekday_work = t.weekday() < 5 and 9 <= t.hour < 17
        target = 0.12 if weekday_work else 0.92
        state = rng.random() < (0.55 * target + 0.45 * (1.0 if state else 0.0))
        out.append(Observation(t, state))
    return out


def test_fit_learns_positive_habit_and_persistence_weights_on_synthetic_routine():
    train = {"h1": _routine_home(1, 45), "h2": _routine_home(2, 45)}
    fitted = fit(train, Grids(half_life_days=(14.0,), prior_strength=(2.0,), tau_hours=(2.0, 6.0)))
    assert fitted.b1 > 0.3, "the weekly habit must help"
    assert fitted.b2 > 0.0, "staying as you are must help"
    assert len(fitted.prior) == SLOTS


def test_fit_improves_on_a_constant_base_rate_on_a_held_out_home():
    import numpy as np

    from home_forecast import walk_forward_examples

    train = {"h1": _routine_home(1, 45), "h2": _routine_home(2, 45)}
    fitted = fit(train, Grids(half_life_days=(14.0,), prior_strength=(2.0,), tau_hours=(3.0,)))
    held = {"h3": _routine_home(3, 45)}
    habit_values, state, ahead, y = walk_forward_examples(held, fitted.half_life_days, fitted.prior_strength, fitted.prior)
    z = fitted.b0 + fitted.b1 * np.array([logit(v) for v in habit_values]) + fitted.b2 * state * np.exp(-ahead / fitted.tau_hours)
    p = 1 / (1 + np.exp(-z))
    model_loss = -np.mean(y * np.log(p) + (1 - y) * np.log(1 - p))
    base = y.mean()
    base_loss = -np.mean(y * np.log(base) + (1 - y) * np.log(1 - base))
    assert model_loss < base_loss - 0.05


def test_walk_forward_examples_match_the_reference_habit_at_each_origin():
    from home_forecast import walk_forward_examples

    rng = random.Random(11)
    start = datetime(2026, 1, 5)
    obs = hourly(start, 30, lambda t: rng.random() < 0.5)
    prior = tuple(rng.random() for _ in range(SLOTS))
    p = params(half_life_days=9.0, prior_strength=3.0, prior=prior)
    habit_v, state_v, ahead_v, y_v = walk_forward_examples({"x": obs}, 9.0, 3.0, prior, horizons=(1, 3))
    first_origin = start + timedelta(days=7)
    for k in range(0, 60, 5):
        origin = first_origin + timedelta(hours=k // 2)
        h = (1, 3)[k % 2]
        assert ahead_v[k] == h
        assert habit_v[k] == pytest.approx(habit(obs, origin, slot_of(origin + timedelta(hours=h)), p), abs=1e-12)
        previous_home = obs[int((origin - start).total_seconds() // 3600) - 1].home
        assert state_v[k] == (1.0 if previous_home else -1.0)
        assert y_v[k] == (1.0 if obs[int((origin - start).total_seconds() // 3600) + h].home else 0.0)


def test_fit_with_flat_prior_returns_a_flat_prior():
    train = {"h1": _routine_home(1, 40), "h2": _routine_home(2, 40)}
    fitted = fit(train, Grids(half_life_days=(14.0,), prior_strength=(2.0,), tau_hours=(3.0,)), flat_prior=True)
    assert fitted.prior == tuple([0.5] * SLOTS)
