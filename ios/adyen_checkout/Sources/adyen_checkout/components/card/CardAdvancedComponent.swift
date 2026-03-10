@_spi(AdyenInternal) import Adyen
#if canImport(AdyenActions)
    import AdyenActions
#endif
#if canImport(AdyenCard)
    import AdyenCard
#endif
import Flutter
import Foundation

class CardAdvancedComponent: BaseCardComponent {
    private var actionComponentDelegate: ActionComponentDelegate?
    private var presentationDelegate: PresentationDelegate?
    private var componentDelegate: PaymentComponentDelegate?
    private var actionComponent: AdyenActionComponent?

    override init(
        frame: CGRect,
        viewIdentifier: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi
    ) {
        super.init(
            frame: frame,
            viewIdentifier: viewIdentifier,
            arguments: arguments,
            binaryMessenger: binaryMessenger,
            componentFlutterApi: componentFlutterApi,
            componentPlatformApi: componentPlatformApi
        )

        actionComponentDelegate = ComponentActionHandler(
            componentFlutterApi: componentFlutterApi,
            componentId: componentId,
            finalizeCallback: finalizeAndDismiss(success:completion:)
        )
        setupCardComponentView()
    }

    private func setupCardComponentView() {
        do {
            let cardComponent = try setupCardComponent()
            actionComponent = buildActionComponent(adyenContext: cardComponent.context)
            showCardComponent(cardComponent: cardComponent)
            componentPlatformApi.register(cardBaseComponent: self)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func setupCardComponent() throws -> CardComponent {
        componentDelegate = AdvancedFlowDelegate(
            componentFlutterApi: componentFlutterApi,
            componentId: componentId
        )
        return try buildCardComponent(
            paymentMethodString: paymentMethod,
            isStoredPaymentMethod: isStoredPaymentMethod,
            cardComponentConfiguration: cardComponentConfiguration,
            componentDelegate: componentDelegate,
            cardDelegate: self
        )
    }

    private func buildActionComponent(adyenContext: AdyenContext) -> AdyenActionComponent {
        var configuration = AdyenActionComponent.Configuration()
        if let threeDS2Config = cardComponentConfiguration?.threeDS2ConfigurationDTO {
            configuration.threeDS = threeDS2Config.mapToThreeDS2Configuration()
        }
        let actionComponent = AdyenActionComponent(context: adyenContext, configuration: configuration)
        actionComponent.delegate = actionComponentDelegate
        actionComponent.presentationDelegate = getViewController()
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

    private func onFinish(paymentEventDTO: PaymentEventDTO) {
        let resultCode = ResultCode(rawValue: paymentEventDTO.result ?? "")
        let isAccepted = resultCode?.isAccepted ?? false
        finalizeAndDismiss(success: isAccepted, completion: { [weak self] in
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: self?.componentId ?? "",
                paymentResult: PaymentResultDTO(
                    type: PaymentResultEnum.finished,
                    result: PaymentResultModelDTO(resultCode: resultCode?.rawValue)
                )
            )
            self?.componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        })
    }

    private func onError(errorDTO: ErrorDTO?) {
        cardComponent?.stopLoadingIfNeeded()
        sendErrorToFlutterLayer(errorMessage: errorDTO?.errorMessage ?? "")
    }

    override func onDispose() {
        actionComponentDelegate = nil
        presentationDelegate = nil
        componentDelegate = nil
        actionComponent = nil
        super.onDispose()
    }

    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        switch paymentEventDTO.paymentEventType {
        case .finished:
            onFinish(paymentEventDTO: paymentEventDTO)
        case .action:
            guard let actionResponse = paymentEventDTO.data else { return }
            onAction(actionResponse: actionResponse)
        case .error:
            onError(errorDTO: paymentEventDTO.error)
        case .update:
            // Card does not support updates
            return
        }
    }

}
