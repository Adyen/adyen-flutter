@_spi(AdyenInternal) import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
#if canImport(AdyenSession)
    import AdyenSession
#endif
import Flutter

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
            let blikComponent = try setupBlikComponent()
            showBlikComponent(blikComponent: blikComponent)
            componentPlatformApi.register(blikBaseComponent: self)
            setupSessionFlowDelegate()
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func setupBlikComponent() throws -> BLIKComponent {
        guard let session = checkoutHolder.session else { throw PlatformError(errorDescription: "Session not found") }
        return try buildBlikComponent(
            paymentMethodString: paymentMethod,
            blikComponentConfiguration: blikComponentConfiguration,
            componentDelegate: session
        )
    }

    private func setupSessionFlowDelegate() {
        if let componentSessionFlowDelegate = (checkoutHolder.sessionDelegate as? ComponentSessionFlowHandler) {
            componentSessionFlowDelegate.register(
                componentId: componentId,
                finalizeCallback: { [weak self] success, completion in
                    self?.finalizeAndDismissSessionComponent(success: success, completion: completion)
                }
            )
        } else {
            assertionFailure("Wrong session flow delegate usage")
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
