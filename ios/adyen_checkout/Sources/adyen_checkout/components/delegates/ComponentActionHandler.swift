import Adyen
import Foundation

// TODO: v6 migration - ActionComponentDelegate, ActionComponent are now package-access.
class ComponentActionHandler {
    private let componentFlutterApi: ComponentFlutterInterface
    private let componentId: String
    private let finalizeCallback: (Bool, @escaping (() -> Void)) -> Void

    init(
        componentFlutterApi: ComponentFlutterInterface,
        componentId: String,
        finalizeCallback: @escaping ((Bool, @escaping (() -> Void)) -> Void)
    ) {
        self.componentFlutterApi = componentFlutterApi
        self.componentId = componentId
        self.finalizeCallback = finalizeCallback
    }
}
