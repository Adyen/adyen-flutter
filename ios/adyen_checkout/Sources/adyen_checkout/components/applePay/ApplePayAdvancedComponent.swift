@_spi(AdyenInternal) import Adyen
import AdyenComponents
import Foundation

class ApplePayAdvancedComponent: BaseApplePayComponent {
    private let componentFlutterApi: ComponentFlutterInterface
    private let configuration: InstantPaymentConfigurationDTO
    private let paymentMethodResponse: String
    private let componentId: String

    init(
        componentFlutterApi: ComponentFlutterInterface,
        configuration: InstantPaymentConfigurationDTO,
        paymentMethodResponse: String,
        componentId: String
    ) throws {
        self.componentFlutterApi = componentFlutterApi
        self.configuration = configuration
        self.paymentMethodResponse = paymentMethodResponse
        self.componentId = componentId
        super.init()
        applePayComponent = try buildApplePayAdvancedComponent()
    }
    
    override func present() {
        if let applePayComponent {
            let componentViewController = applePayComponent.viewController
            getViewController()?.presentViewController(componentViewController, animated: true)
        }
    }
    
    override func onDispose() {
        finalizeAndDismissComponent(success: false, completion: {
            self.applePayComponent = nil
        })
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
        case .update:
            // Apple pay does not support updating the payment flow
            return
        }
    }
    
    private func buildApplePayAdvancedComponent() throws -> ApplePayComponent? {
        let paymentMethod = try JSONDecoder().decode(ApplePayPaymentMethod.self, from: Data(paymentMethodResponse.utf8))
        let context = try configuration.createAdyenContext()
        let configuration = try configuration.mapToApplePayConfiguration(payment: context.payment)
        let applePayComponent = try ApplePayComponent(paymentMethod: paymentMethod, context: context, configuration: configuration)
        applePayComponent.delegate = self
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

extension ApplePayAdvancedComponent: PaymentComponentDelegate {

    internal func didSubmit(_ data: PaymentComponentData, from component: PaymentComponent) {
        do {
            let applePayDetails = data.paymentMethod as? ApplePayDetails
            let submitData = SubmitData(
                data: data.jsonObject,
                extra: applePayDetails?.getExtraData()
            )
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
    
    private func sendErrorToFlutterLayer(error: Error) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: componentId,
            paymentResult: PaymentResultDTO(
                type: .from(error: error),
                reason: error.localizedDescription
            )
        )
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }
}
