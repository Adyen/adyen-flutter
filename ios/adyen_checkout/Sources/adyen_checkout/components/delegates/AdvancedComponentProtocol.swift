import Foundation
import Adyen

// TODO: v6 migration - CheckoutActionComponent, ResultCode are now package-access.
// Advanced component action handling in v6 is done through PaymentCheckout.handle(action:).
@MainActor
protocol AdvancedComponentProtocol: BasePlatformViewComponent {
    func finalizeAndDismiss(success: Bool, completion: @escaping (() -> Void))
    func stopLoadingOnError()
}

@MainActor
extension AdvancedComponentProtocol {
    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        switch paymentEventDTO.paymentEventType {
        case .finished:
            onFinish(paymentEventDTO: paymentEventDTO)
        case .action:
            // TODO: v6 migration - action handling needs PaymentCheckout.handle(action:)
            sendErrorToFlutterLayer(errorMessage: "Action handling not yet migrated to v6.")
        case .error:
            onError(errorDTO: paymentEventDTO.error)
        case .update:
            return
        }
    }

    private func onFinish(paymentEventDTO: PaymentEventDTO) {
        let resultCode = paymentEventDTO.result ?? ""
        let isAccepted = ["Authorised", "Received", "Pending"].contains(resultCode)
        finalizeAndDismiss(success: isAccepted, completion: { [weak self] in
            guard let self else { return }
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: self.componentId,
                paymentResult: PaymentResultDTO(
                    type: PaymentResultEnum.finished,
                    result: PaymentResultModelDTO(resultCode: resultCode)
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
