@_spi(AdyenInternal) import Adyen
#if canImport(AdyenCard)
    import AdyenCard
#endif
#if canImport(AdyenNetworking)
    import AdyenNetworking
#endif
import Flutter

class CardSessionComponent: BaseCardComponent {
    let sessionHolder: SessionHolder

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

        setupCardComponentView()
    }

    private func setupCardComponentView() {
        do {
            let cardComponent = try setupCardComponent()
            showCardComponent(cardComponent: cardComponent)
            componentPlatformApi.register(cardBaseComponent: self)
            setupSessionFlowDelegate()
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func setupCardComponent() throws -> CardComponent {
        guard let session = sessionHolder.session else { throw PlatformError(errorDescription: "Session not found") }
        return try buildCardComponent(
            paymentMethodString: paymentMethod,
            isStoredPaymentMethod: isStoredPaymentMethod,
            cardComponentConfiguration: cardComponentConfiguration,
            componentDelegate: session,
            cardDelegate: self
        )
    }

    private func setupSessionFlowDelegate() {
        if let componentSessionFlowDelegate = (sessionHolder.sessionDelegate as? ComponentSessionFlowHandler) {
            componentSessionFlowDelegate.register(
                componentId: componentId,
                finalizeCallback: { [weak self] success, completion in
                    self?.finalizeAndDismissSessionComponent(success: success, completion: completion)
                }
            )
            if isStoredPaymentMethod {
                componentSessionFlowDelegate.setCurrentFlow(componentId: componentId)
            }
        } else {
            AdyenAssertion.assertionFailure(message: "Wrong session flow delegate usage")
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
