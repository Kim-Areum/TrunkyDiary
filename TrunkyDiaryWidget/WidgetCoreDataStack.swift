import CoreData

final class WidgetCoreDataStack {
    static let shared = WidgetCoreDataStack()

    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BabyDiary")
        let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.io.analoglab.TrunkyDiary"
        )!
        let storeURL = appGroupURL.appendingPathComponent("BabyDiary.sqlite")
        let desc = NSPersistentStoreDescription(url: storeURL)
        desc.isReadOnly = true
        desc.cloudKitContainerOptions = nil
        container.persistentStoreDescriptions = [desc]
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Widget Core Data error: \(error)")
            }
        }
        return container
    }()

    var viewContext: NSManagedObjectContext { container.viewContext }

    func fetchBaby() -> CDBaby? {
        let req: NSFetchRequest<CDBaby> = CDBaby.fetchRequest()
        req.fetchLimit = 1
        return try? viewContext.fetch(req).first
    }

    func fetchLatestEntryWithPhoto() -> CDDiaryEntry? {
        let req: NSFetchRequest<CDDiaryEntry> = CDDiaryEntry.fetchRequest()
        req.predicate = NSPredicate(format: "photoData != nil")
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        req.fetchLimit = 1
        return try? viewContext.fetch(req).first
    }
}
