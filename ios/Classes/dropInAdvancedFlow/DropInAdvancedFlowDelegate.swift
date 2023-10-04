import Adyen
import AdyenNetworking

class DropInAdvancedFlowDelegate : DropInComponentDelegate {
    private let checkoutFlutterApi : CheckoutFlutterApi
    private let component: DropInComponent
    
    init(checkoutFlutterApi : CheckoutFlutterApi, component: DropInComponent) {
        self.checkoutFlutterApi = checkoutFlutterApi
        self.component = component
    }
    
    func didSubmit(_ data: PaymentComponentData, from component: PaymentComponent, in dropInComponent: AnyDropInComponent) {
        do {
            let paymentComponentData = PaymentComponentDataResponse(amount: data.amount, paymentMethod: data.paymentMethod.encodable, storePaymentMethod: data.storePaymentMethod, order: data.order, amountToPay: data.order?.remainingAmount, installments: data.installments, shopperName: data.shopperName, emailAddress: data.emailAddress, telephoneNumber: data.telephoneNumber, browserInfo: data.browserInfo, checkoutAttemptId: data.checkoutAttemptId, billingAddress: data.billingAddress, deliveryAddress: data.deliveryAddress, socialSecurityNumber: data.socialSecurityNumber, delegatedAuthenticationData: data.delegatedAuthenticationData)
            let paymentComponentJson = try JSONEncoder().encode(paymentComponentData)
            let paymentComponentString = String(data: paymentComponentJson, encoding: .utf8)
            checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel:PlatformCommunicationModel(type: PlatformCommunicationType.paymentComponent, data: paymentComponentString), completion: {_ in })
        } catch let error {
            self.sendErrorToFlutterLayer(error: error)
        }
    }
    
    func didProvide(_ data: ActionComponentData, from component: ActionComponent, in dropInComponent: AnyDropInComponent) {
        do {
            let actionComponentData = ActionComponentDataModel(details: data.details.encodable, paymentData: data.paymentData)
            let actionComponentDataJson = try JSONEncoder().encode(actionComponentData)
            let actionComponentDataString = String(data: actionComponentDataJson, encoding: .utf8)
            checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.additionalDetails, data: actionComponentDataString), completion: {_ in })
        } catch let error {
            self.sendErrorToFlutterLayer(error: error)
        }
    }
    
    func didComplete(from component: ActionComponent, in dropInComponent: AnyDropInComponent) {
        print("did complete")
    }
    
    func didFail(with error: Error, from component: PaymentComponent, in dropInComponent: AnyDropInComponent) {
        dropInComponent.viewController.presentedViewController?.dismiss(animated: true, completion: {
            self.sendErrorToFlutterLayer(error: error)
        })
    }
    
    func didFail(with error: Error, from component: ActionComponent, in dropInComponent: AnyDropInComponent) {
        dropInComponent.viewController.presentedViewController?.dismiss(animated: true, completion: {
            self.sendErrorToFlutterLayer(error: error)
        })
    }
    
    func didFail(with error: Error, from dropInComponent: Adyen.AnyDropInComponent) {
        dropInComponent.viewController.dismiss(animated: true, completion: {
            switch (error) {
            case ComponentError.cancelled:
                let platformCommunicationModel = PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: PaymentResultDTO(type: PaymentResultEnum.cancelledByUser, reason: error.localizedDescription))
                self.checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: platformCommunicationModel, completion: {_ in })
            default:
                self.sendErrorToFlutterLayer(error: error)
            }
        })
    }
    
    private func sendErrorToFlutterLayer(error: Error) {
        let platformCommunicationModel = PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription))
        checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: platformCommunicationModel, completion: {_ in })
    }
}
