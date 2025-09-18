@_spi(AdyenInternal) import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import PassKit

class ApplePayComponentManager {
    private let componentFlutterApi: ComponentFlutterInterface
    private let sessionHolder: SessionHolder
    private var applePayComponent: BaseApplePayComponent?
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
 
    func isApplePayAvailable(
        instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO,
        paymentMethodResponse: String,
        componentId: String,
        callback: (Result<InstantPaymentSetupResultDTO, Error>) -> Void
    ) {
        do {
            let applePayPaymentMethod = try getApplePayPaymentMethod(
                paymentMethodResponse: paymentMethodResponse,
                componentId: componentId
            )
            
            try checkApplePayAvailability(
                applePayConfiguration: instantPaymentComponentConfigurationDTO.applePayConfigurationDTO,
                paymentMethod: applePayPaymentMethod
            )
            
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
    
    func startApplePayComponent(
        instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO,
        paymentMethodResponse: String,
        componentId: String
    ) {
        do {
            applePayComponent = try createApplePayComponent(
                instantPaymentComponentConfigurationDTO: instantPaymentComponentConfigurationDTO,
                paymentMethodResponse: paymentMethodResponse,
                componentId: componentId
            )
            applePayComponent?.present()
        } catch {
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: componentId,
                paymentResult: PaymentResultDTO(
                    type: PaymentResultEnum.error,
                    reason: error.localizedDescription
                )
            )
            componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        }
    }
    
    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        if let applePayComponentWrapper = applePayComponent as? ApplePayAdvancedComponent {
            applePayComponentWrapper.handlePaymentEvent(paymentEventDTO: paymentEventDTO)
        }
    }
    
    func onDispose() {
        applePayComponent?.onDispose()
        applePayComponent = nil
    }
    
    private func createApplePayComponent(
        instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO,
        paymentMethodResponse: String,
        componentId: String
    ) throws -> BaseApplePayComponent {
        if componentId == Constants.applePaySessionComponentId {
            return try ApplePaySessionComponent(
                sessionHolder: sessionHolder,
                configuration: instantPaymentComponentConfigurationDTO,
                componentId: componentId
            )
        } else {
            return try ApplePayAdvancedComponent(
                componentFlutterApi: componentFlutterApi,
                configuration: instantPaymentComponentConfigurationDTO,
                paymentMethodResponse: paymentMethodResponse,
                componentId: componentId
            )
        }
    }
    
    private func getApplePayPaymentMethod(
        paymentMethodResponse: String,
        componentId: String
    ) throws -> ApplePayPaymentMethod {
        if componentId == Constants.applePaySessionComponentId {
            guard let paymentMethod = sessionHolder.session?.sessionContext.paymentMethods.paymentMethod(ofType: ApplePayPaymentMethod.self) else {
                throw PlatformError(errorDescription: "Apple Pay payment method not valid.")
            }
            return paymentMethod
        }

        return try JSONDecoder().decode(ApplePayPaymentMethod.self, from: Data(paymentMethodResponse.utf8))
    }
    
    private func checkApplePayAvailability(
        applePayConfiguration: ApplePayConfigurationDTO?,
        paymentMethod: ApplePayPaymentMethod
    ) throws {
        guard PKPaymentAuthorizationViewController.canMakePayments() else {
            throw ApplePayComponent.Error.deviceDoesNotSupportApplyPay
        }
        
        let allowOnboarding = applePayConfiguration?.allowOnboarding ?? false
        guard allowOnboarding || PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentMethod.supportedNetworks) else {
            throw ApplePayComponent.Error.userCannotMakePayment
        }
    }
}

extension ApplePayPaymentMethod {
    internal var supportedNetworks: [PKPaymentNetwork] {
        var networks = PKPaymentRequest.availableNetworks()
        if let brands {
            let brandsSet = Set(brands)
            networks = networks.filter { brandsSet.contains($0.txVariantName) }
        }
        return networks
    }
}
