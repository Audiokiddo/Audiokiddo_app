import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/player/player_providers.dart';
import 'package:audiokiddo/features/player/playback_controller.dart';
import 'package:audiokiddo/features/session/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'queue_runner_test.dart' show QueueAudio;
import 'session_test.dart' show FakeSessionAudio;

const play = ContentItem(
  id: 'paid-test',
  kind: ContentKind.audioGame,
  title: 'Paid',
  parentDescription: '',
  ageMin: 3,
  durationSec: 60,
  access: ContentAccess.paid,
  audio: [],
);

class FailingSessionAudio extends FakeSessionAudio {
  @override
  Future<void> playItem(ContentItem item, {Duration fadeOut = Duration.zero}) async {
    throw const PlaybackAccessUnavailable();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('playback rechecks expired cached access before trying any source', () async {
    final db = memoryDatabase();
    final audio = QueueAudio();
    var now = DateTime(2026, 10, 15, 10);
    final c = ProviderContainer(
      overrides: [
        ...testOverrides(db),
        audioHandlerProvider.overrideWithValue(audio),
        clockProvider.overrideWithValue(() => now),
        entitlementsProvider.overrideWithValue([
          Entitlement(
            scope: Scopes.allContent,
            status: EntitlementStatus.active,
            source: EntitlementSource.appStore,
            validUntil: now.add(const Duration(seconds: 20)),
          ),
        ]),
        leaseStateProvider.overrideWithValue(LeaseState.valid),
      ],
    );
    expect(c.read(canPlayProvider(play)), true);
    now = now.add(const Duration(seconds: 21));
    await expectLater(
      c.read(playbackControllerProvider).start(play, album: 'Test'),
      throwsA(isA<PlaybackAccessUnavailable>()),
    );
    expect(audio.mediaItem.value, isNull);
    c.dispose();
    await db.close();
  });

  test('a session whose source fails stops with a visible error instead of hanging', () async {
    final db = memoryDatabase();
    final c = ProviderContainer(
      overrides: [...testOverrides(db), sessionAudioProvider.overrideWithValue(FailingSessionAudio())],
    );
    await c.read(sessionProvider.notifier).start(SessionKind.dinner, [ItemStep(play)]);
    expect(c.read(sessionProvider).running, false);
    expect(c.read(sessionProvider).error, isNotNull);
    expect(c.read(sessionProvider).finished, false);
    c.dispose();
    await db.close();
  });
}
