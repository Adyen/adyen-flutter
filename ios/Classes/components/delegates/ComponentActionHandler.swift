import Adyen

class ComponentActionHandler: ActionComponentDelegate {
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
    
    internal func didProvide(_ data: ActionComponentData, from _: ActionComponent) {
        do {
            let actionComponentData = ActionComponentDataModel(details: data.details.encodable, paymentData: data.paymentData)
            let actionComponentDataJson = try JSONEncoder().encode(actionComponentData)
            let actionComponentDataString = String(data: actionComponentDataJson, encoding: .utf8)
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.additionalDetails,
                componentId: componentId,
                data: actionComponentDataString
            )
            componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        } catch {
            finalizeCallback(false) { [weak self] in
                self?.sendErrorToFlutterLayer(error: error)
            }
        }
    }

    internal func didComplete(from _: ActionComponent) {
        // Only for voucher payment method - currently not supported.
    }

    internal func didFail(with error: Error, from _: ActionComponent) {
        finalizeCallback(false) { [weak self] in
            self?.sendErrorToFlutterLayer(error: error)
        }
    }
    
    private func sendErrorToFlutterLayer(error: Error) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: componentId,
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
