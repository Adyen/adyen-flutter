@_spi(AdyenInternal) import Adyen

class BaseDropInManager {
    var dropInComponent: DropInComponent?
    var viewController: UIViewController?
    
    func getViewController() -> UIViewController? {
        var rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        while let presentedViewController = rootViewController?.presentedViewController {
            let type = String(describing: type(of: presentedViewController))
            if type == "DropInNavigationController" {
                return nil
            } else {
                rootViewController = presentedViewController
            }
        }

        return rootViewController
    }
    
    func finalizeAndDismiss(success: Bool, completion: @escaping (() -> Void)) {
        dropInComponent?.finalizeIfNeeded(with: success) { [weak self] in
            self?.viewController?.dismiss(animated: true, completion: {
                completion()
            })
        }
    }
    
    func removeGiftCardPaymentMethods(paymentMethods: PaymentMethods) -> PaymentMethods {
        let storedPaymentMethods = paymentMethods.stored.filter { !($0.type == PaymentMethodType.giftcard) }
        let paymentMethods = paymentMethods.regular.filter { !($0.type == PaymentMethodType.giftcard) }
        return PaymentMethods(regular: paymentMethods, stored: storedPaymentMethods)
    }
}
