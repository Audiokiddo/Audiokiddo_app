import 'dart:convert';
import 'dart:io';

import 'package:audiokiddo_studio/io/studio_io.dart';
import 'package:audiokiddo_studio/main.dart';
import 'package:audiokiddo_studio/screens/script_editor.dart';
import 'package:audiokiddo_studio/state/studio_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final appCatalog = File('../app/assets/mock/catalog.json').readAsStringSync();

class FakeIo implements StudioIo {
  String? draft;
  String? importFile;
  PickedAsset? asset;
  final downloads = <String, String>{};

  @override
  Future<String?> readDraft() async => draft;

  @override
  Future<String?> readStarterCatalog() async => null;
  @override
  Future<void> writeDraft(String json) async => draft = json;
  @override
  Future<String?> pickCatalogJson() async => importFile;
  @override
  Future<PickedAsset?> pickAsset({required List<String> extensions}) async => asset;
  @override
  void download(String fileName, String content) => downloads[fileName] = content;
}

Future<ProviderContainer> loaded(FakeIo io) async {
  final c = ProviderContainer(overrides: [studioIoProvider.overrideWithValue(io)]);
  c.read(studioProvider);
  await Future<void>.delayed(Duration.zero);
  return c;
}

void main() {
  test('the app catalog imports and validates cleanly', () async {
    final c = await loaded(FakeIo());
    addTearDown(c.dispose);
    c.read(studioProvider.notifier).importCatalog(appCatalog);
    final v = c.read(validationProvider);
    // Every item of the catalog comes in (the count changes whenever an activity is added).
    expect(
      c.read(studioProvider).items,
      hasLength(((jsonDecode(appCatalog) as Map<String, Object?>)['items']! as List).length),
    );
    expect(v.canPublish, isTrue, reason: '${v.itemErrors} ${v.otherErrors}');
  });

  test('broken items are reported with the reason the app would hide them', () async {
    final c = await loaded(FakeIo());
    addTearDown(c.dispose);
    final studio = c.read(studioProvider.notifier)..importCatalog(appCatalog);
    studio.updateItem('mikstura', (i) => i['audio'] = <Object?>[]);
    studio.updateItem('mistrz-kuchni', (i) => i['pack_id'] = 'nie-ma');
    final v = c.read(validationProvider);
    expect(v.itemErrors['mikstura'], 'Brak nagrania: wybierz plik audio');
    expect(v.itemErrors['mistrz-kuchni'], 'Nieznany pakiet "nie-ma"');
    expect(v.canPublish, isFalse);
  });

  test('renaming an item updates the shelves; deleting removes it from them', () async {
    final c = await loaded(FakeIo());
    addTearDown(c.dispose);
    final studio = c.read(studioProvider.notifier)..importCatalog(appCatalog);
    studio.renameItem('zaginiony-skarb', 'skarb');
    final shelves = c.read(studioProvider).shelves;
    expect((shelves.first['item_ids'] as List), ['skarb']);
    studio.deleteItem('skarb');
    expect(c.read(studioProvider).shelves.every((s) => !(s['item_ids'] as List).contains('skarb')), isTrue);
    expect(c.read(validationProvider).otherErrors, isEmpty);
  });

  test('shelf pointing to a missing item is flagged', () async {
    final c = await loaded(FakeIo());
    addTearDown(c.dispose);
    c.read(studioProvider.notifier)
      ..importCatalog(appCatalog)
      ..update((cat) => ((cat['shelves'] as List).first as Json)['item_ids'] = ['duch']);
    expect(c.read(validationProvider).otherErrors.single, contains('duch'));
  });

  test('new interactive game from the template is valid once its recordings exist', () async {
    final c = await loaded(FakeIo());
    addTearDown(c.dispose);
    final studio = c.read(studioProvider.notifier)..importCatalog(appCatalog);
    final script = scriptTemplate('zgadnij');
    expect(scriptIssues(script, errorsOnly: true), [
      'Błąd w kroku „intro”: nieznane nagranie „intro” (dodaj je w sekcji Nagrania)',
      'Błąd w kroku „answer”: nieznane nagranie „answer” (dodaj je w sekcji Nagrania)',
    ]);
    script['assets'] = {
      'intro': {'path': 'games/zgadnij/intro.m4a', 'bytes': 10, 'sha256': 'x'},
      'answer': {'path': 'games/zgadnij/answer.m4a', 'bytes': 10, 'sha256': 'x'},
    };
    expect(scriptIssues(script, errorsOnly: true), isEmpty);
    studio.addItem({
      'id': 'zgadnij',
      'kind': 'interactive_game',
      'title': 'Zgadnij',
      'parent_description': 'd',
      'age_min': 3,
      'duration_sec': 300,
      'access': 'paid',
      'script': script,
    });
    expect(c.read(validationProvider).itemErrors['zgadnij'], isNull);
  });

  test('export bumps the version and the draft survives a reload', () async {
    final io = FakeIo();
    final c = await loaded(io);
    addTearDown(c.dispose);
    final studio = c.read(studioProvider.notifier)..importCatalog(appCatalog);
    final exported = jsonDecode(studio.exportForPublishing()) as Json;
    expect(exported['version'], 2);
    await Future<void>.delayed(const Duration(milliseconds: 500)); // autosave debounce
    final reloaded = await loaded(io);
    addTearDown(reloaded.dispose);
    expect(reloaded.read(studioProvider).catalog['version'], 2);
  });

  testWidgets('editing a title in the UI updates the catalog', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final io = FakeIo()..draft = appCatalog;
    await tester.pumpWidget(
      ProviderScope(overrides: [studioIoProvider.overrideWithValue(io)], child: const StudioApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Katalog gotowy'), findsOneWidget);

    await tester.tap(find.text('Magiczny sklep'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Tytuł'), 'Magiczny sklepik');
    await tester.pumpAndSettle();
    expect(find.text('Magiczny sklepik'), findsWidgets);

    await tester.tap(find.text('Publikacja'));
    await tester.pumpAndSettle();
    expect(find.text('Katalog jest poprawny'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });

  test('messages name the field in Polish', () async {
    final c = await loaded(FakeIo());
    addTearDown(c.dispose);
    c.read(studioProvider.notifier)
      ..importCatalog(appCatalog)
      ..updateItem('mikstura', (i) => i['parent_description'] = '')
      ..updateItem('mistrz-kuchni', (i) => i['age_min'] = 99);
    final v = c.read(validationProvider);
    expect(v.itemErrors['mikstura'], 'Opis dla rodzica: nie może być puste');
    expect(v.itemErrors['mistrz-kuchni'], 'Wiek od: może być najwyżej 18');
  });
}
