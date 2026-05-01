@_spi(AdyenInternal) import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import PassKit

class ApplePaySessionComponent: BaseApplePayComponent {
    private let sessionHolder: SessionHolder
    private let configuration: InstantPaymentConfigurationDTO
    private let componentFlutterApi: ComponentFlutterInterface
    private let componentId: String
    
    init(
        sessionHolder: SessionHolder,
        configuration: InstantPaymentConfigurationDTO,
        componentFlutterApi: ComponentFlutterInterface,
        componentId: String
    ) throws {
        self.sessionHolder = sessionHolder
        self.configuration = configuration
        self.componentFlutterApi = componentFlutterApi
        self.componentId = componentId
        super.init()
        applePayComponent = try buildApplePaySessionComponent()
    }
    
    override func present() {
        if let applePayComponent {
            (sessionHolder.sessionDelegate as? ComponentSessionFlowHandler)?.setCurrentFlow(componentId: componentId)
            getViewController()?.present(component: applePayComponent)
        }
    }
    
    override func onDispose() {
        applePayComponent = nil
    }
    
    private func buildApplePaySessionComponent() throws -> ApplePayComponent? {
        guard let session = sessionHolder.session else { throw PlatformError(errorDescription: "Session is not available.") }
        guard let paymentMethod = session.sessionContext.paymentMethods.paymentMethod(ofType: ApplePayPaymentMethod.self) else { throw PlatformError(errorDescription: "Apple Pay payment method not valid.") }
        let context = try configuration.createAdyenContext()
        let payment = session.sessionContext.createPayment(fallbackCountryCode: configuration.countryCode)
        let configuration = try configuration.mapToApplePayConfiguration(payment: payment)
        let applePayComponent = try ApplePayComponent(paymentMethod: paymentMethod, context: context, configuration: configuration)
        applePayComponent.delegate = sessionHolder.session
        if self.configuration.applePayConfigurationDTO?.hasOnShippingMethodChange == true {
            applePayComponent.applePayDelegate = self
        }
        setupSessionFlowDelegate()
        return applePayComponent
    }
    
    private func setupSessionFlowDelegate() {
        if let componentSessionFlowDelegate = (sessionHolder.sessionDelegate as? ComponentSessionFlowHandler) {
            componentSessionFlowDelegate.register(
                componentId: componentId,
                finalizeCallback: finalizeAndDismissComponent
            )
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

extension ApplePaySessionComponent: ApplePayComponentDelegate {
    func didUpdate(
        contact: PKContact,
        for payment: ApplePayPayment,
        completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        completion(PKPaymentRequestShippingContactUpdate(paymentSummaryItems: payment.summaryItems))
    }

    func didUpdate(
        shippingMethod: PKShippingMethod,
        for payment: ApplePayPayment,
        completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
    ) {
        componentFlutterApi.onApplePayShippingMethodChange(
            componentId: componentId,
            shippingMethod: shippingMethod.toDTO(currencyCode: payment.currencyCode),
            currentSummaryItems: payment.summaryItems.map { $0.toDTO(currencyCode: payment.currencyCode) },
            completion: { result in
                switch result {
                case let .success(update):
                    completion(update.toPKPaymentRequestShippingMethodUpdate())
                case .failure:
                    completion(PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: payment.summaryItems))
                }
            }
        )
    }

    @available(iOS 15.0, *)
    func didUpdate(
        couponCode: String,
        for payment: ApplePayPayment,
        completion: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void
    ) {
        completion(PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: payment.summaryItems))
    }
}
