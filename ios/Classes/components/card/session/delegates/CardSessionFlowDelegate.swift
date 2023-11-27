import Adyen
import AdyenNetworking

class CardSessionFlowDelegate: AdyenSessionDelegate {
    private let componentFlutterApi: ComponentFlutterInterface
    var finalizeAndDismiss: ((Bool, @escaping (() -> Void)) -> Void)?

    init(componentFlutterApi: ComponentFlutterInterface) {
        self.componentFlutterApi = componentFlutterApi
    }

    func didComplete(with result: Adyen.AdyenSessionResult, component : Adyen.Component, session: Adyen.AdyenSession) {
        
        let resultCode = result.resultCode
        let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
        finalizeAndDismiss?(success, {
            let paymentResult = PaymentResultModelDTO(sessionId: session.sessionContext.identifier, sessionData: session.sessionContext.data, resultCode: result.resultCode.rawValue)
            let componentCommunicationModel = ComponentCommunicationModel(type: ComponentCommunicationType.result, paymentResult: paymentResult)
            self.componentFlutterApi.onComponentCommunication(componentCommunicationModel: componentCommunicationModel, completion: { _ in })
        })
        
    }

    func didFail(with error: Error, from _: Component, session _: AdyenSession) {
        let componentCommunicationModel = ComponentCommunicationModel(type: ComponentCommunicationType.error, data: error.localizedDescription)
        componentFlutterApi.onComponentCommunication(componentCommunicationModel: componentCommunicationModel, completion: { _ in })
    }

    func didOpenExternalApplication(component _: ActionComponent, session _: AdyenSession) {
        print("did open external application")
        // TODO: Could we discuss when this callback is being triggered and needs to be handled?
    }
}
