import Adyen

class InstantAdvancedComponent: BaseInstantComponent, InstantComponentProtocol {
    private var actionComponent: AdyenActionComponent?
    private var actionComponentHandler: ComponentActionHandler?
    
    init(
        componentFlutterApi: ComponentFlutterInterface,
        paymentMethod: PaymentMethod,
        adyenContext: AdyenContext,
        componentId: String
    ) {
        super.init(componentFlutterApi: componentFlutterApi, componentId: componentId)
        instantPaymentComponent = buildInstantComponent(paymentMethod: paymentMethod, adyenContext: adyenContext)
    }
    
    func buildInstantComponent(paymentMethod: PaymentMethod, adyenContext: AdyenContext) -> InstantPaymentComponent {
        let component = InstantPaymentComponent(paymentMethod: paymentMethod, context: adyenContext, order: nil)
        component.delegate = self
        actionComponent = AdyenActionComponent(context: adyenContext)
        actionComponentHandler = ComponentActionHandler(
            componentFlutterApi: componentFlutterApi,
            componentId: componentId,
            finalizeCallback: finalizeCallback(success:completion:)
        )
        actionComponent?.delegate = actionComponentHandler
        actionComponent?.presentationDelegate = getViewController()
        return component
    }
    
    func finalizeCallback(success: Bool, completion: @escaping (() -> Void)) {
        instantPaymentComponent?.finalizeIfNeeded(with: success) { [weak self] in
            self?.getViewController()?.dismiss(animated: true) {
                self?.hideActivityIndicator()
                completion()
            }
        }
    }
    
    func onDispose() {
        actionComponentHandler = nil
        actionComponent = nil
        instantPaymentComponent = nil
    }
    
    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        switch paymentEventDTO.paymentEventType {
        case .finished:
            onFinish(paymentEventDTO: paymentEventDTO)
        case .error:
            onError(paymentEventDTO: paymentEventDTO)
        case .action:
            onAction(paymentEventDTO: paymentEventDTO)
        case .update:
            return
        }
    }
    
    private func onAction(paymentEventDTO: PaymentEventDTO) {
        do {
            guard let jsonActionResponse = paymentEventDTO.data else { return }
            let jsonData = try JSONSerialization.data(withJSONObject: jsonActionResponse, options: [])
            let action = try JSONDecoder().decode(Action.self, from: jsonData)
            actionComponent?.handle(action)
        } catch {
            hideActivityIndicator()
            sendErrorToFlutterLayer(error: error)
        }
    }
    
    private func onFinish(paymentEventDTO: PaymentEventDTO) {
        let resultCode = ResultCode(rawValue: paymentEventDTO.result ?? "")
        let isAccepted = resultCode?.isAccepted ?? false
        finalizeCallback(success: isAccepted, completion: { [weak self] in
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: self?.componentId ?? "",
                paymentResult: PaymentResultDTO(
                    type: PaymentResultEnum.finished,
                    result: PaymentResultModelDTO(resultCode: resultCode?.rawValue)
                )
            )
            self?.componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        })
    }
    
    private func onError(paymentEventDTO: PaymentEventDTO) {
        finalizeCallback(success: false, completion: { [weak self] in
            guard let self else { return }
            let errorMessage = paymentEventDTO.error?.errorMessage
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: self.componentId,
                paymentResult: PaymentResultDTO(
                    type: PaymentResultEnum.error,
                    reason: errorMessage
                )
            )
            self.componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        })
    }
}

extension InstantAdvancedComponent: PaymentComponentDelegate {
    internal func didSubmit(_ data: PaymentComponentData, from component: PaymentComponent) {
        do {
            let submitData = SubmitData(data: data.jsonObject, extra: nil)
            let submitDataEncoded = try submitData.toJsonString()
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.onSubmit,
                componentId: componentId,
                data: submitDataEncoded
            )
            componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        } catch {
            finalizeCallback(success: false, completion: { [weak self] in
                self?.sendErrorToFlutterLayer(error: error)
            })
        }
    }

    internal func didFail(with error: Error, from component: PaymentComponent) {
        finalizeCallback(success: false, completion: { [weak self] in
            self?.sendErrorToFlutterLayer(error: error)
        })
    }
}
