@_spi(AdyenInternal) import Adyen

class BaseInstantComponent {
    internal let componentFlutterApi: ComponentFlutterInterface
    internal var componentId: String
    internal var instantPaymentComponent: InstantPaymentComponent?
    
    init(componentFlutterApi: ComponentFlutterInterface, componentId: String) {
        self.componentFlutterApi = componentFlutterApi
        self.componentId = componentId
    }
    
    func onDispose() {
        preconditionFailure("This method must be implemented")
    }
    
    func finalizeAndDismissComponent(success: Bool, completion: @escaping (() -> Void)) {
        preconditionFailure("This method must be implemented")
    }
    
    func initiatePayment() {
        instantPaymentComponent?.initiatePayment()
    }
    
    func sendErrorToFlutterLayer(error: Error) {
        let type: PaymentResultEnum
        if let componentError = (error as? ComponentError), componentError == ComponentError.cancelled {
            type = PaymentResultEnum.cancelledByUser
        } else {
            type = PaymentResultEnum.error
        }
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: componentId,
            paymentResult: PaymentResultDTO(
                type: type,
                reason: error.localizedDescription
            )
        )
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }
    
    func getViewController() -> UIViewController? {
        let rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        return rootViewController?.adyen.topPresenter
    }
}
