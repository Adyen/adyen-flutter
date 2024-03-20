import Adyen

class CardAdvancedFlowActionComponentDelegate: ActionComponentDelegate {
    private let componentFlutterApi: ComponentFlutterInterface
    private let componentId: String

    init(componentFlutterApi: ComponentFlutterInterface, componentId: String) {
        self.componentFlutterApi = componentFlutterApi
        self.componentId = componentId
    }

    func didProvide(_ data: Adyen.ActionComponentData, from _: Adyen.ActionComponent) {
        do {
            let actionComponentData = ActionComponentDataModel(details: data.details.encodable, paymentData: data.paymentData)
            let actionComponentDataJson = try JSONEncoder().encode(actionComponentData)
            let actionComponentDataString = String(data: actionComponentDataJson, encoding: .utf8)
            componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: ComponentCommunicationModel(
                    type: ComponentCommunicationType.additionalDetails,
                    componentId: componentId,
                    data: actionComponentDataString
                ), completion: { _ in }
            )
        } catch {
            sendErrorToFlutterLayer(error: error)
        }
    }

    func didComplete(from _: Adyen.ActionComponent) {
        // Only for voucher payment method - currently not supported.
    }

    func didFail(with error: Error, from _: Adyen.ActionComponent) {
        sendErrorToFlutterLayer(error: error)
    }

    private func sendErrorToFlutterLayer(error: Error) {
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: componentId,
                paymentResult: PaymentResultDTO(
                    type: PaymentResultEnum.error,
                    reason: error.localizedDescription
                )
            ),
            completion: { _ in }
        )
    }
}
