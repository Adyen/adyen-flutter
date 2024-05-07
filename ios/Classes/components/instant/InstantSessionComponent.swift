import Adyen

class InstantSessionComponent: BaseInstantComponent {
    private let sessionHolder: SessionHolder
    
    init(
        componentFlutterApi: ComponentFlutterInterface,
        paymentMethod: PaymentMethod,
        adyenContext: AdyenContext,
        sessionHolder: SessionHolder,
        componentId: String
    ) {
        self.sessionHolder = sessionHolder
        super.init(componentFlutterApi: componentFlutterApi, componentId: componentId)
        instantPaymentComponent = buildInstantSessionComponent(paymentMethod: paymentMethod, adyenContext: adyenContext)
    }
    
    func buildInstantSessionComponent(paymentMethod: PaymentMethod, adyenContext: AdyenContext) -> InstantPaymentComponent? {
        do {
            guard let session = sessionHolder.session else {
                throw PlatformError(errorDescription: "The provided session identifier or data is invalid.")
            }
            
            let componentSessionFlowDelegate = sessionHolder.sessionDelegate as? ComponentSessionFlowDelegate
            componentSessionFlowDelegate?.componentId = componentId
            componentSessionFlowDelegate?.finalizeAndDismissHandler = finalizeAndDismissComponent
            let component = InstantPaymentComponent(paymentMethod: paymentMethod, context: adyenContext, order: nil)
            component.delegate = session
            return component
        } catch {
            sendErrorToFlutterLayer(error: error)
            return nil
        }
    }
    
    override func finalizeAndDismissComponent(success: Bool, completion: @escaping (() -> Void)) {
        instantPaymentComponent?.finalizeIfNeeded(with: success) { [weak self] in
            guard let self else { return }
            getViewController()?.dismiss(animated: true) {
                completion()
                if success {
                    self.sessionHolder.reset()
                }
            }
        }
    }
    
    override func onDispose() {
        instantPaymentComponent = nil
    }
}
