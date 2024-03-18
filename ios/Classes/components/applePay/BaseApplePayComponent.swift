@_spi(AdyenInternal) import Adyen

class BaseApplePayComponent {
    var applePayComponent: ApplePayComponent?

    func present() {
        preconditionFailure("This method must be overridden")
    }
    
    func getViewController() -> UIViewController? {
        let rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        return rootViewController?.adyen.topPresenter
    }
}
