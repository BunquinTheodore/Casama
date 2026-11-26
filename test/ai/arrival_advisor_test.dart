import 'package:casama/features/parcels/home_forecast/arrival_advisor.dart';
import 'package:casama/features/parcels/home_forecast/forecast_params.dart';
import 'package:casama/features/parcels/home_forecast/habit_profile.dart';
import 'package:casama/features/parcels/home_forecast/home_forecaster.dart';
import 'package:flutter_test/flutter_test.dart';

ForecastParams flat({double b1 = 1.0, double b2 = 0.0}) => ForecastParams(
  b0: 0,
  b1: b1,
  b2: b2,
  tauHours: 3,
  halfLifeDays: 14,
  priorStrength: 2,
  prior: List<double>.filled(168, 0.5),
);

// The same weekday at 14:00 for the last [weeks] weeks, all home or all out.
List<HourObservation> weekly(DateTime now, int weeks, bool home) => [
  for (var w = 1; w <= weeks; w++)
    HourObservation(
      DateTime.utc(now.year, now.month, now.day, 14).subtract(Duration(days: 7 * w)),
      home,
    ),
];

MemberHistory member(
  String id,
  String name, {
  bool optedIn = true,
  bool homeNow = true,
  List<HourObservation> hours = const [],
}) => MemberHistory(
  memberId: id,
  name: name,
  optedIn: optedIn,
  homeNow: homeNow,
  hours: hours,
);

