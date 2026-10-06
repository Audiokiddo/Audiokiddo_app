import AVFoundation
import AVKit
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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AudioRoutePlugin") {
      AudioRoutePlugin.register(with: registrar)
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

/// Where the sound goes (`pl.audiokiddo/audio_route`): the system AirPlay and Bluetooth
/// picker, and the name of the current output, with an event on every change.
final class AudioRoutePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  /// Kept on screen (invisible) while the system sheet is open: the picker presents from it.
  private var picker: AVRoutePickerView?

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = AudioRoutePlugin()
    let channel = FlutterMethodChannel(name: "pl.audiokiddo/audio_route", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: channel)
    let events = FlutterEventChannel(name: "pl.audiokiddo/audio_route/events", binaryMessenger: registrar.messenger())
    events.setStreamHandler(instance)
    NotificationCenter.default.addObserver(
      instance, selector: #selector(routeChanged), name: AVAudioSession.routeChangeNotification, object: nil)
  }

  static func current() -> [String: Any] {
    guard let output = AVAudioSession.sharedInstance().currentRoute.outputs.first else {
      return ["name": "Głośnik", "kind": "speaker"]
    }
    let kind: String
    switch output.portType {
    case .builtInSpeaker, .builtInReceiver: kind = "speaker"
    case .headphones: kind = "headphones"
    case .bluetoothA2DP, .bluetoothLE, .bluetoothHFP: kind = "bluetooth"
    case .airPlay: kind = "airplay"
    case .carAudio: kind = "car"
    default: kind = "other"
    }
    let name = kind == "speaker" ? "Głośnik telefonu" : output.portName
    return ["name": name, "kind": kind]
  }

  @objc private func routeChanged() {
    DispatchQueue.main.async { self.sink?(AudioRoutePlugin.current()) }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "current":
      result(AudioRoutePlugin.current())
    case "pick":
      DispatchQueue.main.async {
        guard let window = UIApplication.shared.connectedScenes
          .compactMap({ ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) }).first
        else {
          result(false)
          return
        }
        self.picker?.removeFromSuperview()
        let picker = AVRoutePickerView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        picker.alpha = 0.011
        picker.prioritizesVideoDevices = false
        window.addSubview(picker)
        self.picker = picker
        // The picker opens the system sheet from its own button.
        if let button = picker.subviews.compactMap({ $0 as? UIButton }).first {
          button.sendActions(for: .touchUpInside)
          result(true)
        } else {
          result(false)
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    events(AudioRoutePlugin.current())
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
}
