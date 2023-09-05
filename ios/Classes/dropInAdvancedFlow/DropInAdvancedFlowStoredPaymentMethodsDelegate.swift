import Adyen

class DropInAdvancedFlowStoredPaymentMethodsDelegate : StoredPaymentMethodsDelegate {
    internal func disable(storedPaymentMethod: StoredPaymentMethod, completion: @escaping (Bool) -> Void) {
        print("stored disabled")
    }
}
