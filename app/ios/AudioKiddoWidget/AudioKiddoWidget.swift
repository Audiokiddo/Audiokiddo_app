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

struct PartEntry: TimelineEntry {
  let date: Date
  let part: DayPart
}

struct PartProvider: TimelineProvider {
  func placeholder(in context: Context) -> PartEntry { PartEntry(date: Date(), part: .evening) }

  func getSnapshot(in context: Context, completion: @escaping (PartEntry) -> Void) {
    completion(PartEntry(date: Date(), part: DayPart.of(Date())))
  }

  /// One entry now and one at each change of the part of the day for the next 24 hours.
  func getTimeline(in context: Context, completion: @escaping (Timeline<PartEntry>) -> Void) {
    let now = Date()
    let calendar = Calendar.current
    var entries = [PartEntry(date: now, part: DayPart.of(now))]
    for dayOffset in 0...1 {
      guard let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)) else { continue }
      for hour in DayPart.startHours {
        guard let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day), date > now,
          date.timeIntervalSince(now) <= 24 * 3600
        else { continue }
        entries.append(PartEntry(date: date, part: DayPart.of(date)))
      }
    }
    completion(Timeline(entries: entries, policy: .atEnd))
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
        Text("AudioKiddo")
          .font(.system(size: 11, weight: .bold))
          .opacity(0.7)
      }
      Spacer(minLength: 0)
      Text(part.title)
        .font(.system(size: family == .systemSmall ? 17 : 20, weight: .heavy))
        .minimumScaleFactor(0.8)
        .lineLimit(2)
      if family != .systemSmall {
        Text(part.subtitle)
          .font(.system(size: 13))
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
