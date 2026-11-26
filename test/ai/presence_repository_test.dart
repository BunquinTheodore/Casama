import 'package:casama/data/mock_repository.dart';
import 'package:casama/features/parcels/home_forecast/habit_profile.dart';
import 'package:flutter_test/flutter_test.dart';

const me = '11111111-1111-1111-1111-111111111111';
const maria = '22222222-2222-2222-2222-222222222222';

// A Wednesday. The most recent Monday is 2026-03-23.
MockRepository repo() => MockRepository(clock: () => DateTime(2026, 3, 25, 10));

void main() {
  test('a new account starts opted out', () {
    expect(repo().isRoutineOptedIn('a-brand-new-user'), isFalse);
  });

  test('the demo household has four opted in members with three weeks of history', () {
    final inputs = repo().forecastInputs(DateTime(2026, 3, 25, 10));
    expect(inputs.length, 4);
    for (final m in inputs) {
      expect(m.optedIn, isTrue, reason: m.name);
      expect(m.hours.length, 504, reason: m.name);
    }
  });

  test('the demo history is three whole Monday to Sunday weeks ending at the most recent Monday', () {
    final hours = repo().forecastInputs(DateTime(2026, 3, 25, 10)).first.hours;
    expect(hours.first.at, DateTime.utc(2026, 3, 2));
    expect(hours.first.at.weekday, DateTime.monday);
    expect(hours.last.at, DateTime.utc(2026, 3, 22, 23));
    expect(slotOf(hours.last.at), 167);
  });

  test('updatePresence does not record when the member is opted out', () {
    final r = repo()..setRoutineOptIn(me, false);
    r.updatePresence(isHome: false, note: 'Out');
    expect(r.presenceHistoryFor(me), isEmpty);
  });

  test('updatePresence records when the member is opted in', () {
    final r = repo();
    r.updatePresence(isHome: false, note: 'Out');
    final taps = r.presenceHistoryFor(me);
    expect(taps.length, 1);
    expect(taps.single.isHome, isFalse);
    expect(taps.single.userId, me);
    expect(taps.single.at, DateTime(2026, 3, 25, 10));
  });

  test('opting out deletes that member\'s history, taps and demo hours', () {
    final r = repo();
    r.updatePresence(isHome: true);
    r.setRoutineOptIn(me, false);
    expect(r.presenceHistoryFor(me), isEmpty);
    final mine = r.forecastInputs(DateTime(2026, 3, 25, 10)).firstWhere((m) => m.memberId == me);
    expect(mine.optedIn, isFalse);
    expect(mine.hours, isEmpty);
  });

  test('forecastInputs excludes the hours of a member who is not opted in', () {
    final r = repo()..setRoutineOptIn(maria, false);
    final inputs = r.forecastInputs(DateTime(2026, 3, 25, 10));
    final m = inputs.firstWhere((h) => h.memberId == maria);
    expect(m.optedIn, isFalse);
    expect(m.hours, isEmpty);
    expect(inputs.where((h) => h.optedIn).length, 3);
  });

  test('opting in again starts from an empty history', () {
    final r = repo()
      ..setRoutineOptIn(me, false)
      ..setRoutineOptIn(me, true);
    expect(r.isRoutineOptedIn(me), isTrue);
    expect(r.presenceHistoryFor(me), isEmpty);
    final mine = r.forecastInputs(DateTime(2026, 3, 25, 10)).firstWhere((m) => m.memberId == me);
    expect(mine.hours, isEmpty);
  });

  test('changing the opt in notifies listeners', () {
    final r = repo();
    var calls = 0;
    r.addListener(() => calls++);
    r.setRoutineOptIn(me, false);
    expect(calls, 1);
  });

  test('the repository exposes the clock it records with', () {
    expect(repo().now, DateTime(2026, 3, 25, 10));
  });

  test('existing updatePresence behaviour is unchanged', () {
    final r = repo();
    r.updatePresence(isHome: false, note: 'At class');
    final mine = r.members.firstWhere((m) => m.profile.id == me);
    expect(mine.isHome, isFalse);
    expect(mine.note, 'At class');
  });

  test('forecastInputs reports each member\'s current home state', () {
    final inputs = repo().forecastInputs(DateTime(2026, 3, 25, 10));
    expect(inputs.firstWhere((m) => m.memberId == me).homeNow, isTrue);
    expect(inputs.firstWhere((m) => m.name == 'Alex').homeNow, isFalse);
  });
}
