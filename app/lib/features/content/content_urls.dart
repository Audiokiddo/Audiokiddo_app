import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/foundation.dart';

/// Where a catalog file can be fetched from. Etap 3 replaces the dev server with
/// short-lived signed URLs issued by the server after an entitlement check.
abstract interface class ContentUrlResolver {
  Future<Uri> urlFor(AssetRef asset);
}

class BaseUrlResolver implements ContentUrlResolver {
  const BaseUrlResolver(this.baseUrl);

  final String baseUrl;

  @override
  Future<Uri> urlFor(AssetRef asset) async => Uri.parse('$baseUrl/${asset.path}');
}

/// The file cannot be fetched now (no access, offline, server trouble). Downloads fail with a
/// retry; playback shows its usual message. Never thrown while the app starts.
class ContentUnavailable implements Exception {
  const ContentUnavailable(this.reason);

  final String reason;

  @override
  String toString() => 'ContentUnavailable($reason)';
}

/// Store builds: a short-lived signed link from the download-url function, issued after the
/// server checked access (audit 2026-09-28, P1-6). [sign] returns null when it cannot.
class SignedUrlResolver implements ContentUrlResolver {
  const SignedUrlResolver(this._sign);

  final Future<Uri?> Function(String path) _sign;

  @override
  Future<Uri> urlFor(AssetRef asset) async =>
      await _sign(asset.path) ?? (throw ContentUnavailable(asset.path));
}

/// Debug: the local server started with tool/dev_server.py. Store builds: signed links.
/// Override either with `--dart-define=CONTENT_BASE_URL=...`.
ContentUrlResolver defaultContentUrlResolver(Future<Uri?> Function(String path) sign) {
  const override = String.fromEnvironment('CONTENT_BASE_URL');
  if (override.isNotEmpty) return const BaseUrlResolver(override);
  if (kDebugMode) {
    // The Android emulator reaches the host computer at 10.0.2.2.
    return BaseUrlResolver(Platform.isAndroid ? 'http://10.0.2.2:8787' : 'http://127.0.0.1:8787');
  }
  return SignedUrlResolver(sign);
}
