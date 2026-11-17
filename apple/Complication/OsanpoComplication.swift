import SwiftUI
import WalkCore
import WidgetKit

// Watch face complication: 「うんち 3時間前」 for the dogs walking now (spec 3.2 ①).
// The Watch app writes ComplicationData to the App Group; this extension only reads it.
// Facts only (elapsed time); never any judgement. Quiet marks (a dot for poop, a drop for pee), no 💩 on the wrist.

struct WalkEntry: TimelineEntry {
    let date: Date
    let data: ComplicationData?
}

struct WalkProvider: TimelineProvider {
    private func load() -> ComplicationData? {
        ComplicationData.decode(UserDefaults(suiteName: ComplicationData.appGroup)?.data(forKey: ComplicationData.defaultsKey))
    }

    func placeholder(in context: Context) -> WalkEntry {
        WalkEntry(date: .now, data: ComplicationData(
            lines: [.init(dogName: "おはぎ", lastPoop: .now.addingTimeInterval(-3 * 3600), lastPee: .now.addingTimeInterval(-1200))],
            madeAt: .now))
    }

    func getSnapshot(in context: Context, completion: @escaping (WalkEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : WalkEntry(date: .now, data: load()))
    }

    /// One entry every 10 minutes for 4 hours, so 「3時間」 moves on without the app.
    func getTimeline(in context: Context, completion: @escaping (Timeline<WalkEntry>) -> Void) {
        let data = load()
        let now = Date()
        let entries = (0..<24).map { WalkEntry(date: now.addingTimeInterval(Double($0) * 600), data: data) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct WalkComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WalkEntry

    private func short(_ date: Date?) -> String {
        date.map { WalkLog.elapsedShort(since: $0, now: entry.date) } ?? "―"
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                VStack(spacing: 0) {
                    Image(systemName: "circle.fill").font(.system(size: 11))
                    Text(short(entry.data?.latestPoop))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.6).lineLimit(1)
                }
            case .accessoryCorner:
                Image(systemName: "circle.fill").font(.system(size: 14))
                    .widgetLabel(short(entry.data?.latestPoop))
            case .accessoryInline:
                Text("\(Image(systemName: "circle.fill")) \(short(entry.data?.latestPoop))")
            default: // rectangular
                VStack(alignment: .leading, spacing: 1) {
                    if let lines = entry.data?.lines, !lines.isEmpty {
                        ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                            HStack(spacing: 4) {
                                Text(line.dogName).lineLimit(1).frame(maxWidth: 62, alignment: .leading)
                                Text("\(Image(systemName: "circle.fill"))\(short(line.lastPoop))")
                                Text("\(Image(systemName: "drop.fill"))\(short(line.lastPee))")
                            }
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .minimumScaleFactor(0.7)
                        }
                    } else {
                        Text("おさんぽ帳").font(.headline)
                        Text("iPhone で わんちゃんを とうろく").font(.caption2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

@main
struct OsanpoComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "OsanpoComplication", provider: WalkProvider()) { entry in
            WalkComplicationView(entry: entry)
        }
        .configurationDisplayName("おさんぽ帳")
        .description("前回の トイレからの じかん（● うんち・しずく おしっこ）")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}
