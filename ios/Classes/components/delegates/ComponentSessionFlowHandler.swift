import Adyen

class ComponentSessionFlowHandler: AdyenSessionDelegate {
    private let componentFlutterApi: ComponentFlutterInterface
    var componentId: String?
    var finalizeCallback: ((Bool, @escaping (() -> Void)) -> Void)?

    init(
        componentFlutterApi: ComponentFlutterInterface
    ) {
        self.componentFlutterApi = componentFlutterApi
    }
    
    func didComplete(with result: AdyenSessionResult, component _: Component, session: AdyenSession) {
        let resultCode = result.resultCode
        let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
        finalizeCallback?(success, { [weak self] in
            let paymentResult = PaymentResultModelDTO(
                sessionId: session.sessionContext.identifier,
                sessionData: session.sessionContext.data,
                sessionResult: result.encodedResult,
                resultCode: result.resultCode.rawValue
            )
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: self?.componentId ?? "",
                paymentResult: PaymentResultDTO(
                    type: PaymentResultEnum.finished,
                    result: paymentResult
                )
            )
            self?.componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        })
    }
    
    func didFail(with error: Error, from component: Component, session: AdyenSession) {
        finalizeCallback?(false, { [weak self] in
            guard let self else { return }
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: self.componentId ?? "",
                paymentResult: PaymentResultDTO(
                    type: .from(error: error),
                    reason: error.localizedDescription
                )
            )
            self.componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        })
        
    }
    
}
