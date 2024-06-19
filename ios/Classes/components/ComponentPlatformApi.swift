class ComponentPlatformApi: ComponentPlatformInterface {
    var onUpdateViewHeightCallback: () -> Void = {}
    var onActionCallback: ([String?: Any?]) -> Void = { _ in }
    var onFinishCallback: (PaymentEventDTO) -> Void = { _ in }
    var onErrorCallback: (ErrorDTO?) -> Void = { _ in }
    private let applePayComponentManager: ApplePayComponentManager
    private let instantComponentManager: InstantComponentManager
    private let actionComponentManager: ActionComponentManager

    init(componentFlutterApi: ComponentFlutterInterface, sessionHolder: SessionHolder) {
        self.applePayComponentManager = ApplePayComponentManager(componentFlutterApi: componentFlutterApi, sessionHolder: sessionHolder)
        self.instantComponentManager = InstantComponentManager(componentFlutterApi: componentFlutterApi, sessionHolder: sessionHolder)
        self.actionComponentManager = ActionComponentManager(componentFlutterApi: componentFlutterApi)
    }

    func updateViewHeight(viewId _: Int64) {
        onUpdateViewHeightCallback()
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
            applePayComponentManager.setUpApplePayIfAvailable(
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
            applePayComponentManager.onApplePayComponentPressed(componentId: componentId)
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
        }
    }

    private func handlePaymentEvent(componentId: String, paymentEventDTO: PaymentEventDTO) {
        if isApplePayComponent(componentId: componentId) {
            applePayComponentManager.handlePaymentEvent(paymentEventDTO: paymentEventDTO)
        } else if isInstantPaymentComponent(componentId: componentId) {
            instantComponentManager.handlePaymentEvent(paymentEventDTO: paymentEventDTO)
        } else {
            switch paymentEventDTO.paymentEventType {
            case .finished:
                onFinishCallback(paymentEventDTO)
            case .action:
                guard let jsonActionResponse = paymentEventDTO.actionResponse else { return }
                onActionCallback(jsonActionResponse)
            case .error:
                onErrorCallback(paymentEventDTO.error)
            }
        }
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
