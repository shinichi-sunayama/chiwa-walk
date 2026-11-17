import Foundation

/// What the Watch face shows (「うんち 3時間前」). The Watch app writes it to the shared App Group
/// container; the complication (widget extension) reads it. Times are absolute dates, so the face can
/// count up by itself without the app running.
public struct ComplicationData: Codable, Equatable, Sendable {
    public struct Line: Codable, Equatable, Sendable {
        public var dogName: String
        public var lastPoop: Date?
        public var lastPee: Date?
        public init(dogName: String, lastPoop: Date?, lastPee: Date?) {
            self.dogName = dogName
            self.lastPoop = lastPoop
            self.lastPee = lastPee
        }
    }

    /// One line per dog walking now (selected dogs, in order), at most `maxLines`.
    public var lines: [Line]
    public var madeAt: Date

    public init(lines: [Line], madeAt: Date) {
        self.lines = lines
        self.madeAt = madeAt
    }

    public static let maxLines = 3
    public static let appGroup = "group.com.ohagikinakokobo.osanpo"
    public static let defaultsKey = "complication"

    /// Build from the Watch's state. If no dog is selected, all dogs are used.
    public static func make(dogs: [Dog], selected: Set<UUID>, events: [WalkEvent], now: Date) -> ComplicationData {
        let ordered = dogs.sorted { $0.order < $1.order }
        let chosen = ordered.filter { selected.contains($0.id) }
        let shown = (chosen.isEmpty ? ordered : chosen).prefix(maxLines)
        let lines = shown.map { dog in
            Line(dogName: dog.name,
                 lastPoop: WalkLog.last(.poop, dog: dog.id, in: events, now: now)?.date,
                 lastPee: WalkLog.last(.pee, dog: dog.id, in: events, now: now)?.date)
        }
        return ComplicationData(lines: Array(lines), madeAt: now)
    }

    /// The most recent poop among the shown dogs (for the small round complication).
    public var latestPoop: Date? { lines.compactMap(\.lastPoop).max() }

    public func encoded() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return try? encoder.encode(self)
    }

    public static func decode(_ data: Data?) -> ComplicationData? {
        guard let data else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(ComplicationData.self, from: data)
    }
}
