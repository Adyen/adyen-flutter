import Adyen

// TODO: v6 migration - ApplePayComponent, Session, SessionDelegate are now package-access.
@MainActor
class ApplePaySessionComponent: BaseApplePayComponent {
    private let checkoutHolder: CheckoutHolder
    private let configuration: InstantPaymentConfigurationDTO
    private let componentId: String

    init(
        checkoutHolder: CheckoutHolder,
        configuration: InstantPaymentConfigurationDTO,
        componentId: String
    ) throws {
        self.checkoutHolder = checkoutHolder
        self.configuration = configuration
        self.componentId = componentId
        super.init()
    }

    override func present() {
        // TODO: v6 migration - present Apple Pay through checkout session
    }

    override func onDispose() {}
}
