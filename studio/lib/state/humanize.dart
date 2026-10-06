import 'package:ak_core/ak_core.dart';

/// Turns ak_core's technical validation messages into Polish sentences for Dawid and Nela.
const _fields = {
  'id': 'ID',
  'kind': 'Rodzaj',
  'pack_id': 'Pakiet',
  'title': 'Tytuł',
  'parent_description': 'Opis dla rodzica',
  'age_min': 'Wiek od',
  'duration_sec': 'Czas',
  'access': 'Dostęp',
  'audio': 'Nagranie',
  'pdf': 'Plik PDF',
  'situations': 'Kiedy się sprawdza',
  'requirements': 'Co będzie potrzebne',
  'script': 'Skrypt',
  'path': 'ścieżka pliku',
  'bytes': 'rozmiar pliku',
  'sha256': 'suma kontrolna',
};

String humanizeIssue(String path, String reason) {
  final field = RegExp(r'\.([a-z_0-9]+)(\[\d+\])?$').firstMatch(path.split(' ').first)?.group(1);
  final label = field == null ? null : _fields[field] ?? field;
  final what = switch (reason) {
    'expected a non-empty string' => 'nie może być puste',
    'expected an integer' => 'musi być liczbą',
    'expected an object' || 'expected a list' || 'expected a list of strings' => 'ma zły format',
    'no audio file' => 'brak nagrania: wybierz plik audio',
    'duplicate id' => 'to ID już istnieje',
    'interactive games need a script' => 'gra interaktywna potrzebuje skryptu',
    _ when reason.startsWith('must be >= ') => 'musi być co najmniej ${reason.substring(11)}',
    _ when reason.startsWith('must be <= ') => 'może być najwyżej ${reason.substring(11)}',
    _ when reason.startsWith('unknown pack') => 'nieznany pakiet ${reason.substring(13)}',
    _ when reason.startsWith('unknown value') => 'nieznana wartość ${reason.substring(14)}',
    _ when reason.startsWith('needs a newer app') => 'wymaga nowszej wersji aplikacji',
    _ when reason.startsWith('invalid script: ') => 'błąd w skrypcie (${reason.substring(16)})',
    _ => reason,
  };
  return label == null ||
          reason == 'no audio file' ||
          reason == 'duplicate id' ||
          reason.startsWith('unknown pack') ||
          reason.startsWith('invalid script') ||
          reason.startsWith('needs a newer')
      ? _capitalize(what)
      : '$label: $what';
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Script validator messages in Polish: "Błąd w kroku „pytanie”: nieznane nagranie „krowa”".
String humanizeScriptIssue(ScriptIssue issue) {
  String quoted(String m) => RegExp('"([^"]*)"').firstMatch(m)?.group(1) ?? '';
  final m = issue.message;
  final text = switch (m) {
    _ when m.startsWith('unknown asset') => 'nieznane nagranie „${quoted(m)}” (dodaj je w sekcji Nagrania)',
    _ when m.startsWith('jumps to missing step') => 'prowadzi do nieistniejącego kroku „${quoted(m)}”',
    _ when m.startsWith('missing fallback') => 'brakuje wariantu bez mikrofonu / przy zablokowanym ekranie',
    _ when m.startsWith('loop without max_visits') =>
      'pętla bez limitu przejść (ustaw „Maksymalna liczba przejść”)',
    _ when m.startsWith('no path from this step') => 'z tego kroku nie da się dojść do końca zabawy',
    _ when m.startsWith('step is never reached') => 'ten krok nigdy nie zostanie użyty',
    _ when m.startsWith('undeclared variable') => 'nieznana zmienna „${quoted(m)}”',
    _ when m.startsWith('wait longer') => 'czekanie może trwać najwyżej 120 s',
    _ when m.startsWith('input window longer') => 'nasłuch może trwać najwyżej 30 s',
    _ when m.startsWith('start step') => 'brak kroku startowego „${quoted(m)}”',
    _ when m.startsWith('script has no end step') => 'skrypt nie ma kroku „Koniec”',
    _ when m.contains('is not supported by this engine') =>
      'ten rodzaj nasłuchu nie jest jeszcze obsługiwany',
    _ when m.startsWith('requires engine') => 'wymaga nowszej wersji aplikacji',
    _ => m,
  };
  final prefix = issue.severity == IssueSeverity.error ? 'Błąd' : 'Uwaga';
  final step = issue.stepId?.split(' ').first;
  return step == null ? '$prefix: $text' : '$prefix w kroku „$step”: $text';
}
