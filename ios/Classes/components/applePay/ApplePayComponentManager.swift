@_spi(AdyenInternal) import Adyen

class ApplePayComponentManager {
    private let componentFlutterApi: ComponentFlutterInterface
    private let sessionHolder: SessionHolder
    var applePayComponent: BaseApplePayComponent?

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
            if (componentId == ApplePaySessionComponent.applePaySessionComponentId) {
                applePayComponent = ApplePaySessionComponent(
                    sessionHolder: sessionHolder,
                    configuration: applePayConfiguration,
                    adyenContext: adyenContext
                )
            } else {
                applePayComponent = ApplePayAdvancedComponent(
                    componentFlutterApi: componentFlutterApi,
                    configuration: applePayConfiguration,
                    adyenContext: adyenContext,
                    paymentMethodResponse: paymentMethodResponse
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
        applePayComponent?.present()
    }
    
    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        applePayComponent?.handlePaymentEvent(paymentEventDTO: paymentEventDTO)
    }
}
