import CoreData
import Foundation

/// Core Data stack manager
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    private let logger = AppLogger.shared

    // MARK: - Preview Support
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        return controller
    }()

    init(inMemory: Bool = false) {
        // Use an in-memory NSPersistentContainer with programmatic model
        container = NSPersistentContainer(name: "OpenClaw", managedObjectModel: Self.createModel())

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                AppLogger.shared.error("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Programmatic Model

    static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // FamilyEntity
        let familyEntity = NSEntityDescription()
        familyEntity.name = "FamilyEntity"
        familyEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let familyIdAttr = NSAttributeDescription()
        familyIdAttr.name = "id"
        familyIdAttr.attributeType = .UUIDAttributeType

        let familyNameAttr = NSAttributeDescription()
        familyNameAttr.name = "name"
        familyNameAttr.attributeType = .stringAttributeType

        let familyDataAttr = NSAttributeDescription()
        familyDataAttr.name = "jsonData"
        familyDataAttr.attributeType = .binaryDataAttributeType

        let familyCreatedAttr = NSAttributeDescription()
        familyCreatedAttr.name = "createdAt"
        familyCreatedAttr.attributeType = .dateAttributeType

        let familyUpdatedAttr = NSAttributeDescription()
        familyUpdatedAttr.name = "updatedAt"
        familyUpdatedAttr.attributeType = .dateAttributeType

        familyEntity.properties = [familyIdAttr, familyNameAttr, familyDataAttr, familyCreatedAttr, familyUpdatedAttr]

        // ChatMessageEntity
        let chatEntity = NSEntityDescription()
        chatEntity.name = "ChatMessageEntity"
        chatEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let chatIdAttr = NSAttributeDescription()
        chatIdAttr.name = "id"
        chatIdAttr.attributeType = .UUIDAttributeType

        let chatRoleAttr = NSAttributeDescription()
        chatRoleAttr.name = "role"
        chatRoleAttr.attributeType = .stringAttributeType

        let chatContentAttr = NSAttributeDescription()
        chatContentAttr.name = "content"
        chatContentAttr.attributeType = .stringAttributeType

        let chatTimestampAttr = NSAttributeDescription()
        chatTimestampAttr.name = "timestamp"
        chatTimestampAttr.attributeType = .dateAttributeType

        let chatSkillAttr = NSAttributeDescription()
        chatSkillAttr.name = "skill"
        chatSkillAttr.attributeType = .stringAttributeType
        chatSkillAttr.isOptional = true

        chatEntity.properties = [chatIdAttr, chatRoleAttr, chatContentAttr, chatTimestampAttr, chatSkillAttr]

        // GenericDataEntity - flexible storage for skill data
        let dataEntity = NSEntityDescription()
        dataEntity.name = "GenericDataEntity"
        dataEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let dataIdAttr = NSAttributeDescription()
        dataIdAttr.name = "id"
        dataIdAttr.attributeType = .UUIDAttributeType

        let dataTypeAttr = NSAttributeDescription()
        dataTypeAttr.name = "dataType"
        dataTypeAttr.attributeType = .stringAttributeType

        let dataJsonAttr = NSAttributeDescription()
        dataJsonAttr.name = "jsonData"
        dataJsonAttr.attributeType = .binaryDataAttributeType

        let dataCreatedAttr = NSAttributeDescription()
        dataCreatedAttr.name = "createdAt"
        dataCreatedAttr.attributeType = .dateAttributeType

        dataEntity.properties = [dataIdAttr, dataTypeAttr, dataJsonAttr, dataCreatedAttr]

        model.entities = [familyEntity, chatEntity, dataEntity]
        return model
    }

    // MARK: - Family Operations

    func saveFamily(_ family: Family) {
        let context = container.viewContext
        context.perform {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FamilyEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", family.id as CVarArg)

            do {
                let results = try context.fetch(fetchRequest)
                let entity: NSManagedObject

                if let existing = results.first {
                    entity = existing
                } else {
                    entity = NSManagedObject(entity: NSEntityDescription.entity(forEntityName: "FamilyEntity", in: context)!, insertInto: context)
                }

                entity.setValue(family.id, forKey: "id")
                entity.setValue(family.name, forKey: "name")
                entity.setValue(try? JSONEncoder().encode(family), forKey: "jsonData")
                entity.setValue(Date(), forKey: "updatedAt")

                if results.isEmpty {
                    entity.setValue(Date(), forKey: "createdAt")
                }

                try context.save()
            } catch {
                AppLogger.shared.error("Failed to save family: \(error.localizedDescription)")
            }
        }
    }

    func loadFamily() -> Family? {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FamilyEntity")
        fetchRequest.fetchLimit = 1

        do {
            guard let entity = try context.fetch(fetchRequest).first,
                  let data = entity.value(forKey: "jsonData") as? Data else {
                return nil
            }
            return try JSONDecoder().decode(Family.self, from: data)
        } catch {
            logger.error("Failed to load family: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Chat Messages

    func saveChatMessage(_ message: ChatMessage) {
        let context = container.viewContext
        context.perform {
            let entity = NSManagedObject(entity: NSEntityDescription.entity(forEntityName: "ChatMessageEntity", in: context)!, insertInto: context)
            entity.setValue(message.id, forKey: "id")
            entity.setValue(message.role.rawValue, forKey: "role")
            entity.setValue(message.content, forKey: "content")
            entity.setValue(message.timestamp, forKey: "timestamp")
            entity.setValue(message.skill?.rawValue, forKey: "skill")

            do {
                try context.save()
            } catch {
                AppLogger.shared.error("Failed to save chat message: \(error.localizedDescription)")
            }
        }
    }

    func loadChatHistory(limit: Int = 50) -> [ChatMessage] {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ChatMessageEntity")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        fetchRequest.fetchLimit = limit

        do {
            return try context.fetch(fetchRequest).compactMap { entity in
                guard let id = entity.value(forKey: "id") as? UUID,
                      let roleString = entity.value(forKey: "role") as? String,
                      let role = MessageRole(rawValue: roleString),
                      let content = entity.value(forKey: "content") as? String,
                      let timestamp = entity.value(forKey: "timestamp") as? Date else {
                    return nil
                }
                let skillString = entity.value(forKey: "skill") as? String
                let skill = skillString.flatMap { SkillType(rawValue: $0) }
                return ChatMessage(id: id, role: role, content: content, timestamp: timestamp, skill: skill)
            }
        } catch {
            logger.error("Failed to load chat history: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Generic Data Storage

    func saveData<T: Codable>(_ data: T, type: String) {
        let context = container.viewContext
        context.perform {
            let entity = NSManagedObject(entity: NSEntityDescription.entity(forEntityName: "GenericDataEntity", in: context)!, insertInto: context)
            entity.setValue(UUID(), forKey: "id")
            entity.setValue(type, forKey: "dataType")
            entity.setValue(try? JSONEncoder().encode(data), forKey: "jsonData")
            entity.setValue(Date(), forKey: "createdAt")

            do {
                try context.save()
            } catch {
                AppLogger.shared.error("Failed to save data of type \(type): \(error.localizedDescription)")
            }
        }
    }

    func loadData<T: Codable>(type: String) -> [T] {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "GenericDataEntity")
        fetchRequest.predicate = NSPredicate(format: "dataType == %@", type)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return try context.fetch(fetchRequest).compactMap { entity in
                guard let data = entity.value(forKey: "jsonData") as? Data else { return nil }
                return try? JSONDecoder().decode(T.self, from: data)
            }
        } catch {
            logger.error("Failed to load data of type \(type): \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Cleanup

    func deleteAllData() throws {
        let context = container.viewContext
        for entityName in ["FamilyEntity", "ChatMessageEntity", "GenericDataEntity"] {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(deleteRequest)
        }
        try context.save()
    }
}
