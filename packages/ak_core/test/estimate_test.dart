import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:test/test.dart';

void main() {
  test('a branching story is timed by its shortest way to an end, and ends at zero', () {
    final catalog = parseCatalog(
      jsonDecode(File('../../app/assets/mock/catalog.json').readAsStringSync()) as Map<String, Object?>,
    ).catalog;
    final script = catalog.item('zgubiona-gwiazdka')!.script!;
    final whole = estimatedSecondsLeft(script, script.start);
    expect(whole, inInclusiveRange(60, 8 * 60));
    final end = script.steps.values.whereType<EndStep>().first;
    expect(estimatedSecondsLeft(script, end.id), lessThan(60));
  });
}
