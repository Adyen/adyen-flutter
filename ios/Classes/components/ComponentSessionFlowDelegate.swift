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
            let paymentResult = PaymentResultModelDTO(
                sessionId: session.sessionContext.identifier,
                sessionData: session.sessionContext.data,
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
    
    func didFail(with error: Error, from component: Adyen.Component, session: Adyen.AdyenSession) {
        finalizeAndDismissHandler?(false, { [weak self] in
            guard let self else { return }
            let type: PaymentResultEnum
            if let componentError = (error as? ComponentError), componentError == ComponentError.cancelled {
                type = PaymentResultEnum.cancelledByUser
            } else {
                type = PaymentResultEnum.error
            }
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: self.componentId ?? "",
                paymentResult: PaymentResultDTO(
                    type: type,
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
