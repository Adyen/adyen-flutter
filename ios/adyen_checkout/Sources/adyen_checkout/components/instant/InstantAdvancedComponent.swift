@_spi(AdyenInternal) import Adyen
@_spi(AdyenInternal) import AdyenCheckout
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import Foundation

@MainActor
class InstantAdvancedComponent: BaseInstantComponent, InstantComponentProtocol {
    private let instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO
    private let paymentMethodResponse: String
    private var submitContinuation: CheckedContinuation<PaymentEventDTO, Never>?
    private var presentationDelegate: ComponentPresentationDelegate?

    init(
        componentFlutterApi: ComponentFlutterInterface,
        instantPaymentConfigurationDTO: InstantPaymentConfigurationDTO,
        paymentMethodResponse: String,
        componentId: String
    ) {
        self.instantPaymentConfigurationDTO = instantPaymentConfigurationDTO
        self.paymentMethodResponse = paymentMethodResponse
        super.init(componentFlutterApi: componentFlutterApi, componentId: componentId)
    }

    func initiatePayment() {
        Task {
            do {
                let component = try await createPaymentComponent()
                present(component: component)
            } catch {
                sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
            }
        }
    }

    override func onDispose() {
        submitContinuation = nil
        presentationDelegate = nil
        super.onDispose()
    }

    func handlePaymentEvent(paymentEventDTO: PaymentEventDTO) {
        submitContinuation?.resume(returning: paymentEventDTO)
        submitContinuation = nil
    }

    private func createPaymentComponent() async throws -> CheckoutPaymentComponent {
        let checkoutConfiguration = try instantPaymentConfigurationDTO.createCheckoutConfiguration(
            componentFlutterApi: componentFlutterApi,
            componentId: { [componentId] in componentId }
        )
        let paymentMethods = try decodePaymentMethods()
        guard let paymentMethod = paymentMethods.regular.first else {
            throw PlatformError(errorDescription: "Payment method not found")
        }
        presentationDelegate = ComponentPresentationDelegate(presentingViewController: getViewController())
        let checkout = try await Checkout.setup(
            with: paymentMethods,
            configuration: checkoutConfiguration,
            presentationDelegate: presentationDelegate
        ).onSubmit { [weak self] data in
            guard let self else { return .completion(resultCode: "Error") }
            return await self.handleSubmit(paymentData: data)
        }.onComplete { [weak self] result in
            self?.sendFinishedResult(resultCode: result.resultCode.rawValue)
        }.onFailure { [weak self] error in
            self?.sendErrorToFlutterLayer(error: error)
        }

        return try checkout.createPaymentComponent(for: paymentMethod.type)
    }

    private func decodePaymentMethods() throws -> PaymentMethods {
        let wrappedJSON = "{\"paymentMethods\":[\(paymentMethodResponse)]}"
        guard let jsonData = wrappedJSON.data(using: .utf8) else {
            throw PlatformError(errorDescription: "Failed to encode payment methods")
        }
        return try JSONDecoder().decode(PaymentMethods.self, from: jsonData)
    }

    private func handleSubmit(paymentData: PaymentComponentData) async -> SubmitResult {
        do {
            let submitData = SubmitData(
                data: paymentData.jsonObject,
                extra: extraData(for: paymentData)
            )
            let submitDataJson = try submitData.toJsonString()
            let paymentEventDTO = await sendSubmitToFlutter(submitDataJson: submitDataJson)
            return mapToSubmitResult(paymentEventDTO)
        } catch {
            sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
            return .completion(resultCode: "Error")
        }
    }

    private func extraData(for paymentData: PaymentComponentData) -> [String: Any?]? {
        #if canImport(AdyenComponents)
            return (paymentData.paymentMethod as? ApplePayDetails)?.getExtraData()
        #else
            return nil
        #endif
    }

    private func sendSubmitToFlutter(submitDataJson: String) async -> PaymentEventDTO {
        await withCheckedContinuation { continuation in
            submitContinuation = continuation
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.onSubmit,
                componentId: componentId,
                data: submitDataJson
            )
            componentFlutterApi.onComponentCommunication(
                componentCommunicationModel: componentCommunicationModel,
                completion: { _ in }
            )
        }
    }

    private func mapToSubmitResult(_ paymentEventDTO: PaymentEventDTO) -> SubmitResult {
        switch paymentEventDTO.paymentEventType {
        case .finished:
            return .completion(resultCode: paymentEventDTO.result ?? "")
        case .action:
            guard let actionData = paymentEventDTO.data,
                  let action = try? decodeAction(from: actionData) else {
                sendErrorToFlutterLayer(errorMessage: "Failed to decode action.")
                return .completion(resultCode: "Error")
            }
            return .action(action)
        case .error:
            sendErrorToFlutterLayer(errorMessage: paymentEventDTO.error?.errorMessage ?? "Unknown error")
            return .completion(resultCode: "Error")
        case .update:
            sendErrorToFlutterLayer(errorMessage: "Update is not supported for the advanced flow.")
            return .completion(resultCode: "Error")
        }
    }

    private func decodeAction(from dictionary: [String?: Any?]) throws -> Action {
        let sanitizedDictionary = dictionary.reduce(into: [String: Any]()) { result, entry in
            if let key = entry.key, let value = entry.value {
                result[key] = value
            }
        }
        let jsonData = try JSONSerialization.data(withJSONObject: sanitizedDictionary)
        return try JSONDecoder().decode(Action.self, from: jsonData)
    }
}
