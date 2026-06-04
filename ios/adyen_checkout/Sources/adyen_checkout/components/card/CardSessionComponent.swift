@_spi(AdyenInternal) import Adyen
@_spi(AdyenInternal) import AdyenCheckout
#if canImport(AdyenCard)
    import AdyenCard
#endif
import Flutter

class CardSessionComponent: BaseCardComponent {
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

        Task {
            await setupCardComponentView()
        }
    }

    private func setupCardComponentView() async {
        do {
            guard let checkout = checkoutHolder.adyenCheckout,
                  let cardPaymentMethod = checkout.paymentMethods?.paymentMethod(ofType: CardPaymentMethod.self)
            else {
                throw PlatformError(errorDescription: "Card payment method not found")
            }
            let cardComponent = try buildCardComponent(
                adyenCheckout: checkout,
                cardPaymentMethod: cardPaymentMethod
            )
            showCardComponent(cardComponent: cardComponent)
            componentPlatformApi.register(cardBaseComponent: self)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }
}
