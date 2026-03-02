@_spi(AdyenInternal) import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
#if canImport(AdyenSession)
    import AdyenSession
#endif
import Flutter

class BlikSessionComponent: BaseBlikComponent {
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

        setupBlikComponentView()
        setupSessionFlowDelegate()
    }

    private func setupBlikComponentView() {
        do {
            let blikComponent = try setupBlikComponent()
            showBlikComponent(blikComponent: blikComponent)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func setupBlikComponent() throws -> BLIKComponent {
        guard let session = sessionHolder.session else { throw PlatformError(errorDescription: "Session not found") }
        guard let paymentMethodString = paymentMethod else { throw PlatformError(errorDescription: "Payment method not found") }
        guard let blikComponentConfiguration else { throw PlatformError(errorDescription: "Blik configuration not found") }
        let adyenContext = try blikComponentConfiguration.createAdyenContext()
        let paymentMethod = try JSONDecoder().decode(BLIKPaymentMethod.self, from: Data(paymentMethodString.utf8))
        let blikComponentStyle = AdyenAppearance.blikComponentStyle
        let blikComponent = BLIKComponent(
            paymentMethod: paymentMethod,
            context: adyenContext,
            configuration: .init(style: blikComponentStyle)
        )
        blikComponent.delegate = session
        return blikComponent
    }

    private func setupSessionFlowDelegate() {
        if let componentSessionFlowDelegate = (sessionHolder.sessionDelegate as? ComponentSessionFlowHandler) {
            componentSessionFlowDelegate.finalizeCallback = finalizeAndDismissSessionComponent
            componentSessionFlowDelegate.componentId = componentId
        } else {
            AdyenAssertion.assertionFailure(message: "Wrong session flow delegate usage")
        }
    }

    func finalizeAndDismissSessionComponent(success: Bool, completion: @escaping (() -> Void)) {
        finalizeAndDismiss(success: success, completion: { [weak self] in
            guard let self else { return }
            completion()
            self.blikComponent = nil
        })
    }
}
