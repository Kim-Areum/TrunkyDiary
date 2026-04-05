import UIKit
import CoreData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var syncObservation: Any?
    private var syncTimeout: DispatchWorkItem?
    private var didRoute = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        print("🟢 SceneDelegate scene 호출됨")
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .light
        window.backgroundColor = DS.bgBase

        // 스플래시 표시
        let splashVC = SplashViewController()
        window.rootViewController = splashVC
        window.makeKeyAndVisible()
        self.window = window

        NotificationCenter.default.addObserver(self, selector: #selector(handleBabyCreated), name: Notification.Name("babyCreated"), object: nil)

        // iCloud 켜져 있고 로컬에 데이터 없으면 동기화 기다리기
        let iCloudEnabled = !(UserDefaults.standard.object(forKey: "iCloudSyncDisabled") as? Bool ?? false)
        let hasBaby = CoreDataStack.shared.fetchBaby() != nil

        if iCloudEnabled && !hasBaby {
            waitForSync()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.routeToMain()
            }
        }
    }

    /// iCloud 동기화 완료를 기다림 (최대 8초)
    private func waitForSync() {
        syncObservation = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let event = notification.userInfo?[
                NSPersistentCloudKitContainer.eventNotificationUserInfoKey
            ] as? NSPersistentCloudKitContainer.Event else { return }

            // import 완료 시 라우팅
            if event.type == .import, event.endDate != nil {
                DispatchQueue.main.async {
                    self?.finishWaiting()
                }
            }
        }

        // 타임아웃 8초 — 동기화가 안 오면 그냥 진행
        let timeout = DispatchWorkItem { [weak self] in
            self?.finishWaiting()
        }
        syncTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: timeout)
    }

    private func finishWaiting() {
        guard !didRoute else { return }
        didRoute = true
        syncTimeout?.cancel()
        if let obs = syncObservation {
            NotificationCenter.default.removeObserver(obs)
            syncObservation = nil
        }
        routeToMain()
    }

    @objc private func handleBabyCreated() {
        guard let window = window else { return }
        let mainVC = MainTabBarController()
        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve) {
            window.rootViewController = mainVC
        }
    }

    func routeToMain() {
        guard let window = window else { return }

        let rootVC: UIViewController
        if CoreDataStack.shared.fetchBaby() != nil {
            rootVC = MainTabBarController()
        } else {
            rootVC = BabySetupViewController()
        }

        UIView.transition(with: window, duration: 0.4, options: .transitionCrossDissolve) {
            window.rootViewController = rootVC
        }
    }
}
