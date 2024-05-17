import Adyen

class CardAdvancedFlowDelegate: PaymentComponentDelegate {
    private let componentFlutterApi: ComponentFlutterInterface
    private let componentId: String

    init(componentFlutterApi: ComponentFlutterInterface, componentId: String) {
        self.componentFlutterApi = componentFlutterApi
        self.componentId = componentId
    }

    func didSubmit(_ data: Adyen.PaymentComponentData, from _: Adyen.PaymentComponent) {
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
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.onSubmit,
                componentId: componentId,
                data: paymentComponentString
            )
            componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        } catch {
            sendErrorToFlutterLayer(error: error)
        }
    }

    func didFail(with error: Error, from _: Adyen.PaymentComponent) {
        sendErrorToFlutterLayer(error: error)
    }

    private func sendErrorToFlutterLayer(error: Error) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: componentId,
            paymentResult: PaymentResultDTO(
                type: PaymentResultEnum.error,
                reason: error.localizedDescription
            )
        )
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }
}
