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
    private var dismissalCompletion: (() -> Void)?

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

        guard dropInWindow == nil else { return false }

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

    func dismiss(animated: Bool, completion: @escaping () -> Void = {}) {
        assertMainThread()
        guard let viewController = dropInWindow?.rootViewController?.presentedViewController else { return }
        dismiss(
            viewController: viewController,
            animated: animated,
            completion: completion
        )
    }

    func dismiss(
        viewController: UIViewController,
        animated: Bool,
        completion: @escaping () -> Void = {}
    ) {
        assertMainThread()
        guard let window = dropInWindow,
              window.rootViewController?.presentedViewController === viewController else {
            return
        }
        performDismissal(
            window: window,
            animated: animated,
            completion: completion
        )
    }

    func cleanUp() {
        dismissalCompletion = nil
        tearDownWindow()
    }

    private func performDismissal(
        window: UIWindow,
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        assertMainThread()
        guard dismissalCompletion == nil, dropInWindow === window else { return }
        dismissalCompletion = completion

        guard let rootViewController = window.rootViewController,
              rootViewController.presentedViewController != nil else {
            tearDownWindow()
            return
        }

        // `self` is captured strongly on purpose: the window must be torn down even if the owner released us.
        dismissViewController(rootViewController, animated) { self.tearDownWindow() }
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
            let wasDismissalRequested = dismissalCompletion != nil
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

        let completion = dismissalCompletion
        dismissalCompletion = nil
        window.isHidden = true
        window.rootViewController = nil
        dropInWindow = nil
        completion?()
    }
}
