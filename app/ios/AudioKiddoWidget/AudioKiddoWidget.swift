import SwiftUI
import WidgetKit

/// Home-screen widget: what fits this part of the day, one tap away. The same parts of the
/// day as the Start card in the app (lib/features/home/today.dart, `dayPartOf`).
enum DayPart: CaseIterable {
  case morning, midday, afternoon, evening

  static func of(_ date: Date) -> DayPart {
    switch Calendar.current.component(.hour, from: date) {
    case 5..<11: return .morning
    case 11..<15: return .midday
    case 15..<19: return .afternoon
    default: return .evening
    }
  }

  /// Hours at which a part begins (the timeline refreshes exactly then).
  static let startHours = [5, 11, 15, 19]

  var title: String {
    switch self {
    case .morning: return "Poranna rozgrzewka"
    case .midday: return "Czas na przygodę"
    case .afternoon: return "W drogę z Szop’enem"
    case .evening: return "Czas się wyciszyć"
    }
  }

  var subtitle: String {
    switch self {
    case .morning: return "Ty ogarnij kawę. Ja ogarnę zagadki."
    case .midday: return "Cisza w domu? Sprawdź, co robi pisak."
    case .afternoon: return "Zanim padnie „daleko jeszcze?”."
    case .evening: return "Kołysanka dla dziecka, cisza dla ciebie."
    }
  }

  var action: String {
    switch self {
    case .morning, .midday: return "Graj"
    case .afternoon: return "W drogę"
    case .evening: return "Dobranoc"
    }
  }

  var symbol: String {
    switch self {
    case .morning: return "sun.max.fill"
    case .midday: return "sparkles"
    case .afternoon: return "car.fill"
    case .evening: return "moon.stars.fill"
    }
  }

  /// Opens the matching screen through the app's `audiokiddo://open/...` deep link.
  var url: URL {
    switch self {
    case .morning, .midday: return URL(string: "audiokiddo://open/")!
    case .afternoon: return URL(string: "audiokiddo://open/podroz")!
    case .evening: return URL(string: "audiokiddo://open/dobranoc")!
    }
  }

  var colors: [Color] {
    switch self {
    case .morning: return [Color(hex: 0xFFD27A), Color(hex: 0xFF9A6B)]
    case .midday: return [Color(hex: 0x7FD3D6), Color(hex: 0xFFD27A)]
    case .afternoon: return [Color(hex: 0xFFB38A), Color(hex: 0xC9A6E0)]
    case .evening: return [Color(hex: 0x3B2E5A), Color(hex: 0x1E2A4A)]
    }
  }

  /// Szop’en in his current look: a coffee in the morning, sneaking up on the day, listening
  /// on the road, yawning at night.
  var mascot: String {
    switch self {
    case .morning: return "szop_rano"
    case .midday: return "szop_dzien"
    case .afternoon: return "szop_droga"
    case .evening: return "szop_wieczor"
    }
  }

  /// The second shortcut next to the part's own: bedtime by day, the road in the evening.
  var other: (label: String, symbol: String, url: URL) {
    switch self {
    case .evening: return ("W drogę", "car.fill", URL(string: "audiokiddo://open/podroz")!)
    default: return ("Dobranoc", "moon.stars.fill", URL(string: "audiokiddo://open/dobranoc")!)
    }
  }

  var foreground: Color { self == .evening ? .white : Color(hex: 0x231A16) }
}

extension Color {
  init(hex: UInt32) {
    self.init(
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255
    )
  }
}

/// A play on the widget, written by the app: one tap opens it (and starts it).
struct PlayLink {
  let title: String
  let detail: String
  let url: URL

  static func load(_ defaults: UserDefaults?, _ key: String) -> PlayLink? {
    guard let title = defaults?.string(forKey: "\(key)_title"), !title.isEmpty,
      let path = defaults?.string(forKey: "\(key)_path"), !path.isEmpty,
      let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
      let url = URL(string: "audiokiddo://open\(encoded)")
    else { return nil }
    return PlayLink(title: title, detail: defaults?.string(forKey: "\(key)_detail") ?? "", url: url)
  }
}

/// What the app wrote into the shared App Group (lib/features/home/home_widget_sync.dart): the
/// child's week, today's play from the plan and the play stopped halfway.
struct ChildWeek {
  /// From Info.plist (AK_APP_GROUP in Flutter/AppIds.xcconfig): a personal test build uses its own.
  static let appGroup = Bundle.main.object(forInfoDictionaryKey: "AKAppGroup") as? String ?? "group.pl.audiokiddo.app"

  let line: String
  let notes: Int
  let todayDone: Bool
  let next: PlayLink?
  let resume: PlayLink?

  var hasChild: Bool { !line.isEmpty }

  var resumeOnly: ChildWeek? {
    resume == nil ? nil : ChildWeek(line: "", notes: 0, todayDone: false, next: nil, resume: resume)
  }

