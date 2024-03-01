import Adyen

class ApplePayComponentManager {
 
    func isApplePayAvailable(instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO) -> Bool {
        var config = instantPaymentComponentConfigurationDTO.mapToApplePayConfiguration()
        
        return true
    }
    
    internal func applePayComponent(from session: AdyenSession, configuration: ApplePayComponent.Configuration ) throws -> ApplePayComponent {
        let paymentMethods = session.sessionContext.paymentMethods
        guard let paymentMethod = paymentMethods.paymentMethod(ofType: ApplePayPaymentMethod.self) else {
            //TODO
        }

        let component = try ApplePayComponent(paymentMethod: paymentMethod,
                                              context: context,
                                              configuration: configuration)
        component.delegate = session
        return component
    }
}
