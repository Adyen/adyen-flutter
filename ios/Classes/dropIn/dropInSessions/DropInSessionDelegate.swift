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
        let resultCode = result.resultCode
        let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
        finalizeAndDismiss(success) { [weak self] in
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
            self?.dropInFlutterApi.onDropInSessionPlatformCommunication(
                platformCommunicationModel: platformCommunicationModel,
                completion: { _ in }
            )
        }
    }

    func didFail(with error: Error, from _: Component, session _: AdyenSession) {
        finalizeAndDismiss(false) { [weak self] in
            guard let self else { return }
            let type: PaymentResultEnum
            if let componentError = (error as? ComponentError), componentError == ComponentError.cancelled {
                type = PaymentResultEnum.cancelledByUser
            } else {
                type = PaymentResultEnum.error
            }
            let platformCommunicationModel = PlatformCommunicationModel(
                type: PlatformCommunicationType.result,
                paymentResult: PaymentResultDTO(
                    type: type,
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
