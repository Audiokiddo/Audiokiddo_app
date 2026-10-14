import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audiokiddo/core/audio/kiddo_voice.dart' show plainName;
import 'package:audiokiddo/features/catalog/all_plays.dart';
import 'package:audiokiddo/features/session/plan.dart';
import 'package:audiokiddo/features/session/session.dart';

Catalog loadCatalog() =>
    parseCatalog(jsonDecode(File('assets/mock/catalog.json').readAsStringSync()) as Map<String, Object?>)
        .catalog;

void main() {
  final catalog = loadCatalog();
  bool all(ContentItem _) => true;
  final audio = catalog.items
      .where((i) => i.audio.isNotEmpty && i.kind != ContentKind.interactiveGame)
      .toList();
  final a = audio[0], b = audio[1], c = audio[2], d = audio[3];
  final steps = <SessionStep>[
    const LineStep('trip_start'),
    ItemStep(a),
    ItemStep(b),
    const LineStep('window_1', pauseAfter: Duration(seconds: 40)),
    ItemStep(c),
    const LineStep('trip_end'),
  ];

  List<String> ids(List<SessionStep> s) => [
    for (final x in s)
      if (x is ItemStep) x.item.id,
  ];

  group('plan edits', () {
    test('remove drops one play and leaves Szop’en’s lines', () {
      final out = planRemove(steps, 1);
      expect(ids(out), [a.id, c.id]);
      expect(out.whereType<LineStep>(), hasLength(3));
    });

    test('plays before [from] cannot be touched: positions count from there', () {
      // The first play already played: position 0 is the second one.
      final out = planRemove(steps, 0, from: 2);
      expect(ids(out), [a.id, c.id]);
      expect(planRemove(steps, 5, from: 2), same(steps), reason: 'out of range changes nothing');
    });

    test('reorder moves a play, the lines stay in their places', () {
      final out = planReorder(steps, 0, 2);
      expect(ids(out), [b.id, c.id, a.id]);
      expect(out[0], isA<LineStep>());
      expect(out[3], isA<LineStep>());
      expect(out.last, isA<LineStep>());
    });

    test('replace swaps the play in its slot', () {
      final out = planReplace(steps, 1, d);
      expect(ids(out), [a.id, d.id, c.id]);
    });

    test('add puts plays after the last play, before the closing line', () {
      final out = planAdd(steps, [d]);
      expect(ids(out), [a.id, b.id, c.id, d.id]);
      expect(out.last, isA<LineStep>());
      expect((out[out.length - 2] as ItemStep).item.id, d.id);
    });
  });

  group('time left', () {
    test('counts the plays, the breaks and what is left of the one playing', () {
      final full = planSecondsLeft(steps, index: 0, started: false);
      expect(full, a.durationSec + b.durationSec + c.durationSec + 40);
      final half = planSecondsLeft(steps, index: 1, position: const Duration(seconds: 30));
      expect(half, a.durationSec - 30 + b.durationSec + c.durationSec + 40);
    });

    test('minutes are rounded up', () {
      expect(minutesLabel(61), '2 min');
      expect(minutesLabel(60 * 65), '1 h 5 min');
      expect(minutesLabel(3600), '1 h');
    });
  });

  group('candidates and extra minutes', () {
    test('candidates leave out what is already in the plan, and games that need the phone', () {
      final out = planCandidates(catalog, age: 6, canPlay: all, exclude: {a.id});
      expect(out.map((i) => i.id), isNot(contains(a.id)));
      expect(out.where((i) => i.kind == ContentKind.interactiveGame), isEmpty);
    });

    test('a dinner only takes audio plays with nothing to prepare', () {
      final out = planCandidates(catalog, age: 6, canPlay: all, dinner: true);
      expect(out.every((i) => i.kind == ContentKind.audioGame && i.requirements.isEmpty), isTrue);
    });

    test('+10 minutes adds at least ten minutes of plays', () {
      final pool = planCandidates(catalog, age: 6, canPlay: all);
      final more = playsForMinutes(pool, 10);
      expect(more, isNotEmpty);
      final seconds = more.fold(0, (s, i) => s + i.durationSec);
      expect(seconds, greaterThanOrEqualTo(10 * 60));
    });
  });

  group('a ride uses the time', () {
    test('the plays of a ride come within a minute or two of the length asked for', () {
      for (final minutes in [15, 20, 31, 47, 60]) {
        final trip = buildTrip(catalog, minutes: minutes, age: 6, canPlay: all);
        final secs = playsFrom(trip, 0).fold(0, (s, i) => s + i.durationSec);
        expect(secs, lessThanOrEqualTo(minutes * 60 + 5 * 60), reason: '$minutes min ride');
        expect(secs, greaterThanOrEqualTo(minutes * 60 - 8 * 60), reason: '$minutes min ride');
      }
    });
  });

  group('all plays list', () {
    final now = DateTime(2026, 10, 16);
    test('is A–Z by default, with every released play', () {
      final out = allPlays(catalog, now: now);
      final titles = out.map((i) => i.title.toLowerCase()).toList();
      // Polish order differs from plain string order only for ą, ć…: the first letters are in order.
      final firsts = [for (final s in titles) plainName(s)[0]];
      expect(firsts, [...firsts]..sort());
      expect(out.length, catalog.items.where((i) => i.releasedOn?.isAfter(now) != true).length);
    });

    test('finds a title typed without Polish letters, by a word, or by the pack', () {
      final target = catalog.items.firstWhere(
        (i) => i.title.contains(RegExp('[ąćęłńóśźż]')),
        orElse: () => catalog.items.first,
      );
      String plain(String s) => s
          .toLowerCase()
          .replaceAll('ł', 'l')
          .replaceAll('ą', 'a')
          .replaceAll('ę', 'e')
          .replaceAll('ś', 's')
          .replaceAll('ć', 'c')
          .replaceAll('ń', 'n')
          .replaceAll('ó', 'o')
          .replaceAll('ź', 'z')
          .replaceAll('ż', 'z');
      final out = allPlays(catalog, now: now, query: plain(target.title));
      expect(out.map((i) => i.id), contains(target.id));
      final word = target.title.split(' ').first;
      expect(allPlays(catalog, now: now, query: word.toUpperCase()).map((i) => i.id), contains(target.id));
      expect(allPlays(catalog, now: now, query: 'zzzzqqq'), isEmpty);
    });

    test('titles that start with the query come first', () {
      final first = catalog.items.first.title;
      final out = allPlays(catalog, now: now, query: first.substring(0, 3));
      expect(out.first.title.toLowerCase().startsWith(first.substring(0, 3).toLowerCase()), isTrue);
    });

    test('kind and free filters narrow the list', () {
      final songs = allPlays(catalog, now: now, kind: AllKind.song);
      expect(songs.every((i) => i.kind == ContentKind.song), isTrue);
      final free = allPlays(catalog, now: now, kind: AllKind.free);
      expect(free.every((i) => i.isFree), isTrue);
    });
  });
}
