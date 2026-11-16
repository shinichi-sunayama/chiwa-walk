import CoreData
import WalkCore

// The walk log on the iPhone, stored with Core Data.
// The model is built in code (no .xcdatamodeld) and follows the rules of iCloud sync (NSPersistentCloudKitContainer):
// every attribute optional or defaulted, every relationship optional with an inverse, no unique constraints.
// Graph: Household (one per family, the unit shared with the family later) -> Dogs -> Events.
// iCloud is OFF for now (cloudKitContainerOptions = nil); turning it on later only changes `PersistenceController.init`.
// Once the schema is in iCloud production, NEVER rename or remove attributes; only add new optional ones.

@objc(CDHousehold)
final class CDHousehold: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var createdAt: Date?
    @NSManaged var dogs: NSSet?
}

@objc(CDDog)
final class CDDog: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var avatar: String?
    @NSManaged var order: Int64
    @NSManaged var createdAt: Date?
    @NSManaged var photo: Data?
    @NSManaged var household: CDHousehold?
    @NSManaged var events: NSSet?

    var value: Dog? {
        guard let id else { return nil }
        return Dog(id: id, name: name ?? "", avatar: Avatar(rawValue: avatar ?? "") ?? .paw, order: Int(order), photo: photo)
    }
}

@objc(CDEvent)
final class CDEvent: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var kind: String?
    @NSManaged var date: Date?
    @NSManaged var author: String?
    @NSManaged var groupID: UUID?
    @NSManaged var dog: CDDog?

    var value: WalkEvent? {
        guard let id, let dogID = dog?.id, let kind = EventKind(rawValue: kind ?? ""), let date else { return nil }
        return WalkEvent(id: id, dogID: dogID, kind: kind, date: date, author: author ?? "", groupID: groupID ?? id)
    }
}

enum OsanpoModel {
    static let model: NSManagedObjectModel = {
        func attribute(_ name: String, _ type: NSAttributeType, defaultValue: Any? = nil) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name
            a.attributeType = type
            a.isOptional = true
            a.defaultValue = defaultValue
            return a
        }

        // The dog's own photo (square JPEG, about 20 KB). Large values go to a file next to the store (and a CKAsset in iCloud).
        let photoAttribute = attribute("photo", .binaryDataAttributeType)
        photoAttribute.allowsExternalBinaryDataStorage = true

        let household = NSEntityDescription()
        household.name = "Household"
        household.managedObjectClassName = NSStringFromClass(CDHousehold.self)

        let dog = NSEntityDescription()
        dog.name = "Dog"
        dog.managedObjectClassName = NSStringFromClass(CDDog.self)

        let event = NSEntityDescription()
        event.name = "Event"
        event.managedObjectClassName = NSStringFromClass(CDEvent.self)

        let householdDogs = NSRelationshipDescription()
        let dogHousehold = NSRelationshipDescription()
        householdDogs.name = "dogs"
        householdDogs.destinationEntity = dog
        householdDogs.minCount = 0
        householdDogs.maxCount = 0 // to-many
        householdDogs.isOptional = true
        householdDogs.deleteRule = .cascadeDeleteRule
        dogHousehold.name = "household"
        dogHousehold.destinationEntity = household
        dogHousehold.minCount = 0
        dogHousehold.maxCount = 1
        dogHousehold.isOptional = true
        dogHousehold.deleteRule = .nullifyDeleteRule
        householdDogs.inverseRelationship = dogHousehold
        dogHousehold.inverseRelationship = householdDogs

        let dogEvents = NSRelationshipDescription()
        let eventDog = NSRelationshipDescription()
        dogEvents.name = "events"
        dogEvents.destinationEntity = event
        dogEvents.minCount = 0
        dogEvents.maxCount = 0
        dogEvents.isOptional = true
        dogEvents.deleteRule = .cascadeDeleteRule
        eventDog.name = "dog"
        eventDog.destinationEntity = dog
        eventDog.minCount = 0
        eventDog.maxCount = 1
        eventDog.isOptional = true
        eventDog.deleteRule = .nullifyDeleteRule
        dogEvents.inverseRelationship = eventDog
        eventDog.inverseRelationship = dogEvents

        household.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("createdAt", .dateAttributeType),
            householdDogs,
        ]
        dog.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType),
            attribute("avatar", .stringAttributeType),
            attribute("order", .integer64AttributeType, defaultValue: 0),
            attribute("createdAt", .dateAttributeType),
            photoAttribute,
            dogHousehold,
            dogEvents,
        ]
        event.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("kind", .stringAttributeType),
            attribute("date", .dateAttributeType),
            attribute("author", .stringAttributeType),
            attribute("groupID", .UUIDAttributeType),
            eventDog,
        ]

        let model = NSManagedObjectModel()
        model.entities = [household, dog, event]
        return model
    }()
}

final class PersistenceController {
    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Osanpo", managedObjectModel: OsanpoModel.model)
        let description = container.persistentStoreDescriptions.first!
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        // Needed for iCloud sync later; harmless now.
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.cloudKitContainerOptions = nil // iCloud off in prototype 1
        container.loadPersistentStores { _, error in
            if let error {
                // The log must never be lost silently; keep the app running and show it in the settings screen.
                PersistenceController.loadError = error.localizedDescription
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    static var loadError: String?
}
