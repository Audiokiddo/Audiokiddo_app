import 'package:flutter/services.dart';

/// Native helpers for downloads (see AppDelegate.swift and MainActivity.kt).
class DeviceStorage {
  const DeviceStorage();

  static const _channel = MethodChannel('pl.audiokiddo/storage');

  /// Free space usable for app data, or null when the platform cannot tell.
  Future<int?> freeBytes() async {
    try {
      return await _channel.invokeMethod<int>('freeBytes');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Keeps downloaded recordings out of iCloud backups (they can be downloaded again).
  Future<void> excludeFromBackup(String path) async {
    try {
      await _channel.invokeMethod<void>('excludeFromBackup', {'path': path});
    } on MissingPluginException {
      // Tests and platforms without the channel.
    }
  }
}
