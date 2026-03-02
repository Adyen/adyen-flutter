@_spi(AdyenInternal) import Adyen
#if canImport(AdyenActions)
    import AdyenActions
#endif
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import Flutter

class BlikAdvancedComponent: BaseBlikComponent {
    private var actionComponentDelegate: ActionComponentDelegate?
    private var actionComponent: AdyenActionComponent?
    private var componentDelegate: PaymentComponentDelegate?

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
        setupFinalizeComponentCallback()
    }

    private func setupBlikComponentView() {
        do {
            let blikComponent = try setupBlikComponent()
            actionComponent = AdyenActionComponent(context: blikComponent.context)
            actionComponent?.delegate = actionComponentDelegate
            actionComponent?.presentationDelegate = getViewController()
            showBlikComponent(blikComponent: blikComponent)
            componentPlatformApi.onActionCallback = { [weak self] jsonActionResponse in
                self?.onAction(actionResponse: jsonActionResponse)
            }
            componentPlatformApi.onErrorCallback = { [weak self] error in
                self?.blikComponent?.stopLoadingIfNeeded()
                self?.sendErrorToFlutterLayer(errorMessage: error?.errorMessage ?? "")
            }
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }

    private func setupBlikComponent() throws -> BLIKComponent {
        componentDelegate = BlikAdvancedFlowDelegate(
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

    private func setupFinalizeComponentCallback() {
        componentPlatformApi.onFinishCallback = { [weak self] paymentEvent in
            let resultCode = ResultCode(rawValue: paymentEvent.result ?? "")
            let isAccepted = resultCode?.isAccepted ?? false
            self?.finalizeAndDismiss(success: isAccepted, completion: { [weak self] in
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
    }
}
