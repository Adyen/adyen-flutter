import AdyenCheckout
import Foundation

@MainActor
internal final class V6ComponentControllerRegistry {

    static let shared = V6ComponentControllerRegistry()

    private var controllers: [String: () -> CheckoutPaymentComponent?] = [:]
    private var activeComponentId: String?

    private init() {}

    func register(componentId: String, component: @escaping () -> CheckoutPaymentComponent?) {
        controllers[componentId] = component
    }

    func unregister(componentId: String) {
        controllers.removeValue(forKey: componentId)
        if activeComponentId == componentId {
            activeComponentId = nil
        }
    }

    func component(for componentId: String) -> CheckoutPaymentComponent? {
        controllers[componentId]?()
    }

    func setActive(componentId: String) {
        guard controllers[componentId] != nil else { return }
        activeComponentId = componentId
    }

    func activeComponent() -> CheckoutPaymentComponent? {
        guard let activeComponentId else { return nil }
        return controllers[activeComponentId]?()
    }

    func clear() {
        controllers.removeAll()
        activeComponentId = nil
    }
}
