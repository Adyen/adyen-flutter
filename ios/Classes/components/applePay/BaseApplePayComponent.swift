@_spi(AdyenInternal) import Adyen

class BaseApplePayComponent {
    var applePayComponent: ApplePayComponent?

    func present() {
        preconditionFailure("This method must be overridden")
    }
    
    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {}
    
    func finalizeAndDismissComponent(success: Bool, completion: @escaping (() -> Void)) {
        applePayComponent?.finalizeIfNeeded(with: success) { [weak self] in
            self?.getViewController()?.dismiss(animated: true, completion: { [weak self] in
                completion()
                self?.applePayComponent = nil
            })
        }
    }
    
    func getViewController() -> UIViewController? {
        let rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        return rootViewController?.adyen.topPresenter
    }
}