void main() {
  // 2026-03-23 is a Monday.
  final now = DateTime(2026, 3, 23, 8);
  final arrival = DateTime(2026, 3, 23, 14);

  test('empty history uses the prior', () {
    final advice = adviseArrival(
      expectedArrival: arrival,
      now: now,
      members: [member('a', 'Alex')],
      params: flat(),
    );
    expect(advice.ranked.single.probability, closeTo(0.5, 1e-9));
    expect(advice.ranked.single.observedHours, 0);
  });

  test('a member who has not opted in is excluded from ranking and from anyone home', () {
    final advice = adviseArrival(
      expectedArrival: arrival,
      now: now,
      members: [
        member('a', 'Alex'),
        member('m', 'Maria', optedIn: false, hours: weekly(now, 6, true)),
      ],
      params: flat(),
    );
    expect(advice.ranked.map((m) => m.name), ['Alex']);
    expect(advice.optedInCount, 1);
    expect(advice.memberCount, 2);
    expect(advice.anyoneHomeProbability, closeTo(0.5, 1e-9));
  });

  test('nobody opted in gives optedInCount 0 and no best window', () {
    final advice = adviseArrival(
      expectedArrival: arrival,
      now: now,
      members: [
        member('a', 'Alex', optedIn: false),
        member('m', 'Maria', optedIn: false),
      ],
      params: flat(),
    );
    expect(advice.optedInCount, 0);
    expect(advice.status, AdviceStatus.nobodyOptedIn);
    expect(advice.ranked, isEmpty);
    expect(advice.bestWindowStart, isNull);
    expect(advice.anyoneHomeProbability, 0.0);
  });

  test('ranking is sorted by probability descending', () {
    final advice = adviseArrival(
      expectedArrival: arrival,
      now: now,
      members: [
        member('a', 'Alex', hours: weekly(now, 6, false)),
        member('m', 'Maria', hours: weekly(now, 6, true)),
        member('r', 'Ria'),
      ],
      params: flat(),
    );
    expect(advice.ranked.map((m) => m.name), ['Maria', 'Ria', 'Alex']);
  });

  test('band thresholds at 0.40 and 0.70', () {
    expect(bandOf(0.70), HomeBand.likely);
    expect(bandOf(0.6999), HomeBand.maybe);
    expect(bandOf(0.40), HomeBand.maybe);
    expect(bandOf(0.3999), HomeBand.unlikely);
  });

  test('best window never starts before now and lies on the arrival day', () {
    final advice = adviseArrival(
      expectedArrival: arrival,
      now: DateTime(2026, 3, 23, 10, 30),
      members: [member('a', 'Alex', hours: weekly(now, 6, true))],
      params: flat(),
    );
    final start = advice.bestWindowStart!;
    expect(start.isAfter(DateTime.utc(2026, 3, 23, 10)), isTrue);
    expect(start.day, 23);
  });

  test('window probability equals one minus the product of the complements', () {
    final advice = adviseArrival(
      expectedArrival: arrival,
      now: now,
      members: [member('a', 'Alex'), member('m', 'Maria')],
      params: flat(),
    );
    expect(advice.anyoneHomeProbability, closeTo(1 - 0.5 * 0.5, 1e-9));
    expect(advice.bestWindowProbability, closeTo(0.75, 1e-9));
  });

  test('why line counts recent same weekday and hour', () {
    final advice = adviseArrival(
      expectedArrival: arrival,
      now: now,
      members: [member('a', 'Alex', hours: weekly(now, 4, true))],
      params: flat(),
    );
    expect(advice.ranked.single.why, 'was home 4 of 4 recent Mondays at 2 PM');
  });

  test('why line when there is no history says so', () {
    final advice = adviseArrival(
      expectedArrival: arrival,
      now: now,
      members: [member('a', 'Alex')],
      params: flat(),
    );
    expect(
      advice.ranked.single.why,
      'has no history for that hour yet, so Cas uses a typical week',
    );
  });

  test('an arrival in a past hour gets no forecast', () {
    final advice = adviseArrival(
      expectedArrival: DateTime(2026, 3, 23, 6),
      now: now,
      members: [member('a', 'Alex')],
      params: flat(),
    );
    expect(advice.status, AdviceStatus.past);
    expect(advice.ranked, isEmpty);
    expect(advice.bestWindowStart, isNull);
  });

  test('an arrival in the hour that has already started is forecast for the next whole hour, and says so', () {
    final nine = [
      for (var w = 1; w <= 3; w++)
        HourObservation(DateTime.utc(2026, 3, 23, 9).subtract(Duration(days: 7 * w)), true),
    ];
    final params = flat();
    final advice = adviseArrival(
      expectedArrival: DateTime(2026, 3, 23, 8, 30),
      now: DateTime(2026, 3, 23, 8, 10),
      members: [member('a', 'Alex', hours: nine)],
      params: params,
    );
    expect(advice.status, AdviceStatus.ready);
    expect(advice.forecastHour, DateTime.utc(2026, 3, 23, 9));
    expect(advice.shifted, isTrue);
    expect(advice.ranked.single.why, 'was home 3 of 3 recent Mondays at 9 AM');
    expect(
      advice.ranked.single.probability,
      closeTo(forecastHome(nine, DateTime(2026, 3, 23, 8, 10), homeNow: true, hoursAhead: 1, params: params), 1e-12),
    );
  });

  test('a later arrival is forecast for its own hour', () {
    final advice = adviseArrival(
      expectedArrival: arrival,
      now: now,
      members: [member('a', 'Alex')],
      params: flat(),
    );
    expect(advice.forecastHour, DateTime.utc(2026, 3, 23, 14));
    expect(advice.shifted, isFalse);
  });

  test('a forecast is given up to 72 hours ahead and not beyond', () {
    ArrivalAdvice at(int hours) => adviseArrival(
      expectedArrival: now.add(Duration(hours: hours)),
      now: now,
      members: [member('a', 'Alex')],
      params: flat(),
    );
    expect(at(72).status, AdviceStatus.ready);
    expect(at(73).status, AdviceStatus.tooFar);
    expect(at(73).ranked, isEmpty);
    expect(maxForecastHours, 72);
  });

  test('the best window stays inside the 72 hours that were tested', () {
    final advice = adviseArrival(
      expectedArrival: now.add(const Duration(hours: 70)),
      now: now,
      members: [member('a', 'Alex')],
      params: flat(),
    );
    final end = advice.bestWindowStart!.add(const Duration(hours: 2));
    expect(end.difference(DateTime.utc(2026, 3, 23, 8)).inHours, lessThanOrEqualTo(maxForecastHours + 1));
  });
}
