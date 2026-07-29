@MainActor
class ComponentPlatformApi: ComponentPlatformInterface {
    private let blikComponentManager: BlikComponentManager
    private let instantComponentManager: InstantComponentManager
    private let actionComponentManager: ActionComponentManager

    init(componentFlutterApi: ComponentFlutterInterface, checkoutHolder: CheckoutHolder) {
        self.instantComponentManager = InstantComponentManager(componentFlutterApi: componentFlutterApi, checkoutHolder: checkoutHolder)
        self.actionComponentManager = ActionComponentManager(componentFlutterApi: componentFlutterApi)
        self.blikComponentManager = BlikComponentManager()
    }

    func updateViewHeight(viewId: Int64) {
        blikComponentManager.updateViewHeight(viewId: viewId)
    }

    func onPaymentsResult(componentId: String, paymentsResult: PaymentEventDTO) {
        handlePaymentEvent(componentId: componentId, paymentEventDTO: paymentsResult)
    }

    func onPaymentsDetailsResult(componentId: String, paymentsDetailsResult: PaymentEventDTO) {
        handlePaymentEvent(componentId: componentId, paymentEventDTO: paymentsDetailsResult)
    }

    func isInstantPaymentSupportedByPlatform(
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO,
        paymentMethodResponse: String,
        componentId: String,
        completion: @escaping (Result<InstantPaymentSetupResultDTO, Error>) -> Void
    ) {
        switch instantPaymentConfigurationDTO.instantPaymentType {
        case .googlePay,
             .instant:
            return
        case .applePay:
            instantComponentManager.isApplePayAvailable(
                instantPaymentComponentConfigurationDTO: instantPaymentConfigurationDTO,
                paymentMethodResponse: paymentMethodResponse,
                componentId: componentId,
                callback: completion
            )
        }
    }

    func onInstantPaymentPressed(
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO,
        encodedPaymentMethod: String,
        componentId: String
    ) {
        switch instantPaymentConfigurationDTO.instantPaymentType {
        case .googlePay:
            return
        case .applePay,
             .instant:
            instantComponentManager.startInstantComponent(
                instantPaymentConfigurationDTO: instantPaymentConfigurationDTO,
                encodedPaymentMethod: encodedPaymentMethod,
                componentId: componentId
            )
        }
    }

    func handleAction(actionComponentConfiguration: ActionComponentConfigurationDTO, componentId: String, actionResponse: [String?: Any?]?) throws {
        actionComponentManager.handleAction(
            actionComponentConfiguration: actionComponentConfiguration,
            componentId: componentId,
            actionResponse: actionResponse ?? [:]
        )
    }

    func onDispose(componentId: String) {
        if isInstantPaymentComponent(componentId: componentId) {
            instantComponentManager.onDispose()
        } else if isActionComponent(componentId: componentId) {
            actionComponentManager.onDispose()
        } else if isBlikComponent(componentId: componentId) {
            blikComponentManager.onDispose()
        }
    }

    private func handlePaymentEvent(componentId: String, paymentEventDTO: PaymentEventDTO) {
        if isInstantPaymentComponent(componentId: componentId) {
            instantComponentManager.handlePaymentEvent(paymentEventDTO: paymentEventDTO)
        } else if isBlikComponent(componentId: componentId) {
            blikComponentManager.handlePaymentEvent(paymentEventDTO: paymentEventDTO)
        }
    }

    func register(blikBaseComponent: BaseBlikComponent) {
        blikComponentManager.register(baseComponent: blikBaseComponent)
    }

    private func isBlikComponent(componentId: String) -> Bool {
        componentId == BlikComponentManager.Constants.blikAdvancedComponentId ||
            componentId == BlikComponentManager.Constants.blikSessionComponentId
    }

    private func isInstantPaymentComponent(componentId: String) -> Bool {
        componentId == InstantComponentManager.Constants.instantSessionComponentId ||
            componentId == InstantComponentManager.Constants.instantAdvancedComponentId ||
            componentId == InstantComponentManager.Constants.applePaySessionComponentId ||
            componentId == InstantComponentManager.Constants.applePayAdvancedComponentId
    }

    private func isActionComponent(componentId: String) -> Bool {
        componentId == ActionComponentManager.Constants.actionComponentId
    }
}
