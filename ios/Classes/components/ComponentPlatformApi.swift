class ComponentPlatformApi: ComponentPlatformInterface {
    var onUpdateViewHeightCallback: () -> Void = {}
    var onActionCallback: ([String?: Any?]) -> Void = { _ in }
    var onFinishCallback: (PaymentEventDTO) -> Void = { _ in }
    var onErrorCallback: (ErrorDTO?) -> Void = { _ in }
    private let applePayComponentManager: ApplePayComponentManager
    
    init(applePayComponentManager: ApplePayComponentManager) {
        self.applePayComponentManager = applePayComponentManager
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
        case .googlePay:
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

    func onInstantPaymentPressed(instantPaymentType: InstantPaymentType, componentId: String) {
        switch instantPaymentType {
        case .googlePay:
            return
        case .applePay:
            applePayComponentManager.onApplePayComponentPressed(componentId: componentId)
        }
    }

    func onDispose(componentId: String) {
        if isApplePayComponent(componentId: componentId) {
            applePayComponentManager.onDispose()
        }
    }

    private func handlePaymentEvent(componentId: String, paymentEventDTO: PaymentEventDTO) {
        if isApplePayComponent(componentId: componentId) {
            applePayComponentManager.handlePaymentEvent(paymentEventDTO: paymentEventDTO)
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
        componentId == ApplePayComponentManager.Constants.applePaySessionComponentId || componentId == ApplePayComponentManager.Constants.applePayAdvancedComponentId
    }
}
