import 'package:audiokiddo/features/family_sharing/grandparents.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the message for grandparents: the app, what the child likes, how it works, plainly', () {
    final m = grandparentsMessage(childName: 'Zosia', favorites: ['Magiczny sklep', 'Mikstura']);
    expect(m, contains('https://audiokiddo.pl'));
    expect(m, contains('Najbardziej lubi: „Magiczny sklep”, „Mikstura”.'));
    expect(m, contains('telefon ekranem w dół'));
    expect(m, contains('Zosia odpowiada na głos'));
    expect(m, isNot(contains('!')));
    expect(grandparentsMessage(), isNot(contains('Najbardziej lubi')));
  });
}
