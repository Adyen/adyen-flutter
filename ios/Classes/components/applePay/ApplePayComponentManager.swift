@_spi(AdyenInternal) import Adyen

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
            // Creating an instance is unused to check whether Apple Pay is available.
            if componentId == Constants.applePaySessionComponentId {
                _ = try ApplePaySessionComponent(
                    sessionHolder: sessionHolder,
                    configuration: instantPaymentComponentConfigurationDTO,
                    componentId: componentId
                )
            } else {
                _ = try ApplePayAdvancedComponent(
                    componentFlutterApi: componentFlutterApi,
                    configuration: instantPaymentComponentConfigurationDTO,
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
}
