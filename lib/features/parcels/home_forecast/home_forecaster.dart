import 'dart:math' as math;

import 'forecast_params.dart';
import 'habit_profile.dart';

/// Probability the person is home for the hour that starts [hoursAhead] hours after the hour of [now].
/// [homeNow] is whether the person is home at [now].
double forecastHome(
  List<HourObservation> observations,
  DateTime now, {
  required bool homeNow,
  required int hoursAhead,
  required ForecastParams params,
}) {
  final target = wallHour(now).add(Duration(hours: hoursAhead));
  final habit = habitProbability(observations, now, slotOf(target), params);
  final n = homeNow ? 1.0 : -1.0;
  final z =
      params.b0 +
      params.b1 * logit(habit, params.eps) +
      params.b2 * n * math.exp(-hoursAhead / params.tauHours);
  return sigmoid(z);
}
