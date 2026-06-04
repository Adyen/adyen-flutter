import Adyen
import Foundation
import UIKit

// TODO: v6 migration - CheckoutActionComponent, ActionComponentDelegate are now package-access.
// Action handling in v6 is done through PaymentCheckout.handle(action:) instead.
@MainActor
class ActionComponentManager {
    private let componentFlutterApi: ComponentFlutterInterface
    enum Constants {
        static let actionComponentId: String = "ACTION_COMPONENT"
    }

    init(componentFlutterApi: ComponentFlutterInterface) {
        self.componentFlutterApi = componentFlutterApi
    }

    func handleAction(actionComponentConfiguration: ActionComponentConfigurationDTO, componentId: String, actionResponse: [String?: Any?]) {
        sendErrorToFlutterLayer(error: PlatformError(errorDescription: "Standalone action component is not available in v6. Use PaymentCheckout.handle(action:) instead."))
    }

    func finalizeCallback(success: Bool, completion: @escaping (() -> Void)) {
        completion()
    }

    func onDispose() {}

    private func sendErrorToFlutterLayer(error: Error) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: Constants.actionComponentId,
            paymentResult: PaymentResultDTO(
                type: .from(error: error),
                reason: error.localizedDescription
            )
        )
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }
}
