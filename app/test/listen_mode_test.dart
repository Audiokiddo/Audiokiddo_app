import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/player/listen_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('together or alone is remembered; two different questions to talk about', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final c = ProviderContainer(overrides: testOverrides(db));
    addTearDown(c.dispose);
    expect(await c.read(listenModeProvider.future), isNull);
    await c.read(listenModeProvider.notifier).set(ListenMode.together);
    final again = ProviderContainer(overrides: testOverrides(db));
    addTearDown(again.dispose);
    expect(await again.read(listenModeProvider.future), ListenMode.together);

    final catalog = await c.read(catalogProvider.future);
    for (final item in catalog.items) {
      final q = talkQuestions(item);
      expect(q, hasLength(2));
      expect(q.first, isNot(q.last));
      expect(q.join(' '), isNot(contains('!')));
    }
  });
}
