@_spi(AdyenInternal) import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif

class ApplePaySessionComponent: BaseApplePayComponent {
    private let checkoutHolder: CheckoutHolder
    private let configuration: InstantPaymentConfigurationDTO
    private let componentId: String
    
    init(
        checkoutHolder: CheckoutHolder,
        configuration: InstantPaymentConfigurationDTO,
        componentId: String
    ) throws {
        self.checkoutHolder = checkoutHolder
        self.configuration = configuration
        self.componentId = componentId
        super.init()
        applePayComponent = try buildApplePaySessionComponent()
    }
    
    override func present() {
        if let applePayComponent {
            getViewController()?.present(component: applePayComponent)
        }
    }
    
    override func onDispose() {
        applePayComponent = nil
    }
    
    private func buildApplePaySessionComponent() throws -> ApplePayComponent? {
        guard let session = checkoutHolder.session else { throw PlatformError(errorDescription: "Session is not available.") }
        guard let paymentMethod = session.state.paymentMethods.paymentMethod(ofType: ApplePayPaymentMethod.self) else { throw PlatformError(errorDescription: "Apple Pay payment method not valid.") }
        let context = try configuration.createAdyenContext()
        let payment = session.state.createPayment(fallbackCountryCode: configuration.countryCode)
        let configuration = try configuration.mapToApplePayConfiguration(payment: payment)
        let applePayComponent = try ApplePayComponent(paymentMethod: paymentMethod, context: context, configuration: configuration)
        applePayComponent.delegate = checkoutHolder.session
        setupSessionFlowDelegate()
        return applePayComponent
    }
    
    private func setupSessionFlowDelegate() {
        if let componentSessionFlowDelegate = (checkoutHolder.sessionDelegate as? ComponentSessionFlowHandler) {
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
