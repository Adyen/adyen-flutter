@_spi(AdyenInternal) import Adyen
#if canImport(AdyenSession)
    import AdyenSession
#endif
#if canImport(AdyenNetworking)
    import AdyenNetworking
#endif
import UIKit

class DropInSessionsDelegate: SessionDelegate {
    private let viewController: UIViewController?
    private let checkoutFlutter: CheckoutFlutterInterface

    init(viewController: UIViewController?, checkoutFlutter: CheckoutFlutterInterface) {
        self.viewController = viewController
        self.checkoutFlutter = checkoutFlutter
    }

    func didComplete(with result: CheckoutResult, component _: Adyen.Component, session: Session) {
        viewController?.dismiss(animated: true, completion: { [weak self] in
            let paymentResult = PaymentResultModelDTO(
                sessionId: session.state.identifier,
                sessionResult: result.sessionResult,
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

    func didFail(with error: Error, from _: Component, session _: Session) {
        viewController?.dismiss(animated: true, completion: { [weak self] in
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

    func didOpenExternalApplication(component _: ActionComponent, session _: Session) {
        print("external")
    }
}