  static func load() -> ChildWeek? {
    let defaults = UserDefaults(suiteName: appGroup)
    let week = ChildWeek(
      line: defaults?.string(forKey: "line") ?? "",
      notes: Int(defaults?.string(forKey: "notes") ?? "") ?? 0,
      todayDone: defaults?.string(forKey: "done") == "1",
      next: PlayLink.load(defaults, "next"),
      resume: PlayLink.load(defaults, "resume")
    )
    return week.hasChild || week.resume != nil ? week : nil
  }
}

/// Szop’en's line for the parent in each part of the day, written by the app every day
/// (lib/features/home/home_widget_sync.dart); the built-in subtitle until the app has run.
enum LordJoke {
  static func load(_ part: DayPart) -> String? {
    let key: String
    switch part {
    case .morning: key = "joke_morning"
    case .midday: key = "joke_midday"
    case .afternoon: key = "joke_afternoon"
    case .evening: key = "joke_evening"
    }
    guard let joke = UserDefaults(suiteName: ChildWeek.appGroup)?.string(forKey: key), !joke.isEmpty else { return nil }
    return joke
  }
}

struct PartEntry: TimelineEntry {
  let date: Date
  let part: DayPart
  var week: ChildWeek? = nil
  var joke: String { LordJoke.load(part) ?? part.subtitle }
}

struct PartProvider: TimelineProvider {
  func placeholder(in context: Context) -> PartEntry { PartEntry(date: Date(), part: .evening) }

  func getSnapshot(in context: Context, completion: @escaping (PartEntry) -> Void) {
    completion(PartEntry(date: Date(), part: DayPart.of(Date()), week: ChildWeek.load()))
  }

  /// One entry now and one at each change of the part of the day for the next 24 hours. The
  /// app asks for a new timeline whenever the child's week changes.
  func getTimeline(in context: Context, completion: @escaping (Timeline<PartEntry>) -> Void) {
    let now = Date()
    let calendar = Calendar.current
    let week = ChildWeek.load()
    var entries = [PartEntry(date: now, part: DayPart.of(now), week: week)]
    for dayOffset in 0...1 {
      guard let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)) else { continue }
      for hour in DayPart.startHours {
        guard let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day), date > now,
          date.timeIntervalSince(now) <= 24 * 3600
        else { continue }
        // After midnight "today's note" and today's play are new ones; the app refreshes them
        // when opened. The play to finish stays.
        let sameDay = calendar.isDate(date, inSameDayAs: now)
        entries.append(PartEntry(date: date, part: DayPart.of(date), week: sameDay ? week : week?.resumeOnly))
      }
    }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

/// Seven dots: this week's melody, filled for every note collected.
struct NotesRow: View {
  let notes: Int
  let color: Color

  var body: some View {
    HStack(spacing: 4) {
      ForEach(0..<7, id: \.self) { i in
        Circle()
          .fill(i < notes ? color : color.opacity(0.22))
          .frame(width: 7, height: 7)
      }
    }
    .accessibilityLabel("\(notes) z 7 nut w tym tygodniu")
  }
}

/// One tappable row on the medium widget.
struct ShortcutRow: View {
  let symbol: String
  let label: String
  let title: String
  let url: URL
  let color: Color

  var body: some View {
    Link(destination: url) {
      HStack(spacing: 8) {
        Image(systemName: symbol).font(.system(size: 13, weight: .bold)).frame(width: 18)
        VStack(alignment: .leading, spacing: 0) {
          Text(label).font(.system(size: 10, weight: .semibold)).opacity(0.75).lineLimit(1)
          Text(title).font(.system(size: 13, weight: .bold)).lineLimit(1).minimumScaleFactor(0.8)
        }
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 10).padding(.vertical, 6)
      .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.14)))
    }
  }
}

struct PartView: View {
  let entry: PartEntry
  @Environment(\.widgetFamily) private var family

  /// The play the small widget and the lock screen open: the unfinished one, else today's.
  private var main: (label: String, link: PlayLink)? {
    if let resume = entry.week?.resume { return ("Dokończ", resume) }
    if let next = entry.week?.next { return ("Na dziś", next) }
    return nil
  }

