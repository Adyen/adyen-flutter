@_spi(AdyenInternal) import Adyen

class ApplePaySessionComponentWrapper: BaseApplePayComponentWrapper {
    private let sessionWrapper: SessionWrapper
    private let configuration: ApplePayComponent.Configuration
    private let adyenContext: AdyenContext
    private let componentId: String
    
    init(
        sessionWrapper: SessionWrapper,
        configuration: ApplePayComponent.Configuration,
        adyenContext: AdyenContext,
        componentId: String
    ) {
        self.sessionWrapper = sessionWrapper
        self.configuration = configuration
        self.adyenContext = adyenContext
        self.componentId = componentId
        super.init()
        applePayComponent = buildApplePaySessionComponent()
    }
    
    override func present() {
        if let applePayComponent {
            sessionWrapper.sessionPresentationDelegate?.present(component: applePayComponent)
        }
    }
    
    override func onDispose() {
        sessionWrapper.reset()
        applePayComponent = nil
    }
    
    private func buildApplePaySessionComponent() -> ApplePayComponent? {
        guard let session = sessionWrapper.session,
              let paymentMethod = session.sessionContext.paymentMethods.paymentMethod(ofType: ApplePayPaymentMethod.self),
              let applePayComponent = try? ApplePayComponent(paymentMethod: paymentMethod, context: adyenContext, configuration: configuration)
        else {
            return nil
        }
        applePayComponent.delegate = sessionWrapper.session
        setupSessionFlowDelegate()
        return applePayComponent
    }
    
    private func setupSessionFlowDelegate() {
        if let componentSessionFlowDelegate = (sessionWrapper.sessionDelegate as? ComponentSessionFlowDelegate) {
            componentSessionFlowDelegate.componentId = componentId
            componentSessionFlowDelegate.finalizeAndDismiss = finalizeAndDismissComponent
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
