import 'dart:convert';
import 'dart:io';

import 'package:casama/features/parcels/home_forecast/habit_profile.dart';
import 'package:casama/features/parcels/home_forecast/presence_hours.dart';
import 'package:flutter_test/flutter_test.dart';

String stamp(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)}T${two(t.hour)}:${two(t.minute)}';
}

PresenceEvent ev(int day, int hour, int minute, bool home) => PresenceEvent(
  userId: 'u',
  at: DateTime(2026, 3, day, hour, minute),
  isHome: home,
);

void main() {
  final golden =
      jsonDecode(File('AI/output/golden.json').readAsStringSync())
          as Map<String, dynamic>;

  for (final c
      in (golden['hourly_cases'] as List).cast<Map<String, dynamic>>()) {
    test('hourly golden: ${c['name']}', () {
      final events = [
        for (final e in (c['events'] as List))
          PresenceEvent(
            userId: 'u',
            at: DateTime.parse(e[0] as String),
            isHome: (e[1] as num) == 1,
          ),
      ];
      final got = eventsToHourly(events, DateTime.parse(c['end'] as String));
      final expected = (c['expected'] as List).map((e) => [e[0], e[1]]).toList();
      expect([
        for (final h in got) [stamp(h.at), h.home ? 1 : 0],
      ], expected);
    });
  }

  test('no events gives an empty list', () {
    expect(eventsToHourly(const [], DateTime(2026, 3, 2, 12)), isEmpty);
  });

  test('unsorted events are sorted first', () {
    final got = eventsToHourly([
      ev(2, 10, 0, false),
      ev(2, 9, 0, true),
    ], DateTime(2026, 3, 2, 11));
    expect(got.map((h) => h.home).toList(), [true, false]);
  });

  test('events in the same second keep the order they were given in', () {
    // 100 taps in one second, alternating, the last one is Out: the hour must be away whatever sort is used
    final events = [
      for (var i = 0; i < 100; i++)
        PresenceEvent(userId: 'u', at: DateTime(2026, 3, 2, 9, 0, 0, i), isHome: i.isEven),
    ];
    final got = eventsToHourly(events, DateTime(2026, 3, 2, 10));
    expect(got.single.home, isFalse);
  });

  test('hours are returned as wall clock hour starts', () {
    final got = eventsToHourly([ev(2, 9, 0, true)], DateTime(2026, 3, 2, 12));
    expect(got.map((h) => slotOf(h.at)).toList(), [9, 10, 11]);
  });
}
