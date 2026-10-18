import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ContentItem item({DateTime? release}) => ContentItem(
  id: 'time-test',
  kind: ContentKind.audioGame,
  title: 'Time test',
  parentDescription: '',
  ageMin: 3,
  durationSec: 60,
  access: ContentAccess.paid,
  audio: const [AssetRef(path: 'audio/time-test.m4a', bytes: 1, sha256: 'x')],
  releasedOn: release,
);

void main() {
  testWidgets('access expires at its boundary without a screen change', (tester) async {
    var now = DateTime(2026, 10, 14, 10);
    final container = ProviderContainer(
      overrides: [
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
    final play = item();
    expect(container.read(itemAccessProvider(play)), ItemAccess.playable);
    now = now.add(const Duration(seconds: 20));
    await tester.pump(const Duration(seconds: 20));
    expect(container.read(itemAccessProvider(play)), ItemAccess.locked);
    container.dispose();
  });

  testWidgets('midnight releases the scheduled item without refetching the manifest', (tester) async {
    var now = DateTime(2026, 10, 14, 23, 59, 50);
    var loads = 0;
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        entitlementsProvider.overrideWithValue(const []),
        fullCatalogProvider.overrideWith((ref) async {
          loads++;
          return Catalog(
            version: 1,
            packs: const [],
            items: [item(release: DateTime(2026, 10, 15))],
            shelves: const [],
          );
        }),
      ],
    );
    final before = container.read(catalogProvider.future);
    await tester.pump();
    expect((await before).items, isEmpty);
    now = DateTime(2026, 10, 15);
    await tester.pump(const Duration(seconds: 10));
    final after = container.read(catalogProvider.future);
    await tester.pump();
    expect((await after).items, hasLength(1));
    expect(loads, 1);
    container.dispose();
  });

  testWidgets('refresh after background updates access without waiting for the timer', (tester) async {
    var now = DateTime(2026, 10, 14, 10);
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        entitlementsProvider.overrideWithValue([
          Entitlement(
            scope: Scopes.allContent,
            status: EntitlementStatus.active,
            source: EntitlementSource.appStore,
            validUntil: now.add(const Duration(hours: 1)),
          ),
        ]),
        leaseStateProvider.overrideWithValue(LeaseState.valid),
      ],
    );
    final play = item();
    expect(container.read(itemAccessProvider(play)), ItemAccess.playable);
    now = now.add(const Duration(hours: 2));
    container.invalidate(currentTimeProvider);
    expect(container.read(itemAccessProvider(play)), ItemAccess.locked);
    container.dispose();
  });
}
