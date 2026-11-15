import CoreData
import SwiftUI
import WalkCore

/// The iPhone app's state: dogs and events read from Core Data as plain WalkCore values,
/// plus the device's own settings (selected dogs, the user's name).
@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var dogs: [Dog] = []
    @Published private(set) var events: [WalkEvent] = []
    @Published var selectedDogIDs: Set<UUID> = [] {
        didSet { saveSelection() }
    }
    @Published var authorName: String = UserDefaults.standard.string(forKey: "authorName") ?? "" {
        didSet {
            UserDefaults.standard.set(authorName, forKey: "authorName")
            onChange?()
        }
    }
    /// The last one-tap record, kept for a few seconds so it can be undone.
    @Published var lastRecord: [WalkEvent]?

    let persistence: PersistenceController
    private var context: NSManagedObjectContext { persistence.container.viewContext }
    var onChange: (@MainActor () -> Void)?
    private var observer: NSObjectProtocol?

    init(persistence: PersistenceController) {
        self.persistence = persistence
        reload()
        loadSelection()
        observer = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextObjectsDidChange, object: persistence.container.viewContext, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.reload() }
        }
    }

    // MARK: - Reading

    func reload() {
        let dogRequest = NSFetchRequest<CDDog>(entityName: "Dog")
        dogRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true), NSSortDescriptor(key: "createdAt", ascending: true)]
        let newDogs = ((try? context.fetch(dogRequest)) ?? []).compactMap(\.value)

        let eventRequest = NSFetchRequest<CDEvent>(entityName: "Event")
        eventRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let newEvents = ((try? context.fetch(eventRequest)) ?? []).compactMap(\.value)

        if newDogs != dogs { dogs = newDogs }
        if newEvents != events { events = newEvents }
        let valid = Set(dogs.map(\.id))
        if !selectedDogIDs.isSubset(of: valid) { selectedDogIDs = selectedDogIDs.intersection(valid) }
        onChange?()
    }

    func dog(_ id: UUID) -> Dog? { dogs.first { $0.id == id } }

    var selectedDogs: [Dog] { dogs.filter { selectedDogIDs.contains($0.id) } }

    // MARK: - Recording

    /// One tap: log `kind` for every selected dog now.
    @discardableResult
    func record(_ kind: EventKind, date: Date = .now) -> [WalkEvent] {
        let ids = dogs.map(\.id).filter { selectedDogIDs.contains($0) }
        let made = WalkLog.makeEvents(kind: kind, dogIDs: ids, date: date, author: authorName)
        add(made)
        lastRecord = made
        Haptics.play(kind == .walkStart || kind == .walkEnd ? .walk : .recorded)
        return made
    }

    func undoLastRecord() {
        guard let made = lastRecord else { return }
        remove(made.map(\.id))
        lastRecord = nil
        Haptics.play(.undone)
    }

    /// Add events (from this screen or from the Watch). Events already stored (same id) are skipped.
    func add(_ new: [WalkEvent]) {
        let existing = Set(events.map(\.id))
        for e in new where !existing.contains(e.id) {
            guard let dog = cdDog(e.dogID) else { continue }
            let obj = CDEvent(context: context)
            obj.id = e.id
            obj.kind = e.kind.rawValue
            obj.date = e.date
            obj.author = e.author
            obj.groupID = e.groupID
            obj.dog = dog
        }
        save()
    }

    func remove(_ ids: [UUID]) {
        guard !ids.isEmpty else { return }
        let request = NSFetchRequest<CDEvent>(entityName: "Event")
        request.predicate = NSPredicate(format: "id IN %@", ids)
        for obj in (try? context.fetch(request)) ?? [] { context.delete(obj) }
        save()
    }

    func update(_ e: WalkEvent) {
        let request = NSFetchRequest<CDEvent>(entityName: "Event")
        request.predicate = NSPredicate(format: "id == %@", e.id as CVarArg)
        guard let obj = (try? context.fetch(request))?.first, let dog = cdDog(e.dogID) else { return }
        obj.kind = e.kind.rawValue
        obj.date = e.date
        obj.dog = dog
        save()
    }

    func apply(_ op: WatchSync.Operation) {
        switch op {
        case .add(let new): add(new)
        case .remove(let ids): remove(ids)
        }
    }

    // MARK: - Dogs

    func addDog(name: String, avatar: Avatar) {
        let obj = CDDog(context: context)
        obj.id = UUID()
        obj.name = name
        obj.avatar = avatar.rawValue
        obj.order = Int64((dogs.map(\.order).max() ?? -1) + 1)
        obj.createdAt = .now
        obj.household = household()
        save()
        if let id = obj.id { selectedDogIDs.insert(id) }
    }

    func updateDog(_ dog: Dog) {
        guard let obj = cdDog(dog.id) else { return }
        obj.name = dog.name
        obj.avatar = dog.avatar.rawValue
        save()
    }

    /// Deletes the dog and all of its records.
    func deleteDog(_ id: UUID) {
        guard let obj = cdDog(id) else { return }
        context.delete(obj)
        save()
    }

    func moveDogs(from source: IndexSet, to destination: Int) {
        var ordered = dogs
        ordered.move(fromOffsets: source, toOffset: destination)
        for (i, d) in ordered.enumerated() { cdDog(d.id)?.order = Int64(i) }
        save()
    }

    // MARK: - Helpers

    private func cdDog(_ id: UUID) -> CDDog? {
        let request = NSFetchRequest<CDDog>(entityName: "Dog")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    private func household() -> CDHousehold {
        let request = NSFetchRequest<CDHousehold>(entityName: "Household")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        if let first = (try? context.fetch(request))?.first { return first }
        let h = CDHousehold(context: context)
        h.id = UUID()
        h.createdAt = .now
        return h
    }

    private func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            saveError = error.localizedDescription
            context.rollback()
        }
        reload()
    }

    @Published var saveError: String?

    private func saveSelection() {
        UserDefaults.standard.set(selectedDogIDs.map(\.uuidString), forKey: "selectedDogs")
    }

    private func loadSelection() {
        if let saved = UserDefaults.standard.array(forKey: "selectedDogs") as? [String] {
            selectedDogIDs = Set(saved.compactMap(UUID.init(uuidString:))).intersection(dogs.map(\.id))
        } else {
            selectedDogIDs = Set(dogs.map(\.id))
        }
    }
}
