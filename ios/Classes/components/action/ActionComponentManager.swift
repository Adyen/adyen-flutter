@_spi(AdyenInternal) import Adyen

class ActionComponentManager {
    private let componentFlutterApi: ComponentFlutterInterface
    private var actionComponent: AdyenActionComponent?
    enum Constants {
        static let actionComponentId: String = "ACTION_COMPONENT"
    }
    
    init(componentFlutterApi: ComponentFlutterInterface) {
        self.componentFlutterApi = componentFlutterApi
    }
    
    func handleAction(adyenContext: AdyenContext, componentId: String, actionResponse: [String?: Any?]) throws {
        actionComponent = AdyenActionComponent(context: adyenContext)
        actionComponent?.delegate = self
        actionComponent?.presentationDelegate = getViewController()
        let jsonData = try JSONSerialization.data(withJSONObject: actionResponse, options: [])
        let action = try JSONDecoder().decode(Action.self, from: jsonData)
        actionComponent?.handle(action)
    }
    
    func getViewController() -> UIViewController? {
        let rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        return rootViewController?.adyen.topPresenter
    }
    
    func finalizeCallback(success: Bool, completion: @escaping (() -> Void)) {
        actionComponent?.finalizeIfNeeded(with: success) { [weak self] in
            self?.getViewController()?.dismiss(animated: true) {
                completion()
            }
        }
    }
    
    func onDispose() {
        actionComponent = nil
    }
}

extension ActionComponentManager: ActionComponentDelegate {
    func didProvide(_ data: Adyen.ActionComponentData, from component: any Adyen.ActionComponent) {
        do {
            let actionComponentData = ActionComponentDataModel(details: data.details.encodable, paymentData: data.paymentData)
            let actionComponentDataJson = try JSONEncoder().encode(actionComponentData)
            let actionComponentDataString = String(data: actionComponentDataJson, encoding: .utf8)
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.additionalDetails,
                componentId: Constants.actionComponentId,
                data: actionComponentDataString
            )
            componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
            finalizeCallback(success: true) {}
        } catch {
            finalizeCallback(success: false) { [weak self] in
                self?.sendErrorToFlutterLayer(error: error)
            }
        }
    }
    
    func didComplete(from component: any Adyen.ActionComponent) {
        // Only for voucher payment method - currently not supported.
    }
    
    func didFail(with error: any Error, from component: any Adyen.ActionComponent) {
        finalizeCallback(success: false) { [weak self] in
            self?.sendErrorToFlutterLayer(error: error)
        }
    }
    
    private func sendErrorToFlutterLayer(error: Error) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: Constants.actionComponentId,
            paymentResult: PaymentResultDTO(
                type: .from(error: error),
                reason: error.localizedDescription
            )
        )
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }
}
