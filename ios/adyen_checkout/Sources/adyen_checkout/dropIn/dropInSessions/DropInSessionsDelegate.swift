@_spi(AdyenInternal) import Adyen
#if canImport(AdyenSession)
    import AdyenSession
#endif
#if canImport(AdyenNetworking)
    import AdyenNetworking
#endif
import UIKit

class DropInSessionsDelegate: AdyenSessionDelegate {
    weak var viewController: UIViewController?
    var dismissHandler: ((@escaping () -> Void) -> Void)?
    var terminalEventHandler: ((CheckoutEvent) -> Void)?
    private let checkoutFlutter: CheckoutFlutterInterface
    private var didSendTerminalResult = false
    private var isActive = true

    init(viewController: UIViewController?, checkoutFlutter: CheckoutFlutterInterface) {
        self.viewController = viewController
        self.checkoutFlutter = checkoutFlutter
    }

    func didComplete(with result: AdyenSessionResult, component _: Adyen.Component, session: AdyenSession) {
        guard isActive, !didSendTerminalResult else { return }
        didSendTerminalResult = true
        dismissDropIn { [weak self] in
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
            self?.sendTerminalEvent(checkoutEvent)
        }
    }

    func didFail(with error: Error, from _: Component, session _: AdyenSession) {
        guard isActive, !didSendTerminalResult else { return }
        didSendTerminalResult = true
        dismissDropIn { [weak self] in
            switch error {
            case ComponentError.cancelled:
                let checkoutEvent = CheckoutEvent(
                    type: CheckoutEventType.result,
                    data: PaymentResultDTO(
                        type: PaymentResultEnum.cancelledByUser,
                        reason: error.localizedDescription
                    )
                )
                self?.sendTerminalEvent(checkoutEvent)
            default:
                let checkoutEvent = CheckoutEvent(
                    type: CheckoutEventType.result,
                    data: PaymentResultDTO(
                        type: PaymentResultEnum.error,
                        reason: error.localizedDescription
                    )
                )
                self?.sendTerminalEvent(checkoutEvent)
            }
        }
    }

    func didOpenExternalApplication(component _: ActionComponent, session _: AdyenSession) {
        print("external")
    }

    func invalidate() {
        isActive = false
        viewController = nil
        dismissHandler = nil
        terminalEventHandler = nil
    }

    private func sendTerminalEvent(_ checkoutEvent: CheckoutEvent) {
        guard isActive else { return }
        if let terminalEventHandler {
            terminalEventHandler(checkoutEvent)
        } else {
            checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
        }
    }

    private func dismissDropIn(completion: @escaping () -> Void) {
        if let dismissHandler {
            dismissHandler(completion)
            return
        }
        guard let viewController else {
            completion()
            return
        }
        if let dropInViewController = viewController as? DropInViewController {
            dropInViewController.dismissDropIn(animated: true, completion: completion)
        } else {
            viewController.dismiss(animated: true, completion: completion)
        }
    }
}
