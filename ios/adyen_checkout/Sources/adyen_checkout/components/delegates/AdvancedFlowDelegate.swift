import Adyen
import Foundation

// TODO: v6 migration - PaymentComponentDelegate, PaymentComponent are now package-access.
class AdvancedFlowDelegate {
    private let componentFlutterApi: ComponentFlutterInterface
    private let componentId: String

    init(componentFlutterApi: ComponentFlutterInterface, componentId: String) {
        self.componentFlutterApi = componentFlutterApi
        self.componentId = componentId
    }
}
