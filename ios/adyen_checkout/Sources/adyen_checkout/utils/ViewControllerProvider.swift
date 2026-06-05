import UIKit

/// Scene-aware helpers for locating the active key window and top-most view controller.
///
/// Centralises the previous scattered `UIApplication.shared.adyen.mainKeyWindow` lookups
/// so the plugin does not depend on Adyen iOS SDK internals and behaves correctly under
/// the `UIScene` lifecycle that Apple now requires for iOS 26+ SDK submissions.
enum ViewControllerProvider {
    /// Returns the key window of a foreground `UIWindowScene` on iOS 13+,
    /// or the application's key window on iOS 12. Returns `nil` if no window is key.
    /// Accepts both `.foregroundActive` and `.foregroundInactive` — during
    /// Apple Pay, 3DS2 / biometric, and system-overlay transitions the active
    /// scene briefly becomes `.foregroundInactive`, and the plugin still needs
    /// a window to anchor modal presentation (e.g. for a redirect-component
    /// view controller). Background scenes are skipped.
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

    /// Returns the root view controller of the key window, or `nil`.
    static func rootViewController() -> UIViewController? {
        keyWindow()?.rootViewController
    }

    /// Walks up the presented-view-controller chain starting from the key window's root.
    /// If `skipTypeName` is set, the walk bails out (returns `nil`) the first time it
    /// encounters a presented view controller whose type name matches. This preserves
    /// the previous `String(describing:) == "DropInNavigationController"` behaviour.
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
