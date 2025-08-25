@_spi(AdyenInternal) import Adyen
import AdyenSession
import AdyenNetworking
import UIKit

class DropInSessionsDelegate: AdyenSessionDelegate {
    private let viewController: UIViewController?
    private let checkoutFlutter: CheckoutFlutterInterface

    init(viewController: UIViewController?, checkoutFlutter: CheckoutFlutterInterface) {
        self.viewController = viewController
        self.checkoutFlutter = checkoutFlutter
    }

    func didComplete(with result: AdyenSessionResult, component _: Adyen.Component, session: AdyenSession) {
        viewController?.dismiss(animated: true, completion: { [weak self] in
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

    func didOpenExternalApplication(component _: ActionComponent, session _: AdyenSession) {
        print("external")
    }
}
