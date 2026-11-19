import Foundation

/// One walk: 「7:10〜7:42（32分）」. Built from the start / end records; dogs that walked together
/// (same start and end time) are one walk.
public struct WalkSession: Equatable, Identifiable, Sendable {
    public var id: UUID { startEventIDs[0] }
    public var dogIDs: [UUID]
    public var start: Date
    /// nil while walking, or when "おわり" was never tapped.
    public var end: Date?
    public var startEventIDs: [UUID]
    public var endEventIDs: [UUID]

    public var eventIDs: [UUID] { startEventIDs + endEventIDs }

    public var minutes: Int? {
        end.map { max(0, Int($0.timeIntervalSince(start) / 60)) }
    }
}

/// What happened on one day, for the calendar and the day's header. Facts only.
public struct DaySummary: Equatable, Sendable {
    public var day: Date
    public var walks: Int
    /// Total minutes of the walks that have an end.
    public var walkMinutes: Int
    /// Records per kind (all dogs together; a tap for two dogs counts once).
    public var taps: [EventKind: Int]

    public init(day: Date, walks: Int = 0, walkMinutes: Int = 0, taps: [EventKind: Int] = [:]) {
        self.day = day
        self.walks = walks
        self.walkMinutes = walkMinutes
        self.taps = taps
    }
}

/// One row of a day's timeline: a walk, or one tap (all the dogs it was recorded for).
public enum TimelineItem: Equatable, Identifiable, Sendable {
    case walk(WalkSession)
    case tap([WalkEvent])

    public var id: UUID {
        switch self {
        case .walk(let w): return w.id
        case .tap(let events): return events[0].id
        }
    }

    public var date: Date {
        switch self {
        case .walk(let w): return w.start
        case .tap(let events): return events[0].date
        }
    }

    public var eventIDs: [UUID] {
        switch self {
        case .walk(let w): return w.eventIDs
        case .tap(let events): return events.map(\.id)
        }
    }
}

public enum Walks {
    /// Pair each dog's starts and ends into walks, then join dogs that walked together. Newest first.
    /// An end more than `limit` after its start is not paired (the start was likely forgotten).
    public static func sessions(in events: [WalkEvent], limit: TimeInterval = 4 * 3600) -> [WalkSession] {
        let marks = events.filter { $0.kind == .walkStart || $0.kind == .walkEnd }
        var perDog: [(dog: UUID, start: WalkEvent, end: WalkEvent?)] = []
        for (dog, list) in Dictionary(grouping: marks, by: \.dogID) {
            var open: WalkEvent?
            for e in list.sorted(by: { $0.date < $1.date }) {
                if e.kind == .walkStart {
                    if let o = open { perDog.append((dog, o, nil)) }
                    open = e
                } else if let o = open {
                    if e.date.timeIntervalSince(o.date) <= limit {
                        perDog.append((dog, o, e))
                    } else {
                        perDog.append((dog, o, nil))
                    }
                    open = nil
                }
            }
            if let o = open { perDog.append((dog, o, nil)) }
        }
        // Join dogs with the same start and end (one tap for several dogs).
        var joined: [WalkSession] = []
        for item in perDog.sorted(by: { $0.start.date < $1.start.date || ($0.start.date == $1.start.date && $0.dog.uuidString < $1.dog.uuidString) }) {
            if let i = joined.firstIndex(where: { $0.start == item.start.date && $0.end == item.end?.date }) {
                joined[i].dogIDs.append(item.dog)
                joined[i].startEventIDs.append(item.start.id)
                if let end = item.end { joined[i].endEventIDs.append(end.id) }
            } else {
                joined.append(WalkSession(dogIDs: [item.dog], start: item.start.date, end: item.end?.date,
                                          startEventIDs: [item.start.id], endEventIDs: item.end.map { [$0.id] } ?? []))
            }
        }
        return joined.sorted { $0.start > $1.start }
    }

    /// The day's rows, newest first: walks (by start time) and taps (one row per tap, all its dogs).
    /// Walk start / end records are shown only through their walk.
    public static func timeline(on day: Date, events: [WalkEvent], calendar: Calendar) -> [TimelineItem] {
        let walks = sessions(in: events).filter { calendar.isDate($0.start, inSameDayAs: day) }
        let used = Set(sessions(in: events).flatMap(\.eventIDs))
        let taps = events.filter { calendar.isDate($0.date, inSameDayAs: day) && !used.contains($0.id) }
        var items = walks.map(TimelineItem.walk)
        for (_, group) in Dictionary(grouping: taps, by: { "\($0.groupID)|\($0.kind.rawValue)|\($0.date.timeIntervalSince1970)" }) {
            items.append(.tap(group.sorted { $0.dogID.uuidString < $1.dogID.uuidString }))
        }
        return items.sorted { $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date > $1.date }
    }

    /// Summaries keyed by the start of each day that has records.
    public static func summaries(events: [WalkEvent], calendar: Calendar) -> [Date: DaySummary] {
        var out: [Date: DaySummary] = [:]
        for w in sessions(in: events) {
            let day = calendar.startOfDay(for: w.start)
            var s = out[day] ?? DaySummary(day: day)
            s.walks += 1
            s.walkMinutes += w.minutes ?? 0
            out[day] = s
        }
        var seenGroups = Set<String>()
        for e in events where e.kind != .walkStart && e.kind != .walkEnd {
            let key = "\(e.groupID)|\(e.kind.rawValue)|\(e.date.timeIntervalSince1970)"
            guard seenGroups.insert(key).inserted else { continue }
            let day = calendar.startOfDay(for: e.date)
            var s = out[day] ?? DaySummary(day: day)
            s.taps[e.kind, default: 0] += 1
            out[day] = s
        }
        return out
    }

    /// 「おさんぽ 2回・55分」 (minutes left out when no walk has ended).
    public static func walkText(_ s: DaySummary) -> String {
        guard s.walks > 0 else { return "おさんぽ なし" }
        return s.walkMinutes > 0 ? "おさんぽ \(s.walks)回・\(WalkLog.durationText(minutes: s.walkMinutes))" : "おさんぽ \(s.walks)回"
    }
}

extension WalkLog {
    /// 「25分」「1時間10分」 from minutes.
    public static func durationText(minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)分" }
        let rest = minutes % 60
        return rest == 0 ? "\(minutes / 60)時間" : "\(minutes / 60)時間\(rest)分"
    }
}
