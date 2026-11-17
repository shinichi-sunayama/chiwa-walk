import Foundation
import WalkCore
import WatchConnectivity
import WidgetKit

/// The Watch's state. Records are saved on the Watch first (a JSON file), then queued to the iPhone with
/// transferUserInfo, which is delivered even if the iPhone is at home and the walk is long (spec 6).
/// The iPhone answers with a snapshot of dogs and recent events (applicationContext).
@MainActor
final class WatchStore: NSObject, ObservableObject {
    @Published private(set) var dogs: [Dog] = []
    @Published private(set) var events: [WalkEvent] = []
    /// Buttons chosen on the iPhone (おしっこ・うんち, plus おみず・ごはん if turned on).
    @Published private(set) var buttons: [EventKind] = EventKind.standardButtons
    @Published var selectedDogIDs: Set<UUID> = [] {
        didSet {
            UserDefaults.standard.set(selectedDogIDs.map(\.uuidString), forKey: "selectedDogs")
            updateComplication()
        }
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
        // App Store screenshots (simulator): sample dogs and records, no file, no iPhone link.
        if UserDefaults.standard.bool(forKey: "shotDemo") {
            let now = Date()
            saved.snapshot = WatchSync.Snapshot(dogs: DemoData.dogs, events: DemoData.events(now: now), madeAt: now)
            selectedDogIDs = [DemoData.ohagiID]
            rebuild()
            return
        }
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

    var selectionLabel: String { DogSelection.label(selectedDogIDs, dogs: dogs) }

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
        buttons = snap?.buttons ?? EventKind.standardButtons
        // Keep only own events from the last 3 days; older ones are on the iPhone already (or will be).
        let cutoff = Date.now.addingTimeInterval(-3 * 86400)
        saved.own.removeAll { $0.date < cutoff }
        if saved.removed.count > 500 { saved.removed.removeFirst(saved.removed.count - 500) }
        events = WalkLog.merge(saved.own, snap?.events ?? [], deleted: Set(saved.removed))
        // Dogs that no longer exist are dropped. New dogs are NOT added by themselves
        // (records must not go to a dog by surprise); the iPhone's choice arrives with the snapshot.
        let cleaned = DogSelection.cleaned(selectedDogIDs, dogs: dogs)
        if cleaned != selectedDogIDs { selectedDogIDs = cleaned }
        updateComplication()
    }

    /// Hand the Watch face what it shows (App Group), and refresh it only when something changed.
    private func updateComplication() {
        guard let shared = UserDefaults(suiteName: ComplicationData.appGroup) else { return }
        let data = ComplicationData.make(dogs: dogs, selected: selectedDogIDs, events: events, now: .now)
        let old = ComplicationData.decode(shared.data(forKey: ComplicationData.defaultsKey))
        guard old?.lines != data.lines, let encoded = data.encoded() else { return }
        shared.set(encoded, forKey: ComplicationData.defaultsKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func apply(snapshot: WatchSync.Snapshot, author: String?) {
        if let current = saved.snapshot, current.madeAt > snapshot.madeAt { return }
        saved.snapshot = snapshot
        // Follow the iPhone when its choice of dogs changes; a choice made here stays until then.
        if let phone = snapshot.selected.map({ Set($0) }) {
            let key = "phoneSelected"
            let last = Set((UserDefaults.standard.array(forKey: key) as? [String] ?? []).compactMap(UUID.init(uuidString:)))
            if phone != last {
                UserDefaults.standard.set(phone.map(\.uuidString), forKey: key)
                selectedDogIDs = phone
            }
        }
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
