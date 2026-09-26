import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:test/test.dart';

Map<String, Object?> item(String id, {String? pack, String access = 'paid', Map<String, Object?>? extra}) => {
  'id': id,
  'kind': 'audio_game',
  'pack_id': ?pack,
  'title': 'Tytuł $id',
  'parent_description': 'Opis',
  'age_min': 3,
  'duration_sec': 360,
  'access': access,
  'situations': ['podroz', 'w_domu'],
  'audio': [
    {'path': 'audio/$id.m4a', 'bytes': 1000, 'sha256': 'x'},
  ],
  ...?extra,
};

Map<String, Object?> manifest(List<Object?> items) => {
  'schema_version': 1,
  'version': 7,
  'packs': [
    {'id': 'wyobraznia', 'title': 'Wyobraźnia', 'age_min': 3, 'color': 'lavender', 'description': 'd'},
  ],
  'items': items,
  'shelves': [
    {
      'id': 'featured',
      'title': 'Zabawa dnia',
      'kind': 'featured',
      'item_ids': ['a', 'broken', 'b'],
    },
  ],
};

void main() {
  group('catalog', () {
    test('parses valid items and skips broken ones without failing', () {
      final result = parseCatalog(
        manifest([
          item('a', pack: 'wyobraznia'),
          {'id': 'broken', 'kind': 'audio_game'}, // missing fields
          item('b', access: 'free'),
          item('c', pack: 'nieznany'),
          item('a'), // duplicate
        ]),
      );
      expect(result.catalog.items.map((i) => i.id), ['a', 'b']);
      expect(result.skipped, hasLength(3));
      expect(result.catalog.shelves.single.itemIds, ['a', 'b'], reason: 'shelves drop ids of skipped items');
      expect(result.catalog.items.first.situations, [Situation.podroz, Situation.wDomu]);
    });

    test('items needing a newer engine are hidden', () {
      final result = parseCatalog(
        manifest([
          item('a', extra: {'min_engine_version': 99}),
        ]),
      );
      expect(result.catalog.items, isEmpty);
      expect(result.skipped.single.reason, contains('newer app'));
    });

    test('interactive game with an invalid script is hidden', () {
      final script =
          jsonDecode(File('test/fixtures/zgadnij_dzwiek.json').readAsStringSync()) as Map<String, Object?>;
      (script['steps'] as Map)['q1'] = {'type': 'play', 'asset': 'q_krowa', 'next': 'missing'};
      final game = {...item('g'), 'kind': 'interactive_game', 'audio': <Object?>[], 'script': script};
      final result = parseCatalog(manifest([game, item('a')]));
      expect(result.catalog.items.map((i) => i.id), ['a']);
      expect(result.skipped.single.reason, startsWith('invalid script'));
    });

    test('unsupported schema version rejects the whole manifest', () {
      expect(() => parseCatalog({...manifest([]), 'schema_version': 2}), throwsA(isA<FormatError>()));
    });
  });

  group('access', () {
    final now = DateTime.utc(2026, 10, 1);
    final catalog = parseCatalog(
      manifest([item('a', pack: 'wyobraznia'), item('free', access: 'free'), item('song')]),
    ).catalog;
    final packItem = catalog.item('a')!;
    final song = catalog.item('song')!;

    Entitlement ent(String scope, {EntitlementStatus status = EntitlementStatus.active, DateTime? until}) =>
        Entitlement(scope: scope, status: status, source: EntitlementSource.appStore, validUntil: until);

    test('free content is always playable', () {
      expect(const AccessPolicy([]).canPlay(catalog.item('free')!, now), isTrue);
    });

    test('pack purchase unlocks only its pack', () {
      final policy = AccessPolicy([ent(Scopes.pack('wyobraznia'))]);
      expect(policy.canPlay(packItem, now), isTrue);
      expect(policy.canPlay(song, now), isFalse);
    });

    test('single item purchase unlocks only that item', () {
      final policy = AccessPolicy([ent(Scopes.item('song'))]);
      expect(policy.canPlay(song, now), isTrue);
      expect(policy.canPlay(packItem, now), isFalse);
    });

    test('subscription unlocks everything until it ends', () {
      final policy = AccessPolicy([ent(Scopes.allContent, until: now.add(const Duration(days: 1)))]);
      expect(policy.canPlay(packItem, now), isTrue);
      expect(policy.canPlay(song, now.add(const Duration(days: 2))), isFalse);
    });

    test('grace keeps access, billing retry and refunds do not', () {
      expect(
        AccessPolicy([ent(Scopes.allContent, status: EntitlementStatus.grace)]).canPlay(song, now),
        isTrue,
      );
      for (final s in [
        EntitlementStatus.billingRetry,
        EntitlementStatus.refunded,
        EntitlementStatus.revoked,
      ]) {
        expect(AccessPolicy([ent(Scopes.allContent, status: s)]).canPlay(song, now), isFalse, reason: s.name);
      }
    });
  });

  group('offline lease', () {
    final issued = DateTime.utc(2026, 10, 1);

    test('lease is capped at 30 days offline', () {
      expect(leaseValidUntil(issuedAt: issued), issued.add(const Duration(days: 30)));
      expect(
        leaseValidUntil(issuedAt: issued, paidUntil: issued.add(const Duration(days: 365))),
        issued.add(const Duration(days: 30)),
      );
    });

    test('lease ends shortly after a subscription period that is not renewed', () {
      expect(
        leaseValidUntil(issuedAt: issued, paidUntil: issued.add(const Duration(days: 5))),
        issued.add(const Duration(days: 8)),
      );
    });

    test('evaluation', () {
      final until = issued.add(const Duration(days: 30));
      expect(evaluateLease(now: issued, validUntil: until, lastSeenAt: issued), LeaseState.valid);
      expect(evaluateLease(now: until, validUntil: until, lastSeenAt: issued), LeaseState.expired);
      expect(evaluateLease(now: issued, validUntil: null, lastSeenAt: null), LeaseState.missing);
    });

    test('moving the clock back more than a day forces a refresh', () {
      final until = issued.add(const Duration(days: 30));
      final lastSeen = issued.add(const Duration(days: 40));
      expect(
        evaluateLease(now: issued.add(const Duration(days: 10)), validUntil: until, lastSeenAt: lastSeen),
        LeaseState.clockRolledBack,
      );
      expect(
        evaluateLease(
          now: lastSeen.subtract(const Duration(hours: 2)),
          validUntil: until,
          lastSeenAt: lastSeen,
        ),
        LeaseState.expired,
        reason: 'small clock corrections are tolerated',
      );
    });

    test('files of expired content are kept for 14 days', () {
      expect(
        shouldDeleteExpiredFiles(now: issued.add(const Duration(days: 13)), accessLostAt: issued),
        isFalse,
      );
      expect(
        shouldDeleteExpiredFiles(now: issued.add(const Duration(days: 14)), accessLostAt: issued),
        isTrue,
      );
    });
  });
}
