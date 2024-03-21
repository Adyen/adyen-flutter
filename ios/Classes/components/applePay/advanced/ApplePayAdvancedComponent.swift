@_spi(AdyenInternal) import Adyen

class ApplePayAdvancedComponent: BaseApplePayComponent {
    static let applePaySessionComponentId = "APPLE_PAY_ADVANCED_COMPONENT"
    private let componentFlutterApi: ComponentFlutterInterface
    private let configuration: ApplePayComponent.Configuration
    private let adyenContext: AdyenContext
    private let paymentMethodResponse: String
    
    init(
        componentFlutterApi: ComponentFlutterInterface,
        configuration: ApplePayComponent.Configuration,
        adyenContext: AdyenContext,
        paymentMethodResponse: String
    ) {
        self.componentFlutterApi = componentFlutterApi
        self.configuration = configuration
        self.adyenContext = adyenContext
        self.paymentMethodResponse = paymentMethodResponse
        super.init()
        applePayComponent = try? buildApplePayAdvancedComponent()
    }
    
    override func present() {
        if let applePayComponent {
            let componentViewController = applePayComponent.viewController
            getViewController()?.presentViewController(componentViewController, animated: true)
        }
    }
    
    override func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
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
            let resultCode = paymentEventDTO.result ?? ""
            self?.componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: ComponentCommunicationModel(
                    type: ComponentCommunicationType.result,
                    componentId: Self.applePaySessionComponentId,
                    paymentResult: PaymentResultDTO(
                        type: PaymentResultEnum.finished,
                        result: PaymentResultModelDTO(resultCode: resultCode)
                    )
                ),
                completion: { _ in }
            )
        })
    }
    
    private func onError(paymentEventDTO: PaymentEventDTO) {
        finalizeAndDismissComponent(success: false, completion: { [weak self] in
            let errorMessage = paymentEventDTO.error?.errorMessage
            self?.componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: ComponentCommunicationModel(
                    type: ComponentCommunicationType.result,
                    componentId: Self.applePaySessionComponentId,
                    paymentResult: PaymentResultDTO(
                        type: PaymentResultEnum.error,
                        reason: errorMessage
                    )
                ),
                completion: { _ in }
            )
        })
    }
}

extension ApplePayAdvancedComponent: PaymentComponentDelegate {

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
            componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: ComponentCommunicationModel(
                    type: ComponentCommunicationType.onSubmit,
                    componentId: Self.applePaySessionComponentId,
                    data: paymentComponentString
                ), completion: { _ in }
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
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: Self.applePaySessionComponentId,
                paymentResult: PaymentResultDTO(
                    type: type,
                    reason: error.localizedDescription
                )
            ),
            completion: { _ in }
        )
    }
}
