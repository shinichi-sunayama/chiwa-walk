import Foundation

/// Pure functions over a list of events. Only facts (times, counts, elapsed time); never any health judgement.
public enum WalkLog {
    /// One tap: the same kind for every selected dog, same time, one shared group (so undo removes all of them).
    public static func makeEvents(kind: EventKind, dogIDs: [UUID], date: Date, author: String) -> [WalkEvent] {
        let group = UUID()
        return dogIDs.map { WalkEvent(dogID: $0, kind: kind, date: date, author: author, groupID: group) }
    }

    /// Latest event of a kind for a dog, not later than `now` (events in the future are ignored).
    public static func last(_ kind: EventKind, dog: UUID, in events: [WalkEvent], now: Date) -> WalkEvent? {
        events
            .filter { $0.dogID == dog && $0.kind == kind && $0.date <= now }
            .max { $0.date < $1.date }
    }

    /// How many events of a kind the dog has on the calendar day of `now`.
    public static func count(_ kind: EventKind, dog: UUID, in events: [WalkEvent], on now: Date, calendar: Calendar) -> Int {
        events.filter { $0.dogID == dog && $0.kind == kind && calendar.isDate($0.date, inSameDayAs: now) }.count
    }

    /// Events of the calendar day of `day`, newest first.
    public static func events(on day: Date, in events: [WalkEvent], calendar: Calendar) -> [WalkEvent] {
        events.filter { calendar.isDate($0.date, inSameDayAs: day) }.sorted { $0.date > $1.date }
    }

    /// Start of the walk in progress for a dog, or nil if the dog is not walking.
    /// A walk counts as in progress when the latest start has no later end and began less than `limit` ago
    /// (a forgotten "おわり" should not keep a walk open forever).
    public static func walkInProgress(dog: UUID, in events: [WalkEvent], now: Date, limit: TimeInterval = 4 * 3600) -> Date? {
        guard let start = last(.walkStart, dog: dog, in: events, now: now) else { return nil }
        if let end = last(.walkEnd, dog: dog, in: events, now: now), end.date >= start.date { return nil }
        return now.timeIntervalSince(start.date) < limit ? start.date : nil
    }

    /// Japanese elapsed text: 「たった今」「12分前」「3時間5分前」「2日前」.
    public static func elapsedText(since date: Date, now: Date) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        let minutes = Int(seconds / 60)
        if minutes < 1 { return "たった今" }
        if minutes < 60 { return "\(minutes)分前" }
        let hours = minutes / 60
        if hours < 24 {
            let rest = minutes % 60
            return rest == 0 ? "\(hours)時間前" : "\(hours)時間\(rest)分前"
        }
        return "\(hours / 24)日前"
    }

    /// Short form for tight places (complication, Watch rows): 「たった今」「12分」「3時間」「2日」.
    public static func elapsedShort(since date: Date, now: Date) -> String {
        let minutes = Int(max(0, now.timeIntervalSince(date)) / 60)
        if minutes < 1 { return "たった今" }
        if minutes < 60 { return "\(minutes)分" }
        if minutes < 24 * 60 { return "\(minutes / 60)時間" }
        return "\(minutes / (24 * 60))日"
    }

    /// Duration text for a walk: 「25分」「1時間10分」.
    public static func durationText(from start: Date, to end: Date) -> String {
        let minutes = max(0, Int(end.timeIntervalSince(start) / 60))
        if minutes < 60 { return "\(minutes)分" }
        let rest = minutes % 60
        return rest == 0 ? "\(minutes / 60)時間" : "\(minutes / 60)時間\(rest)分"
    }

    /// Merge two copies of the log (e.g. the Watch's own events and the iPhone's snapshot).
    /// Same id = same event; the copy from `incoming` wins. Ids in `deleted` are dropped from both.
    public static func merge(_ base: [WalkEvent], _ incoming: [WalkEvent], deleted: Set<UUID> = []) -> [WalkEvent] {
        var byID: [UUID: WalkEvent] = [:]
        for e in base { byID[e.id] = e }
        for e in incoming { byID[e.id] = e }
        for id in deleted { byID[id] = nil }
        return byID.values.sorted { $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date > $1.date }
    }
}
