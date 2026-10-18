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

// CarPlay (audio apps, iOS 14+): tabs asked from the Dart side over `pl.audiokiddo/carplay`
// (CarLibrary.carPlayLibrary): Na drogę, Ostatnie (with how far), Pakiety (each opens its plays)
// and Więcej (songs, bedtime, downloaded). A tap plays and shows the system Now Playing screen,
// which audio_service fills; there a loop button switches the same loop as in the app. The Dart
// side says "reload" when the lists change. It appears in the car once Apple grants the CarPlay
// audio entitlement (docs/CARPLAY.md).
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
  /// The car screen now connected, so a "reload" from the Dart side reaches it.
  static weak var current: CarPlaySceneDelegate?

  private var interface: CPInterfaceController?
  private var tabBar: CPTabBarTemplate?
  private var looping = false

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController
  ) {
    interface = interfaceController
    CarPlaySceneDelegate.current = self
    interfaceController.setRootTemplate(CPListTemplate(title: "audiokiddo", sections: []), animated: false, completion: nil)
    updateLoopButton()
    reload()
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didDisconnectInterfaceController interfaceController: CPInterfaceController
  ) {
    interface = nil
    tabBar = nil
    if CarPlaySceneDelegate.current === self { CarPlaySceneDelegate.current = nil }
  }

  func reload() {
    guard let channel = CarPlayBridge.channel else {
      return message("Otwórz audiokiddo na telefonie, żeby wczytać zabawy.")
    }
    channel.invokeMethod("library", arguments: nil) { [weak self] result in
      guard let self else { return }
      guard let library = result as? [String: Any], let tabs = library["tabs"] as? [[String: Any]], !tabs.isEmpty
      else {
        return self.message("Otwórz audiokiddo na telefonie, żeby wczytać zabawy.")
      }
      let playing = library["playing"] as? String
      self.looping = library["looping"] as? Bool ?? false
      self.updateLoopButton()
      let shown = Array(tabs.prefix(CPTabBarTemplate.maximumTabCount))
      // Same tabs as before: only their rows change, so the car keeps the open tab and list.
      if let tabBar = self.tabBar, tabBar.templates.count == shown.count,
        zip(tabBar.templates, shown).allSatisfy({ $0.tabTitle == $1["title"] as? String })
      {
        for (template, tab) in zip(tabBar.templates, shown) {
          (template as? CPListTemplate)?.updateSections(self.sections(tab["sections"], playing: playing))
        }
        return
      }
      let templates: [CPTemplate] = shown.map { tab in
        let title = tab["title"] as? String ?? "audiokiddo"
        let list = CPListTemplate(title: title, sections: self.sections(tab["sections"], playing: playing))
        list.tabTitle = title
        if let symbol = tab["symbol"] as? String { list.tabImage = UIImage(systemName: symbol) }
        return list
      }
      let tabBar = CPTabBarTemplate(templates: templates)
      self.tabBar = tabBar
      self.interface?.setRootTemplate(tabBar, animated: false, completion: nil)
    }
  }

  private func sections(_ raw: Any?, playing: String?) -> [CPListSection] {
    let list = raw as? [[String: Any]] ?? []
    return list.prefix(CPListTemplate.maximumSectionCount).map { section in
      let rows = (section["rows"] as? [[String: Any]] ?? []).prefix(CPListTemplate.maximumItemCount)
      return CPListSection(
        items: rows.map { row($0, playing: playing) }, header: section["title"] as? String, sectionIndexTitle: nil)
    }
  }

  /// A play (tap plays it) or a pack (tap opens its plays).
  private func row(_ raw: [String: Any], playing: String?) -> CPListItem {
    let item = CPListItem(text: raw["title"] as? String, detailText: raw["detail"] as? String)
    if let path = raw["image"] as? String, let image = UIImage(contentsOfFile: path) {
      item.setImage(image)
    }
    let id = raw["id"] as? String ?? ""
    if let children = raw["rows"] as? [[String: Any]] {
      item.accessoryType = .disclosureIndicator
      item.handler = { [weak self] _, done in
        guard let self else { return done() }
        let rows = children.prefix(CPListTemplate.maximumItemCount).map { self.row($0, playing: playing) }
        let list = CPListTemplate(title: raw["title"] as? String ?? "", sections: [CPListSection(items: rows)])
        self.interface?.pushTemplate(list, animated: true, completion: nil)
        done()
      }
      return item
    }
    if let progress = raw["progress"] as? Double { item.playbackProgress = CGFloat(progress) }
    item.isPlaying = id == playing
    item.handler = { [weak self] _, done in
      CarPlayBridge.channel?.invokeMethod("play", arguments: id) { _ in
        self?.interface?.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
        done()
      }
    }
    return item
  }

  /// The loop button on Now Playing, lit while the play loops.
  private func updateLoopButton() {
    let button = CPNowPlayingRepeatButton { [weak self] _ in
      CarPlayBridge.channel?.invokeMethod("toggleLoop", arguments: nil) { result in
        self?.looping = result as? Bool ?? false
        self?.updateLoopButton()
      }
    }
    button.isSelected = looping
    CPNowPlayingTemplate.shared.updateNowPlayingButtons([button])
  }

  private func message(_ text: String) {
    let item = CPListItem(text: text, detailText: nil)
    item.handler = { [weak self] _, done in
      self?.reload()
      done()
    }
    tabBar = nil
    interface?.setRootTemplate(
      CPListTemplate(title: "audiokiddo", sections: [CPListSection(items: [item])]), animated: false, completion: nil)
  }
}

/// The channel to the Dart side, set when the Flutter engine starts (AppDelegate).
enum CarPlayBridge {
  static var channel: FlutterMethodChannel?
}
