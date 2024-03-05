@_spi(AdyenInternal)
import Adyen

class ApplePayComponentManager {
    private let sessionHolder: SessionHolder
    
    var applePayComponent : ApplePayComponent?

    init(sessionHolder: SessionHolder) {
        self.sessionHolder = sessionHolder
    }
 
    func isApplePayAvailable(instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO, callback: (Result<InstantPaymentSetupResultDTO, Error>) -> Void) {
        do {
            guard let applePayConfiguration = try? instantPaymentComponentConfigurationDTO.mapToApplePayConfiguration(),
                  let adyenContext = try? instantPaymentComponentConfigurationDTO.createAdyenContextt() else {
                throw PlatformError(errorDescription: "Apple Pay error")
            }
            
            if (sessionHolder.session != nil && sessionHolder.sessionDelegate != nil) {
                self.applePayComponent = try? buildApplePaySessionComponent(configuration: applePayConfiguration, context: adyenContext )
            } else {
                    throw PlatformError(errorDescription: "Apple Pay error")
                }
            
           
            
            callback(Result.success(InstantPaymentSetupResultDTO(instantPaymentType: InstantPaymentType.applePay, isSupported: true)))
        } catch {
            callback(Result.failure(PlatformError(errorDescription: "Apple Pay error")))
        }
    }
    
    func onInstantPaymentPressed(componentId: String) {
        sessionHolder.sessionPresentationDelegate?.present(component: applePayComponent!)        
    }
    
    private func buildApplePaySessionComponent(configuration: ApplePayComponent.Configuration, context: AdyenContext ) throws -> ApplePayComponent {
        do {
            let paymentMethods = sessionHolder.session!.sessionContext.paymentMethods
            guard let paymentMethod = paymentMethods.paymentMethod(ofType: ApplePayPaymentMethod.self) else {
                throw PlatformError(errorDescription: "Apple Pay not found")
            }

            let component = try ApplePayComponent(paymentMethod: paymentMethod,
                                                  context: context,
                                                  configuration: configuration)
            component.delegate = sessionHolder.session!
            (sessionHolder.sessionDelegate as? ApplePaySessionDelegate)?.finalizeAndDismissHandler = finalizeAndDismissSessionComponent
            
            return component
        } catch {
            throw PlatformError(errorDescription: "Apple Pay not found")
        }
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
