import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/discovery/discovery_model.dart';
import 'package:audiokiddo/core/storage/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

ContentItem sample(
  String id, {
  int seconds = 600,
  int min = 3,
  int? max,
  ContentAccess access = ContentAccess.free,
  List<Requirement> needs = const [],
  List<Situation> situations = const [],
}) => ContentItem(
  id: id,
  kind: ContentKind.audioGame,
  title: id,
  parentDescription: '',
  ageMin: min,
  ageMax: max,
  durationSec: seconds,
  access: access,
  audio: const [AssetRef(path: 'test.m4a', bytes: 1, sha256: 'unused')],
  requirements: needs,
  situations: situations,
);
void main() {
  test('rescue respects the time budget, age range, access and every material', () {
    final items = [
      sample('fits'),
      sample('too long', seconds: 1201),
      sample('too old', min: 7),
      sample('too young', max: 4),
      sample('locked', access: ContentAccess.paid),
      sample('needs paper', needs: [Requirement.kartkaIOlowek]),
    ];
    final picks = rescuePicks(
      items,
      minutes: 20,
      age: 6,
      mood: ChildMood.bored,
      available: {},
      canPlay: (i) => i.isFree,
    );
    expect(picks.map((i) => i.id), ['fits']);
    expect(
      rescuePicks(
        items,
        minutes: 20,
        age: 6,
        mood: ChildMood.bored,
        available: {Requirement.kartkaIOlowek},
        canPlay: (i) => i.isFree,
      ).map((i) => i.id),
      contains('needs paper'),
    );
  });
  test('sleep recommendations contain only bedtime recordings', () {
    final items = [
      sample('active'),
      sample('night', situations: [Situation.przedSnem]),
    ];
    expect(
      rescuePicks(
        items,
        minutes: 20,
        age: 6,
        mood: ChildMood.sleepy,
        available: {},
        canPlay: (_) => true,
      ).map((i) => i.id),
      ['night'],
    );
  });
  test('queue, routine and mascot preference survive restarting the container', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    var container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    await container.read(discoveryProvider.future);
    final controller = container.read(discoveryProvider.notifier);
    await controller.add('one');
    await controller.add('one');
    await controller.add('two');
    await controller.setQueue(['two', 'one']);
    await controller.saveRoutine('Obiad');
    await controller.quiet(true);
    await controller.shown('2026-10-02');
    container.dispose();
    container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    final restored = await container.read(discoveryProvider.future);
    expect(restored.queue, ['two', 'one']);
    expect(restored.routines.single.items, ['two', 'one']);
    expect(restored.quiet, isTrue);
    expect(restored.cameoDay, '2026-10-02');
    await container.read(discoveryProvider.notifier).setQueue(['one']);
    expect(container.read(discoveryProvider).value!.routines.single.items, ['two', 'one']);
  });
}
