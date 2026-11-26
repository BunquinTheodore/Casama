import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../data/repository_provider.dart';
import 'arrival_advisor.dart';
import 'forecast_params.dart';

/// The Home Forecast on a parcel: who is probably home when it arrives, and the best window.
/// Advice only. It never edits the parcel or who is marked available.
class ForecastRow extends ConsumerWidget {
  const ForecastRow({super.key, required this.expectedArrival, this.compact = false});

  final DateTime expectedArrival;

  /// The short version used in the add parcel sheet (best window and the count only).
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    final now = repo.now; // the same clock the history was recorded with
    final advice = adviseArrival(
      expectedArrival: expectedArrival,
      now: now,
      members: repo.forecastInputs(now),
      params: bundledForecastParams,
    );
    final me = repo.currentUser.id;
    final taps = repo.isRoutineOptedIn(me) ? repo.presenceHistoryFor(me).length : 0;
    return ForecastSummary(advice: advice, learnedTaps: taps, compact: compact);
  }
}

/// The text and box for one [ArrivalAdvice]. Shows nothing when nobody has turned the forecast on.
class ForecastSummary extends StatelessWidget {
  const ForecastSummary({super.key, required this.advice, this.learnedTaps = 0, this.compact = false});

  final ArrivalAdvice advice;
  final int learnedTaps;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (advice.status != AdviceStatus.ready || advice.optedInCount == 0 || advice.ranked.isEmpty) {
      return const SizedBox.shrink();
    }

    final top = advice.ranked.first;
    final window = advice.bestWindowStart;
    final windowIsUseful = window != null &&
        (compact || advice.bestWindowProbability > advice.anyoneHomeProbability + 0.05);
    final housemates = advice.memberCount == 1 ? 'housemate' : 'housemates';

    final lines = <Widget>[
      if (!compact || window == null)
        Text(
          headlineFor(top),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textColor),
        ),
      if (!compact && advice.shifted && advice.forecastHour != null)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            'Due now, so this is for ${_hour(advice.forecastHour!.hour)} ${_meridiem(advice.forecastHour!.hour)}',
            style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
          ),
        ),
      if (!compact)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            whyFor(top),
            style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
          ),
        ),
      if (!compact && advice.ranked.length > 1)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            'Chance at least one housemate is home: ${percent(advice.anyoneHomeProbability)}%',
            style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
          ),
        ),
      if (windowIsUseful)
        Padding(
          padding: EdgeInsets.only(top: compact ? 0 : 4),
          child: Text(
            'Best window that day: ${windowLabel(window)} '
            '(${percent(advice.bestWindowProbability)}% someone is home)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: compact ? context.textColor : CasamaColors.primaryCoral,
            ),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'Based on ${advice.optedInCount} of ${advice.memberCount} $housemates who turned this on',
          style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
        ),
      ),
      if (!compact && learnedTaps > 0)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            'Learned from $learnedTaps ${learnedTaps == 1 ? 'tap' : 'taps'} of yours',
            style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
          ),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CasamaColors.primaryCoral.withValues(alpha: context.isDark ? 0.14 : 0.08),
          borderRadius: CasamaSpacing.roundedMd,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.auto_awesome_rounded, size: 18, color: CasamaColors.primaryCoral),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines),
            ),
          ],
        ),
      ),
    );
  }
}

/// A forecast is never certain, so the display stays between 1 and 99 percent.
String percent(double p) => (p * 100).round().clamp(1, 99).toString();

bool _isYou(MemberForecast m) => m.name == 'You';

/// "Cas thinks Alex is probably home (82%)", or about nobody when even the best chance is low.
String headlineFor(MemberForecast top) {
  final pct = percent(top.probability);
  if (top.band == HomeBand.unlikely) return 'Cas thinks nobody is likely home then (best chance $pct%)';
  final subject = _isYou(top) ? 'you' : top.name;
  final verb = _isYou(top) ? 'are' : 'is';
  final phrase = top.band == HomeBand.likely ? '$verb probably home' : 'might be home';
  return 'Cas thinks $subject $phrase ($pct%)';
}

/// The reason line, "Alex was home 9 of 12 recent Thursdays at 2 PM".
String whyFor(MemberForecast m) {
  if (!_isYou(m)) return '${m.name} ${m.why}';
  final why = m.why.startsWith('was ')
      ? m.why.replaceFirst('was ', 'were ')
      : m.why.startsWith('has ')
      ? m.why.replaceFirst('has ', 'have ')
      : m.why;
  return 'You $why';
}

String _hour(int h) => '${h % 12 == 0 ? 12 : h % 12}';

String _meridiem(int h) => (h % 24) < 12 ? 'AM' : 'PM';

/// "2 to 4 PM" or "11 AM to 1 PM" for a two hour window that starts at [start].
String windowLabel(DateTime start) {
  final from = start.hour;
  final to = (from + 2) % 24;
  final left = _meridiem(from) == _meridiem(to) ? _hour(from) : '${_hour(from)} ${_meridiem(from)}';
  return '$left to ${_hour(to)} ${_meridiem(to)}';
}
