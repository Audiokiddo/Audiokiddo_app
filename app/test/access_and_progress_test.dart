import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/core/format.dart';
import 'package:audiokiddo/core/storage/database.dart';
import 'package:audiokiddo/core/storage/storage_providers.dart';
import 'package:audiokiddo/features/access/access_controller.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/personal/personal_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

ContentItem paidItem(String id, {String? pack}) => ContentItem(
  id: id,
  kind: ContentKind.audioGame,
  packId: pack,
  title: id,
  parentDescription: '',
  ageMin: 3,
  durationSec: 60,
  access: ContentAccess.paid,
  audio: const [],
);

PlaybackProgressData progress(int posSec, int durSec, {bool completed = false}) => PlaybackProgressData(
  itemId: 'a',
  positionMs: posSec * 1000,
  durationMs: durSec * 1000,
  completed: completed,
  updatedAt: DateTime(2026),
);

void main() {
  group('resume position', () {
    test('no progress, finished or barely started starts from zero', () {
      expect(resumePosition(null), Duration.zero);
      expect(resumePosition(progress(200, 400, completed: true)), Duration.zero);
      expect(resumePosition(progress(5, 400)), Duration.zero);
    });

    test('almost finished starts over', () {
      expect(resumePosition(progress(390, 400)), Duration.zero);
    });

    test('in the middle resumes 3 seconds earlier', () {
      expect(resumePosition(progress(151, 400)), const Duration(seconds: 148));
    });
  });

  group('access with the dev backend', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = memoryDatabase();
      container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<void> setMode(DevAccessMode mode) async {
      await (container.read(entitlementBackendProvider) as DevEntitlementBackend).setMode(mode);
      await container.read(accessProvider.future);
      await container.read(accessProvider.notifier).refresh();
    }

    test('without purchases paid content is locked', () async {
      await setMode(DevAccessMode.none);
      expect(container.read(itemAccessProvider(paidItem('a', pack: 'wyobraznia'))), ItemAccess.locked);
    });

    test('pack purchase unlocks only its pack and grants an offline lease', () async {
      await setMode(DevAccessMode.packWyobraznia);
      expect(container.read(itemAccessProvider(paidItem('a', pack: 'wyobraznia'))), ItemAccess.playable);
      expect(container.read(itemAccessProvider(paidItem('b', pack: 'detektyw'))), ItemAccess.locked);
      final lease = container.read(accessProvider).value!.leaseValidUntil!;
      expect(lease.difference(DateTime.now()).inDays, 29);
    });

    test('expired lease asks for a refresh, refresh restores access', () async {
      await setMode(DevAccessMode.subscription);
      await container.read(accessProvider.notifier).expireLeaseForTesting();
      expect(container.read(itemAccessProvider(paidItem('a'))), ItemAccess.needsRefresh);
      await container.read(accessProvider.notifier).refresh();
      expect(container.read(itemAccessProvider(paidItem('a'))), ItemAccess.playable);
    });

    test('access state survives an app restart', () async {
      await setMode(DevAccessMode.allPacks);
      final restarted = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
      addTearDown(restarted.dispose);
      final state = await restarted.read(accessProvider.future);
      expect(state.entitlements.map((e) => e.scope), contains(Scopes.pack('detektyw')));
    });
  });

  test('AccessState JSON round trip', () {
    final state = AccessState(
      entitlements: [
        Entitlement(
          scope: Scopes.allContent,
          status: EntitlementStatus.grace,
          source: EntitlementSource.appStore,
          validUntil: DateTime.utc(2026, 11),
        ),
      ],
      leaseValidUntil: DateTime.utc(2026, 10, 20),
      lastSeenAt: DateTime.utc(2026, 9, 26),
    );
    final back = AccessState.fromJson(state.toJson());
    expect(back.entitlements.single.status, EntitlementStatus.grace);
    expect(back.entitlements.single.validUntil, DateTime.utc(2026, 11));
    expect(back.leaseValidUntil, DateTime.utc(2026, 10, 20));
  });

  test('formatting', () {
    expect(formatBytes(295850), '296 KB');
    expect(formatBytes(3160000), '3,2 MB');
    expect(formatClock(const Duration(minutes: 2, seconds: 5)), '2:05');
    expect(formatClock(const Duration(hours: 1, minutes: 2, seconds: 5)), '1:02:05');
  });
}
