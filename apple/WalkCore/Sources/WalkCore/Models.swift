import Foundation

/// What can be logged. Raw values are stored (Core Data, iCloud, Watch messages), so never rename them.
public enum EventKind: String, Codable, CaseIterable, Sendable {
    case pee
    case poop
    case water
    case food
    case walkStart
    case walkEnd

    /// Kinds that can be one-tap buttons, in screen order.
    public static let buttonKinds: [EventKind] = [.pee, .poop, .water, .food]
    /// Always shown. おみず and ごはん are optional (turned on in せってい).
    public static let standardButtons: [EventKind] = [.pee, .poop]

    /// The buttons to show: the standard two plus the optional ones turned on, in screen order.
    public static func buttons(extra: Set<EventKind>) -> [EventKind] {
        buttonKinds.filter { standardButtons.contains($0) || extra.contains($0) }
    }

    /// Lay buttons out in rows of two; an odd last button gets a row of its own (full width).
    public static func rows(_ buttons: [EventKind]) -> [[EventKind]] {
        stride(from: 0, to: buttons.count, by: 2).map { Array(buttons[$0 ..< min($0 + 2, buttons.count)]) }
    }

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
    /// The user's own photo of the dog (small square JPEG). When set, it is shown instead of `avatar`.
    public var photo: Data?

    public init(id: UUID = UUID(), name: String, avatar: Avatar, order: Int, photo: Data? = nil) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.order = order
        self.photo = photo
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
