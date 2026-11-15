import Foundation

/// What can be logged. Raw values are stored (Core Data, iCloud, Watch messages), so never rename them.
public enum EventKind: String, Codable, CaseIterable, Sendable {
    case pee
    case poop
    case water
    case food
    case walkStart
    case walkEnd

    /// The four big one-tap buttons, in screen order (2x2 on the Watch).
    public static let buttons: [EventKind] = [.pee, .poop, .water, .food]

    public var label: String {
        switch self {
        case .pee: return "おしっこ"
        case .poop: return "うんち"
        case .water: return "おみず"
        case .food: return "ごはん"
        case .walkStart: return "おさんぽ スタート"
        case .walkEnd: return "おさんぽ おわり"
        }
    }

    /// Short label for small places (Watch rows, complications).
    public var shortLabel: String {
        switch self {
        case .walkStart: return "スタート"
        case .walkEnd: return "おわり"
        default: return label
        }
    }
}

/// Built-in dog pictures (the five dogs of おはぎきなこ工房) plus a plain paw for the user's own dog.
public enum Avatar: String, Codable, CaseIterable, Sendable {
    case ohagi, shiratama, kinako, yokan, dorayaki, paw

    public var displayName: String {
        switch self {
        case .ohagi: return "おはぎ"
        case .shiratama: return "しらたま"
        case .kinako: return "きなこ"
        case .yokan: return "ようかん"
        case .dorayaki: return "どらやき"
        case .paw: return "あしあと"
        }
    }

    /// Asset name in the app's asset catalog (made by tools/make_apple_assets.sh), nil for the paw symbol.
    public var imageName: String? {
        self == .paw ? nil : "dog_\(rawValue)"
    }
}

public struct Dog: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var avatar: Avatar
    public var order: Int

    public init(id: UUID = UUID(), name: String, avatar: Avatar, order: Int) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.order = order
    }
}

/// One logged thing for one dog. Tapping a button with three dogs selected makes three events that share a groupID,
/// so the tap can be undone as a whole.
public struct WalkEvent: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var dogID: UUID
    public var kind: EventKind
    public var date: Date
    /// Who logged it (the name set on that device, e.g. 「パパ」). Empty when not set.
    public var author: String
    public var groupID: UUID

    public init(id: UUID = UUID(), dogID: UUID, kind: EventKind, date: Date, author: String = "", groupID: UUID = UUID()) {
        self.id = id
        self.dogID = dogID
        self.kind = kind
        self.date = date
        self.author = author
        self.groupID = groupID
    }
}
