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
    case .afternoon: return "W drogę z Kiddo"
    case .evening: return "Czas się wyciszyć"
    }
  }

  var subtitle: String {
    switch self {
    case .morning: return "Zagadka do śniadania. Kawa poczeka."
    case .midday: return "Zabawa dnia czeka. Ekran w kieszeni."
    case .afternoon: return "Zanim padnie „daleko jeszcze?”."
    case .evening: return "Kołysanka dla dziecka, cisza dla Ciebie."
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

/// The child's week, written by the app (lib/features/home/home_widget_sync.dart) into the
/// shared App Group. Empty until a child profile exists.
struct ChildWeek {
  static let appGroup = "group.pl.audiokiddo.app"

  let line: String
  let notes: Int
  let todayDone: Bool

  static func load() -> ChildWeek? {
    let defaults = UserDefaults(suiteName: appGroup)
    guard let line = defaults?.string(forKey: "line"), !line.isEmpty else { return nil }
    return ChildWeek(
      line: line,
      notes: Int(defaults?.string(forKey: "notes") ?? "") ?? 0,
      todayDone: defaults?.string(forKey: "done") == "1"
    )
  }
}

struct PartEntry: TimelineEntry {
  let date: Date
  let part: DayPart
  var week: ChildWeek? = nil
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
        // After midnight "today's note" is a new one; the app refreshes it when opened.
        let sameDay = calendar.isDate(date, inSameDayAs: now)
        entries.append(PartEntry(date: date, part: DayPart.of(date), week: sameDay ? week : nil))
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

struct PartView: View {
  let entry: PartEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    let part = entry.part
    let content = VStack(alignment: .leading, spacing: 6) {
      HStack {
        Image(systemName: part.symbol)
          .font(.system(size: 22, weight: .semibold))
        Spacer()
        if let week = entry.week {
          NotesRow(notes: week.notes, color: part.foreground)
        } else {
          Text("AudioKiddo")
            .font(.system(size: 11, weight: .bold))
            .opacity(0.7)
        }
      }
      Spacer(minLength: 0)
      Text(part.title)
        .font(.system(size: family == .systemSmall ? 17 : 20, weight: .heavy))
        .minimumScaleFactor(0.8)
        .lineLimit(2)
      if family != .systemSmall {
        Text(entry.week?.line ?? part.subtitle)
          .font(.system(size: 13, weight: entry.week == nil ? .regular : .semibold))
          .opacity(0.85)
          .lineLimit(2)
      }
      Text(part.action)
        .font(.system(size: 14, weight: .bold))
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Capsule().fill(part.foreground.opacity(0.16)))
    }
    .foregroundColor(part.foreground)
    .widgetURL(part.url)

    let gradient = LinearGradient(colors: part.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    if #available(iOSApplicationExtension 17.0, *) {
      content.containerBackground(for: .widget) { gradient }
    } else {
      content.padding().background(gradient)
    }
  }
}

@main
struct AudioKiddoWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "AudioKiddoWidget", provider: PartProvider()) { entry in
      PartView(entry: entry)
    }
    .configurationDisplayName("Kiddo na dziś")
    .description("Zabawa na tę porę dnia: rano rozgrzewka, po południu droga, wieczorem kołysanka.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
