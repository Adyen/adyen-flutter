@_spi(AdyenInternal) import Adyen
#if canImport(AdyenActions)
    import AdyenActions
#endif
import Foundation
import UIKit

class ActionComponentManager {
    private let componentFlutterApi: ComponentFlutterInterface
    private var actionComponent: CheckoutActionComponent?
    enum Constants {
        static let actionComponentId: String = "ACTION_COMPONENT"
    }
    
    init(componentFlutterApi: ComponentFlutterInterface) {
        self.componentFlutterApi = componentFlutterApi
    }
    
    func handleAction(actionComponentConfiguration: ActionComponentConfigurationDTO, componentId: String, actionResponse: [String?: Any?]) {
        do {
            let adyenContext = try actionComponentConfiguration.createAdyenContext()
            actionComponent = CheckoutActionComponent(context: adyenContext)
            actionComponent?.delegate = self
            actionComponent?.presentationDelegate = getViewController()
            let jsonData = try JSONSerialization.data(withJSONObject: actionResponse, options: [])
            let action = try JSONDecoder().decode(Action.self, from: jsonData)
            actionComponent?.handle(action)
        } catch {
            sendErrorToFlutterLayer(error: error)
        }
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
    
}
