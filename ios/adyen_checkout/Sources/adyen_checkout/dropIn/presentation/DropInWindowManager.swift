import UIKit

final class DropInWindowManager {
    /// Kept above the host window so the Drop-in stays in front of content the host application presents itself.
    private static let dropInWindowLevel = UIWindow.Level(rawValue: UIWindow.Level.normal.rawValue + 1)

    weak var delegate: DropInWindowManagerDelegate?

    private let windowPresenter: DropInWindowPresenting
    private var dropInWindow: UIWindow?
    private var pendingDismissalCompletion: (() -> Void)?

    init(windowPresenter: DropInWindowPresenting = DropInWindowPresenter()) {
        self.windowPresenter = windowPresenter
    }

    deinit {
        windowPresenter.stopObservingSceneDisconnect()
    }

    @discardableResult
    func present(dropInViewController: UIViewController) throws -> Bool {
        assertMainThread()

        guard dropInWindow == nil else {
            return false
        }

        guard let hostWindow = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow }),
            let windowScene = hostWindow.windowScene else {
            throw PlatformError(errorDescription: "Host window scene is not available.")
        }

        let rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .clear

        let window = windowPresenter.makeWindow(for: windowScene)
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
        dropInViewController: UIViewController,
        animated: Bool,
        completion: @escaping () -> Void = {}
    ) {
        assertMainThread()
        guard pendingDismissalCompletion == nil,
              let window = dropInWindow,
              let rootViewController = window.rootViewController,
              rootViewController.presentedViewController === dropInViewController else {
            return
        }
        pendingDismissalCompletion = completion

        // `self` is captured strongly on purpose: the window must be torn down even if the owner released us.
        windowPresenter.dismiss(rootViewController, animated: animated) {
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
        windowPresenter.observeSceneDisconnect(of: windowScene) { [weak self] in
            guard let self else { return }
            let wasDismissalRequested = pendingDismissalCompletion != nil
            tearDownWindow()
            if !wasDismissalRequested {
                delegate?.dropInWindowDidDismissUnexpectedly()
            }
        }
    }

    private func tearDownWindow() {
        assertMainThread()
        guard let window = dropInWindow else { return }
        windowPresenter.stopObservingSceneDisconnect()

        let completion = pendingDismissalCompletion
        pendingDismissalCompletion = nil
        window.isHidden = true
        window.rootViewController = nil
        dropInWindow = nil
        completion?()
    }
}
