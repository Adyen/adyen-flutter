class ComponentPlatformApi: ComponentPlatformInterface {
    var onUpdateViewHeightCallback: () -> Void = {  }
    var onActionCallback: ([String?: Any?]) -> Void = { _ in }
    var onFinishCallback: (PaymentFlowOutcomeDTO) -> Void = { _ in  }
    var onErrorCallback: (ErrorDTO?) -> Void = { _ in }
    
    func updateViewHeight(viewId: Int64) {
        onUpdateViewHeightCallback()
    }
    
    func onPaymentsResult(paymentsResult: PaymentFlowOutcomeDTO) {
        handlePaymentFlowOutcome(paymentFlowOutcomeDTO: paymentsResult)
    }
    
    func onPaymentsDetailsResult(paymentsDetailsResult: PaymentFlowOutcomeDTO) {
        handlePaymentFlowOutcome(paymentFlowOutcomeDTO: paymentsDetailsResult)
    }
    
    private func handlePaymentFlowOutcome(paymentFlowOutcomeDTO: PaymentFlowOutcomeDTO) {
        switch paymentFlowOutcomeDTO.paymentFlowResultType {
        case .finished:
            onFinishCallback(paymentFlowOutcomeDTO)
        case .action:
            guard let jsonActionResponse = paymentFlowOutcomeDTO.actionResponse else { return }
            onActionCallback(jsonActionResponse)
        case .error:
            onErrorCallback(paymentFlowOutcomeDTO.error)
        }
    }
}
