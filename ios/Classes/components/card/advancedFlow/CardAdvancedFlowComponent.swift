@_spi(AdyenInternal)
import Adyen
import AdyenNetworking
import Flutter

class CardAdvancedFlowComponent: BaseCardComponent {
    private let actionComponentDelegate: ActionComponentDelegate
    private var presentationDelegate: PresentationDelegate?
    private var actionComponent: AdyenActionComponent?
    private let initialFrame: CGRect

    override init(
        frame: CGRect,
        viewIdentifier: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface
    ) {
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
            let cardComponentView = try createCardComponentView(arguments: arguments)
            attachCardView(cardComponentView: cardComponentView)
            componentPlatformApi.onActionCallback = { [weak self] jsonActionResponse in
                self?.onAction(actionResponse: jsonActionResponse)
            }
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func createCardComponentView(arguments: NSDictionary) throws -> UIView {
        guard let paymentMethodsResponse = arguments.value(forKey: "paymentMethods") as? String else { throw PlatformError(errorDescription: "Payment methods not found") }
        guard let cardComponentConfiguration = arguments.value(forKey: "cardComponentConfiguration") as? CardComponentConfigurationDTO else { throw PlatformError(errorDescription: "Card configuration not found") }
        let paymentMethods = try JSONDecoder().decode(PaymentMethods.self, from: Data(paymentMethodsResponse.utf8))
        cardComponent = try buildCardComponent(paymentMethods: paymentMethods, cardComponentConfiguration: cardComponentConfiguration)
        cardDelegate = CardAdvancedFlowDelegate(componentFlutterApi: componentFlutterApi)
        cardComponent?.delegate = cardDelegate
        cardComponent?.viewController.view.frame = initialFrame
        guard let cardView = cardComponent?.viewController.view else { throw PlatformError(errorDescription: "Failed to get card component view") }
        return cardView
    }

    private func buildCardComponent(paymentMethods: PaymentMethods, cardComponentConfiguration: CardComponentConfigurationDTO) throws -> CardComponent {
        guard let paymentMethod = paymentMethods.paymentMethod(ofType: CardPaymentMethod.self) else { throw PlatformError(errorDescription: "Card payment method not provided") }
        let adyenContext = try cardComponentConfiguration.createAdyenContext()
        let cardConfiguration = cardComponentConfiguration.cardConfiguration.mapToCardComponentConfiguration()
        let cardComponent = CardComponent(paymentMethod: paymentMethod, context: adyenContext, configuration: cardConfiguration)
        presentationDelegate = CardPresentationDelegate(topViewController: getViewController())
        actionComponent = buildActionComponent(adyenContext: adyenContext)
        return cardComponent
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
        componentPlatformApi.onFinishCallback = { paymentFlowOutcome in
            let resultCode = ResultCode(rawValue: paymentFlowOutcome.result ?? "")
            let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
            self.finalizeAndDismiss(success: success, completion: {
                let componentCommunicationModel = ComponentCommunicationModel(type: ComponentCommunicationType.result,
                                                                              paymentResult: PaymentResultModelDTO(resultCode: resultCode?.rawValue))
                self.componentFlutterApi.onComponentCommunication(componentCommunicationModel: componentCommunicationModel, completion: { _ in })
            })
        }
    }

}
