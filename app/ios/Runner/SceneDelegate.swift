import AppIntents
import CarPlay
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

// CarPlay (audio apps, iOS 14+): the same shelves as on Android Auto (Na drogę, Pobrane,
// Piosenki, Na dobranoc), asked from the Dart side over `pl.audiokiddo/carplay`; a tap plays
// and shows the system Now Playing screen, which audio_service already fills. It appears in
// the car once Apple grants the CarPlay audio entitlement (docs/CARPLAY.md).
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
  private var interface: CPInterfaceController?

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController
  ) {
    interface = interfaceController
    interfaceController.setRootTemplate(CPListTemplate(title: "AudioKiddo", sections: []), animated: false, completion: nil)
    reload()
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didDisconnectInterfaceController interfaceController: CPInterfaceController
  ) {
    interface = nil
  }

  private func reload() {
    guard let channel = CarPlayBridge.channel else {
      return message("Otwórz AudioKiddo na telefonie, żeby wczytać zabawy.")
    }
    channel.invokeMethod("shelves", arguments: nil) { [weak self] result in
      guard let self else { return }
      guard let shelves = result as? [[String: Any]], !shelves.isEmpty else {
        return self.message("Otwórz AudioKiddo na telefonie, żeby wczytać zabawy.")
      }
      let sections = shelves.map { shelf -> CPListSection in
        let items = (shelf["items"] as? [[String: Any]] ?? []).map { raw -> CPListItem in
          let item = CPListItem(text: raw["title"] as? String, detailText: raw["detail"] as? String)
          if let path = raw["image"] as? String, let image = UIImage(contentsOfFile: path) {
            item.setImage(image)
          }
          let id = raw["id"] as? String ?? ""
          item.handler = { [weak self] _, done in
            channel.invokeMethod("play", arguments: id) { _ in
              self?.interface?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
              done()
            }
          }
          return item
        }
        return CPListSection(items: items, header: shelf["title"] as? String, sectionIndexTitle: nil)
      }
      self.interface?.setRootTemplate(
        CPListTemplate(title: "AudioKiddo", sections: sections), animated: false, completion: nil)
    }
  }

  private func message(_ text: String) {
    let item = CPListItem(text: text, detailText: nil)
    item.handler = { [weak self] _, done in
      self?.reload()
      done()
    }
    interface?.setRootTemplate(
      CPListTemplate(title: "AudioKiddo", sections: [CPListSection(items: [item])]), animated: false, completion: nil)
  }
}

/// The channel to the Dart side, set when the Flutter engine starts (AppDelegate).
enum CarPlayBridge {
  static var channel: FlutterMethodChannel?
}
