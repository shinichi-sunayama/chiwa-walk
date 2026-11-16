import Foundation

/// Messages between the Watch and the iPhone (WatchConnectivity). Encoded as JSON Data inside the
/// userInfo / applicationContext dictionary under `WatchSync.key`, so both sides share one tested format.
public enum WatchSync {
    public static let key = "payload"
    public static let version = 1

    /// Watch -> iPhone, queued with transferUserInfo (delivered later if the iPhone is away).
    public enum Operation: Codable, Equatable, Sendable {
        case add([WalkEvent])
        /// Remove events by id (undo on the Watch).
        case remove([UUID])
    }

    public struct OperationEnvelope: Codable, Equatable, Sendable {
        public var version: Int
        public var operation: Operation
        public init(_ operation: Operation) {
            self.version = WatchSync.version
            self.operation = operation
        }
    }

    /// iPhone -> Watch, sent with updateApplicationContext (only the latest one matters).
    public struct Snapshot: Codable, Equatable, Sendable {
        public var version: Int
        public var dogs: [Dog]
        /// Recent events plus the latest event of every kind for every dog (so "last poop" works even if old).
        public var events: [WalkEvent]
        public var madeAt: Date
        /// One-tap buttons chosen in the iPhone's せってい (nil in older snapshots = the standard two).
        public var buttons: [EventKind]?

        public init(dogs: [Dog], events: [WalkEvent], madeAt: Date, buttons: [EventKind]? = nil) {
            self.version = WatchSync.version
            self.dogs = dogs
            self.events = events
            self.madeAt = madeAt
            self.buttons = buttons
        }
    }

    /// Choose what goes into a snapshot: events of the last `days` days, plus the latest of each kind per dog.
    public static func snapshotEvents(dogs: [Dog], events: [WalkEvent], now: Date, days: Int = 2) -> [WalkEvent] {
        let since = now.addingTimeInterval(-Double(days) * 86400)
        var chosen: [UUID: WalkEvent] = [:]
        for e in events where e.date >= since && e.date <= now { chosen[e.id] = e }
        for dog in dogs {
            for kind in EventKind.allCases {
                if let e = WalkLog.last(kind, dog: dog.id, in: events, now: now) { chosen[e.id] = e }
            }
        }
        return chosen.values.sorted { $0.date > $1.date }
    }

    public static func encode<T: Encodable>(_ value: T) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return [key: try encoder.encode(value)]
    }

    public static func decode<T: Decodable>(_ type: T.Type, from dictionary: [String: Any]) -> T? {
        guard let data = dictionary[key] as? Data else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(type, from: data)
    }
}
