@_spi(AdyenInternal) import Adyen

class ApplePaySessionComponent : BaseApplePayComponent {
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
        if let applePayComponent = applePayComponent  {
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
        (sessionHolder.sessionDelegate as? ComponentSessionFlowDelegate)?.componentId = "APPLE_PAY_SESSION_COMPONENT"
        (sessionHolder.sessionDelegate as? ComponentSessionFlowDelegate)?.finalizeAndDismissHandler = finalizeAndDismissSessionComponent
        return applePayComponent
    }
        
    func finalizeAndDismissSessionComponent(success: Bool, completion: @escaping (() -> Void)) {
        applePayComponent?.finalizeIfNeeded(with: success) { [weak self] in
            self?.getViewController()?.dismiss(animated: true, completion: {
                completion()
                self?.sessionHolder.reset()
                self?.applePayComponent = nil
            })
        }
    }
}
