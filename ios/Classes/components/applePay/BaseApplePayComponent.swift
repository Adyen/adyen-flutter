@_spi(AdyenInternal)
import Adyen

class BaseApplePayComponent {
    var applePayComponent: ApplePayComponent?

    func present() {
        preconditionFailure("This method must be overridden")
    }
    
    func getViewController() -> UIViewController? {
        var rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        while let presentedViewController = rootViewController?.presentedViewController {
            rootViewController = presentedViewController
        }

        return rootViewController
    }
}
