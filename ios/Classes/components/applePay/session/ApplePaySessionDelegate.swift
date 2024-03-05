import Adyen

class ApplePaySessionDelegate : AdyenSessionDelegate {
    private let componentFlutterApi: ComponentFlutterInterface
    private let componentId: String
    var finalizeAndDismissHandler: ((Bool, @escaping (() -> Void)) -> Void)?

    init(
        componentFlutterApi: ComponentFlutterInterface,
        componentId: String) {
        self.componentFlutterApi = componentFlutterApi
        self.componentId = componentId
    }
    
    func didComplete(with result: Adyen.AdyenSessionResult, component: Adyen.Component, session: Adyen.AdyenSession) {
        let resultCode = result.resultCode
        let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
        finalizeAndDismissHandler?(success, { [weak self] in
            let paymentResult = PaymentResultModelDTO(
                sessionId: session.sessionContext.identifier,
                sessionData: session.sessionContext.data,
                resultCode: result.resultCode.rawValue
            )
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: self?.componentId ?? "",
                paymentResult: paymentResult
            )
            self?.componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        })
    }
    
    func didFail(with error: Error, from component: Adyen.Component, session: Adyen.AdyenSession) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.error,
            componentId: componentId,
            data: error.localizedDescription
        )
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }
    
    
}
