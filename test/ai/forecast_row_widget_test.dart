import 'package:casama/data/mock_repository.dart';
import 'package:casama/data/repository_provider.dart';
import 'package:casama/features/legal/terms_privacy_screen.dart';
import 'package:casama/features/parcels/home_forecast/arrival_advisor.dart';
import 'package:casama/features/parcels/home_forecast/forecast_row.dart';
import 'package:casama/features/parcels/parcels_screen.dart';
import 'package:casama/features/settings/app_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const me = '11111111-1111-1111-1111-111111111111';
const everyone = [
  me,
  '22222222-2222-2222-2222-222222222222',
  '33333333-3333-3333-3333-333333333333',
  '44444444-4444-4444-4444-444444444444',
];

Widget app(MockRepository repo, Widget home) => ProviderScope(
  overrides: [repositoryProvider.overrideWith((ref) => repo)],
  child: MaterialApp(home: home),
);

void bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

ArrivalAdvice advice({String name = 'Alex', double p = 0.82, int opted = 2, int all = 4}) => ArrivalAdvice(
  ranked: [
    MemberForecast(
      memberId: 'a',
      name: name,
      probability: p,
      band: bandOf(p),
      why: 'was home 9 of 12 recent Thursdays at 2 PM',
      observedHours: 500,
    ),
  ],
  anyoneHomeProbability: p,
  bestWindowStart: DateTime.utc(2026, 3, 26, 18),
  bestWindowProbability: 0.9,
  optedInCount: opted,
  memberCount: all,
);

