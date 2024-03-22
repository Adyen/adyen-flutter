@_spi(AdyenInternal) import Adyen

class BaseApplePayComponent {
    var applePayComponent: ApplePayComponent?

    func present() {
        preconditionFailure("This method must be overridden")
    }
    
    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {}
    
    func finalizeAndDismissComponent(success: Bool, completion: @escaping (() -> Void)) {
        applePayComponent?.finalizeIfNeeded(with: success) { [weak self] in
            if let viewController = self?.getViewController() {
                viewController.dismiss(animated: true) { [weak self] in
                    self?.applePayComponent = nil
                    completion()
                }
            } else {
                self?.applePayComponent = nil
                completion()
            }
        }
    }
    
    func getViewController() -> UIViewController? {
        let rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        return rootViewController?.adyen.topPresenter
    }
}
