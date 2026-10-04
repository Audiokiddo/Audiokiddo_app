import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DeviceStoragePlugin") {
      DeviceStoragePlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LaunchRoutePlugin") {
      LaunchRoutePlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppIconPlugin") {
      AppIconPlugin.register(with: registrar)
    }
  }
}

/// Free disk space and backup exclusion for downloaded recordings (`pl.audiokiddo/storage`).
final class DeviceStoragePlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "pl.audiokiddo/storage", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(DeviceStoragePlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "freeBytes":
      let home = URL(fileURLWithPath: NSHomeDirectory())
      let values = try? home.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
      result(values?.volumeAvailableCapacityForImportantUsage.map { NSNumber(value: $0) })
    case "excludeFromBackup":
      guard let path = (call.arguments as? [String: Any])?["path"] as? String else {
        result(FlutterError(code: "bad_args", message: "path required", details: nil))
        return
      }
      var url = URL(fileURLWithPath: path)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      do {
        try url.setResourceValues(values)
        result(nil)
      } catch {
        result(FlutterError(code: "io", message: error.localizedDescription, details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

/// The home-screen icon the parent picked (`pl.audiokiddo/icon`). Only on request: Apple
/// allows alternate icons chosen by the user, never changed automatically (guideline 4.6).
final class AppIconPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "pl.audiokiddo/icon", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(AppIconPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "supported":
      result(UIApplication.shared.supportsAlternateIcons)
    case "current":
      result(UIApplication.shared.alternateIconName)
    case "set":
      let name = (call.arguments as? [String: Any])?["name"] as? String
      UIApplication.shared.setAlternateIconName(name) { error in
        DispatchQueue.main.async {
          if let error = error {
            result(FlutterError(code: "icon", message: error.localizedDescription, details: nil))
          } else {
            result(nil)
          }
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
