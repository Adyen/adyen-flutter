import Foundation
@_spi(AdyenInternal) import Adyen
#if canImport(AdyenActions)
    import AdyenActions
#endif

protocol AdvancedComponentProtocol: BasePlatformViewComponent {
    var actionComponent: AdyenActionComponent? { get }

    func finalizeAndDismiss(success: Bool, completion: @escaping (() -> Void))
    func stopLoadingOnError()
}

extension AdvancedComponentProtocol {
    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        switch paymentEventDTO.paymentEventType {
        case .finished:
            onFinish(paymentEventDTO: paymentEventDTO)
        case .action:
            guard let actionResponse = paymentEventDTO.data else { return }
            onAction(actionResponse: actionResponse)
        case .error:
            onError(errorDTO: paymentEventDTO.error)
        case .update:
            return
        }
    }

    private func onAction(actionResponse: [String?: Any?]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: actionResponse, options: [])
            let action = try JSONDecoder().decode(Action.self, from: jsonData)
            actionComponent?.handle(action)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func onFinish(paymentEventDTO: PaymentEventDTO) {
        let resultCode = ResultCode(rawValue: paymentEventDTO.result ?? "")
        let isAccepted = resultCode?.isAccepted ?? false
        finalizeAndDismiss(success: isAccepted, completion: { [weak self] in
            guard let self else { return }
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: self.componentId,
                paymentResult: PaymentResultDTO(
                    type: PaymentResultEnum.finished,
                    result: PaymentResultModelDTO(resultCode: resultCode?.rawValue)
                )
            )
            self.componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        })
    }

    private func onError(errorDTO: ErrorDTO?) {
        stopLoadingOnError()
        sendErrorToFlutterLayer(errorMessage: errorDTO?.errorMessage ?? "")
    }
}
