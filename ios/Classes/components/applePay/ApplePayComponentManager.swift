@_spi(AdyenInternal) import Adyen

class ApplePayComponentManager {
    private let componentFlutterApi: ComponentFlutterInterface
    private let sessionHolder: SessionHolder
    private var applePayComponentWrapper: BaseApplePayComponentWrapper?
    
    enum Constants {
        static let applePaySessionComponentId = "APPLE_PAY_SESSION_COMPONENT"
        static let applePayAdvancedComponentId = "APPLE_PAY_ADVANCED_COMPONENT"
    }

    init(
        componentFlutterApi: ComponentFlutterInterface,
        sessionHolder: SessionHolder
    ) {
        self.componentFlutterApi = componentFlutterApi
        self.sessionHolder = sessionHolder
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
            if componentId == Constants.applePaySessionComponentId {
                applePayComponentWrapper = ApplePaySessionComponentWrapper(
                    sessionHolder: sessionHolder,
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
