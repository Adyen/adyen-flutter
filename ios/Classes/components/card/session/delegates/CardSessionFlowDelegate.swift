import Adyen
import AdyenNetworking

class CardSessionFlowDelegate: AdyenSessionDelegate {
    private let componentFlutterApi: ComponentFlutterInterface
    var finalizeAndDismissHandler: ((Bool, @escaping (() -> Void)) -> Void)?

    init(componentFlutterApi: ComponentFlutterInterface) {
        self.componentFlutterApi = componentFlutterApi
    }

    func didComplete(with result: AdyenSessionResult, component _: Component, session: AdyenSession) {
        let resultCode = result.resultCode
        let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
        finalizeAndDismissHandler?(success, { [weak self] in
            let paymentResult = PaymentResultModelDTO(sessionId: session.sessionContext.identifier, sessionData: session.sessionContext.data, resultCode: result.resultCode.rawValue)
            let componentCommunicationModel = ComponentCommunicationModel(type: ComponentCommunicationType.result, paymentResult: paymentResult)
            self?.componentFlutterApi.onComponentCommunication(componentCommunicationModel: componentCommunicationModel, completion: { _ in })
        })
    }

    func didFail(with error: Error, from _: Component, session _: AdyenSession) {
        let componentCommunicationModel = ComponentCommunicationModel(type: ComponentCommunicationType.error, data: error.localizedDescription)
        componentFlutterApi.onComponentCommunication(componentCommunicationModel: componentCommunicationModel, completion: { _ in })
    }

    func didOpenExternalApplication(component _: ActionComponent, session _: AdyenSession) {
        // TODO: Add implementation when we support external applications
    }
}
