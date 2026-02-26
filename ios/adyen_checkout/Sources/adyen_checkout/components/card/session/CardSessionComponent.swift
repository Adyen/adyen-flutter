@_spi(AdyenInternal) import Adyen
#if canImport(AdyenCard)
    import AdyenCard
#endif
#if canImport(AdyenNetworking)
    import AdyenNetworking
#endif
import Flutter

class CardSessionComponent: BaseCardComponent {
    private let checkoutHolder: CheckoutHolder

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
            do {
                await setupCardComponentView()
            }
        }
    }

    private func setupCardComponentView() async {
        do {
            guard let cardPaymentMethod = checkoutHolder.adyenCheckout?.paymentMethods?.paymentMethod(ofType: CardPaymentMethod.self) else {throw PlatformError(errorDescription: "Card payment method not found") }
            let cardComponent = try buildCardComponent(
                adyenCheckout: checkoutHolder.adyenCheckout!,
                cardPaymentMethod: cardPaymentMethod
            )
            showCardComponent(cardComponent: cardComponent)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    func finalizeAndDismissSessionComponent(success: Bool, completion: @escaping (() -> Void)) {
        finalizeAndDismiss(success: success, completion: { [weak self] in
            guard let self else { return }
            completion()
            self.cardComponent = nil
        })
    }
}
