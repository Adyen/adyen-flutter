@_spi(AdyenInternal) import Adyen

class InstantComponentManager {
    private let componentFlutterApi: ComponentFlutterInterface
    private let sessionHolder: SessionHolder
    
    enum Constants {
        static let instantSessionComponentId = "SESSION_COMPONENT"
        static let instantAdvancedComponentId = "ADVANCED_COMPONENT"
    }
    
    init(componentFlutterApi: ComponentFlutterInterface, sessionHolder: SessionHolder) {
        self.componentFlutterApi = componentFlutterApi
        self.sessionHolder = sessionHolder
    }
    
    internal var instantPaymentComponent: InstantPaymentComponent?

    func startInstantComponent(instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO, encodedPaymentMethod: String, componentId: String) {
        do {
            let paymentMethod = try JSONDecoder().decode(InstantPaymentMethod.self, from: Data(encodedPaymentMethod.utf8))
            let adyenContext = try instantPaymentConfigurationDTO.createAdyenContext()
            let instantPaymentComponent: InstantPaymentComponent
            switch componentId {
            case let id where id.contains(Constants.instantAdvancedComponentId):
                instantPaymentComponent = try createInstantAdvancedComponent(paymentMethod: paymentMethod, adyenContext: adyenContext)

            case let id where id.contains(Constants.instantSessionComponentId):
                instantPaymentComponent = try createInstantSessionComponent(paymentMethod: paymentMethod, adyenContext: adyenContext, componentId: componentId)

            default:
                throw PlatformError(errorDescription: "Instant component not available for payment flow.")
            }
            
            self.instantPaymentComponent = instantPaymentComponent
            instantPaymentComponent.initiatePayment()
        } catch {
            sendErrorToFlutterLayer(componentId: componentId, errorMessage: error.localizedDescription)
        }
    }
    
    func createInstantAdvancedComponent(paymentMethod: PaymentMethod, adyenContext: AdyenContext) throws -> InstantPaymentComponent {
        let component = InstantPaymentComponent(paymentMethod: paymentMethod, context: adyenContext, order: nil)
        return component
    }
    
    func createInstantSessionComponent(paymentMethod: PaymentMethod, adyenContext: AdyenContext, componentId: String) throws -> InstantPaymentComponent {
        guard let session = sessionHolder.session else {
            throw PlatformError(errorDescription: "The provided session identifier or data is invalid.")
        }
        
        let componentSessionFlowDelegate = sessionHolder.sessionDelegate as? ComponentSessionFlowDelegate
        componentSessionFlowDelegate?.componentId = componentId
        componentSessionFlowDelegate?.finalizeAndDismissHandler = finalizeAndDismissComponent
        let component = InstantPaymentComponent(paymentMethod: paymentMethod, context: adyenContext, order: nil)
        component.delegate = session
        return component
    }
    
    func finalizeAndDismissComponent(success: Bool, completion: @escaping (() -> Void)) {
        instantPaymentComponent?.finalizeIfNeeded(with: success) { [weak self] in
            guard let self else { return }
            getViewController()?.dismiss(animated: true) {
                completion()
                if success {
                    self.sessionHolder.reset()
                }
            }
        }
    }
    
    func getViewController() -> UIViewController? {
        let rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        return rootViewController?.adyen.topPresenter
    }
    
    func onDispose() {
        instantPaymentComponent = nil
    }
    
    func sendErrorToFlutterLayer(componentId: String, errorMessage: String) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: componentId,
            paymentResult: PaymentResultDTO(
                type: PaymentResultEnum.error,
                reason: errorMessage
            )
        )
        self.componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }
}
