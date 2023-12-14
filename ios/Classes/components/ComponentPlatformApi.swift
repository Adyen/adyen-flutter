class ComponentPlatformApi: ComponentPlatformInterface {
    var onUpdateViewHeightCallback: () -> Void = {}
    var onActionCallback: ([String?: Any?]) -> Void = { _ in }
    var onFinishCallback: (PaymentOutcomeDTO) -> Void = { _ in }
    var onErrorCallback: (ErrorDTO?) -> Void = { _ in }

    func updateViewHeight(viewId _: Int64) {
        onUpdateViewHeightCallback()
    }

    func onPaymentsResult(paymentsResult: PaymentOutcomeDTO) {
        handlePaymentOutcome(paymentOutcomeDTO: paymentsResult)
    }

    func onPaymentsDetailsResult(paymentsDetailsResult: PaymentOutcomeDTO) {
        handlePaymentOutcome(paymentOutcomeDTO: paymentsDetailsResult)
    }

    private func handlePaymentOutcome(paymentOutcomeDTO: PaymentOutcomeDTO) {
        switch paymentOutcomeDTO.paymentOutcomeType {
        case .finished:
            onFinishCallback(paymentOutcomeDTO)
        case .action:
            guard let jsonActionResponse = paymentOutcomeDTO.actionResponse else { return }
            onActionCallback(jsonActionResponse)
        case .error:
            onErrorCallback(paymentOutcomeDTO.error)
        }
    }
}
