import Foundation
import WalkCore
import WatchConnectivity

/// The Watch's state. Records are saved on the Watch first (a JSON file), then queued to the iPhone with
/// transferUserInfo, which is delivered even if the iPhone is at home and the walk is long (spec 6).
/// The iPhone answers with a snapshot of dogs and recent events (applicationContext).
@MainActor
final class WatchStore: NSObject, ObservableObject {
    @Published private(set) var dogs: [Dog] = []
    @Published private(set) var events: [WalkEvent] = []
    @Published var selectedDogIDs: Set<UUID> = [] {
        didSet { UserDefaults.standard.set(selectedDogIDs.map(\.uuidString), forKey: "selectedDogs") }
    }
    /// The last tap, shown with an undo button for a few seconds.
    @Published var lastRecord: [WalkEvent]?

    private struct Saved: Codable {
        var snapshot: WatchSync.Snapshot?
        var own: [WalkEvent] = []
        var removed: [UUID] = []
    }

    private var saved = Saved()
    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("watch-log.json")
    }()

    override init() {
        super.init()
        load()
        if let ids = UserDefaults.standard.array(forKey: "selectedDogs") as? [String] {
            selectedDogIDs = Set(ids.compactMap(UUID.init(uuidString:)))
        }
        rebuild()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    var selectedDogs: [Dog] { dogs.filter { selectedDogIDs.contains($0.id) } }

    func dog(_ id: UUID) -> Dog? { dogs.first { $0.id == id } }

    // MARK: Recording

    func record(_ kind: EventKind) {
        let ids = dogs.map(\.id).filter { selectedDogIDs.contains($0) }
        guard !ids.isEmpty else { return }
        let made = WalkLog.makeEvents(kind: kind, dogIDs: ids, date: .now, author: authorName)
        saved.own.append(contentsOf: made)
        persist()
        rebuild()
        send(.add(made))
        lastRecord = made
        Haptics.play(kind == .walkStart || kind == .walkEnd ? .walk : .recorded)
    }

    func undoLastRecord() {
        guard let made = lastRecord else { return }
        let ids = made.map(\.id)
        saved.removed.append(contentsOf: ids)
        saved.own.removeAll { ids.contains($0.id) }
        persist()
        rebuild()
        send(.remove(ids))
        lastRecord = nil
        Haptics.play(.undone)
    }

    /// The user's name is set on the iPhone and arrives with each snapshot ("author"). Empty until then.
    private var authorName: String {
        UserDefaults.standard.string(forKey: "authorName") ?? ""
    }

    // MARK: State

    private func rebuild() {
        let snap = saved.snapshot
        dogs = (snap?.dogs ?? []).sorted { $0.order < $1.order }
        // Keep only own events from the last 3 days; older ones are on the iPhone already (or will be).
        let cutoff = Date.now.addingTimeInterval(-3 * 86400)
        saved.own.removeAll { $0.date < cutoff }
        if saved.removed.count > 500 { saved.removed.removeFirst(saved.removed.count - 500) }
        events = WalkLog.merge(saved.own, snap?.events ?? [], deleted: Set(saved.removed))
        // Dogs added on the iPhone are selected by default; dogs that no longer exist are dropped.
        let valid = Set(dogs.map(\.id))
        let known = Set(UserDefaults.standard.array(forKey: "knownDogs") as? [String] ?? []).compactMap(UUID.init(uuidString:))
        let newDogs = valid.subtracting(known)
        if !newDogs.isEmpty || !selectedDogIDs.isSubset(of: valid) {
            selectedDogIDs = selectedDogIDs.intersection(valid).union(newDogs)
        }
        UserDefaults.standard.set(valid.map(\.uuidString), forKey: "knownDogs")
    }

    private func apply(snapshot: WatchSync.Snapshot, author: String?) {
        if let current = saved.snapshot, current.madeAt > snapshot.madeAt { return }
        saved.snapshot = snapshot
        if let author { UserDefaults.standard.set(author, forKey: "authorName") }
        persist()
        rebuild()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        if let s = try? decoder.decode(Saved.self, from: data) { saved = s }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        if let data = try? encoder.encode(saved) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func send(_ op: WatchSync.Operation) {
        guard WCSession.isSupported(), let dict = try? WatchSync.encode(WatchSync.OperationEnvelope(op)) else { return }
        // Queued by the system: delivered when the iPhone is reachable, even after the Watch app closes.
        WCSession.default.transferUserInfo(dict)
    }

    fileprivate func received(context: [String: Any]) {
        guard let snap = WatchSync.decode(WatchSync.Snapshot.self, from: context) else { return }
        apply(snapshot: snap, author: context["author"] as? String)
    }
}

extension WatchStore: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let context = session.receivedApplicationContext
        Task { @MainActor in self.received(context: context) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in self.received(context: applicationContext) }
    }
}
