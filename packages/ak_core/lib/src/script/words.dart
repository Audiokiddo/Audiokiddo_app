/// Matching what a child said against the words a game listens for (engine 3).
///
/// Speech recognition of small children is imperfect: it drops sounds, swaps letters and
/// hears neighbours ("lewo" as "lego"). The matcher is therefore forgiving in two ways that
/// cannot confuse two words of one game: letters are compared without Polish diacritics and
/// case, and one wrong letter is tolerated in words of five letters or more. A word that
/// is close to two different vocabulary words is never guessed (the game asks again).
library;

/// "Dziękuję!" → "dziekuje": lower case, no Polish diacritics, letters and digits only.
String normalizeSpoken(String text) {
  const map = {'ą': 'a', 'ć': 'c', 'ę': 'e', 'ł': 'l', 'ń': 'n', 'ó': 'o', 'ś': 's', 'ź': 'z', 'ż': 'z'};
  final lower = text.toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    final plain = map[char] ?? char;
    final code = plain.codeUnitAt(0);
    final letter = (code >= 0x61 && code <= 0x7a) || (code >= 0x30 && code <= 0x39);
    out.write(letter ? plain : ' ');
  }
  return out.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

int _distance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      current[j] = [
        previous[j] + 1,
        current[j - 1] + 1,
        previous[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    previous = current;
  }
  return previous[b.length];
}

/// Finds which of the game's words a transcript contains.
class WordMatcher {
  /// [vocabulary]: every word or phrase the game accepts (any spelling, they are normalised).
  WordMatcher(Iterable<String> vocabulary)
    : _words = {for (final w in vocabulary) normalizeSpoken(w): w}..remove('');

  /// normalised word or phrase → the word as the script wrote it.
  final Map<String, String> _words;

  Iterable<String> get words => _words.values;

  /// The script word heard in [transcript], or null when nothing (or two different words)
  /// fits. Whole words only: "lewo" is not found inside "lewościsko".
  String? match(String transcript) {
    final text = normalizeSpoken(transcript);
    if (text.isEmpty) return null;
    final spoken = text.split(' ');
    final found = <String>{};
    for (final MapEntry(key: normal, value: original) in _words.entries) {
      final parts = normal.split(' ');
      if (_containsPhrase(spoken, parts)) found.add(original);
    }
    // "w lewo" contains "lewo": the longer phrase says more, so it wins over the word inside it.
    found.removeWhere(
      (w) => found.any((o) => o != w && normalizeSpoken(o).length > normalizeSpoken(w).length && _contains(o, w)),
    );
    if (found.length == 1) return found.single;
    if (found.length > 1) return null;
    // No exact hit: allow one wrong letter in longer words, if exactly one word is that close.
    final close = <String>{};
    for (final MapEntry(key: normal, value: original) in _words.entries) {
      if (normal.contains(' ') || normal.length < 5) {
        continue;
      }
      if (spoken.any((s) => (s.length - normal.length).abs() <= 1 && _distance(s, normal) <= 1)) {
        close.add(original);
      }
    }
    return close.length == 1 ? close.single : null;
  }

  static bool _contains(String longer, String shorter) =>
      ' ${normalizeSpoken(longer)} '.contains(' ${normalizeSpoken(shorter)} ');

  static bool _containsPhrase(List<String> spoken, List<String> phrase) {
    for (var i = 0; i + phrase.length <= spoken.length; i++) {
      var all = true;
      for (var j = 0; j < phrase.length; j++) {
        if (spoken[i + j] != phrase[j]) {
          all = false;
          break;
        }
      }
      if (all) return true;
    }
    return false;
  }
}
