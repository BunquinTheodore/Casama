import 'habit_profile.dart';

/// One Home or Out tap. The app records these only for members who turned the forecast on.
class PresenceEvent {
  const PresenceEvent({required this.userId, required this.at, required this.isHome});

  final String userId;
  final DateTime at;
  final bool isHome;
}

const int _homeSecondsNeeded = 30 * 60;
const Duration _hour = Duration(hours: 1);

DateTime _wallExact(DateTime t) => DateTime.utc(t.year, t.month, t.day, t.hour, t.minute, t.second);

DateTime _floorHour(DateTime t) => DateTime.utc(t.year, t.month, t.day, t.hour);

/// Turns state changes into hourly home or away. An hour is home when the person was home for 30
/// minutes or more of it. The series starts at the first whole hour at or after the first event and
/// ends with the last hour that has fully ended before [end]. Mirrors AI/src/derive_hourly.py.
List<HourObservation> eventsToHourly(List<PresenceEvent> events, DateTime end) {
  if (events.isEmpty) return const [];
  // Dart's sort is not stable, so ties are broken by position: events in the same second keep the order they came in
  // (Python's sorted is stable, and the two must agree).
  final indexed = [
    for (var i = 0; i < events.length; i++) (index: i, at: _wallExact(events[i].at), home: events[i].isHome),
  ]..sort((a, b) {
      final byTime = a.at.compareTo(b.at);
      return byTime != 0 ? byTime : a.index.compareTo(b.index);
    });
  final ordered = [for (final e in indexed) (at: e.at, home: e.home)];
  final first = ordered.first.at;
  var start = _floorHour(first);
  if (start.isBefore(first)) start = start.add(_hour);
  final endWall = _wallExact(end);
  final lastHour = _floorHour(endWall);
  if (!start.isBefore(lastHour)) return const [];

  final homeSeconds = <DateTime, int>{};
  for (var i = 0; i < ordered.length; i++) {
    final begins = ordered[i].at;
    final stops = i + 1 < ordered.length ? ordered[i + 1].at : endWall;
    if (!ordered[i].home || !stops.isAfter(begins)) continue;
    var cursor = begins.isAfter(start) ? begins : start;
    final until = stops.isBefore(lastHour) ? stops : lastHour;
    while (cursor.isBefore(until)) {
      final hour = _floorHour(cursor);
      final next = hour.add(_hour);
      final sliceEnd = until.isBefore(next) ? until : next;
      homeSeconds[hour] = (homeSeconds[hour] ?? 0) + sliceEnd.difference(cursor).inSeconds;
      cursor = sliceEnd;
    }
  }

  final hours = <HourObservation>[];
  for (var hour = start; hour.isBefore(lastHour); hour = hour.add(_hour)) {
    hours.add(HourObservation(hour, (homeSeconds[hour] ?? 0) >= _homeSecondsNeeded));
  }
  return hours;
}
