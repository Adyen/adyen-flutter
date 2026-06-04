import Adyen
import Foundation

// TODO: v6 migration - ApplePayComponent, PaymentComponentDelegate are now package-access.
@MainActor
class ApplePayAdvancedComponent: BaseApplePayComponent {
    private let componentFlutterApi: ComponentFlutterInterface
    private let configuration: InstantPaymentConfigurationDTO
    private let paymentMethodResponse: String
    private let componentId: String

    init(
        componentFlutterApi: ComponentFlutterInterface,
        configuration: InstantPaymentConfigurationDTO,
        paymentMethodResponse: String,
        componentId: String
    ) throws {
        self.componentFlutterApi = componentFlutterApi
        self.configuration = configuration
        self.paymentMethodResponse = paymentMethodResponse
        self.componentId = componentId
        super.init()
    }

    override func present() {
        sendErrorToFlutterLayer(errorMessage: "Apple Pay advanced component not yet migrated to v6.")
    }

    override func onDispose() {}

    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        // TODO: v6 migration - handle payment events through checkout callbacks
    }

    private func sendErrorToFlutterLayer(errorMessage: String) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: componentId,
            paymentResult: PaymentResultDTO(
                type: PaymentResultEnum.error,
                reason: errorMessage
            )
        )
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }
}