  var body: some View {
    if #available(iOSApplicationExtension 16.0, *) {
      if [WidgetFamily.accessoryRectangular, .accessoryCircular, .accessoryInline].contains(family) {
        accessory
      } else {
        home
      }
    } else {
      home
    }
  }

  @available(iOSApplicationExtension 16.0, *)
  @ViewBuilder private var accessory: some View {
    let part = entry.part
    switch family {
    case .accessoryCircular:
      ZStack {
        Circle().fill(Color.white.opacity(0.15))
        Image(systemName: main == nil ? part.symbol : "play.fill").font(.system(size: 20, weight: .bold))
      }
      .widgetURL(main?.link.url ?? part.url)
      .accessibilityLabel(main.map { "\($0.label): \($0.link.title)" } ?? part.action)
    default:
      VStack(alignment: .leading, spacing: 1) {
        Text(main?.label ?? "AudioKiddo").font(.system(size: 12, weight: .semibold))
        Text(main?.link.title ?? part.title).font(.system(size: 15, weight: .bold)).lineLimit(1)
        Text(main?.link.detail ?? part.action).font(.system(size: 12)).lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .widgetURL(main?.link.url ?? part.url)
    }
  }

  @ViewBuilder private var home: some View {
    let part = entry.part
    let ink = part.foreground
    let content = Group {
      if family == .systemSmall {
        small(part: part, ink: ink)
      } else {
        medium(part: part, ink: ink)
      }
    }
    .foregroundColor(ink)

    let gradient = LinearGradient(colors: part.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    if #available(iOSApplicationExtension 17.0, *) {
      content.containerBackground(for: .widget) { gradient }
    } else {
      content.padding().background(gradient)
    }
  }

  private func header(ink: Color) -> some View {
    Group {
      if let week = entry.week, week.hasChild {
        NotesRow(notes: week.notes, color: ink)
      } else {
        Text("AudioKiddo").font(.system(size: 11, weight: .bold))
      }
    }
  }

  /// Small: Szop’en, then the one play to start (or his line), the whole widget is the button.
  private func small(part: DayPart, ink: Color) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .top) {
        header(ink: ink)
        Spacer(minLength: 0)
        Image(part.mascot).resizable().scaledToFit().frame(width: 50, height: 46)
          .accessibilityLabel("Szop’en")
      }
      Spacer(minLength: 0)
      if let main {
        Text(main.label.uppercased()).font(.system(size: 10, weight: .heavy)).opacity(0.75)
        Text(main.link.title).font(.system(size: 15, weight: .heavy)).lineLimit(2).minimumScaleFactor(0.8)
        Label(main.link.detail.isEmpty ? "Graj" : main.link.detail, systemImage: "play.fill")
          .font(.system(size: 12, weight: .bold))
          .padding(.horizontal, 10).padding(.vertical, 4)
          .background(Capsule().fill(ink.opacity(0.16)))
      } else {
        Text(entry.joke)
          .font(.system(size: 13, weight: .semibold)).italic()
          .minimumScaleFactor(0.8).lineLimit(3)
        Text(part.action)
          .font(.system(size: 13, weight: .bold))
          .padding(.horizontal, 12).padding(.vertical, 5)
          .background(Capsule().fill(ink.opacity(0.16)))
      }
    }
    .widgetURL(main?.link.url ?? part.url)
  }

  /// Medium: Szop’en with the child's week on the left; up to three one-tap shortcuts on the
  /// right (finish, today's play, the part of the day, bedtime or the road).
  private func medium(part: DayPart, ink: Color) -> some View {
    var rows: [(String, String, String, URL)] = []
    if let resume = entry.week?.resume { rows.append(("play.fill", "Dokończ", resume.title, resume.url)) }
    if let next = entry.week?.next {
      rows.append(("star.fill", next.detail.isEmpty ? "Na dziś" : "Na dziś · \(next.detail)", next.title, next.url))
    }
    rows.append((part.symbol, part.title, part.action, part.url))
    if rows.count < 3 { rows.append((part.other.symbol, "Jednym dotknięciem", part.other.label, part.other.url)) }
    return HStack(alignment: .top, spacing: 10) {
      VStack(alignment: .leading, spacing: 4) {
        header(ink: ink)
        Image(part.mascot).resizable().scaledToFit().frame(maxWidth: 92, maxHeight: 74)
          .accessibilityLabel("Szop’en")
        Spacer(minLength: 0)
        if let week = entry.week, week.hasChild {
          Text(week.line).font(.system(size: 11, weight: .semibold)).lineLimit(2).minimumScaleFactor(0.8)
        } else {
          Text(entry.joke).font(.system(size: 11)).italic().lineLimit(3).minimumScaleFactor(0.8)
        }
      }
      .frame(width: 104, alignment: .leading)
      VStack(spacing: 6) {
        ForEach(Array(rows.prefix(3).enumerated()), id: \.offset) { _, row in
          ShortcutRow(symbol: row.0, label: row.1, title: row.2, url: row.3, color: ink)
        }
        Spacer(minLength: 0)
      }
    }
    .widgetURL(part.url)
  }
}

@main
struct AudioKiddoWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "AudioKiddoWidget", provider: PartProvider()) { entry in
      PartView(entry: entry)
    }
    .configurationDisplayName("Szop’en na dziś")
    .description("Jednym dotknięciem: dokończ zabawę, włącz dzisiejszą z planu, W drogę albo Dobranoc.")
    .supportedFamilies(Self.families)
  }

  /// The home screen everywhere; the lock screen from iOS 16.
  static var families: [WidgetFamily] {
    if #available(iOSApplicationExtension 16.0, *) {
      return [.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular]
    }
    return [.systemSmall, .systemMedium]
  }
}
