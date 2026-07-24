import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
#if canImport(AdyenNetworking)
    import AdyenNetworking
#endif
import Foundation

class DropInAdvancedFlowDelegate: DropInComponentDelegate {
    private let checkoutFlutter: CheckoutFlutterInterface
    weak var dropInInteractorDelegate: DropInInteractorDelegate?
    var terminalEventHandler: ((CheckoutEvent) -> Void)?
    var isApplePay: Bool = false
    private var isActive = true

    init(checkoutFlutter: CheckoutFlutterInterface) {
        self.checkoutFlutter = checkoutFlutter
    }

    func didSubmit(_ data: PaymentComponentData, from paymentComponent: PaymentComponent, in _: AnyDropInComponent) {
        guard isActive else { return }
        do {
            isApplePay = paymentComponent is ApplePayComponent
            let applePayDetails = data.paymentMethod as? ApplePayDetails
            let submitData = SubmitData(
                data: data.jsonObject,
                extra: applePayDetails?.getExtraData()
            )
            let submitDataEncoded = try submitData.toJsonString()
            let checkoutEvent = CheckoutEvent(
                type: CheckoutEventType.submit,
                data: submitDataEncoded
            )
            checkoutFlutter.send(
                event: checkoutEvent,
                completion: { _ in }
            )
        } catch {
            dropInInteractorDelegate?.finalizeAndDismiss(success: false) { [weak self] in
                self?.sendErrorToFlutterLayer(error: error)
            }
        }
    }

    func didProvide(_ data: ActionComponentData, from _: ActionComponent, in _: AnyDropInComponent) {
        guard isActive else { return }
        do {
            let actionComponentData = ActionComponentDataModel(details: data.details.encodable, paymentData: data.paymentData)
            let actionComponentDataJson = try JSONEncoder().encode(actionComponentData)
            let actionComponentDataString = String(data: actionComponentDataJson, encoding: .utf8)
            let checkoutEvent = CheckoutEvent(type: CheckoutEventType.additionalDetails, data: actionComponentDataString)
            checkoutFlutter.send(
                event: checkoutEvent,
                completion: { _ in }
            )
        } catch {
            dropInInteractorDelegate?.finalizeAndDismiss(success: false) { [weak self] in
                self?.sendErrorToFlutterLayer(error: error)
            }
        }
    }

    func didComplete(from _: ActionComponent, in _: AnyDropInComponent) {
        guard isActive else { return }
        dropInInteractorDelegate?.finalizeAndDismiss(success: true) { [weak self] in
            let paymentResult = PaymentResultDTO(
                type: PaymentResultEnum.finished,
                result: PaymentResultModelDTO(resultCode: ResultCode.received.rawValue)
            )
            let checkoutEvent = CheckoutEvent(
                type: CheckoutEventType.result,
                data: paymentResult
            )
            self?.sendTerminalEvent(checkoutEvent)
        }
    }

    func didFail(with error: Error, from _: PaymentComponent, in _: AnyDropInComponent) {
        guard isActive else { return }
        dropInInteractorDelegate?.finalizeAndDismiss(success: false) { [weak self] in
            self?.sendErrorToFlutterLayer(error: error)
        }
    }

    func didFail(with error: Error, from _: ActionComponent, in _: AnyDropInComponent) {
        guard isActive else { return }
        dropInInteractorDelegate?.finalizeAndDismiss(success: false) { [weak self] in
            self?.sendErrorToFlutterLayer(error: error)
        }
    }

    func didFail(with error: Error, from _: Adyen.AnyDropInComponent) {
        guard isActive else { return }
        dropInInteractorDelegate?.finalizeAndDismiss(success: false) { [weak self] in
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
                self?.sendErrorToFlutterLayer(error: error)
            }
        }
    }

    func invalidate() {
        isActive = false
        dropInInteractorDelegate = nil
        terminalEventHandler = nil
    }

    private func sendErrorToFlutterLayer(error: Error) {
        let checkoutEvent = CheckoutEvent(
            type: CheckoutEventType.result,
            data: PaymentResultDTO(
                type: PaymentResultEnum.error,
                reason: error.localizedDescription
            )
        )
        sendTerminalEvent(checkoutEvent)
    }

    private func sendTerminalEvent(_ checkoutEvent: CheckoutEvent) {
        guard isActive else { return }
        if let terminalEventHandler {
            terminalEventHandler(checkoutEvent)
        } else {
            checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
        }
    }
}
