@_spi(AdyenInternal) import Adyen
#if canImport(AdyenSession)
    import AdyenSession
#endif
#if canImport(AdyenNetworking)
    import AdyenNetworking
#endif
import Foundation

class DropInSessionsDelegate: AdyenSessionDelegate {
    weak var dropInInteractorDelegate: DropInInteractorDelegate?
    private let checkoutFlutter: CheckoutFlutterInterface

    init(checkoutFlutter: CheckoutFlutterInterface) {
        self.checkoutFlutter = checkoutFlutter
    }

    func didComplete(with result: AdyenSessionResult, component _: Adyen.Component, session: AdyenSession) {
        dropInInteractorDelegate?.dismiss(completion: { [weak self] in
            let paymentResult = PaymentResultModelDTO(
                sessionId: session.sessionContext.identifier,
                sessionData: session.sessionContext.data,
                sessionResult: result.encodedResult,
                resultCode: result.resultCode.rawValue
            )
            let checkoutEvent = CheckoutEvent(
                type: CheckoutEventType.result,
                data: PaymentResultDTO(
                    type: PaymentResultEnum.finished,
                    result: paymentResult
                )
            )
            self?.checkoutFlutter.send(
                event: checkoutEvent,
                completion: { _ in }
            )
        })
    }

    func didFail(with error: Error, from _: Component, session _: AdyenSession) {
        dropInInteractorDelegate?.dismiss(completion: { [weak self] in
            switch error {
            case ComponentError.cancelled:
                let checkoutEvent = CheckoutEvent(
                    type: CheckoutEventType.result,
                    data: PaymentResultDTO(
                        type: PaymentResultEnum.cancelledByUser,
                        reason: error.localizedDescription
                    )
                )
                self?.checkoutFlutter.send(
                    event: checkoutEvent,
                    completion: { _ in }
                )
            default:
                let checkoutEvent = CheckoutEvent(
                    type: CheckoutEventType.result,
                    data: PaymentResultDTO(
                        type: PaymentResultEnum.error,
                        reason: error.localizedDescription
                    )
                )
                self?.checkoutFlutter.send(
                    event: checkoutEvent,
                    completion: { _ in }
                )
            }
        })
    }

    func didOpenExternalApplication(component _: ActionComponent, session _: AdyenSession) {
        print("external")
    }
}
