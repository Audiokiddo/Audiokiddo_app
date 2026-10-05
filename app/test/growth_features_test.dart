import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/alerts/alerts.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/home/first_play.dart';
import 'package:audiokiddo/features/player/szop_lines.dart';
import 'package:audiokiddo/features/promotions/promotions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> manifest() =>
    jsonDecode(File('assets/mock/catalog.json').readAsStringSync()) as Map<String, Object?>;

class _Source implements CatalogSource {
  const _Source(this.json);
  final Map<String, Object?> json;
  @override
  Future<Map<String, Object?>> load() async => json;
}

void main() {
  final catalog = parseCatalog(manifest()).catalog;

  test('a new family starts with a short free play that needs nothing', () {
    final item = firstPlay(catalog)!;
    expect(item.isFree, isTrue);
    expect(item.requirements, isEmpty);
    expect(item.kind, ContentKind.audioGame);
  });

  test('no placeholder songs; ages as decided', () {
    expect(catalog.items.where((i) => i.kind == ContentKind.song), isEmpty);
    for (final i in catalog.itemsInPack('detektyw')) {
      expect(i.ageMin, 7);
    }
    for (final i in [...catalog.itemsInPack('wyobraznia'), ...catalog.itemsInPack('slowa-i-wiedza')]) {
      expect((i.ageMin, i.ageMax), (3, 9));
    }
  });

  test('plays with a future release date wait in "Wkrótce"', () async {
    final json = manifest();
    final items = (json['items']! as List).cast<Map<String, Object?>>();
    items.first['released'] = '2030-01-15';
    final container = ProviderContainer(
      overrides: [
        catalogSourceProvider.overrideWithValue(_Source(json)),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 6)),
      ],
    );
    addTearDown(container.dispose);
    final shown = await container.read(catalogProvider.future);
    expect(shown.item(items.first['id']! as String), isNull);
    await container.read(fullCatalogProvider.future);
    expect(container.read(upcomingItemsProvider).single.id, items.first['id']);
  });

  test('access ending by itself is found; store subscriptions renew and are skipped', () {
    final now = DateTime(2026, 10, 6);
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        entitlementsProvider.overrideWithValue([
          Entitlement(
            scope: Scopes.allContent,
            status: EntitlementStatus.active,
            source: EntitlementSource.appStore,
            validUntil: now.add(const Duration(days: 3)),
          ),
          Entitlement(
            scope: Scopes.allContent,
            status: EntitlementStatus.active,
            source: EntitlementSource.manual,
            validUntil: now.add(const Duration(days: 5)),
          ),
        ]),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(endingAccessProvider), now.add(const Duration(days: 5)));
  });

  test('promotion deadline reads like a person would say it', () {
    final now = DateTime(2026, 12, 1, 10);
    expect(promotionDeadline(DateTime(2026, 12, 6, 23, 59), now), 'do 6 grudnia');
    expect(promotionDeadline(DateTime(2026, 12, 1, 23, 59), now), 'tylko do dziś');
  });

  test('Szop’en’s lines during a play do not repeat until all were used', () {
    final bag = SzopLineBag(szopPlayingLines);
    final seen = <String>{};
    for (var i = 0; i < szopPlayingLines.length; i++) {
      expect(seen.add(bag.next().$2), isTrue);
    }
    expect(szopPlayingLines.length, greaterThanOrEqualTo(40));
  });
}
