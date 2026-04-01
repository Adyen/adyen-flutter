import Adyen
#if canImport(AdyenCard)
    import AdyenCard
#endif
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
#if canImport(AdyenSession)
    import AdyenSession
#endif

class ComponentSessionFlowHandler: AdyenSessionDelegate {
    private let componentFlutterApi: ComponentFlutterInterface
    private var componentRegistrations: [String: ComponentRegistration] = [:]
    private var currentFlowRegistration: ComponentRegistration?

    init(
        componentFlutterApi: ComponentFlutterInterface
    ) {
        self.componentFlutterApi = componentFlutterApi
    }

    func register(
        componentId: String,
        finalizeCallback: @escaping (Bool, @escaping (() -> Void)) -> Void
    ) {
        componentRegistrations[componentId] = ComponentRegistration(
            componentId: componentId,
            finalizeCallback: finalizeCallback
        )
    }
    
    func setCurrentFlow(componentId: String) {
        currentFlowRegistration = componentRegistrations[componentId]
    }

    func reset() {
        componentRegistrations.removeAll()
        currentFlowRegistration = nil
    }

    func handlerForPayments(in component: PaymentComponent, session: AdyenSession) -> AdyenSessionPaymentsHandler? {
        guard let componentId = sessionComponentId(for: component) else {
            currentFlowRegistration = nil
            return nil
        }
        setCurrentFlow(componentId: componentId)
        return nil
    }
    
    func didComplete(with result: AdyenSessionResult, component: Component, session: AdyenSession) {
        guard let registration = currentFlowRegistration else {
            return
        }
        let resultCode = result.resultCode
        let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
        registration.finalizeCallback(success) { [weak self] in
            let paymentResult = PaymentResultModelDTO(
                sessionId: session.sessionContext.identifier,
                sessionData: session.sessionContext.data,
                sessionResult: result.encodedResult,
                resultCode: result.resultCode.rawValue
            )
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: registration.componentId,
                paymentResult: PaymentResultDTO(
                    type: PaymentResultEnum.finished,
                    result: paymentResult
                )
            )
            self?.componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        }
    }
    
    func didFail(with error: Error, from component: Component, session: AdyenSession) {
        guard let registration = currentFlowRegistration else { return }
        registration.finalizeCallback(false) { [weak self] in
            guard let self else { return }
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: registration.componentId,
                paymentResult: PaymentResultDTO(
                    type: .from(error: error),
                    reason: error.localizedDescription
                )
            )
            self.componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        }
    }

    private func sessionComponentId(for component: PaymentComponent) -> String? {
        let paymentMethod = component.paymentMethod
        switch paymentMethod {
        case is AnyCardPaymentMethod:
            return CardComponentManager.Constants.cardSessionComponentId
        case is BLIKPaymentMethod, is StoredBLIKPaymentMethod:
            return BlikComponentManager.Constants.blikSessionComponentId
        case is ApplePayPaymentMethod:
            return ApplePayComponentManager.Constants.applePaySessionComponentId
        case is InstantPaymentMethod, is StoredInstantPaymentMethod:
            return InstantComponentManager.Constants.instantSessionComponentId
        default:
            return nil
        }
    }
}

struct ComponentRegistration {
    let componentId: String
    let finalizeCallback: (Bool, @escaping (() -> Void)) -> Void
}
