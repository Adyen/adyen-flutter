import Adyen
#if canImport(AdyenSession)
    import AdyenSession
#endif

class ComponentSessionFlowHandler: AdyenSessionDelegate {
    private let componentFlutterApi: ComponentFlutterInterface
    var componentId: String?
    var finalizeCallback: ((Bool, @escaping (() -> Void)) -> Void)?

    init(
        componentFlutterApi: ComponentFlutterInterface
    ) {
        self.componentFlutterApi = componentFlutterApi
    }
    
    func didComplete(with result: CheckoutResult, component _: Component, session: AdyenSession) {
        let resultCode = result.resultCode
        let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
        finalizeCallback?(success) { [weak self] in
            let paymentResult = PaymentResultModelDTO(
                sessionId: session.state.identifier,
                sessionData: session.state.data,
                sessionResult: result.sessionResult,
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
        }
    }
    
    func didFail(with error: Error, from component: Component, session: AdyenSession) {
        finalizeCallback?(false) { [weak self] in
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
        }
        
    }
    
}
