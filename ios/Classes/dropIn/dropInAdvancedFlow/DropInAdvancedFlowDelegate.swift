import Adyen
import AdyenNetworking

class DropInAdvancedFlowDelegate: DropInComponentDelegate {
    private let dropInFlutterApi: DropInFlutterInterface
    private let finalizeAndDismiss: (Bool, @escaping (() -> Void)) -> Void
    var isApplePay: Bool = false

    init(dropInFlutterApi: DropInFlutterInterface, finalizeAndDismiss: @escaping ((Bool, @escaping (() -> Void)) -> Void)) {
        self.dropInFlutterApi = dropInFlutterApi
        self.finalizeAndDismiss = finalizeAndDismiss
    }

    func didSubmit(_ data: PaymentComponentData, from paymentComponent: PaymentComponent, in _: AnyDropInComponent) {
        do {
            isApplePay = paymentComponent is ApplePayComponent
            let applePayDetails = data.paymentMethod as? ApplePayDetails
            let submitData = SubmitData(
                data: data.jsonObject,
                extra: applePayDetails?.getExtraData()
            )
            let submitDataEncoded = try submitData.toJsonString()
            let platformCommunicationModel = PlatformCommunicationModel(
                type: PlatformCommunicationType.paymentComponent,
                data: submitDataEncoded
            )
            dropInFlutterApi.onDropInAdvancedPlatformCommunication(
                platformCommunicationModel: platformCommunicationModel,
                completion: { _ in }
            )
        } catch {
            finalizeAndDismiss(false) { [weak self] in
                self?.sendErrorToFlutterLayer(error: error)
            }
        }
    }

    func didProvide(_ data: ActionComponentData, from _: ActionComponent, in _: AnyDropInComponent) {
        do {
            let actionComponentData = ActionComponentDataModel(details: data.details.encodable, paymentData: data.paymentData)
            let actionComponentDataJson = try JSONEncoder().encode(actionComponentData)
            let actionComponentDataString = String(data: actionComponentDataJson, encoding: .utf8)
            dropInFlutterApi.onDropInAdvancedPlatformCommunication(
                platformCommunicationModel: PlatformCommunicationModel(
                    type: PlatformCommunicationType.additionalDetails,
                    data: actionComponentDataString
                ),
                completion: { _ in }
            )
        } catch {
            finalizeAndDismiss(false) { [weak self] in
                self?.sendErrorToFlutterLayer(error: error)
            }
        }
    }

    func didComplete(from _: ActionComponent, in _: AnyDropInComponent) {
        finalizeAndDismiss(true) { [weak self] in
            let paymentResult = PaymentResultDTO(
                type: PaymentResultEnum.finished,
                result: PaymentResultModelDTO(resultCode: ResultCode.received.rawValue)
            )
            let platformCommunicationModel = PlatformCommunicationModel(
                type: PlatformCommunicationType.result,
                paymentResult: paymentResult
            )
            self?.dropInFlutterApi.onDropInAdvancedPlatformCommunication(
                platformCommunicationModel: platformCommunicationModel,
                completion: { _ in }
            )
        }
    }

    func didFail(with error: Error, from _: PaymentComponent, in _: AnyDropInComponent) {
        finalizeAndDismiss(false) { [weak self] in
            self?.sendErrorToFlutterLayer(error: error)
        }
    }

    func didFail(with error: Error, from _: ActionComponent, in _: AnyDropInComponent) {
        finalizeAndDismiss(false) { [weak self] in
            self?.sendErrorToFlutterLayer(error: error)
        }
    }

    func didFail(with error: Error, from _: Adyen.AnyDropInComponent) {
        finalizeAndDismiss(false) { [weak self] in
            switch error {
            case ComponentError.cancelled:
                let platformCommunicationModel = PlatformCommunicationModel(
                    type: PlatformCommunicationType.result,
                    paymentResult: PaymentResultDTO(
                        type: PaymentResultEnum.cancelledByUser,
                        reason: error.localizedDescription
                    )
                )
                self?.dropInFlutterApi.onDropInAdvancedPlatformCommunication(
                    platformCommunicationModel: platformCommunicationModel,
                    completion: { _ in }
                )
            default:
                self?.sendErrorToFlutterLayer(error: error)
            }
        }
    }

    private func sendErrorToFlutterLayer(error: Error) {
        let platformCommunicationModel = PlatformCommunicationModel(
            type: PlatformCommunicationType.result,
            paymentResult: PaymentResultDTO(
                type: PaymentResultEnum.error,
                reason: error.localizedDescription
            )
        )
        dropInFlutterApi.onDropInAdvancedPlatformCommunication(platformCommunicationModel: platformCommunicationModel, completion: { _ in })
    }
}
