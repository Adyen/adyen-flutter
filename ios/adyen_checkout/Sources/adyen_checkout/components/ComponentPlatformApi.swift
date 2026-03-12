class ComponentPlatformApi: ComponentPlatformInterface {
    private let cardComponentManager: CardComponentManager
    private let blikComponentManager: BlikComponentManager
    private let applePayComponentManager: ApplePayComponentManager
    private let instantComponentManager: InstantComponentManager
    private let actionComponentManager: ActionComponentManager

    init(
        componentFlutterApi: ComponentFlutterInterface,
        sessionHolder: SessionHolder
    ) {
        self.applePayComponentManager = ApplePayComponentManager(
            componentFlutterApi: componentFlutterApi,
            sessionHolder: sessionHolder
        )
        self.instantComponentManager = InstantComponentManager(
            componentFlutterApi: componentFlutterApi,
            sessionHolder: sessionHolder
        )
        self.actionComponentManager = ActionComponentManager(componentFlutterApi: componentFlutterApi)
        self.cardComponentManager = CardComponentManager()
        self.blikComponentManager = BlikComponentManager()
    }

    func updateViewHeight(viewId: Int64) {
        cardComponentManager.updateViewHeight(viewId: viewId)
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
            applePayComponentManager.isApplePayAvailable(
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
        case .applePay:
            applePayComponentManager.startApplePayComponent(
                instantPaymentComponentConfigurationDTO: instantPaymentConfigurationDTO,
                paymentMethodResponse: encodedPaymentMethod,
                componentId: componentId
            )
        case .instant:
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
        if isApplePayComponent(componentId: componentId) {
            applePayComponentManager.onDispose()
        } else if isInstantPaymentComponent(componentId: componentId) {
            instantComponentManager.onDispose()
        } else if isActionComponent(componentId: componentId) {
            actionComponentManager.onDispose()
        } else if isCardComponent(componentId: componentId) {
            cardComponentManager.onDispose()
        } else if isBlikComponent(componentId: componentId) {
            blikComponentManager.onDispose()
        }
    }

    private func handlePaymentEvent(componentId: String, paymentEventDTO: PaymentEventDTO) {
        if isApplePayComponent(componentId: componentId) {
            applePayComponentManager.handlePaymentEvent(paymentEventDTO: paymentEventDTO)
        } else if isInstantPaymentComponent(componentId: componentId) {
            instantComponentManager.handlePaymentEvent(paymentEventDTO: paymentEventDTO)
        } else if isCardComponent(componentId: componentId) {
            cardComponentManager.handlePaymentEvent(paymentEventDTO: paymentEventDTO)
        } else if isBlikComponent(componentId: componentId) {
            blikComponentManager.handlePaymentEvent(paymentEventDTO: paymentEventDTO)
        }
    }

    func register(cardBaseComponent: BaseCardComponent) {
        cardComponentManager.register(baseComponent: cardBaseComponent)
    }

    func register(blikBaseComponent: BaseBlikComponent) {
        blikComponentManager.register(baseComponent: blikBaseComponent)
    }

    private func isCardComponent(componentId: String) -> Bool {
        componentId == CardComponentManager.Constants.cardAdvancedComponentId ||
            componentId == CardComponentManager.Constants.cardSessionComponentId
    }

    private func isBlikComponent(componentId: String) -> Bool {
        componentId == BlikComponentManager.Constants.blikAdvancedComponentId ||
            componentId == BlikComponentManager.Constants.blikSessionComponentId
    }
    
    private func isApplePayComponent(componentId: String) -> Bool {
        componentId == ApplePayComponentManager.Constants.applePaySessionComponentId ||
            componentId == ApplePayComponentManager.Constants.applePayAdvancedComponentId
    }
    
    private func isInstantPaymentComponent(componentId: String) -> Bool {
        componentId == InstantComponentManager.Constants.instantSessionComponentId ||
            componentId == InstantComponentManager.Constants.instantAdvancedComponentId
    }

    private func isActionComponent(componentId: String) -> Bool {
        componentId == ActionComponentManager.Constants.actionComponentId
    }
}
