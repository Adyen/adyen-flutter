@_spi(AdyenInternal) import Adyen
#if canImport(AdyenCard)
    import AdyenCard
#endif
#if canImport(AdyenNetworking)
    import AdyenNetworking
#endif
import Flutter

class CardSessionComponent: BaseCardComponent {
    private let sessionHolder: SessionHolder

    init(
        frame: CGRect,
        viewIdentifier: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi,
        sessionHolder: SessionHolder
    ) {
        self.sessionHolder = sessionHolder
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
            let cardComponent = try await setupCardComponent()
            showCardComponent(cardComponent: cardComponent)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func setupCardComponent() async throws -> AdyenCheckoutComponent {
        return try await buildCardComponentV6(sessionHolder: sessionHolder)
//        guard let session = sessionHolder.session else { throw PlatformError(errorDescription: "Session not found") }
//        return try buildCardComponent(
//            paymentMethodString: paymentMethod,
//            isStoredPaymentMethod: isStoredPaymentMethod,
//            cardComponentConfiguration: cardComponentConfiguration,
//            componentDelegate: session,
//            cardDelegate: self
//        )
    }

    func finalizeAndDismissSessionComponent(success: Bool, completion: @escaping (() -> Void)) {
        finalizeAndDismiss(success: success, completion: { [weak self] in
            guard let self else { return }
            completion()
            self.cardComponent = nil
        })
    }
}
