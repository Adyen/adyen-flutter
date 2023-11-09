@_spi(AdyenInternal)
import Adyen
import AdyenNetworking
import Flutter

class CardAdvancedFlowComponent: BaseCardComponent {
    private let actionComponentDelegate: ActionComponentDelegate
    private let presentationDelegate: PresentationDelegate

    override init(
        frame: CGRect,
        viewIdentifier: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterApi
    ) {
        presentationDelegate = CardAdvancedFlowPresentationDelegate()
        actionComponentDelegate = CardAdvancedFlowActionComponentDelegate(componentFlutterApi: componentFlutterApi)
        super.init(
            frame: frame,
            viewIdentifier: viewIdentifier,
            arguments: arguments,
            binaryMessenger: binaryMessenger,
            componentFlutterApi: componentFlutterApi
        )

        setupCardComponentView(arguments: arguments)
    }

    private func setupCardComponentView(arguments: NSDictionary) {
        do {
            let cardComponentView = try createCardComponentView(arguments: arguments)
            attachCardView(cardComponentView: cardComponentView)
            componentPlatformApi.onActionCallback = { [weak self] jsonActionResponse in
                self?.onAction(actionResponse: jsonActionResponse)
            }
        } catch {
            // TODO: Dispaly error
        }
    }

    private func createCardComponentView(arguments: NSDictionary) throws -> UIView {
        guard let paymentMethodsResponse = arguments.value(forKey: "paymentMethods") as? String else { throw PlatformError(errorDescription: "Payment methods not found") }
        guard let cardComponentConfiguration = arguments.value(forKey: "cardComponentConfiguration") as? CardComponentConfigurationDTO else { throw PlatformError(errorDescription: "Card configuration not found") }
        let paymentMethods = try JSONDecoder().decode(PaymentMethods.self, from: Data(paymentMethodsResponse.utf8))
        cardComponent = try buildCardComponent(paymentMethods: paymentMethods, cardComponentConfiguration: cardComponentConfiguration)
        cardDelegate = CardAdvancedFlowDelegate(componentFlutterApi: componentFlutterApi)
        cardComponent?.delegate = cardDelegate
        guard let componentViewController = cardComponent?.viewController else { throw PlatformError(errorDescription: "Failed to initialize card component") }
        guard let cardView = componentViewController.view else { throw PlatformError(errorDescription: "Failed to get card component view") }
        getViewController()?.addChild(componentViewController)
        return cardView
    }

    private func buildCardComponent(paymentMethods: PaymentMethods, cardComponentConfiguration: CardComponentConfigurationDTO) throws -> CardComponent {
        guard let paymentMethod = paymentMethods.paymentMethod(ofType: CardPaymentMethod.self) else {
            throw PlatformError(errorDescription: "Card payment method not provided")
        }

        let adyenContext = try cardComponentConfiguration.createAdyenContext()
        let cardConfiguration = cardComponentConfiguration.cardConfiguration.mapToCardComponentConfiguration()
        let cardComponent = CardComponent(paymentMethod: paymentMethod, context: adyenContext, configuration: cardConfiguration)
        actionComponent = try buildActionComponent(adyenContext: adyenContext)
        return cardComponent
    }

    private func buildActionComponent(adyenContext: AdyenContext) throws -> AdyenActionComponent {
        let actionComponent = AdyenActionComponent(context: adyenContext)
        actionComponent.delegate = actionComponentDelegate
        actionComponent.presentationDelegate = presentationDelegate
        return actionComponent
    }

    private func onAction(actionResponse: [String?: Any?]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: actionResponse, options: [])
            let action = try JSONDecoder().decode(Action.self, from: jsonData)
            actionComponent?.handle(action)
        } catch {
            print("Error in handling action")
        }
    }
}
