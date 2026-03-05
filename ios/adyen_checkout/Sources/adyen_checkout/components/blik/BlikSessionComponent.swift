@_spi(AdyenInternal) import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
#if canImport(AdyenSession)
    import AdyenSession
#endif
import Flutter

class BlikSessionComponent: BaseBlikComponent, SessionComponentProtocol {
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
        let blikComponent = try buildBlikComponent(
            paymentMethodString: paymentMethod,
            blikComponentConfiguration: blikComponentConfiguration,
            componentDelegate: nil
        )
        blikComponent.delegate = session
        return blikComponent
    }

    func finalizeAndDismissSessionComponent(success: Bool, completion: @escaping (() -> Void)) {
        finalizeAndDismiss(success: success, completion: { [weak self] in
            guard let self else { return }
            completion()
            self.blikComponent = nil
        })
    }
}
