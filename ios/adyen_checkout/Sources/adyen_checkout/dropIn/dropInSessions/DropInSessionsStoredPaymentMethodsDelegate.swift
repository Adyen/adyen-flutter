@_spi(AdyenInternal)
import Adyen

class DropInSessionsStoredPaymentMethodsDelegate: StoredPaymentMethodsDelegate {
    private let checkoutFlutter: CheckoutFlutterInterface
    private var completionHandler: ((Bool) -> Void)?

    init(checkoutFlutter: CheckoutFlutterInterface) {
        self.checkoutFlutter = checkoutFlutter
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
