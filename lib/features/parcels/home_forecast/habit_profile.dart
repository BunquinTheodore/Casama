import 'dart:math' as math;

import 'forecast_params.dart';

/// One hour of known presence. [at] is the start of the hour, read as wall clock time.
class HourObservation {
  const HourObservation(this.at, this.home);

  final DateTime at;
  final bool home;
}

/// The hour of [t] as a UTC DateTime with the same wall clock fields, so differences
/// between hours never see a daylight saving shift.
DateTime wallHour(DateTime t) => DateTime.utc(t.year, t.month, t.day, t.hour);

/// Hour of week slot: Monday 00:00 is 0, Sunday 23:00 is 167.
int slotOf(DateTime t) => (t.weekday - 1) * 24 + t.hour;

double clipProbability(double p, [double eps = 1e-6]) => math.min(math.max(p, eps), 1.0 - eps);

double logit(double p, [double eps = 1e-6]) {
  final c = clipProbability(p, eps);
  return math.log(c / (1.0 - c));
}

double sigmoid(double z) {
  if (z >= 0) {
    return z < 700 ? 1.0 / (1.0 + math.exp(-z)) : 1.0;
  }
  final e = z > -700 ? math.exp(z) : 0.0;
  return e / (1.0 + e);
}

/// Recency weighted, prior smoothed share of past hours in [slot] that the person was home.
/// Only hours that ended before the hour of [now] count.
double habitProbability(
  List<HourObservation> observations,
  DateTime now,
  int slot,
  ForecastParams params,
) {
  final cutoff = wallHour(now);
  var numerator = 0.0;
  var denominator = 0.0;
  for (final o in observations) {
    final at = wallHour(o.at);
    if (!at.isBefore(cutoff) || slotOf(at) != slot) continue;
    final ageDays = cutoff.difference(at).inSeconds / 86400.0;
    final weight = math.pow(0.5, ageDays / params.halfLifeDays).toDouble();
    numerator += o.home ? weight : 0.0;
    denominator += weight;
  }
  final k = params.priorStrength;
  return (numerator + k * params.prior[slot]) / (denominator + k);
}

/// How many of the last [limit] hours in [slot] the person was home, newest first.
({int home, int total}) recentSlotCounts(
  List<HourObservation> observations,
  DateTime now,
  int slot, {
  int limit = 12,
}) {
  final cutoff = wallHour(now);
  final inSlot = [
    for (final o in observations)
      if (wallHour(o.at).isBefore(cutoff) && slotOf(o.at) == slot) o,
  ]..sort((a, b) => wallHour(b.at).compareTo(wallHour(a.at)));
  final recent = inSlot.take(limit);
  return (home: recent.where((o) => o.home).length, total: recent.length);
}
