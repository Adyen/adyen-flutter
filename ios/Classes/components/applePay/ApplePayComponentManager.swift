@_spi(AdyenInternal)
import Adyen

class ApplePayComponentManager {
    private let sessionHolder: SessionHolder
    
    var applePayComponent: ApplePayComponent?

    init(sessionHolder: SessionHolder) {
        self.sessionHolder = sessionHolder
    }
 
    func isApplePayAvailable(instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO, callback: (Result<InstantPaymentSetupResultDTO, Error>) -> Void) {
        guard let applePayConfiguration = try? instantPaymentComponentConfigurationDTO.mapToApplePayConfiguration(),
              let adyenContext = try? instantPaymentComponentConfigurationDTO.createAdyenContext() else {
            callback(Result.failure(PlatformError(errorDescription: "Apple Pay configuration error occurred")))
            return
        }
            
        if sessionHolder.session != nil, sessionHolder.sessionDelegate != nil {
            self.applePayComponent = try? buildApplePaySessionComponent(configuration: applePayConfiguration, context: adyenContext)
        }
            
        callback(Result.success(InstantPaymentSetupResultDTO(instantPaymentType: InstantPaymentType.applePay, isSupported: true)))
    }
    
    func onInstantPaymentPressed(componentId: String) {
        sessionHolder.sessionPresentationDelegate?.present(component: applePayComponent!)
    }
    
    private func buildApplePaySessionComponent(configuration: ApplePayComponent.Configuration, context: AdyenContext) throws -> ApplePayComponent {
        guard let session = sessionHolder.session,
              let paymentMethods = sessionHolder.session?.sessionContext.paymentMethods,
              let paymentMethod = paymentMethods.paymentMethod(ofType: ApplePayPaymentMethod.self),
              let applePayComponent = try? ApplePayComponent(paymentMethod: paymentMethod, context: context, configuration: configuration) else {
            throw PlatformError(errorDescription: "Apple Pay component not found")
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
            })
        }
    }
    
    private func getViewController() -> UIViewController? {
        var rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        while let presentedViewController = rootViewController?.presentedViewController {
            rootViewController = presentedViewController
        }

        return rootViewController
    }
}
