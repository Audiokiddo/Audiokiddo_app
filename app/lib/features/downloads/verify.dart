import 'dart:io';

import 'package:crypto/crypto.dart';

/// True when the file at [path] has exactly [bytes] bytes and the given SHA-256 (hex).
/// Streams the file, so it is safe for long recordings; run it in an isolate.
Future<bool> verifyFile(String path, {required int bytes, required String sha256Hex}) async {
  final file = File(path);
  if (!await file.exists() || await file.length() != bytes) return false;
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString() == sha256Hex.toLowerCase();
}
