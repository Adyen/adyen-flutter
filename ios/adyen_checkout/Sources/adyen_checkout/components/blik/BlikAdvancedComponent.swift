@_spi(AdyenInternal) import Adyen
#if canImport(AdyenActions)
    import AdyenActions
#endif
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import Flutter
import Foundation

class BlikAdvancedComponent: BaseBlikComponent {
    private var actionComponentDelegate: ActionComponentDelegate?
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
        setupBlikComponentView()
    }

    private func setupBlikComponentView() {
        do {
            let blikComponent = try setupBlikComponent()
            actionComponent = AdyenActionComponent(context: blikComponent.context)
            actionComponent?.delegate = actionComponentDelegate
            actionComponent?.presentationDelegate = getViewController()
            showBlikComponent(blikComponent: blikComponent)
            componentPlatformApi.register(blikBaseComponent: self)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func setupBlikComponent() throws -> BLIKComponent {
        componentDelegate = AdvancedFlowDelegate(
            componentFlutterApi: componentFlutterApi,
            componentId: componentId
        )
        return try buildBlikComponent(
            paymentMethodString: paymentMethod,
            blikComponentConfiguration: blikComponentConfiguration,
            componentDelegate: componentDelegate
        )
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
        blikComponent?.stopLoadingIfNeeded()
        sendErrorToFlutterLayer(errorMessage: errorDTO?.errorMessage ?? "")
    }

    override func onDispose() {
        actionComponentDelegate = nil
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
            // Blik does not support updates
            return
        }
    }

}
