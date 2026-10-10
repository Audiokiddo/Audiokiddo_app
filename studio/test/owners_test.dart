import 'package:audiokiddo_studio/crm/owners.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creative work goes to Nela, technical to Dawid, Claude counts as Dawid', () {
    expect(suggestOwner({'title': 'Napisać scenariusz zabawy o smoku', 'area': 'scenario'}), Owner.nela);
    expect(suggestOwner({'title': 'Zmontować rolkę na TikToka'}), Owner.nela);
    expect(suggestOwner({'title': 'Przygotować grafiki do sklepu'}), Owner.nela);
    expect(suggestOwner({'title': 'Naprawić błąd w aplikacji', 'area': 'feature'}), Owner.dawid);
    expect(suggestOwner({'title': 'Raport sprzedaży za wrzesień'}), Owner.dawid);
    expect(suggestOwner({'title': 'Grafiki do App Store w aplikacji', 'area': 'launch'}), Owner.nela);
    expect(suggestOwner({'title': 'Założyć konto Apple Developer', 'area': 'launch'}), Owner.dawid);
    expect(suggestOwner({'title': 'Pomysł na nową zabawę', 'area': 'pack'}), Owner.nela);
    expect(Owner.of('Claude'), Owner.dawid);
    expect(Owner.of('Razem'), Owner.razem);
    expect(Owner.of(null), isNull);
  });
}
