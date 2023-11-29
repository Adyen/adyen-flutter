@_spi(AdyenInternal)
import Adyen
import AdyenNetworking
import Flutter

class CardAdvancedFlowComponent: BaseCardComponent {
    private let isStoredPaymentMethodKey = "isStoredPaymentMethod"
    private let paymentMethodKey = "paymentMethod"
    private let initialFrame: CGRect
    private let isStoredPaymentMethod: Bool
    private let actionComponentDelegate: ActionComponentDelegate

    private var actionComponent: AdyenActionComponent?

    override init(
        frame: CGRect,
        viewIdentifier: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface
    ) {
        isStoredPaymentMethod = arguments.value(forKey: isStoredPaymentMethodKey) as? Bool ?? false
        actionComponentDelegate = CardAdvancedFlowActionComponentDelegate(componentFlutterApi: componentFlutterApi)
        initialFrame = frame
        super.init(
            frame: frame,
            viewIdentifier: viewIdentifier,
            arguments: arguments,
            binaryMessenger: binaryMessenger,
            componentFlutterApi: componentFlutterApi
        )

        setupCardComponentView(arguments: arguments)
        setupFinalizeComponentCallback()
    }

    private func setupCardComponentView(arguments: NSDictionary) {
        do {
            cardComponent = try setupCardComponent(arguments: arguments)
            if isStoredPaymentMethod {
                guard let storedCardViewController = cardComponent?.viewController else { return }
                attachActivityIndicator()
                getViewController()?.presentViewController(storedCardViewController, animated: true)
            } else {
                guard let cardView = cardComponent?.viewController.view else { return }
                attachCardView(cardView: cardView)
            }

            componentPlatformApi.onActionCallback = { [weak self] jsonActionResponse in
                self?.onAction(actionResponse: jsonActionResponse)
            }
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func setupCardComponent(arguments: NSDictionary) throws -> CardComponent {
        guard let paymentMethodString = arguments.value(forKey: paymentMethodKey) as? String else { throw PlatformError(errorDescription: "Payment method not found") }
        guard let cardComponentConfiguration = arguments.value(forKey: cardComponentConfigurationKey) as? CardComponentConfigurationDTO else { throw PlatformError(errorDescription: "Card configuration not found") }
        let cardComponent = try buildCardComponent(paymentMethodString: paymentMethodString, isStoredPaymentMethod: isStoredPaymentMethod, cardComponentConfiguration: cardComponentConfiguration)
        cardDelegate = CardAdvancedFlowDelegate(componentFlutterApi: componentFlutterApi)
        cardComponent.delegate = cardDelegate
        cardComponent.viewController.view.frame = initialFrame
        return cardComponent
    }

    private func buildCardComponent(paymentMethodString: String, isStoredPaymentMethod: Bool, cardComponentConfiguration: CardComponentConfigurationDTO) throws -> CardComponent {
        let adyenContext = try cardComponentConfiguration.createAdyenContext()
        let cardConfiguration = cardComponentConfiguration.cardConfiguration.mapToCardComponentConfiguration()
        presentationDelegate = CardPresentationDelegate(topViewController: getViewController())
        actionComponent = buildActionComponent(adyenContext: adyenContext)
        if isStoredPaymentMethod {
            let paymentMethod = try JSONDecoder().decode(StoredCardPaymentMethod.self, from: Data(paymentMethodString.utf8))
            return CardComponent(paymentMethod: paymentMethod, context: adyenContext, configuration: cardConfiguration)
        } else {
            let paymentMethod = try JSONDecoder().decode(CardPaymentMethod.self, from: Data(paymentMethodString.utf8))
            return CardComponent(paymentMethod: paymentMethod, context: adyenContext, configuration: cardConfiguration)
        }
    }

    private func buildActionComponent(adyenContext: AdyenContext) -> AdyenActionComponent {
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
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func setupFinalizeComponentCallback() {
        componentPlatformApi.onFinishCallback = { [weak self] paymentFlowOutcome in
            let resultCode = ResultCode(rawValue: paymentFlowOutcome.result ?? "")
            let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
            self?.finalizeAndDismiss(success: success, completion: { [weak self] in
                let componentCommunicationModel = ComponentCommunicationModel(type: ComponentCommunicationType.result,
                                                                              paymentResult: PaymentResultModelDTO(resultCode: resultCode?.rawValue))
                self?.componentFlutterApi.onComponentCommunication(componentCommunicationModel: componentCommunicationModel, completion: { _ in })
            })
        }
    }
}
