@_spi(AdyenInternal)
import Adyen
import UIKit

class DropInAdvancedFlowStoredPaymentMethodsDelegate: StoredPaymentMethodsDelegate {
    private let checkoutFlutter: CheckoutFlutterInterface
    private let viewController: UIViewController
    private var completionHandler: ((Bool) -> Void)?

    init(viewController: UIViewController, checkoutFlutter: CheckoutFlutterInterface) {
        self.checkoutFlutter = checkoutFlutter
        self.viewController = viewController
    }

    func disable(storedPaymentMethod: StoredPaymentMethod, completion: @escaping (Bool) -> Void) {
        completionHandler = completion
        let checkoutEvent = CheckoutEvent(
            type: CheckoutEventType.deleteStoredPaymentMethod,
            data: storedPaymentMethod.identifier
        )
        checkoutFlutter.send(
            event: checkoutEvent,
            completion: { _ in }
        )
    }

    func handleDisableResult(isSuccessfullyRemoved: Bool) {
        completionHandler?(isSuccessfullyRemoved)
    }
}
