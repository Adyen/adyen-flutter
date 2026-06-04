import Adyen
import Foundation

// TODO: v6 migration - SessionDelegate, Session, PaymentComponent are now package-access.
// Session handling in v6 is done through SessionCheckout callbacks.
class ComponentSessionFlowHandler {
    private let componentFlutterApi: ComponentFlutterInterface
    private var componentRegistrations: [String: ComponentRegistration] = [:]
    private var currentFlowRegistration: ComponentRegistration?

    init(
        componentFlutterApi: ComponentFlutterInterface
    ) {
        self.componentFlutterApi = componentFlutterApi
    }

    func register(
        componentId: String,
        finalizeCallback: @escaping (Bool, @escaping (() -> Void)) -> Void
    ) {
        componentRegistrations[componentId] = ComponentRegistration(
            componentId: componentId,
            finalizeCallback: finalizeCallback
        )
    }

    func setCurrentFlow(componentId: String) {
        currentFlowRegistration = componentRegistrations[componentId]
    }

    func reset() {
        componentRegistrations.removeAll()
        currentFlowRegistration = nil
    }
}

struct ComponentRegistration {
    let componentId: String
    let finalizeCallback: (Bool, @escaping (() -> Void)) -> Void
}
