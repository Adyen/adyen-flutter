import UIKit

/// UIScene-aware helpers for locating the active key window and top-most view controller.
enum ViewControllerProvider {
    /// Returns the key window of a foreground `UIWindowScene`, or the application's key
    /// window on iOS 12. Accepts `.foregroundActive` and `.foregroundInactive` so the
    /// plugin can still anchor modal presentation during Apple Pay / 3DS2 / biometric /
    /// system-overlay transitions.
    static func keyWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive })?
                .windows
                .first(where: { $0.isKeyWindow })
        } else {
            return UIApplication.shared.keyWindow
        }
    }

    static func rootViewController() -> UIViewController? {
        keyWindow()?.rootViewController
    }

    /// Walks the presented-view-controller chain. Bails out (returns `nil`) on the first
    /// match of `skipTypeName` to preserve the prior `DropInNavigationController` skip.
    static func topViewController(skipTypeName: String? = nil) -> UIViewController? {
        var top = rootViewController()
        while let presented = top?.presentedViewController {
            if let skipTypeName, String(describing: type(of: presented)) == skipTypeName {
                return nil
            }
            top = presented
        }
        return top
    }
}
