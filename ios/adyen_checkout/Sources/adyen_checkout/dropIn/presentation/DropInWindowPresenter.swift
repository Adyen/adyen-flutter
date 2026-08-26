import UIKit

final class DropInWindowPresenter: DropInWindowPresenting {
    private let notificationCenter: NotificationCenter
    private var sceneDisconnectObserver: NSObjectProtocol?

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    deinit {
        stopObservingSceneDisconnect()
    }

    func makeWindow(for windowScene: UIWindowScene) -> UIWindow {
        UIWindow(windowScene: windowScene)
    }

    func dismiss(_ viewController: UIViewController, animated: Bool, completion: @escaping () -> Void) {
        viewController.dismiss(animated: animated, completion: completion)
    }

    func observeSceneDisconnect(of windowScene: UIWindowScene, handler: @escaping () -> Void) {
        sceneDisconnectObserver = notificationCenter.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: windowScene,
            queue: .main
        ) { _ in
            handler()
        }
    }

    func stopObservingSceneDisconnect() {
        guard let sceneDisconnectObserver else { return }
        notificationCenter.removeObserver(sceneDisconnectObserver)
        self.sceneDisconnectObserver = nil
    }
}
