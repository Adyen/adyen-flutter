import AdyenCheckout
import Foundation

@MainActor
final class CheckoutComponentRegistry {
    static let shared = CheckoutComponentRegistry()

    private var components: [String: (checkoutId: String, component: CheckoutPaymentComponent)] = [:]
    private var activeComponentId: String?

    private init() {}

    func register(
        checkoutId: String,
        componentId: String,
        component: CheckoutPaymentComponent
    ) {
        components[componentId] = (checkoutId, component)
    }

    func component(checkoutId: String, componentId: String) -> CheckoutPaymentComponent? {
        guard let entry = components[componentId], entry.checkoutId == checkoutId else { return nil }
        return entry.component
    }

    func setActive(checkoutId: String, componentId: String) -> CheckoutPaymentComponent? {
        guard let component = component(checkoutId: checkoutId, componentId: componentId) else { return nil }
        activeComponentId = componentId
        return component
    }

    func remove(checkoutId: String, componentId: String) {
        guard components[componentId]?.checkoutId == checkoutId else { return }
        components.removeValue(forKey: componentId)
        if activeComponentId == componentId {
            activeComponentId = nil
        }
    }

    func handleReturn(url: URL) {
        guard activeComponentId != nil else { return }
        _ = Checkout.handleReturn(url: url)
    }

    func clear(checkoutId: String) {
        components = components.filter { $0.value.checkoutId != checkoutId }
        if let activeComponentId, components[activeComponentId] == nil {
            self.activeComponentId = nil
        }
    }

    func clear() {
        components.removeAll()
        activeComponentId = nil
    }
}