void main() {
  testWidgets('forecast row shows for an upcoming parcel in the demo household', (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(app(MockRepository(), const ParcelsScreen()));
    await tester.pump();
    expect(find.textContaining('Cas thinks'), findsWidgets);
    expect(find.textContaining('housemates who turned this on'), findsWidgets);
  });

  testWidgets('forecast row uses the repository clock, not the wall clock', (tester) async {
    bigScreen(tester);
    // a Wednesday at 10:00; the parcel is due at 2 PM the same day
    final repo = MockRepository(clock: () => DateTime(2026, 3, 25, 10));
    await tester.pumpWidget(
      app(repo, Scaffold(body: ForecastRow(expectedArrival: DateTime(2026, 3, 25, 14)))),
    );
    await tester.pump();
    expect(find.textContaining('recent Wednesdays at 2 PM'), findsOneWidget);
  });

  testWidgets('forecast row shows nothing for a parcel that was due in a past hour', (tester) async {
    bigScreen(tester);
    final repo = MockRepository(clock: () => DateTime(2026, 3, 25, 10));
    await tester.pumpWidget(
      app(repo, Scaffold(body: ForecastRow(expectedArrival: DateTime(2026, 3, 25, 7)))),
    );
    await tester.pump();
    expect(find.textContaining('Cas thinks'), findsNothing);
  });

  testWidgets('forecast row is hidden when nobody opted in', (tester) async {
    bigScreen(tester);
    final repo = MockRepository();
    for (final id in everyone) {
      repo.setRoutineOptIn(id, false);
    }
    await tester.pumpWidget(app(repo, const ParcelsScreen()));
    await tester.pump();
    expect(find.textContaining('Cas thinks'), findsNothing);
    expect(find.textContaining('who turned this on'), findsNothing);
  });

  testWidgets('forecast row is hidden for received parcels', (tester) async {
    bigScreen(tester);
    final repo = MockRepository()..receiveParcel('p1');
    await tester.pumpWidget(app(repo, const ParcelsScreen()));
    await tester.pump();
    expect(find.textContaining('Cas thinks'), findsOneWidget, reason: 'only the parcel that is still upcoming');
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cas thinks'), findsNothing);
  });

  testWidgets('showing a forecast does not change availability', (tester) async {
    bigScreen(tester);
    final repo = MockRepository();
    List<List<Object>> snapshot() => [
      for (final p in repo.parcels) [p.id, p.availableMemberNames.join(','), p.isAllUnavailable, p.expectedArrival],
    ];
    final before = snapshot();
    await tester.pumpWidget(app(repo, const ParcelsScreen()));
    await tester.pump();
    expect(snapshot(), before);
  });

  testWidgets('forecast summary does not overflow at 320 px with a long housemate name', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ForecastSummary(
              advice: advice(name: 'Bartholomew Maximilian Fitzgerald Montgomery'),
              learnedTaps: 3,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Learned from 3 taps of yours'), findsOneWidget);
  });

  testWidgets('summary wording for likely, maybe and unlikely', (tester) async {
    Future<void> show(ArrivalAdvice a) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ForecastSummary(advice: a))));
    }

    await show(advice(p: 0.82));
    expect(find.text('Cas thinks Alex is probably home (82%)'), findsOneWidget);
    await show(advice(p: 0.55));
    expect(find.text('Cas thinks Alex might be home (55%)'), findsOneWidget);
    await show(advice(p: 0.2));
    expect(find.text('Cas thinks nobody is likely home then (best chance 20%)'), findsOneWidget);
    await show(advice(name: 'You', p: 0.9));
    expect(find.text('Cas thinks you are probably home (90%)'), findsOneWidget);
    expect(find.text('You were home 9 of 12 recent Thursdays at 2 PM'), findsOneWidget);
  });

  testWidgets('a parcel due now says which hour the forecast is for', (tester) async {
    final due = ArrivalAdvice(
      ranked: advice().ranked,
      anyoneHomeProbability: 0.9,
      bestWindowStart: null,
      bestWindowProbability: 0,
      optedInCount: 2,
      memberCount: 4,
      forecastHour: DateTime.utc(2026, 3, 25, 18),
      shifted: true,
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ForecastSummary(advice: due))));
    expect(find.text('Due now, so this is for 6 PM'), findsOneWidget);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ForecastSummary(advice: advice()))));
    expect(find.textContaining('Due now'), findsNothing);
  });

  testWidgets('summary shows the chance that someone is home and never shows 0 or 100 percent', (tester) async {
    final two = ArrivalAdvice(
      ranked: [
        MemberForecast(memberId: 'a', name: 'Alex', probability: 0.999, band: HomeBand.likely, why: 'was home 3 of 3 recent Mondays at 2 PM', observedHours: 504),
        MemberForecast(memberId: 'm', name: 'Maria', probability: 0.0001, band: HomeBand.unlikely, why: 'was home 0 of 3 recent Mondays at 2 PM', observedHours: 504),
      ],
      anyoneHomeProbability: 0.9999,
      bestWindowStart: null,
      bestWindowProbability: 0,
      optedInCount: 2,
      memberCount: 4,
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ForecastSummary(advice: two))));
    expect(find.text('Chance at least one housemate is home: 99%'), findsOneWidget);
    expect(find.text('Cas thinks Alex is probably home (99%)'), findsOneWidget);
    expect(percent(0.0001), '1');
    expect(percent(0.5), '50');
  });

  testWidgets('settings switch turns the forecast off and clears history', (tester) async {
    bigScreen(tester);
    final repo = MockRepository()..updatePresence(isHome: false);
    expect(repo.presenceHistoryFor(me), isNotEmpty);
    await tester.pumpWidget(app(repo, const AppSettingsScreen()));
    await tester.scrollUntilVisible(find.text('Let Cas learn my routine'), 300);
    await tester.tap(find.text('Let Cas learn my routine'));
    await tester.pump();
    expect(repo.isRoutineOptedIn(me), isFalse);
    expect(repo.presenceHistoryFor(me), isEmpty);
  });

  testWidgets('privacy screen explains the routine forecast', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TermsPrivacyScreen()));
    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();
    expect(find.text('Optional Routine Forecast'), findsOneWidget);
    expect(find.textContaining('demo housemates'), findsOneWidget);
    expect(find.textContaining('never as a full schedule'), findsOneWidget);
  });
}
