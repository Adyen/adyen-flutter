import Adyen
import AdyenNetworking

class DropInAdvancedFlowDelegate: DropInComponentDelegate {
    private let dropInFlutterApi: DropInFlutterInterface
    public weak var dropInInteractorDelegate: DropInInteractorDelegate?
    var isApplePay: Bool = false

    init(dropInFlutterApi: DropInFlutterInterface) {
        self.dropInFlutterApi = dropInFlutterApi
    }

    func didSubmit(_ data: PaymentComponentData, from paymentComponent: PaymentComponent, in _: AnyDropInComponent) {
        do {
            let paymentComponentData = PaymentComponentDataResponse(
                amount: data.amount,
                paymentMethod: data.paymentMethod.encodable,
                storePaymentMethod: data.storePaymentMethod,
                order: data.order,
                amountToPay: data.order?.remainingAmount,
                installments: data.installments,
                shopperName: data.shopperName,
                emailAddress: data.emailAddress,
                telephoneNumber: data.telephoneNumber,
                browserInfo: data.browserInfo,
                checkoutAttemptId: data.checkoutAttemptId,
                billingAddress: data.billingAddress,
                deliveryAddress: data.deliveryAddress,
                socialSecurityNumber: data.socialSecurityNumber,
                delegatedAuthenticationData: data.delegatedAuthenticationData
            )
            let paymentComponentJson = try JSONEncoder().encode(paymentComponentData)
            let paymentComponentString = String(data: paymentComponentJson, encoding: .utf8)
            isApplePay = paymentComponent is ApplePayComponent
            dropInFlutterApi.onDropInAdvancedPlatformCommunication(
                platformCommunicationModel: PlatformCommunicationModel(
                    type: PlatformCommunicationType.paymentComponent,
                    data: paymentComponentString
                ),
                completion: { _ in }
            )
        } catch {
            sendErrorToFlutterLayer(error: error)
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
            sendErrorToFlutterLayer(error: error)
        }
    }

    func didComplete(from _: ActionComponent, in _: AnyDropInComponent) {
        dropInInteractorDelegate?.finalizeAndDismiss(success: true) { [weak self] in
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
        dropInInteractorDelegate?.finalizeAndDismiss(success: false) { [weak self] in
            self?.sendErrorToFlutterLayer(error: error)
        }
    }

    func didFail(with error: Error, from _: ActionComponent, in _: AnyDropInComponent) {
        dropInInteractorDelegate?.finalizeAndDismiss(success: false) { [weak self] in
            self?.sendErrorToFlutterLayer(error: error)
        }
    }

    func didFail(with error: Error, from _: Adyen.AnyDropInComponent) {
        dropInInteractorDelegate?.finalizeAndDismiss(success: false) { [weak self] in
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
