@_spi(AdyenInternal) import Adyen
@_spi(AdyenInternal) import AdyenCheckout
import Flutter

// TODO: v6 migration - Session, SessionDelegate are now package-access.
class BlikSessionComponent: BaseBlikComponent {
    let checkoutHolder: CheckoutHolder

    init(
        frame: CGRect,
        viewIdentifier: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi,
        checkoutHolder: CheckoutHolder
    ) {
        self.checkoutHolder = checkoutHolder
        super.init(
            frame: frame,
            viewIdentifier: viewIdentifier,
            arguments: arguments,
            binaryMessenger: binaryMessenger,
            componentFlutterApi: componentFlutterApi,
            componentPlatformApi: componentPlatformApi
        )

        setupBlikComponentView()
    }

    private func setupBlikComponentView() {
        do {
            guard let checkout = checkoutHolder.adyenCheckout else {
                throw PlatformError(errorDescription: "Checkout not available")
            }
            guard let paymentMethodString = paymentMethod else {
                throw PlatformError(errorDescription: "Payment method not found")
            }
            let blikPaymentMethod = try JSONDecoder().decode(BLIKPaymentMethod.self, from: Data(paymentMethodString.utf8))
            let blikComponent = try buildBlikComponent(adyenCheckout: checkout, blikPaymentMethod: blikPaymentMethod)
            showBlikComponent(blikComponent: blikComponent)
            componentPlatformApi.register(blikBaseComponent: self)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }
}
