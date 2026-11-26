import 'dart:convert';
import 'dart:io';

import 'package:casama/features/parcels/home_forecast/forecast_params.dart';
import 'package:casama/features/parcels/home_forecast/habit_profile.dart';
import 'package:casama/features/parcels/home_forecast/home_forecaster.dart';
import 'package:flutter_test/flutter_test.dart';

// The Dart port must reproduce AI/src/home_forecast.py: every case in AI/output/golden.json.
void main() {
  final golden =
      jsonDecode(File('AI/output/golden.json').readAsStringSync())
          as Map<String, dynamic>;
  final cases = (golden['cases'] as List).cast<Map<String, dynamic>>();

  test('golden file has the edge cases', () {
    expect(cases.length, greaterThanOrEqualTo(12));
  });

  for (final c in cases) {
    test('parity: ${c['name']}', () {
      final params = ForecastParams.fromJson(
        (c['params'] ?? golden['params']) as Map<String, dynamic>,
      );
      final observations = [
        for (final o in (c['observations'] as List))
          HourObservation(DateTime.parse(o[0] as String), (o[1] as num) == 1),
      ];
      final now = DateTime.parse(c['now'] as String);
      final ahead = c['hours_ahead'] as int;
      final target = wallHour(now).add(Duration(hours: ahead));
      expect(
        habitProbability(observations, now, slotOf(target), params),
        closeTo((c['expected_habit'] as num).toDouble(), 1e-9),
      );
      expect(
        forecastHome(
          observations,
          now,
          homeNow: c['home_now'] as bool,
          hoursAhead: ahead,
          params: params,
        ),
        closeTo((c['expected_forecast'] as num).toDouble(), 1e-9),
      );
    });
  }

  test('bundled parameters equal AI/output/home_forecast.json', () {
    final file =
        jsonDecode(File('AI/output/home_forecast.json').readAsStringSync())
            as Map<String, dynamic>;
    final fromFile = ForecastParams.fromJson(file);
    expect(bundledForecastParams.b0, fromFile.b0);
    expect(bundledForecastParams.b1, fromFile.b1);
    expect(bundledForecastParams.b2, fromFile.b2);
    expect(bundledForecastParams.tauHours, fromFile.tauHours);
    expect(bundledForecastParams.halfLifeDays, fromFile.halfLifeDays);
    expect(bundledForecastParams.priorStrength, fromFile.priorStrength);
    expect(bundledForecastParams.prior, fromFile.prior);
  });

  test('slot math at the Sunday to Monday edge', () {
    expect(slotOf(DateTime(2026, 3, 2, 0)), 0);
    expect(slotOf(DateTime(2026, 3, 8, 23)), 167);
    expect(slotOf(DateTime(2026, 3, 5, 14)), 3 * 24 + 14);
  });

  test('sigmoid and logit stay finite at the extremes', () {
    expect(sigmoid(1000), 1.0);
    expect(sigmoid(-1000), 0.0);
    expect(logit(0.0).isFinite, isTrue);
    expect(logit(1.0).isFinite, isTrue);
  });
}
