import 'package:ak_core/ak_core.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeSpoken', () {
    test('lower case, no Polish letters, no punctuation', () {
      expect(normalizeSpoken('Dziękuję!'), 'dziekuje');
      expect(normalizeSpoken('  Łąka, ŻÓŁW  i   Ćma '), 'laka zolw i cma');
      expect(normalizeSpoken('...'), '');
    });
  });

  test('numeric recognition and spoken numbers select the same answer', () {
    final matcher = WordMatcher(['trzy', 'cztery', 'pięć']);
    expect(matcher.match('3'), 'trzy');
    expect(matcher.match('chyba 5'), 'pięć');
    expect(matcher.match('3 albo 4'), isNull);
    expect(matcher.match('13'), isNull);
  });

  group('WordMatcher', () {
    final matcher = WordMatcher(['lewo', 'w lewo', 'prawo', 'prosto', 'dziękuję', 'tak', 'nie']);

    test('finds a word inside what was said, ignoring case and diacritics', () {
      expect(matcher.match('Chcę iść PROSTO'), 'prosto');
      expect(matcher.match('dziekuje bardzo'), 'dziękuję');
      expect(matcher.match('tak'), 'tak');
    });

    test('two different words are never guessed', () {
      expect(matcher.match('lewo albo prawo'), isNull);
      expect(matcher.match('tak nie wiem'), isNull, reason: 'tak and nie both heard');
    });

    test('one wrong letter is forgiven in longer words only', () {
      expect(matcher.match('lewa'), isNull, reason: 'four letters: exact only');
      expect(matcher.match('prosta'), 'prosto');
      expect(matcher.match('dziekuja'), 'dziękuję');
      expect(matcher.match('prosztto'), isNull, reason: 'two letters off');
    });

    test('a word close to two vocabulary words is not guessed', () {
      final pair = WordMatcher(['koszyk', 'koszek']);
      expect(pair.match('koszak'), isNull, reason: 'one letter off from both');
      expect(pair.match('koszyk'), 'koszyk');
    });

    test('words are whole words, phrases match as phrases', () {
      expect(matcher.match('lewościsko'), isNull);
      expect(matcher.match('w lewo'), 'w lewo');
      expect(matcher.match('nie ma'), 'nie');
    });

    test('nothing heard, nothing matched', () {
      expect(matcher.match(''), isNull);
      expect(matcher.match('mamo patrz'), isNull);
      expect(WordMatcher(const []).match('tak'), isNull);
    });
  });
}
