@_spi(AdyenInternal) import Adyen
@_spi(AdyenInternal) import AdyenCheckout

@MainActor
class InstantSessionComponent: BaseInstantComponent, InstantComponentProtocol {
    private let checkoutHolder: CheckoutHolder
    private let paymentMethodType: PaymentMethodType

    init(
        componentFlutterApi: ComponentFlutterInterface,
        paymentMethodType: PaymentMethodType,
        checkoutHolder: CheckoutHolder,
        componentId: String
    ) {
        self.checkoutHolder = checkoutHolder
        self.paymentMethodType = paymentMethodType
        super.init(componentFlutterApi: componentFlutterApi, componentId: componentId)
    }

    func initiatePayment() {
        do {
            guard let checkout = checkoutHolder.adyenCheckout else {
                throw PlatformError(errorDescription: "Session checkout is not set up.")
            }
            let component = try checkout.createPaymentComponent(for: paymentMethodType)
            present(component: component)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    override func onDispose() {
        super.onDispose()
    }
}
