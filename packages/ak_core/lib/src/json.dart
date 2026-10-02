/// Thrown when a JSON document does not match the expected shape.
class FormatError implements Exception {
  FormatError(this.path, this.message);

  /// Dotted path to the offending field, e.g. `items[3].duration_sec`.
  final String path;
  final String message;

  @override
  String toString() => '$path: $message';
}

/// Typed accessors over a decoded JSON object that report the field path on error.
class JsonReader {
  JsonReader(this.json, [this.path = r'$']);

  final Map<String, Object?> json;
  final String path;

  static JsonReader of(Object? value, String path) {
    if (value is Map<String, Object?>) return JsonReader(value, path);
    throw FormatError(path, 'expected an object');
  }

  bool has(String key) => json.containsKey(key) && json[key] != null;

  String string(String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatError('$path.$key', 'expected a non-empty string');
  }

  String? optString(String key) => has(key) ? string(key) : null;

  /// A calendar day written as `YYYY-MM-DD` (release dates), or null when absent.
  DateTime? optDate(String key) {
    if (!has(key)) return null;
    final raw = string(key);
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
    final date = match == null
        ? null
        : DateTime(int.parse(match[1]!), int.parse(match[2]!), int.parse(match[3]!));
    if (date == null || date.month != int.parse(match![2]!) || date.day != int.parse(match[3]!)) {
      throw FormatError('$path.$key', 'expected a date YYYY-MM-DD');
    }
    return date;
  }

  /// A day of any year written as `MM-DD` (seasons), or null when absent.
  String? optMonthDay(String key) {
    if (!has(key)) return null;
    final raw = string(key);
    final match = RegExp(r'^(\d{2})-(\d{2})$').firstMatch(raw);
    final month = match == null ? 0 : int.parse(match[1]!);
    final day = match == null ? 0 : int.parse(match[2]!);
    if (month < 1 || month > 12 || day < 1 || day > DateTime(2024, month + 1, 0).day) {
      throw FormatError('$path.$key', 'expected a day MM-DD');
    }
    return raw;
  }

  int integer(String key, {int? min, int? max}) {
    final value = json[key];
    if (value is! int) throw FormatError('$path.$key', 'expected an integer');
    if (min != null && value < min) {
      throw FormatError('$path.$key', 'must be >= $min');
    }
    if (max != null && value > max) {
      throw FormatError('$path.$key', 'must be <= $max');
    }
    return value;
  }

  int? optInteger(String key, {int? min, int? max}) => has(key) ? integer(key, min: min, max: max) : null;

  bool boolean(String key, {bool fallback = false}) {
    if (!has(key)) return fallback;
    final value = json[key];
    if (value is bool) return value;
    throw FormatError('$path.$key', 'expected a boolean');
  }

  List<String> strings(String key) {
    if (!has(key)) return const [];
    final value = json[key];
    if (value is List && value.every((e) => e is String)) {
      return List.unmodifiable(value.cast<String>());
    }
    throw FormatError('$path.$key', 'expected a list of strings');
  }

  List<Object?> list(String key) {
    if (!has(key)) return const [];
    final value = json[key];
    if (value is List) return value;
    throw FormatError('$path.$key', 'expected a list');
  }

  JsonReader object(String key) => JsonReader.of(json[key], '$path.$key');

  JsonReader? optObject(String key) => has(key) ? object(key) : null;

  T enumValue<T extends Enum>(String key, List<T> values) {
    final raw = string(key);
    for (final v in values) {
      if (_wireName(v.name) == raw) return v;
    }
    throw FormatError('$path.$key', 'unknown value "$raw"');
  }
}

/// Enum names are camelCase in Dart and snake_case on the wire.
String _wireName(String dartName) =>
    dartName.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');

String wireName(Enum value) => _wireName(value.name);
