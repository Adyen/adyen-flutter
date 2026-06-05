import UIKit

enum ViewControllerProvider {
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
