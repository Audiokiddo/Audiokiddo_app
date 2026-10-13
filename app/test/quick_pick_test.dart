import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/home/quick_pick.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = parseCatalog(
    jsonDecode(File('assets/mock/catalog.json').readAsStringSync()) as Map<String, Object?>,
  ).catalog;
  bool all(ContentItem _) => true;
  int minutes(List<ContentItem> run) => run.fold(0, (s, i) => s + i.durationSec) ~/ 60;

  test('a run of audio plays for the child\'s age that fits the time', () {
    final run = pickPlaylist(catalog, minutes: 30, age: 5, canPlay: all);
    expect(run.length, greaterThan(2));
    expect(minutes(run), lessThanOrEqualTo(31));
    expect(run.every((i) => i.kind == ContentKind.audioGame && i.ageMin <= 5), isTrue);
    expect(run.map((i) => i.id).toSet().length, run.length, reason: 'no repeats');
  });

  test('plays not heard yet come first; another draw gives another order', () {
    final heard = {for (final i in catalog.items.take(12)) i.id};
    final run = pickPlaylist(catalog, minutes: 15, age: 8, canPlay: all, heard: heard);
    expect(run.first.id, isNot(isIn(heard)));
    final orders = {
      for (var seed = 0; seed < 6; seed++)
        pickPlaylist(catalog, minutes: 30, age: 8, canPlay: all, seed: seed).map((i) => i.id).join(','),
    };
    expect(orders.length, greaterThan(1));
  });

  test('in the car nothing that needs paper, a printout, moving or the microphone', () {
    final run = pickPlaylist(catalog, minutes: 60, age: 9, canPlay: all, car: true);
    expect(run, isNotEmpty);
    expect(run.every((i) => i.requirements.isEmpty), isTrue);
  });

  test('only what the family may play; the unfinished play is not drawn again', () {
    final run = pickPlaylist(catalog, minutes: 60, age: 9, canPlay: (i) => i.isFree, skip: 'magiczny-sklep');
    expect(run.every((i) => i.isFree), isTrue);
    expect(run.any((i) => i.id == 'magiczny-sklep'), isFalse);
  });
}
