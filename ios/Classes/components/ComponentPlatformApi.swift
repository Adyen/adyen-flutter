class ComponentPlatformApi: ComponentPlatformInterface {
    var onUpdateViewHeightCallback: () -> Void = {}
    var onActionCallback: ([String?: Any?]) -> Void = { _ in }
    var onFinishCallback: (PaymentEventDTO) -> Void = { _ in }
    var onErrorCallback: (ErrorDTO?) -> Void = { _ in }

    func updateViewHeight(viewId _: Int64) {
        onUpdateViewHeightCallback()
    }

    func onPaymentsResult(paymentsResult: PaymentEventDTO) {
        handlePaymentEvent(paymentEventDTO: paymentsResult)
    }

    func onPaymentsDetailsResult(paymentsDetailsResult: PaymentEventDTO) {
        handlePaymentEvent(paymentEventDTO: paymentsDetailsResult)
    }

    func isInstantPaymentSupportedByPlatform(
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO,
        paymentMethodResponse: String,
        componentId: String,
        completion: @escaping (Result<InstantPaymentSetupResultDTO, Error>) -> Void) {

    }

    func onInstantPaymentPressed(instantPaymentType: InstantPaymentType, componentId: String) throws {

    }

    func onDispose(componentId : String) throws {

    }

    private func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
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
