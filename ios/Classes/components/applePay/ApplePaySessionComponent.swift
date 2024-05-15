@_spi(AdyenInternal) import Adyen

class ApplePaySessionComponent: BaseApplePayComponent {
    private let sessionHolder: SessionHolder
    private let configuration: ApplePayComponent.Configuration
    private let adyenContext: AdyenContext
    private let componentId: String
    
    init(
        sessionHolder: SessionHolder,
        configuration: ApplePayComponent.Configuration,
        adyenContext: AdyenContext,
        componentId: String
    ) {
        self.sessionHolder = sessionHolder
        self.configuration = configuration
        self.adyenContext = adyenContext
        self.componentId = componentId
        super.init()
        applePayComponent = buildApplePaySessionComponent()
    }
    
    override func present() {
        if let applePayComponent {
            sessionHolder.sessionPresentationDelegate?.present(component: applePayComponent)
        }
    }
    
    override func onDispose() {
        sessionHolder.reset()
        applePayComponent = nil
    }
    
    private func buildApplePaySessionComponent() -> ApplePayComponent? {
        guard let session = sessionHolder.session,
              let paymentMethod = session.sessionContext.paymentMethods.paymentMethod(ofType: ApplePayPaymentMethod.self),
              let applePayComponent = try? ApplePayComponent(paymentMethod: paymentMethod, context: adyenContext, configuration: configuration)
        else {
            return nil
        }
        applePayComponent.delegate = sessionHolder.session
        setupSessionFlowDelegate()
        return applePayComponent
    }
    
    private func setupSessionFlowDelegate() {
        if let componentSessionFlowDelegate = (sessionHolder.sessionDelegate as? ComponentSessionFlowHandler) {
            componentSessionFlowDelegate.componentId = componentId
            componentSessionFlowDelegate.finalizeCallback = finalizeAndDismissComponent
        } else {
            AdyenAssertion.assertionFailure(message: "Wrong session flow delegate usage")
        }
    }
        
    override func finalizeAndDismissComponent(success: Bool, completion: @escaping (() -> Void)) {
        super.finalizeAndDismissComponent(success: success, completion: { [weak self] in
            completion()
        })
    }
}
