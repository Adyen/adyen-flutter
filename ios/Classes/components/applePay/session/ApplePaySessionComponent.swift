@_spi(AdyenInternal) import Adyen

class ApplePaySessionComponent: BaseApplePayComponent {
    static let applePaySessionComponentId = "APPLE_PAY_SESSION_COMPONENT"
    private let sessionHolder: SessionHolder
    private let configuration: ApplePayComponent.Configuration
    private let adyenContext: AdyenContext
    
    init(
        sessionHolder: SessionHolder,
        configuration: ApplePayComponent.Configuration,
        adyenContext: AdyenContext
    ) {
        self.sessionHolder = sessionHolder
        self.configuration = configuration
        self.adyenContext = adyenContext
        super.init()
        applePayComponent = buildApplePaySessionComponent()
    }
    
    override func present() {
        if let applePayComponent {
            sessionHolder.sessionPresentationDelegate?.present(component: applePayComponent)
        }
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
        if let componentSessionFlowDelegate = (sessionHolder.sessionDelegate as? ComponentSessionFlowDelegate) {
            componentSessionFlowDelegate.componentId = Self.applePaySessionComponentId
            componentSessionFlowDelegate.finalizeAndDismissHandler = finalizeAndDismissComponent
        } else {
            AdyenAssertion.assertionFailure(message: "Wrong session flow delegate usage")
        }
    }
        
    override func finalizeAndDismissComponent(success: Bool, completion: @escaping (() -> Void)) {
        super.finalizeAndDismissComponent(success: success, completion: completion)
        self.sessionHolder.reset()
    }
}
