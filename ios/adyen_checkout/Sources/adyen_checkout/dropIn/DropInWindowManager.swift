@_spi(AdyenInternal) import Adyen
import UIKit

final class DropInWindowManager {
    enum State: Equatable {
        case idle
        case presented
        case dismissing
    }

    private let hostWindowProvider: () -> UIWindow?
    private let windowFactory: (UIWindowScene) -> UIWindow
    private let notificationCenter: NotificationCenter
    private weak var previousKeyWindow: UIWindow?
    private weak var previousRootView: UIView?
    private var previousAccessibilityElementsHidden = false
    private var dropInWindow: UIWindow?
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

    func ensureCanPresent() throws {
        dispatchPrecondition(condition: .onQueue(.main))
        guard state == .idle else {
            throw PlatformError(errorDescription: "Drop-in is already presented.")
        }
    }

    func present(rootViewController: UIViewController) throws {
        dispatchPrecondition(condition: .onQueue(.main))
        try ensureCanPresent()

        guard let hostWindow = hostWindowProvider(), let windowScene = hostWindow.windowScene else {
            throw PlatformError(errorDescription: "Host window scene is not available.")
        }

        previousKeyWindow = hostWindow
        previousRootView = hostWindow.rootViewController?.view
        previousAccessibilityElementsHidden = previousRootView?.accessibilityElementsHidden ?? false
        previousRootView?.accessibilityElementsHidden = true

        let window = windowFactory(windowScene)
        window.windowLevel = .normal
        window.backgroundColor = .clear
        window.isOpaque = false
        rootViewController.view.backgroundColor = .clear
        window.rootViewController = rootViewController
        window.accessibilityViewIsModal = true
        rootViewController.view.accessibilityViewIsModal = true
        dropInWindow = window
        observeDisconnect(of: windowScene)

        window.makeKeyAndVisible()
        state = .presented
    }

    func dismiss(animated: Bool, completion: @escaping () -> Void = {}) {
        dispatchPrecondition(condition: .onQueue(.main))
        switch state {
        case .idle:
            completion()
        case .dismissing:
            dismissalCompletions.append(completion)
        case .presented:
            dismissalCompletions.append(completion)
            guard let rootViewController = dropInWindow?.rootViewController else {
                restorePreviousWindow()
                return
            }

            state = .dismissing
            if rootViewController.presentedViewController != nil {
                let restore = { self.restorePreviousWindow() }
                if let dropInViewController = rootViewController as? DropInViewController {
                    dropInViewController.dismissDropIn(animated: animated, completion: restore)
                } else {
                    rootViewController.dismiss(animated: animated, completion: restore)
                }
            } else {
                restorePreviousWindow()
            }
        }
    }

    func cleanUp() {
        dispatchPrecondition(condition: .onQueue(.main))
        dismiss(animated: false)
    }

    private func observeDisconnect(of windowScene: UIWindowScene) {
        sceneDisconnectObserver = notificationCenter.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: windowScene,
            queue: .main
        ) { [weak self] _ in
            self?.restorePreviousWindow(shouldMakeKey: false)
        }
    }

    private func restorePreviousWindow(shouldMakeKey: Bool = true) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard state != .idle else { return }
        if let sceneDisconnectObserver {
            notificationCenter.removeObserver(sceneDisconnectObserver)
            self.sceneDisconnectObserver = nil
        }

        let dismissedWindowScene = dropInWindow?.windowScene
        dropInWindow?.isHidden = true
        dropInWindow?.rootViewController = nil
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
