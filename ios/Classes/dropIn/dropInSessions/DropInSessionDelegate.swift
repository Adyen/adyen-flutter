import Adyen
import AdyenNetworking

class DropInSessionDelegate: AdyenSessionDelegate {
    private let dropInFlutterApi: DropInFlutterInterface
    private let finalizeAndDismiss: (Bool, @escaping (() -> Void)) -> Void

    init(dropInFlutterApi: DropInFlutterInterface, finalizeAndDismiss: @escaping ((Bool, @escaping (() -> Void)) -> Void)) {
        self.dropInFlutterApi = dropInFlutterApi
        self.finalizeAndDismiss = finalizeAndDismiss
    }

    func didComplete(with result: Adyen.AdyenSessionResult, component _: Adyen.Component, session: Adyen.AdyenSession) {
        finalizeAndDismiss(true) {
            let paymentResult = PaymentResultModelDTO(
                sessionId: session.sessionContext.identifier,
                sessionData: session.sessionContext.data,
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
        }
    }

    func didFail(with error: Error, from _: Component, session _: AdyenSession) {
        finalizeAndDismiss(false) {
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
        }
    }

    func didOpenExternalApplication(component _: ActionComponent, session _: AdyenSession) {
        print("external")
    }
}
