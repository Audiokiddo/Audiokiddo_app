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

  test('in the car: travel activities that fit the time, never answering games', () {
    final picks = quickPick(
      catalog,
      place: PickPlace.car,
      minutes: 10,
      mood: PickMood.move,
      age: 6,
      canPlay: all,
    );
    expect(picks, isNotEmpty);
    expect(picks.any((i) => i.kind == ContentKind.interactiveGame), isFalse);
    expect(picks.first.situations, contains(Situation.podroz));
  });

  test('in bed and calm: bedtime activities first, no games', () {
    final picks = quickPick(
      catalog,
      place: PickPlace.bed,
      minutes: 20,
      mood: PickMood.calm,
      age: 6,
      canPlay: all,
    );
    expect(picks.first.situations, contains(Situation.przedSnem));
    expect(picks.any((i) => i.kind == ContentKind.interactiveGame), isFalse);
  });

  test('only what the family may play, at the child\'s age; something new beats a repeat', () {
    final free = quickPick(
      catalog,
      place: PickPlace.home,
      minutes: 10,
      mood: PickMood.move,
      age: 3,
      canPlay: (i) => i.isFree,
    );
    expect(free.every((i) => i.isFree && i.ageMin <= 3), isTrue);
    final first = quickPick(
      catalog,
      place: PickPlace.out,
      minutes: 5,
      mood: PickMood.move,
      age: 6,
      canPlay: all,
    ).first;
    final again = quickPick(
      catalog,
      place: PickPlace.out,
      minutes: 5,
      mood: PickMood.move,
      age: 6,
      canPlay: all,
      playedToday: {first.id},
    );
    expect(again.first.id, isNot(first.id));
  });
}
