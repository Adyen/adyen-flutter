import Adyen
import Foundation

// TODO: v6 migration - CheckoutActionComponent, InstantPaymentComponent, PaymentComponentDelegate, ResultCode are now package-access.
@MainActor
class InstantAdvancedComponent: BaseInstantComponent, InstantComponentProtocol {
    init(
        componentFlutterApi: ComponentFlutterInterface,
        paymentMethod: PaymentMethod,
        adyenContext: AdyenContext,
        componentId: String
    ) {
        super.init(componentFlutterApi: componentFlutterApi, componentId: componentId)
    }

    func initiatePayment() {
        sendErrorToFlutterLayer(error: PlatformError(errorDescription: "Instant advanced component not yet migrated to v6."))
    }

    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        // TODO: v6 migration - handle payment events through checkout callbacks
    }

    func onDispose() {}
}
