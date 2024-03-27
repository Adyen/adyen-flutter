@_spi(AdyenInternal) import Adyen

class ApplePayAdvancedComponentWrapper: BaseApplePayComponentWrapper {
    private let componentFlutterApi: ComponentFlutterInterface
    private let configuration: ApplePayComponent.Configuration
    private let adyenContext: AdyenContext
    private let paymentMethodResponse: String
    private let componentId: String
    
    init(
        componentFlutterApi: ComponentFlutterInterface,
        configuration: ApplePayComponent.Configuration,
        adyenContext: AdyenContext,
        paymentMethodResponse: String,
        componentId: String
    ) {
        self.componentFlutterApi = componentFlutterApi
        self.configuration = configuration
        self.adyenContext = adyenContext
        self.paymentMethodResponse = paymentMethodResponse
        self.componentId = componentId
        super.init()
        applePayComponent = try? buildApplePayAdvancedComponent()
    }
    
    override func present() {
        if let applePayComponent {
            let componentViewController = applePayComponent.viewController
            getViewController()?.presentViewController(componentViewController, animated: true)
        }
    }
    
    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        switch paymentEventDTO.paymentEventType {
        case .finished:
            onFinished(paymentEventDTO: paymentEventDTO)
        case .error:
            onError(paymentEventDTO: paymentEventDTO)
        case .action:
            // Apple pay does not require action handling
            return
        }
    }
    
    private func buildApplePayAdvancedComponent() throws -> ApplePayComponent? {
        let paymentMethod = try JSONDecoder().decode(ApplePayPaymentMethod.self, from: Data(paymentMethodResponse.utf8))
        let applePayComponent = try? ApplePayComponent(paymentMethod: paymentMethod, context: adyenContext, configuration: configuration)
        applePayComponent?.delegate = self
        // applePayComponent?.applePayDelegate - Dynamic pricing will be added in the next version.
        return applePayComponent
    }
    
    private func onFinished(paymentEventDTO: PaymentEventDTO) {
        finalizeAndDismissComponent(success: true, completion: { [weak self] in
            guard let self else { return }
            let resultCode = paymentEventDTO.result ?? ""
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: self.componentId,
                paymentResult: PaymentResultDTO(
                    type: PaymentResultEnum.finished,
                    result: PaymentResultModelDTO(resultCode: resultCode)
                )
            )
            self.componentFlutterApi.onComponentCommunication(
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

extension ApplePayAdvancedComponentWrapper: PaymentComponentDelegate {

    internal func didSubmit(_ data: PaymentComponentData, from component: PaymentComponent) {
        do {
            let paymentComponentData = PaymentComponentDataResponse(
                amount: data.amount,
                paymentMethod: data.paymentMethod.encodable,
                storePaymentMethod: data.storePaymentMethod,
                order: data.order,
                amountToPay: data.order?.remainingAmount,
                installments: data.installments,
                shopperName: data.shopperName,
                emailAddress: data.emailAddress,
                telephoneNumber: data.telephoneNumber,
                browserInfo: data.browserInfo,
                checkoutAttemptId: data.checkoutAttemptId,
                billingAddress: data.billingAddress,
                deliveryAddress: data.deliveryAddress,
                socialSecurityNumber: data.socialSecurityNumber,
                delegatedAuthenticationData: data.delegatedAuthenticationData
            )
            let paymentComponentJson = try JSONEncoder().encode(paymentComponentData)
            let paymentComponentString = String(data: paymentComponentJson, encoding: .utf8)
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.onSubmit,
                componentId: componentId,
                data: paymentComponentString
            )
            componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        } catch {
            sendErrorToFlutterLayer(error: error)
        }
    }

    internal func didFail(with error: Error, from component: PaymentComponent) {
        finalizeAndDismissComponent(success: false, completion: { [weak self] in
            self?.sendErrorToFlutterLayer(error: error)
        })
    }
    
    private func sendErrorToFlutterLayer(error: Error) {
        let type: PaymentResultEnum
        if let componentError = (error as? ComponentError), componentError == ComponentError.cancelled {
            type = PaymentResultEnum.cancelledByUser
        } else {
            type = PaymentResultEnum.error
        }
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: componentId,
            paymentResult: PaymentResultDTO(
                type: type,
                reason: error.localizedDescription
            )
        )
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }
}
