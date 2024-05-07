import Adyen

class InstantAdvancedComponent: BaseInstantComponent {
    private var actionComponent: AdyenActionComponent?
    private var componentPresentationDelegate: ComponentPresentationDelegate?
    
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
        actionComponent?.delegate = self
        componentPresentationDelegate = ComponentPresentationDelegate(topViewController: getViewController())
        actionComponent?.presentationDelegate = componentPresentationDelegate
        return component
    }
    
    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        switch paymentEventDTO.paymentEventType {
        case .finished:
            onFinish(paymentEventDTO: paymentEventDTO)
        case .error:
            onError(paymentEventDTO: paymentEventDTO)
        case .action:
            onAction(paymentEventDTO: paymentEventDTO)
        }
    }
    
    override func finalizeAndDismissComponent(success: Bool, completion: @escaping (() -> Void)) {
        instantPaymentComponent?.finalizeIfNeeded(with: success) { [weak self] in
            self?.getViewController()?.dismiss(animated: true) {
                completion()
            }
        }
    }
    
    override func onDispose() {
        actionComponent = nil
        componentPresentationDelegate = nil
        instantPaymentComponent = nil
    }
    
    private func onAction(paymentEventDTO: PaymentEventDTO) {
        do {
            guard let jsonActionResponse = paymentEventDTO.actionResponse else { return }
            let jsonData = try JSONSerialization.data(withJSONObject: jsonActionResponse, options: [])
            let action = try JSONDecoder().decode(Action.self, from: jsonData)
            actionComponent?.handle(action)
        } catch {
            sendErrorToFlutterLayer(error: error)
        }
    }
    
    private func onFinish(paymentEventDTO: PaymentEventDTO) {
        let resultCode = ResultCode(rawValue: paymentEventDTO.result ?? "")
        let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
        finalizeAndDismissComponent(success: success, completion: { [weak self] in
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
        finalizeAndDismissComponent(success: false, completion: { [weak self] in
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
            finalizeAndDismissComponent(success: false, completion: { [weak self] in
                self?.sendErrorToFlutterLayer(error: error)
            })
        }
    }

    internal func didFail(with error: Error, from component: PaymentComponent) {
        finalizeAndDismissComponent(success: false, completion: { [weak self] in
            self?.sendErrorToFlutterLayer(error: error)
        })
    }
}

extension InstantAdvancedComponent: ActionComponentDelegate {
    internal func didProvide(_ data: Adyen.ActionComponentData, from _: Adyen.ActionComponent) {
        do {
            let actionComponentData = ActionComponentDataModel(details: data.details.encodable, paymentData: data.paymentData)
            let actionComponentDataJson = try JSONEncoder().encode(actionComponentData)
            let actionComponentDataString = String(data: actionComponentDataJson, encoding: .utf8)
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.additionalDetails,
                componentId: componentId,
                data: actionComponentDataString
            )
            componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        } catch {
            sendErrorToFlutterLayer(error: error)
        }
    }

    internal func didComplete(from _: Adyen.ActionComponent) {
        // Only for voucher payment method - currently not supported.
    }

    internal func didFail(with error: Error, from _: Adyen.ActionComponent) {
        sendErrorToFlutterLayer(error: error)
    }
}
