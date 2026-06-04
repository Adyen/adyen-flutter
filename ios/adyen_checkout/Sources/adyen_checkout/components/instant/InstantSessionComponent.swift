import Adyen

// TODO: v6 migration - Session, InstantPaymentComponent, SessionDelegate are now package-access.
@MainActor
class InstantSessionComponent: BaseInstantComponent, InstantComponentProtocol {
    private let checkoutHolder: CheckoutHolder

    init(
        componentFlutterApi: ComponentFlutterInterface,
        paymentMethod: PaymentMethod,
        adyenContext: AdyenContext,
        checkoutHolder: CheckoutHolder,
        componentId: String
    ) {
        self.checkoutHolder = checkoutHolder
        super.init(componentFlutterApi: componentFlutterApi, componentId: componentId)
    }

    func initiatePayment() {
        sendErrorToFlutterLayer(error: PlatformError(errorDescription: "Instant session component not yet migrated to v6."))
    }

    func onDispose() {}
}
