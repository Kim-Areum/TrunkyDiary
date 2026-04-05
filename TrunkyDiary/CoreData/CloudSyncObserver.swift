import Foundation
import CoreData

/// CloudKit 동기화 이벤트를 감시하고 UI에 반영
final class CloudSyncObserver {

    static let shared = CloudSyncObserver()

    private let initialSyncDoneKey = "cloudSync.initialSyncDone"
    private var observation: Any?
    private var isImporting = false

    private var initialSyncDone: Bool {
        get { UserDefaults.standard.bool(forKey: initialSyncDoneKey) }
        set { UserDefaults.standard.set(newValue, forKey: initialSyncDoneKey) }
    }

    private init() {}

    /// CloudKit 동기화 이벤트 감시 시작
    func start() {
        guard observation == nil else { return }
        observation = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let event = notification.userInfo?[
                NSPersistentCloudKitContainer.eventNotificationUserInfoKey
            ] as? NSPersistentCloudKitContainer.Event else { return }

            self?.handleEvent(event)
        }
    }

    private func handleEvent(_ event: NSPersistentCloudKitContainer.Event) {
        guard event.type == .import else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            if event.endDate == nil {
                // Import 시작
                if !self.isImporting {
                    self.isImporting = true
                    if !self.initialSyncDone {
                        CloudSyncBanner.show()
                    }
                }
            } else {
                // Import 완료
                self.isImporting = false
                CloudSyncBanner.dismiss()

                if event.succeeded {
                    if !self.initialSyncDone {
                        self.initialSyncDone = true
                    }
                    NotificationCenter.default.post(name: .cloudSyncCompleted, object: nil)
                } else {
                    CloudSyncBanner.showError("iCloud 동기화에 실패했어요")
                }
            }
        }
    }
}

extension Notification.Name {
    static let cloudSyncCompleted = Notification.Name("cloudSyncCompleted")
}
