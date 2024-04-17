@_spi(AdyenInternal) import Adyen

class ApplePayComponentManager: SessionSetupProtocol {
    private let componentFlutterApi: ComponentFlutterInterface
    private var applePayComponentWrapper: BaseApplePayComponentWrapper?
    var sessionWrapper: SessionWrapper?
    
    enum Constants {
        static let applePaySessionComponentId = "APPLE_PAY_SESSION_COMPONENT"
        static let applePayAdvancedComponentId = "APPLE_PAY_ADVANCED_COMPONENT"
    }

    init(componentFlutterApi: ComponentFlutterInterface) {
        self.componentFlutterApi = componentFlutterApi
    }
    
    func setupSession(
        adyenContext: AdyenContext,
        sessionId: String,
        sessionData: String,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) {
        let sessionDelegate = ComponentSessionFlowDelegate(componentFlutterApi: componentFlutterApi)
        let sessionPresentationDelegate = ComponentPresentationDelegate(topViewController: getViewController())
        sessionWrapper = SessionWrapper()
        sessionWrapper?.setup(
            adyenContext: adyenContext,
            sessionId: sessionId,
            sessionData: sessionData,
            sessionDelegate: sessionDelegate,
            sessionPresentationDelegate: sessionPresentationDelegate,
            completion: completion
        )
    }
 
    func setUpApplePayIfAvailable(
        instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO,
        paymentMethodResponse: String,
        componentId: String,
        callback: (Result<InstantPaymentSetupResultDTO, Error>) -> Void
    ) {
        do {
            let applePayConfiguration = try instantPaymentComponentConfigurationDTO.mapToApplePayConfiguration()
            let adyenContext = try instantPaymentComponentConfigurationDTO.createAdyenContext()
            if componentId == Constants.applePaySessionComponentId, sessionWrapper != nil {
                applePayComponentWrapper = ApplePaySessionComponentWrapper(
                    sessionWrapper: sessionWrapper!,
                    configuration: applePayConfiguration,
                    adyenContext: adyenContext,
                    componentId: componentId
                )
            } else {
                applePayComponentWrapper = ApplePayAdvancedComponentWrapper(
                    componentFlutterApi: componentFlutterApi,
                    configuration: applePayConfiguration,
                    adyenContext: adyenContext,
                    paymentMethodResponse: paymentMethodResponse,
                    componentId: componentId
                )
            }
            callback(
                Result.success(
                    InstantPaymentSetupResultDTO(
                        instantPaymentType: InstantPaymentType.applePay,
                        isSupported: true
                    )
                )
            )
        } catch {
            callback(Result.failure(error))
        }
    }
    
    func onApplePayComponentPressed(componentId: String) {
        applePayComponentWrapper?.present()
    }
    
    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        if let applePayComponentWrapper = applePayComponentWrapper as? ApplePayAdvancedComponentWrapper {
            applePayComponentWrapper.handlePaymentEvent(paymentEventDTO: paymentEventDTO)
        }
    }
    
    func onDispose() {
        applePayComponentWrapper?.onDispose()
        applePayComponentWrapper = nil
    }
}
