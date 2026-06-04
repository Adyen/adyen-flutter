import UIKit
import Adyen

// TODO: v6 migration - ApplePayComponent is now package-access.
@MainActor
class BaseApplePayComponent {
    func present() {
        preconditionFailure("This method must be implemented")
    }

    func onDispose() {
        preconditionFailure("This method must be implemented")
    }

    func finalizeAndDismissComponent(success: Bool, completion: @escaping (() -> Void)) {
        // TODO: v6 migration - finalize through checkout callbacks
        completion()
    }

    func getViewController() -> UIViewController? {
        var rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
        while let presentedViewController = rootViewController?.presentedViewController {
            rootViewController = presentedViewController
        }
        return rootViewController
    }
}
