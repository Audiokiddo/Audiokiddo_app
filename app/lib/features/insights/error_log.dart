import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/storage/database.dart';

/// Crashes and errors go to our own database (table app_errors), because the Kids Category
/// allows no Crashlytics or Sentry. Each error once per launch, at most [maxPerLaunch];
/// e-mails and long numbers are blanked; nothing about the child. Errors that could not be
/// sent (offline) wait on the phone and go with the next launch.
class ErrorLog {
  ErrorLog({
    required this.send,
    required this.installId,
    this.userId,
    this.appVersion,
    this.platform,
    this.osVersion,
    AppDatabase? database,
  }) : _db = database;

  /// Inserts one row; throws when it could not.
  final Future<void> Function(Map<String, Object?> row) send;
  final Future<String> Function() installId;
  final String? Function()? userId;
  final String? appVersion;
  final String? platform;
  final String? osVersion;
  final AppDatabase? _db;

  static const maxPerLaunch = 20;
  static const _pendingKey = 'pending_errors';

  final _seen = <String>{};
  var _count = 0;

  /// Catches what Flutter and the platform report, then sends what waited from last time.
  void install() {
    final flutter = FlutterError.onError;
    FlutterError.onError = (details) {
      flutter?.call(details);
      record(details.exception, details.stack, kind: 'flutter');
    };
    final platformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack, kind: 'async');
      return platformHandler?.call(error, stack) ?? false;
    };
    unawaited(_flushPending());
  }

  /// Network trouble is normal on a phone (car, plane, lift): not an error of the app.
  static bool isNoise(Object error) {
    final type = error.runtimeType.toString();
    return error is SocketException ||
        error is TimeoutException ||
        error is HttpException ||
        error is HandshakeException ||
        type.contains('ClientException') ||
        type.contains('AuthRetryableFetchException');
  }

  /// Blanks what could identify a person: e-mail addresses and long numbers.
  static String scrub(String text) => text
      .replaceAll(RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'), '<e-mail>')
      .replaceAll(RegExp(r'\d{6,}'), '<liczba>');

  /// The first line of the stack that is our own code, else the first line.
  static String origin(String stack) {
    final lines = stack.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return lines.firstWhere((l) => l.contains('package:audiokiddo/'), orElse: () => lines.firstOrNull ?? '');
  }

  /// Same type, same place in our code: one group (FNV-1a, 8 hex characters).
  static String fingerprint(String type, String stack) {
    // Line and column numbers change between versions; the function and file do not.
    final where = origin(stack).replaceAll(RegExp(r':\d+(:\d+)?\)?'), '').replaceAll(RegExp(r'^#\d+\s+'), '');
    var hash = 0x811c9dc5;
    for (final unit in utf8.encode('$type|$where')) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  void record(Object error, StackTrace? stack, {String kind = 'flutter'}) {
    if (isNoise(error) || _count >= maxPerLaunch) return;
    final type = error.runtimeType.toString();
    final trace = (stack ?? StackTrace.empty).toString();
    final print = fingerprint(type, trace);
    if (!_seen.add(print)) return;
    _count++;
    unawaited(_deliver({
      'kind': kind,
      'error_type': type.length > 120 ? type.substring(0, 120) : type,
      'message': _cut(scrub(error.toString()), 1000),
      'stack': _cut(scrub(trace.split('\n').take(40).join('\n')), 4000),
      'fingerprint': print,
      'app_version': appVersion,
      'platform': platform,
      'os_version': osVersion == null ? null : _cut(osVersion!, 80),
    }));
  }

  Future<void> _deliver(Map<String, Object?> row) async {
    try {
      await send({...row, 'install_id': await installId(), 'user_id': userId?.call()});
    } on Object catch (e) {
      debugPrint('error log: not sent ($e)');
      await _keep(row);
    }
  }

  Future<void> _keep(Map<String, Object?> row) async {
    final db = _db;
    if (db == null) return;
    try {
      final list = _decode(await db.readValue(_pendingKey))..add(row);
      await db.writeValue(_pendingKey, jsonEncode(list.length > maxPerLaunch ? list.sublist(list.length - maxPerLaunch) : list));
    } on Object {
      // The log must never break the app.
    }
  }

  Future<void> _flushPending() async {
    final db = _db;
    if (db == null) return;
    try {
      final list = _decode(await db.readValue(_pendingKey));
      if (list.isEmpty) return;
      await db.deleteValue(_pendingKey);
      for (final row in list) {
        await _deliver(row);
      }
    } on Object {
      // Next time.
    }
  }

  static List<Map<String, Object?>> _decode(String? raw) {
    if (raw == null) return [];
    final value = jsonDecode(raw);
    return [
      if (value is List)
        for (final r in value)
          if (r is Map) Map<String, Object?>.from(r),
    ];
  }

  static String _cut(String text, int max) => text.length > max ? text.substring(0, max) : text;
}
