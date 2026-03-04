@_spi(AdyenInternal) import Adyen
#if canImport(AdyenActions)
    import AdyenActions
#endif
import Flutter

protocol AdvancedComponentProtocol: AnyObject {
    var componentId: String { get }
    var componentFlutterApi: ComponentFlutterInterface { get }
    var componentPlatformApi: ComponentPlatformApi { get }
    var actionComponent: AdyenActionComponent? { get }

    func finalizeAndDismiss(success: Bool, completion: @escaping (() -> Void))
    func sendErrorToFlutterLayer(errorMessage: String)
}

extension AdvancedComponentProtocol {
    func setupFinalizeComponentCallback() {
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

    func onAction(actionResponse: [String?: Any?]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: actionResponse, options: [])
            let action = try JSONDecoder().decode(Action.self, from: jsonData)
            actionComponent?.handle(action)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
        }
    }
}
