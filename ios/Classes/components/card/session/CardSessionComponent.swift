@_spi(AdyenInternal)
import Adyen
import AdyenNetworking
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

        setupCardComponentView()
        setupSessionFlowDelegate()
    }

    private func setupCardComponentView() {
        do {
            let cardComponent = try setupCardComponent()
            showCardComponent(cardComponent: cardComponent)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func setupCardComponent() throws -> CardComponent {
        guard let cardComponentConfiguration else { throw PlatformError(errorDescription: "Card configuration not found") }
        guard let paymentMethodString = paymentMethod else { throw PlatformError(errorDescription: "Payment method not found") }
        guard let session = sessionHolder.session else { throw PlatformError(errorDescription: "Session not found") }
        let adyenContext = try cardComponentConfiguration.createAdyenContext()
        let cardComponent = try buildCardComponent(
            paymentMethodString: paymentMethodString,
            isStoredPaymentMethod: isStoredPaymentMethod,
            cardComponentConfiguration: cardComponentConfiguration,
            adyenContext: adyenContext
        )
        cardComponent.delegate = session
        cardComponent.cardComponentDelegate = self
        return cardComponent
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
            self.cardComponent = nil
        })
    }
}
