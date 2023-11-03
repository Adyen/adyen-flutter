import Adyen


class CardAdvancedFlowDelegate : PaymentComponentDelegate {
    private let componentFlutterApi: ComponentFlutterApi
    
    init(componentFlutterApi: ComponentFlutterApi) {
        self.componentFlutterApi = componentFlutterApi
    }
    
    
    func didSubmit(_ data: Adyen.PaymentComponentData, from component: Adyen.PaymentComponent) {
        print("DID SUBMIT")
        do {
            let paymentComponentData = PaymentComponentDataResponse(amount: data.amount, paymentMethod: data.paymentMethod.encodable, storePaymentMethod: data.storePaymentMethod, order: data.order, amountToPay: data.order?.remainingAmount, installments: data.installments, shopperName: data.shopperName, emailAddress: data.emailAddress, telephoneNumber: data.telephoneNumber, browserInfo: data.browserInfo, checkoutAttemptId: data.checkoutAttemptId, billingAddress: data.billingAddress, deliveryAddress: data.deliveryAddress, socialSecurityNumber: data.socialSecurityNumber, delegatedAuthenticationData: data.delegatedAuthenticationData)
            let paymentComponentJson = try JSONEncoder().encode(paymentComponentData)
            let paymentComponentString = String(data: paymentComponentJson, encoding: .utf8)
            componentFlutterApi.onComponentCommunication(componentCommunicationModel: ComponentCommunicationModel(type: ComponentCommunicationType.onSubmit, data: paymentComponentString), completion: { _ in })
        } catch {
        }
    }
    
    func didFail(with error: Error, from component: Adyen.PaymentComponent) {
        print("DID FAILL")

    }
    
}
