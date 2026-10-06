import 'package:audiokiddo/features/insights/events.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class _Recorder implements EventSink {
  final sent = <(AppEvent, Map<String, Object?>)>[];

  @override
  void track(AppEvent event, {String? itemId, Map<String, Object?> props = const {}}) => sent.add((event, props));
}

void main() {
  test('age bands for the statistics, never the exact age', () {
    expect(ageGroupOf(null), isNull);
    expect([3, 4, 5, 6, 7, 9].map(ageGroupOf), ['3-5', '3-5', '5-7', '5-7', '7-9', '7-9']);
  });

  test('play numbers count per play and say when it was first ever', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final first = await countPlayStart(db, 'a', now: DateTime(2026, 10, 1, 10));
    expect((first.number, first.firstEver, first.previous), (1, true, null));
    final other = await countPlayStart(db, 'b', now: DateTime(2026, 10, 1, 11));
    expect((other.number, other.firstEver), (1, false));
    final again = await countPlayStart(db, 'a', now: DateTime(2026, 10, 2, 10));
    expect((again.number, again.previous), (2, DateTime(2026, 10, 1, 10)));
    expect(again.props['play_number'], 2);
  });

  test('app_open says how many days passed since the last launch', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final sink = _Recorder();
    await trackLaunch(sink, db, now: DateTime(2026, 10, 1, 22));
    expect(sink.sent.single.$2.containsKey('days_since_last'), isFalse);
    await trackLaunch(sink, db, now: DateTime(2026, 10, 4, 7));
    expect(sink.sent.last.$2['days_since_last'], 3);
  });
}
