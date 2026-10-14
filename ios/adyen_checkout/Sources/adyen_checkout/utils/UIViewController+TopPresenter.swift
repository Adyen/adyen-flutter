import UIKit

extension UIViewController {
    static var keyWindowRoot: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })?
            .rootViewController
    }

    var topPresenter: UIViewController {
        if let presented = presentedViewController {
            return presented.topPresenter
        }
        if let navigation = self as? UINavigationController, let visible = navigation.visibleViewController {
            return visible.topPresenter
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.topPresenter
        }
        return self
    }
}
