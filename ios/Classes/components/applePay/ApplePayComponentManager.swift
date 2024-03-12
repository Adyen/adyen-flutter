@_spi(AdyenInternal)
import Adyen

class ApplePayComponentManager {
    private let sessionHolder: SessionHolder
    var applePayComponent: BaseApplePayComponent?

    init(sessionHolder: SessionHolder) {
        self.sessionHolder = sessionHolder
    }
 
    func isApplePayAvailable(instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO, callback: (Result<InstantPaymentSetupResultDTO, Error>) -> Void) {
        guard let applePayConfiguration = try? instantPaymentComponentConfigurationDTO.mapToApplePayConfiguration(),
              let adyenContext = try? instantPaymentComponentConfigurationDTO.createAdyenContext()
        else {
            callback(Result.failure(PlatformError(errorDescription: "Apple Pay configuration error occurred")))
            return
        }
            
        if sessionHolder.session != nil, sessionHolder.sessionDelegate != nil {
            applePayComponent = ApplePaySessionComponent(
                sessionHolder: sessionHolder,
                configuration: applePayConfiguration,
                adyenContext: adyenContext
            )
        }
            
        callback(Result.success(InstantPaymentSetupResultDTO(instantPaymentType: InstantPaymentType.applePay, isSupported: true)))
    }
    
    func onApplePayComponentPressed(componentId: String) {
        applePayComponent?.present()
    }
}
