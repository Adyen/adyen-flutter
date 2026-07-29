@_spi(AdyenInternal) import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import Foundation
import PassKit

/// Generic manager for payment methods that don't need an embedded Flutter platform view
/// (e.g. Apple Pay, Google Pay, redirect-style instant payment methods). Apple Pay is routed
/// through this same manager, since `CheckoutPaymentComponent` handles it identically to any
/// other payment method type; the only Apple Pay-specific step is the on-device hardware
/// capability check before the button is shown.
@MainActor
class InstantComponentManager {
    private let componentFlutterApi: ComponentFlutterInterface
    private let checkoutHolder: CheckoutHolder
    private var instantComponent: InstantComponentProtocol?
    enum Constants {
        static let instantSessionComponentId = "INSTANT_SESSION_COMPONENT"
        static let instantAdvancedComponentId = "INSTANT_ADVANCED_COMPONENT"
        static let applePaySessionComponentId = "APPLE_PAY_SESSION_COMPONENT"
        static let applePayAdvancedComponentId = "APPLE_PAY_ADVANCED_COMPONENT"
    }

    init(componentFlutterApi: ComponentFlutterInterface, checkoutHolder: CheckoutHolder) {
        self.componentFlutterApi = componentFlutterApi
        self.checkoutHolder = checkoutHolder
    }

    func isApplePayAvailable(
        instantPaymentComponentConfigurationDTO: InstantPaymentConfigurationDTO,
        paymentMethodResponse: String,
        componentId: String,
        callback: (Result<InstantPaymentSetupResultDTO, Error>) -> Void
    ) {
        do {
            let applePayPaymentMethod = try JSONDecoder().decode(ApplePayPaymentMethod.self, from: Data(paymentMethodResponse.utf8))
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

    func startInstantComponent(
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO,
        encodedPaymentMethod: String,
        componentId: String
    ) {
        do {
            if isAdvancedComponent(componentId: componentId) {
                instantComponent = InstantAdvancedComponent(
                    componentFlutterApi: componentFlutterApi,
                    instantPaymentConfigurationDTO: instantPaymentConfigurationDTO,
                    paymentMethodResponse: encodedPaymentMethod,
                    componentId: componentId
                )
            } else if isSessionComponent(componentId: componentId) {
                let paymentMethod = try JSONDecoder().decode(InstantPaymentMethod.self, from: Data(encodedPaymentMethod.utf8))
                if componentId == Constants.applePaySessionComponentId {
                    checkoutHolder.activeApplePayComponentId = componentId
                }
                instantComponent = InstantSessionComponent(
                    componentFlutterApi: componentFlutterApi,
                    paymentMethodType: paymentMethod.type,
                    checkoutHolder: checkoutHolder,
                    componentId: componentId
                )
            } else {
                throw PlatformError(errorDescription: "Instant component not available for payment flow.")
            }
            instantComponent?.initiatePayment()
        } catch {
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: componentId,
                paymentResult: PaymentResultDTO(
                    type: PaymentResultEnum.error,
                    reason: error.localizedDescription
                )
            )
            self.componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        }
    }

    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        if let instantAdvancedComponent = instantComponent as? InstantAdvancedComponent {
            instantAdvancedComponent.handlePaymentEvent(paymentEventDTO: paymentEventDTO)
        }
    }

    func onDispose() {
        instantComponent?.onDispose()
        instantComponent = nil
    }

    private func isSessionComponent(componentId: String) -> Bool {
        componentId == Constants.instantSessionComponentId || componentId == Constants.applePaySessionComponentId
    }

    private func isAdvancedComponent(componentId: String) -> Bool {
        componentId == Constants.instantAdvancedComponentId || componentId == Constants.applePayAdvancedComponentId
    }

    private func checkApplePayAvailability(
        applePayConfiguration: ApplePayConfigurationDTO?,
        paymentMethod: ApplePayPaymentMethod
    ) throws {
        guard PKPaymentAuthorizationViewController.canMakePayments() else {
            throw PlatformError(errorDescription: "Device does not support Apple Pay.")
        }

        let allowOnboarding = applePayConfiguration?.allowOnboarding ?? false
        guard allowOnboarding || PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentMethod.supportedNetworks) else {
            throw PlatformError(errorDescription: "User cannot make Apple Pay payments.")
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
