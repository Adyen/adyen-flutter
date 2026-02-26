import Adyen

class InstantSessionComponent: BaseInstantComponent, InstantComponentProtocol {
    private let checkoutHolder: CheckoutHolder
    
    init(
        componentFlutterApi: ComponentFlutterInterface,
        paymentMethod: PaymentMethod,
        adyenContext: AdyenContext,
        checkoutHolder: CheckoutHolder,
        componentId: String
    ) {
        self.checkoutHolder = checkoutHolder
        super.init(componentFlutterApi: componentFlutterApi, componentId: componentId)
        instantPaymentComponent = buildInstantSessionComponent(paymentMethod: paymentMethod, adyenContext: adyenContext)
    }
    
    func buildInstantSessionComponent(paymentMethod: PaymentMethod, adyenContext: AdyenContext) -> InstantPaymentComponent? {
        do {
            guard let session = checkoutHolder.session else {
                throw PlatformError(errorDescription: "The provided session identifier or data is invalid.")
            }
            
            let componentSessionFlowHandler = checkoutHolder.sessionDelegate as? ComponentSessionFlowHandler
            componentSessionFlowHandler?.componentId = componentId
            componentSessionFlowHandler?.finalizeCallback = finalizeCallback
            let component = InstantPaymentComponent(paymentMethod: paymentMethod, context: adyenContext, order: nil)
            component.delegate = session
            return component
        } catch {
            sendErrorToFlutterLayer(error: error)
            return nil
        }
    }
    
    func finalizeCallback(success: Bool, completion: @escaping (() -> Void)) {
        instantPaymentComponent?.finalizeIfNeeded(with: success) { [weak self] in
            guard let self else { return }
            getViewController()?.dismiss(animated: true) {
                self.hideActivityIndicator()
                completion()
            }
        }
    }
   
    func onDispose() {
        instantPaymentComponent = nil
    }
}
