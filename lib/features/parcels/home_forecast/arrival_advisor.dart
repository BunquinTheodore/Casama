import 'forecast_params.dart';
import 'habit_profile.dart';
import 'home_forecaster.dart';

enum HomeBand { likely, maybe, unlikely }

/// likely at 0.70 or more, maybe from 0.40 up to 0.70, unlikely under 0.40.
HomeBand bandOf(double p) {
  if (p >= 0.70) return HomeBand.likely;
  if (p >= 0.40) return HomeBand.maybe;
  return HomeBand.unlikely;
}

/// The longest forecast the model was tested on (1 to 72 hours ahead). Nothing is shown further out.
const int maxForecastHours = 72;

/// Whether there is a forecast to show, and if not, why not.
enum AdviceStatus {
  ready,
  nobodyOptedIn,

  /// The arrival hour is before the current hour: the parcel is overdue and a forecast would be about the wrong hour.
  past,

  /// More than [maxForecastHours] ahead, beyond what was tested.
  tooFar,
}

/// What the forecaster needs to know about one housemate.
class MemberHistory {
  const MemberHistory({
    required this.memberId,
    required this.name,
    required this.optedIn,
    required this.homeNow,
    required this.hours,
  });

  final String memberId;
  final String name;
  final bool optedIn;
  final bool homeNow;
  final List<HourObservation> hours;
}

class MemberForecast {
  const MemberForecast({
    required this.memberId,
    required this.name,
    required this.probability,
    required this.band,
    required this.why,
    required this.observedHours,
  });

  final String memberId;
  final String name;
  final double probability;
  final HomeBand band;

  /// A clause that follows the name, such as "was home 9 of 12 recent Thursdays at 2 PM".
  final String why;
  final int observedHours;
}

class ArrivalAdvice {
  const ArrivalAdvice({
    required this.ranked,
    required this.anyoneHomeProbability,
    required this.bestWindowStart,
    required this.bestWindowProbability,
    required this.optedInCount,
    required this.memberCount,
    this.status = AdviceStatus.ready,
    this.forecastHour,
    this.shifted = false,
  });

  final List<MemberForecast> ranked;

  /// 1 minus the product of (1 minus p) over the opted in members, at the forecast hour.
  final double anyoneHomeProbability;

  /// Start of the best two hour window on the arrival day, or null when there is none.
  final DateTime? bestWindowStart;
  final double bestWindowProbability;
  final int optedInCount;
  final int memberCount;
  final AdviceStatus status;

  /// The hour the percentages are about. It is the arrival hour, or the next whole hour when the parcel is due
  /// within the hour that has already started.
  final DateTime? forecastHour;

  /// True when the parcel is due within the hour that has already started, so the forecast is for the next whole hour.
  final bool shifted;
}

const _weekdays = ['Mondays', 'Tuesdays', 'Wednesdays', 'Thursdays', 'Fridays', 'Saturdays', 'Sundays'];

String _hourLabel(int hour) {
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$h12 ${hour < 12 ? 'AM' : 'PM'}';
}

double _anyoneHome(Iterable<double> probabilities) =>
    1.0 - probabilities.fold<double>(1.0, (product, p) => product * (1.0 - p));

ArrivalAdvice _none(AdviceStatus status, int opted, int all) => ArrivalAdvice(
  ranked: const [],
  anyoneHomeProbability: 0.0,
  bestWindowStart: null,
  bestWindowProbability: 0.0,
  optedInCount: opted,
  memberCount: all,
  status: status,
);

/// Ranks opted in housemates for an expected arrival and finds the best two hour window that day.
/// Housemates who have not opted in are neither forecast nor counted. A parcel that was due in a past hour, or is
/// more than [maxForecastHours] away, gets no forecast. A parcel due in the hour that has already started is
/// forecast for the next whole hour, and [ArrivalAdvice.forecastHour] says so.
ArrivalAdvice adviseArrival({
  required DateTime expectedArrival,
  required DateTime now,
  required List<MemberHistory> members,
  required ForecastParams params,
}) {
  final cutoff = wallHour(now);
  final arrivalHour = wallHour(expectedArrival);
  final opted = members.where((m) => m.optedIn).toList();
  if (opted.isEmpty) return _none(AdviceStatus.nobodyOptedIn, 0, members.length);
  final ahead = arrivalHour.difference(cutoff).inHours;
  if (ahead < 0) return _none(AdviceStatus.past, opted.length, members.length);
  if (ahead > maxForecastHours) return _none(AdviceStatus.tooFar, opted.length, members.length);
  final targetHour = ahead < 1 ? cutoff.add(const Duration(hours: 1)) : arrivalHour;

  int hoursUntil(DateTime t) => t.difference(cutoff).inHours < 1 ? 1 : t.difference(cutoff).inHours;
  double probabilityAt(MemberHistory m, DateTime hour) =>
      forecastHome(m.hours, now, homeNow: m.homeNow, hoursAhead: hoursUntil(hour), params: params);

  final targetSlot = slotOf(targetHour);
  final ranked = [
    for (final m in opted)
      () {
        final p = probabilityAt(m, targetHour);
        final counts = recentSlotCounts(m.hours, now, targetSlot);
        final why = counts.total == 0
            ? 'has no history for that hour yet, so Cas uses a typical week'
            : 'was home ${counts.home} of ${counts.total} recent '
                  '${_weekdays[targetHour.weekday - 1]} at ${_hourLabel(targetHour.hour)}';
        return MemberForecast(
          memberId: m.memberId,
          name: m.name,
          probability: p,
          band: bandOf(p),
          why: why,
          observedHours: m.hours.length,
        );
      }(),
  ]..sort((a, b) {
      final byProbability = b.probability.compareTo(a.probability);
      return byProbability != 0 ? byProbability : a.name.compareTo(b.name);
    });

  final dayStart = DateTime.utc(arrivalHour.year, arrivalHour.month, arrivalHour.day);
  DateTime? bestStart;
  var bestProbability = -1.0;
  for (var s = 0; s <= 22; s++) {
    final start = dayStart.add(Duration(hours: s));
    if (start.difference(cutoff).inHours < 1) continue; // a window cannot start before the next hour
    if (start.difference(cutoff).inHours + 1 > maxForecastHours) continue; // nor reach past what was tested
    final first = _anyoneHome([for (final m in opted) probabilityAt(m, start)]);
    final second = _anyoneHome([for (final m in opted) probabilityAt(m, start.add(const Duration(hours: 1)))]);
    final windowProbability = (first + second) / 2.0;
    if (windowProbability > bestProbability + 1e-12) {
      bestProbability = windowProbability;
      bestStart = start;
    }
  }

  return ArrivalAdvice(
    ranked: ranked,
    anyoneHomeProbability: _anyoneHome(ranked.map((m) => m.probability)),
    bestWindowStart: bestStart,
    bestWindowProbability: bestStart == null ? 0.0 : bestProbability,
    optedInCount: opted.length,
    memberCount: members.length,
    forecastHour: targetHour,
    shifted: ahead < 1,
  );
}
