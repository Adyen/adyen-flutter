@_spi(AdyenInternal) import Adyen
import UIKit

protocol DropInRootViewController: UIViewController {
    var hostViewController: UIViewController? { get set }

    func dismissDropIn(animated: Bool, completion: (() -> Void)?)
}

final class DropInWindowManager {
    enum State: Equatable {
        case idle
        case presented
        case dismissing
    }

    /// Kept above the host window so the Drop-in stays in front of content the host application presents itself.
    private static let dropInWindowLevel = UIWindow.Level(rawValue: UIWindow.Level.normal.rawValue + 1)

    /// Invoked when the Drop-in window is torn down without a dismissal having been requested, for example when the
    /// hosting scene disconnects.
    var onUnexpectedDismissal: (() -> Void)?

    private let hostWindowProvider: () -> UIWindow?
    private let windowFactory: (UIWindowScene) -> UIWindow
    private let notificationCenter: NotificationCenter
    private weak var previousKeyWindow: UIWindow?
    private weak var previousRootView: UIView?
    private var previousAccessibilityElementsHidden = false
    private var dropInWindow: UIWindow?
    private weak var dropInRootViewController: DropInRootViewController?
    private var sceneDisconnectObserver: NSObjectProtocol?
    private var dismissalCompletions: [() -> Void] = []
    private(set) var state = State.idle

    init(
        hostWindowProvider: @escaping () -> UIWindow? = { UIApplication.shared.adyen.mainKeyWindow },
        windowFactory: @escaping (UIWindowScene) -> UIWindow = UIWindow.init(windowScene:),
        notificationCenter: NotificationCenter = .default
    ) {
        self.hostWindowProvider = hostWindowProvider
        self.windowFactory = windowFactory
        self.notificationCenter = notificationCenter
    }

    deinit {
        if let sceneDisconnectObserver {
            notificationCenter.removeObserver(sceneDisconnectObserver)
        }
    }

    @discardableResult
    func present(rootViewController: DropInRootViewController) throws -> Bool {
        assertMainThread()

        guard state == .idle else {
            return false
        }

        guard let hostWindow = hostWindowProvider(), let windowScene = hostWindow.windowScene else {
            throw PlatformError(errorDescription: "Host window scene is not available.")
        }

        let hostRootViewController = hostWindow.rootViewController
        previousKeyWindow = hostWindow
        previousRootView = hostRootViewController?.view
        previousAccessibilityElementsHidden = previousRootView?.accessibilityElementsHidden ?? false

        let window = windowFactory(windowScene)
        window.windowLevel = Self.dropInWindowLevel
        window.backgroundColor = .clear
        window.isOpaque = false
        window.overrideUserInterfaceStyle = hostWindow.overrideUserInterfaceStyle
        // Mirroring the host keeps the preferences configured through Flutter applied.
        rootViewController.hostViewController = hostRootViewController
        rootViewController.view.backgroundColor = .clear
        window.accessibilityViewIsModal = true
        rootViewController.view.accessibilityViewIsModal = true
        dropInRootViewController = rootViewController
        window.rootViewController = rootViewController
        dropInWindow = window
        observeDisconnect(of: windowScene)
        previousRootView?.accessibilityElementsHidden = true
        window.makeKeyAndVisible()
        state = .presented
        return true
    }

    func dismiss(animated: Bool, completion: @escaping () -> Void = {}) {
        assertMainThread()

        guard state != .idle else {
            completion()
            return
        }

        dismissalCompletions.append(completion)

        guard state == .presented else { return }
        state = .dismissing

        guard let dropInRootViewController, dropInRootViewController.presentedViewController != nil else {
            restorePreviousWindow()
            return
        }

        // `self` is captured strongly on purpose: the window must be restored even if the owner released us.
        dropInRootViewController.dismissDropIn(animated: animated, completion: { self.restorePreviousWindow() })
    }

    func cleanUp() {
        assertMainThread()
        dismiss(animated: false)
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
            let wasDismissalRequested = !dismissalCompletions.isEmpty
            restorePreviousWindow(shouldMakeKey: false)
            if !wasDismissalRequested {
                onUnexpectedDismissal?()
            }
        }
    }

    private func restorePreviousWindow(shouldMakeKey: Bool = true) {
        assertMainThread()
        guard state != .idle else { return }
        if let sceneDisconnectObserver {
            notificationCenter.removeObserver(sceneDisconnectObserver)
            self.sceneDisconnectObserver = nil
        }

        let dismissedWindowScene = dropInWindow?.windowScene
        dropInWindow?.isHidden = true
        dropInWindow?.rootViewController = nil
        dropInRootViewController = nil
        dropInWindow = nil
        previousRootView?.accessibilityElementsHidden = previousAccessibilityElementsHidden

        if shouldMakeKey,
           let previousKeyWindow,
           previousKeyWindow.windowScene === dismissedWindowScene,
           !previousKeyWindow.isHidden {
            previousKeyWindow.makeKey()
            UIAccessibility.post(
                notification: .screenChanged,
                argument: previousKeyWindow.rootViewController?.view
            )
        }

        previousKeyWindow = nil
        previousRootView = nil
        previousAccessibilityElementsHidden = false
        state = .idle
        let completions = dismissalCompletions
        dismissalCompletions.removeAll()
        completions.forEach { $0() }
    }
}
