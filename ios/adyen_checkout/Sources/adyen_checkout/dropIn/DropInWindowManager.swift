@_spi(AdyenInternal) import Adyen
import UIKit

final class DropInWindowManager {
    /// Kept above the host window so the Drop-in stays in front of content the host application presents itself.
    private static let dropInWindowLevel = UIWindow.Level(rawValue: UIWindow.Level.normal.rawValue + 1)

    /// Invoked when the Drop-in window is torn down without a dismissal having been requested, for example when the
    /// hosting scene disconnects.
    var onUnexpectedDismissal: (() -> Void)?

    private let windowFactory: (UIWindowScene) -> UIWindow
    private let dismissViewController: (UIViewController, Bool, @escaping () -> Void) -> Void
    private let notificationCenter: NotificationCenter
    private var dropInWindow: UIWindow?
    private var sceneDisconnectObserver: NSObjectProtocol?
    private var pendingDismissalCompletion: (() -> Void)?

    init(
        windowFactory: @escaping (UIWindowScene) -> UIWindow = UIWindow.init(windowScene:),
        dismissViewController: @escaping (UIViewController, Bool, @escaping () -> Void) -> Void = { viewController, animated, completion in
            viewController.dismiss(animated: animated, completion: completion)
        },
        notificationCenter: NotificationCenter = .default
    ) {
        self.windowFactory = windowFactory
        self.dismissViewController = dismissViewController
        self.notificationCenter = notificationCenter
    }

    deinit {
        if let sceneDisconnectObserver {
            notificationCenter.removeObserver(sceneDisconnectObserver)
        }
    }

    @discardableResult
    func present(dropInViewController: UIViewController) throws -> Bool {
        assertMainThread()

        guard dropInWindow == nil else {
            adyenPrint("Drop-in is already visible. Skipping presentation of a new Drop-in window.")
            return false
        }

        guard let hostWindow = UIApplication.shared.adyen.mainKeyWindow,
              let windowScene = hostWindow.windowScene else {
            throw PlatformError(errorDescription: "Host window scene is not available.")
        }

        let rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .clear

        let window = windowFactory(windowScene)
        window.windowLevel = Self.dropInWindowLevel
        window.backgroundColor = .clear
        window.isOpaque = false
        window.overrideUserInterfaceStyle = hostWindow.overrideUserInterfaceStyle
        window.rootViewController = rootViewController

        dropInWindow = window
        observeDisconnect(of: windowScene)

        window.makeKeyAndVisible()
        rootViewController.present(dropInViewController, animated: true)
        return true
    }

    func dismiss(
        viewController: UIViewController,
        animated: Bool,
        completion: @escaping () -> Void = {}
    ) {
        assertMainThread()
        guard pendingDismissalCompletion == nil,
              let window = dropInWindow,
              let rootViewController = window.rootViewController,
              rootViewController.presentedViewController === viewController else {
            return
        }
        pendingDismissalCompletion = completion

        // `self` is captured strongly on purpose: the window must be torn down even if the owner released us.
        dismissViewController(rootViewController, animated) {
            guard self.dropInWindow === window else { return }
            self.tearDownWindow()
        }
    }

    func cleanUp() {
        assertMainThread()
        pendingDismissalCompletion = nil
        tearDownWindow()
    }

    private func assertMainThread() {
        assert(Thread.isMainThread, "DropInWindowManager must be used on the main thread.")
    }

    private func observeDisconnect(of windowScene: UIWindowScene) {
        sceneDisconnectObserver = notificationCenter.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: windowScene,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let wasDismissalRequested = pendingDismissalCompletion != nil
            tearDownWindow()
            if !wasDismissalRequested {
                onUnexpectedDismissal?()
            }
        }
    }

    private func tearDownWindow() {
        assertMainThread()
        guard let window = dropInWindow else { return }
        if let sceneDisconnectObserver {
            notificationCenter.removeObserver(sceneDisconnectObserver)
            self.sceneDisconnectObserver = nil
        }

        let completion = pendingDismissalCompletion
        pendingDismissalCompletion = nil
        window.isHidden = true
        window.rootViewController = nil
        dropInWindow = nil
        completion?()
    }
}
