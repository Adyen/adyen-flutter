import Adyen
import AdyenNetworking

class CardSessionFlowDelegate: AdyenSessionDelegate {
    private let componentFlutterApi: ComponentFlutterApi

    init(componentFlutterApi: ComponentFlutterApi) {
        self.componentFlutterApi = componentFlutterApi
    }

    func didComplete(with result: Adyen.AdyenSessionResult, component _: Adyen.Component, session: Adyen.AdyenSession) {
        let paymentResult = PaymentResultModelDTO(sessionId: session.sessionContext.identifier, sessionData: session.sessionContext.data, resultCode: result.resultCode.rawValue)
        let componentCommunicationModel = ComponentCommunicationModel(type: ComponentCommunicationType.result, paymentResult: paymentResult)
        componentFlutterApi.onComponentCommunication(componentCommunicationModel: componentCommunicationModel, completion: { _ in })
    }

    func didFail(with error: Error, from _: Component, session _: AdyenSession) {
        let componentCommunicationModel = ComponentCommunicationModel(type: ComponentCommunicationType.error, data: error.localizedDescription)
        componentFlutterApi.onComponentCommunication(componentCommunicationModel: componentCommunicationModel, completion: { _ in })
    }

    func didOpenExternalApplication(component _: ActionComponent, session _: AdyenSession) {
        print("did open external application")
    }
}
