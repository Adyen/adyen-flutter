import Adyen

class ComponentSessionFlowDelegate: AdyenSessionDelegate {
    private let componentFlutterApi: ComponentFlutterInterface
    var componentId: String?
    var finalizeAndDismissHandler: ((Bool, @escaping (() -> Void)) -> Void)?

    init(
        componentFlutterApi: ComponentFlutterInterface
    ) {
        self.componentFlutterApi = componentFlutterApi
    }
    
    func didComplete(with result: AdyenSessionResult, component _: Component, session: AdyenSession) {
        let resultCode = result.resultCode
        let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
        finalizeAndDismissHandler?(success, { [weak self] in
            guard let self else { return }
            let paymentResult = PaymentResultModelDTO(
                sessionId: session.sessionContext.identifier,
                sessionData: session.sessionContext.data,
                resultCode: result.resultCode.rawValue
            )
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: componentId ?? "",
                paymentResult: paymentResult
            )
            componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        })
    }
    
    func didFail(with error: Error, from component: Adyen.Component, session: Adyen.AdyenSession) {
        finalizeAndDismissHandler?(false, { [weak self] in
            guard let self else { return }
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.error,
                componentId: componentId ?? "",
                data: error.localizedDescription
            )
            componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        })
        
    }
    
}
