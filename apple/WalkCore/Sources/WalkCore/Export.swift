import Foundation

/// Plain lists to show a vet or keep as a file. Facts only (date, time, dog, kind, who); no judgement.
public enum Export {
    /// CSV (UTF-8 with BOM so Excel opens Japanese correctly). Oldest first.
    public static func csv(dogs: [Dog], events: [WalkEvent], timeZone: TimeZone) -> String {
        let names = Dictionary(uniqueKeysWithValues: dogs.map { ($0.id, $0.name) })
        var lines = ["日付,時刻,犬,きろく,記録した人"]
        for e in events.sorted(by: { $0.date < $1.date }) {
            let (day, time) = dayAndTime(e.date, timeZone: timeZone)
            lines.append([day, time, names[e.dogID] ?? "", e.kind.label, e.author].map(field).joined(separator: ","))
        }
        return "\u{FEFF}" + lines.joined(separator: "\r\n") + "\r\n"
    }

    /// Text summary per day and dog, e.g.
    /// 「2026/11/16（月）」「おはぎ　おしっこ 3回（7:10, 12:30, 18:05）・うんち 1回（7:12）」
    public static func dailyText(dogs: [Dog], events: [WalkEvent], timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let byDay = Dictionary(grouping: events) { calendar.startOfDay(for: $0.date) }
        var out: [String] = []
        for day in byDay.keys.sorted() {
            out.append(dayHeading(day, calendar: calendar))
            let dayEvents = byDay[day]!.sorted { $0.date < $1.date }
            for dog in dogs.sorted(by: { $0.order < $1.order }) {
                let mine = dayEvents.filter { $0.dogID == dog.id }
                if mine.isEmpty { continue }
                var parts: [String] = []
                for kind in EventKind.allCases {
                    let times = mine.filter { $0.kind == kind }.map { dayAndTime($0.date, timeZone: timeZone).1 }
                    if !times.isEmpty { parts.append("\(kind.label) \(times.count)回（\(times.joined(separator: ", "))）") }
                }
                out.append("\(dog.name)　" + parts.joined(separator: "・"))
            }
            out.append("")
        }
        return out.joined(separator: "\n")
    }

    static let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    static func dayHeading(_ day: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day, .weekday], from: day)
        return String(format: "%04d/%02d/%02d", c.year!, c.month!, c.day!) + "（\(weekdays[c.weekday! - 1])）"
    }

    static func dayAndTime(_ date: Date, timeZone: TimeZone) -> (String, String) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return (String(format: "%04d/%02d/%02d", c.year!, c.month!, c.day!), String(format: "%d:%02d", c.hour!, c.minute!))
    }

    static func field(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") || s.contains("\r") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }
}
