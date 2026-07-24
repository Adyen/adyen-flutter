@_spi(AdyenInternal) import Adyen
import UIKit

class DropInWindowManager {
    static let shared = DropInWindowManager()

    private var dropInWindow: UIWindow?
    private(set) var rootViewController: UIViewController?

    private init() {}

    func prepareWindow() -> UIViewController? {
        guard dropInWindow == nil else {
            return rootViewController
        }

        guard let windowScene = UIApplication.shared.adyen.mainKeyWindow?.windowScene else {
            return nil
        }

        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = .statusBar
        let rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .clear
        window.rootViewController = rootViewController
        window.isHidden = true

        self.dropInWindow = window
        self.rootViewController = rootViewController

        return rootViewController
    }

    func show() {
        guard let window = dropInWindow else { return }
        window.isHidden = false
        window.makeKeyAndVisible()
    }

    func hide(completion: (() -> Void)? = nil) {
        guard let window = dropInWindow else {
            completion?()
            return
        }

        window.isHidden = true
        self.dropInWindow = nil
        self.rootViewController = nil
        UIApplication.shared.adyen.mainKeyWindow?.makeKeyAndVisible()
        completion?()
    }
}
