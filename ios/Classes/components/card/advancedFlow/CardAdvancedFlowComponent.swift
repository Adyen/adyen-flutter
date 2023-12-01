@_spi(AdyenInternal)
import Adyen
import AdyenNetworking
import Flutter

class CardAdvancedFlowComponent: BaseCardComponent {
    private let actionComponentDelegate: ActionComponentDelegate
    private var actionComponent: AdyenActionComponent?

    override init(
        frame: CGRect,
        viewIdentifier: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface
    ) {
        actionComponentDelegate = CardAdvancedFlowActionComponentDelegate(componentFlutterApi: componentFlutterApi)
        super.init(
            frame: frame,
            viewIdentifier: viewIdentifier,
            arguments: arguments,
            binaryMessenger: binaryMessenger,
            componentFlutterApi: componentFlutterApi
        )

        setupCardComponentView()
        setupFinalizeComponentCallback()
    }

    private func setupCardComponentView() {
        do {
            cardComponent = try setupCardComponent()
            showCardComponent()
            componentPlatformApi.onActionCallback = { [weak self] jsonActionResponse in
                self?.onAction(actionResponse: jsonActionResponse)
            }
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func setupCardComponent() throws -> CardComponent {
        guard let cardComponentConfiguration = cardComponentConfiguration else { throw PlatformError(errorDescription: "Card configuration not found") }
        guard let paymentMethodString = paymentMethod else { throw PlatformError(errorDescription: "Payment method not found") }
        let cardComponent = try buildCardComponent(paymentMethodString: paymentMethodString, isStoredPaymentMethod: isStoredPaymentMethod, cardComponentConfiguration: cardComponentConfiguration)
        cardDelegate = CardAdvancedFlowDelegate(componentFlutterApi: componentFlutterApi)
        cardComponent.delegate = cardDelegate
        return cardComponent
    }

    private func buildCardComponent(paymentMethodString: String, isStoredPaymentMethod: Bool, cardComponentConfiguration: CardComponentConfigurationDTO) throws -> CardComponent {
        let adyenContext = try cardComponentConfiguration.createAdyenContext()
        let cardConfiguration = cardComponentConfiguration.cardConfiguration.mapToCardComponentConfiguration()
        let paymentMethod: AnyCardPaymentMethod = isStoredPaymentMethod ? try JSONDecoder().decode(StoredCardPaymentMethod.self, from: Data(paymentMethodString.utf8)) : try JSONDecoder().decode(CardPaymentMethod.self, from: Data(paymentMethodString.utf8))
        presentationDelegate = CardPresentationDelegate(topViewController: getViewController())
        actionComponent = buildActionComponent(adyenContext: adyenContext)
        return CardComponent(paymentMethod: paymentMethod, context: adyenContext, configuration: cardConfiguration)
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
                let componentCommunicationModel = ComponentCommunicationModel(type: ComponentCommunicationType.result, paymentResult: PaymentResultModelDTO(resultCode: resultCode?.rawValue))
                self?.componentFlutterApi.onComponentCommunication(componentCommunicationModel: componentCommunicationModel, completion: { _ in })
            })
        }
    }
}
