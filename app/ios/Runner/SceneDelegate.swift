import AppIntents
import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  // Quick actions on the app icon (Info.plist, UIApplicationShortcutItems): the type is the
  // route, e.g. "/dobranoc". The same screens open from the widget and from Siri/Shortcuts.
  override func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    if let item = connectionOptions.shortcutItem {
      // Cold start: the Dart side asks for it once its router is up (LaunchRoutePlugin).
      AppRoutes.open(item.type)
    }
  }

  override func windowScene(
    _ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    completionHandler(AppRoutes.open(shortcutItem.type))
  }
}

/// Opens a screen of the Flutter app (go_router path). Before the Dart side has started,
/// the route waits in [pending] and Dart takes it once its router is ready.
enum AppRoutes {
  static let allowed: Set<String> = ["/", "/dobranoc", "/podroz"]
  static var pending: String?
  static var dartReady = false

  @discardableResult
  static func open(_ route: String) -> Bool {
    guard allowed.contains(route) else { return false }
    let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    if dartReady, let flutter = scene?.windows.first?.rootViewController as? FlutterViewController {
      flutter.pushRoute(route)
    } else {
      pending = route
    }
    return true
  }
}

/// `pl.audiokiddo/launch`: Dart takes the screen a shortcut asked for at launch.
final class LaunchRoutePlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "pl.audiokiddo/launch", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(LaunchRoutePlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "takePendingRoute" else { return result(FlutterMethodNotImplemented) }
    AppRoutes.dartReady = true
    result(AppRoutes.pending)
    AppRoutes.pending = nil
  }
}

// Siri, Spotlight, the Shortcuts app and the Action Button (iOS 16+). Siri itself does not
// speak Polish, so the Polish phrases work in Spotlight and Shortcuts; the English ones by voice.
@available(iOS 16.0, *)
struct BedtimeIntent: AppIntent {
  static var title: LocalizedStringResource = "Dobranoc z Szop’enem"
  static var description = IntentDescription("Wieczorny rytuał: oddechy, cicha zabawa, kołysanka i dobranoc.")
  static var openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    AppRoutes.open("/dobranoc")
    return .result()
  }
}

@available(iOS 16.0, *)
struct TripIntent: AppIntent {
  static var title: LocalizedStringResource = "W drogę z Szop’enem"
  static var description = IntentDescription("Zabawy i piosenki na całą trasę, z przerwami na wyglądanie przez okno.")
  static var openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    AppRoutes.open("/podroz")
    return .result()
  }
}

@available(iOS 16.0, *)
struct KiddoShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: BedtimeIntent(),
      phrases: [
        "Dobranoc z \(.applicationName)",
        "\(.applicationName) dobranoc",
        "Goodnight with \(.applicationName)",
      ],
      shortTitle: "Dobranoc",
      systemImageName: "moon.stars.fill"
    )
    AppShortcut(
      intent: TripIntent(),
      phrases: [
        "W drogę z \(.applicationName)",
        "\(.applicationName) w drogę",
        "Road trip with \(.applicationName)",
      ],
      shortTitle: "W drogę",
      systemImageName: "car.fill"
    )
  }
}
