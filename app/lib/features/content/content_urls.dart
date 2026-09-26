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

/// Local server started with `python3 -m http.server 8787 -d dev_content` (see tool/dev_content.py).
/// Override with `--dart-define=CONTENT_BASE_URL=...`.
ContentUrlResolver defaultContentUrlResolver() {
  const override = String.fromEnvironment('CONTENT_BASE_URL');
  if (override.isNotEmpty) return const BaseUrlResolver(override);
  if (kDebugMode) {
    // The Android emulator reaches the host computer at 10.0.2.2.
    return BaseUrlResolver(Platform.isAndroid ? 'http://10.0.2.2:8787' : 'http://127.0.0.1:8787');
  }
  throw UnsupportedError('Content server is configured in Etap 3');
}
