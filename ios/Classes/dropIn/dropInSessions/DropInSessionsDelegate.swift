import Adyen
import AdyenNetworking

class DropInSessionsDelegate: AdyenSessionDelegate {
    private let viewController: UIViewController?
    private let dropInFlutterApi: DropInFlutterInterface

    init(viewController: UIViewController?, dropInFlutterApi: DropInFlutterInterface) {
        self.viewController = viewController
        self.dropInFlutterApi = dropInFlutterApi
    }

    func didComplete(with result: Adyen.AdyenSessionResult, component _: Adyen.Component, session: Adyen.AdyenSession) {
        viewController?.dismiss(animated: true, completion: {
            let paymentResult = PaymentResultModelDTO(
                sessionId: session.sessionContext.identifier,
                sessionData: session.sessionContext.data,
                sessionResult: result.encodedResult,
                resultCode: result.resultCode.rawValue
            )
            let platformCommunicationModel = PlatformCommunicationModel(
                type: PlatformCommunicationType.result,
                paymentResult: PaymentResultDTO(
                    type: PaymentResultEnum.finished,
                    result: paymentResult
                )
            )
            self.dropInFlutterApi.onDropInSessionPlatformCommunication(
                platformCommunicationModel: platformCommunicationModel,
                completion: { _ in }
            )
        })
    }

    func didFail(with error: Error, from _: Component, session _: AdyenSession) {
        viewController?.dismiss(animated: true, completion: {
            switch error {
            case ComponentError.cancelled:
                let platformCommunicationModel = PlatformCommunicationModel(
                    type: PlatformCommunicationType.result,
                    paymentResult: PaymentResultDTO(
                        type: PaymentResultEnum.cancelledByUser,
                        reason: error.localizedDescription
                    )
                )
                self.dropInFlutterApi.onDropInSessionPlatformCommunication(
                    platformCommunicationModel: platformCommunicationModel,
                    completion: { _ in }
                )
            default:
                let platformCommunicationModel = PlatformCommunicationModel(
                    type: PlatformCommunicationType.result,
                    paymentResult: PaymentResultDTO(
                        type: PaymentResultEnum.error,
                        reason: error.localizedDescription
                    )
                )
                self.dropInFlutterApi.onDropInSessionPlatformCommunication(
                    platformCommunicationModel: platformCommunicationModel,
                    completion: { _ in }
                )
            }
        })
    }

    func didOpenExternalApplication(component _: ActionComponent, session _: AdyenSession) {
        print("external")
    }
}
