import Foundation

/// Sample dogs and records for the App Store screenshots (taken with simulators in the cloud,
/// .github/workflows/screenshots.yml). Never used in normal use.
public enum DemoData {
    public static let ohagiID = UUID(uuidString: "0A0A0A0A-0000-4000-8000-000000000001")!
    public static let kinakoID = UUID(uuidString: "0A0A0A0A-0000-4000-8000-000000000002")!

    public static var dogs: [Dog] {
        [Dog(id: ohagiID, name: "おはぎ", avatar: .ohagi, order: 0),
         Dog(id: kinakoID, name: "きなこ", avatar: .kinako, order: 1)]
    }

    /// Records for today and yesterday, relative to `now` (times are minutes before now).
    public static func events(now: Date) -> [WalkEvent] {
        func at(_ minutesAgo: Double) -> Date { now.addingTimeInterval(-minutesAgo * 60) }
        let both = [ohagiID, kinakoID]
        var out: [WalkEvent] = []
        func add(_ kind: EventKind, _ dogs: [UUID], _ minutesAgo: Double, _ author: String = "") {
            out += WalkLog.makeEvents(kind: kind, dogIDs: dogs, date: at(minutesAgo), author: author)
        }
        // This morning's walk (both dogs)
        add(.walkStart, both, 190, "パパ")
        add(.pee, both, 184, "パパ")
        add(.pee, [ohagiID], 172, "パパ")
        add(.poop, [ohagiID], 165, "パパ")
        add(.poop, [kinakoID], 158, "パパ")
        add(.walkEnd, both, 150, "パパ")
        add(.water, both, 148, "パパ")
        // Around noon
        add(.pee, [kinakoID], 40, "ママ")
        add(.pee, [ohagiID], 22, "ママ")
        // Yesterday evening
        add(.walkStart, both, 1_080, "ママ")
        add(.pee, both, 1_072, "ママ")
        add(.poop, both, 1_060, "ママ")
        add(.walkEnd, both, 1_045, "ママ")
        return out.sorted { $0.date > $1.date }
    }
}
