@_spi(AdyenInternal) import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import UIKit

class BaseApplePayComponent {
    var applePayComponent: ApplePayComponent?

    func present() {
        preconditionFailure("This method must be implemented")
    }
    
    func onDispose() {
        preconditionFailure("This method must be implemented")
    }
        
    func finalizeAndDismissComponent(success: Bool, completion: @escaping (() -> Void)) {
        applePayComponent?.finalizeIfNeeded(with: success) { [weak self] in
            if let viewController = self?.getViewController() {
                viewController.dismiss(animated: true) {
                    completion()
                }
            } else {
                completion()
            }
        }
    }
    
    func getViewController() -> UIViewController? {
        let rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        return rootViewController?.adyen.topPresenter
    }
}
