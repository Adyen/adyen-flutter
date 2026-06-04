import Foundation
import UIKit

#if canImport(AdyenSession)
    import AdyenSession
#endif
#if canImport(AdyenCard)
    import AdyenCard
#endif
#if canImport(AdyenActions)
    import AdyenActions
#endif
@_spi(AdyenInternal) import Adyen
@_spi(AdyenInternal) import AdyenCheckout

// TODO: Add config:
// 1) Add Info.plist for adding photo library usage description
// 2) Add url scheme
// 3) Add AppDelegate redirect

@MainActor
class CheckoutPlatformApi: CheckoutPlatformInterface {
    private let checkoutFlutter: CheckoutFlutterInterface
    private let componentFlutterApi: ComponentFlutterInterface
    private let adyenFlutterInterface: AdyenFlutterInterface
    private let componentPlatformEventHandler: ComponentPlatformEventHandler
    private let checkoutHolder: CheckoutHolder
    private let adyenCse: AdyenCSE = .init()

    init(
        checkoutFlutter: CheckoutFlutterInterface,
        componentFlutterApi: ComponentFlutterInterface,
        adyenFlutterInterface: AdyenFlutterInterface,
        componentPlatformEventHandler: ComponentPlatformEventHandler,
        checkoutHolder: CheckoutHolder
    ) {
        self.checkoutFlutter = checkoutFlutter
        self.componentFlutterApi = componentFlutterApi
        self.adyenFlutterInterface = adyenFlutterInterface
        self.componentPlatformEventHandler = componentPlatformEventHandler
        self.checkoutHolder = checkoutHolder
    }

    func setupSession(sessionResponseDTO: SessionResponseDTO, checkoutConfigurationDTO: CheckoutConfigurationDTO, completion: @escaping (Result<SessionDTO, any Error>) -> Void) {
        Task {
            do {
                let sessionResponse = sessionResponseDTO.mapToSessionResponse()
                let checkoutConfiguration = try createSessionCheckoutConfiguration(
                    configurationDTO: checkoutConfigurationDTO
                )
                let checkoutSession = try await Checkout.setup(
                    with: sessionResponse,
                    configuration: checkoutConfiguration
                )

                setupSessionCallbacks(checkoutSession, sessionId: sessionResponseDTO.id)
                checkoutHolder.adyenCheckout = checkoutSession
                let encodedPaymentMethods = try JSONEncoder().encode(checkoutSession.paymentMethods)
                guard let encodedPaymentMethodsString = String(data: encodedPaymentMethods, encoding: .utf8) else {
                    completion(Result.failure(PlatformError(errorDescription: "Encoding payment methods failed")))
                    return
                }

                completion(Result.success(SessionDTO(
                    id: sessionResponseDTO.id,
                    paymentMethodsJson: encodedPaymentMethodsString
                )))
            } catch {
                completion(Result.failure(error))
            }
        }
    }

    func setupAdvanced(paymentMethodsResponse: String, checkoutConfigurationDTO: CheckoutConfigurationDTO, completion: @escaping (Result<Void, any Error>) -> Void) {
        Task {
            do {
                let paymentMethodsData = Data(paymentMethodsResponse.utf8)
                let paymentMethods = try JSONDecoder().decode(PaymentMethods.self, from: paymentMethodsData)
                let checkoutConfiguration = try createAdvancedCheckoutConfiguration(configurationDTO: checkoutConfigurationDTO)
                let adyenCheckout = try await Checkout.setup(
                    with: paymentMethods,
                    configuration: checkoutConfiguration
                )

                setupAdvancedCallbacks(adyenCheckout)
                checkoutHolder.adyenCheckout = adyenCheckout
                completion(Result.success(()))
            } catch {
                completion(Result.failure(error))
            }
        }
    }

    func clearSession() {
        checkoutHolder.reset()
    }

    func getReturnUrl(completion: @escaping (Result<String, Error>) -> Void) {
        completion(Result.failure(PlatformError(errorDescription: "Please use your app url type instead of this method.")))
    }

    func enableConsoleLogging(loggingEnabled: Bool) {
        AdyenLogging.isEnabled = loggingEnabled
    }
    
    func encryptCard(unencryptedCardDTO: UnencryptedCardDTO, publicKey: String, completion: @escaping (Result<EncryptedCardDTO, any Error>) -> Void) {
        let encryptedCardResult = adyenCse.encryptCard(unencryptedCardDTO: unencryptedCardDTO, publicKey: publicKey)
        completion(encryptedCardResult)
    }
    
    func encryptBin(bin: String, publicKey: String, completion: @escaping (Result<String, any Error>) -> Void) {
        let encryptedBinResult = adyenCse.encryptBin(bin: bin, publicKey: publicKey)
        completion(encryptedBinResult)
    }
    
    func validateCardNumber(cardNumber: String, enableLuhnCheck: Bool) throws -> CardNumberValidationResultDTO {
        let validationResult = CardValidation().validateCardNumber(cardNumber: cardNumber, enableLuhnCheck: enableLuhnCheck)
        return validationResult ? .valid : .invalidOtherReason
    }
    
    func validateCardExpiryDate(expiryMonth: String, expiryYear: String) throws -> CardExpiryDateValidationResultDTO {
        let validationResult = CardValidation().validateCardExpiryDate(expiryMonth: expiryMonth, expiryYear: expiryYear)
        return validationResult ? .valid : .invalidOtherReason
    }
    
    func validateCardSecurityCode(securityCode: String, cardBrand: String?) throws -> CardSecurityCodeValidationResultDTO {
        let validationResult = CardValidation().validateCardSecurityCode(securityCode: securityCode, cardBrand: cardBrand)
        return validationResult ? .valid : .invalid
    }
    
    func getThreeDS2SdkVersion() throws -> String {
        return threeDS2SdkVersion
    }

    // MARK: - Session checkout configuration

    private func createSessionCheckoutConfiguration(
        configurationDTO: CheckoutConfigurationDTO
    ) throws -> CheckoutConfiguration {
        try createCheckoutConfiguration(configurationDTO: configurationDTO)
    }

    private func setupSessionCallbacks(
        _ checkout: SessionCheckout,
        sessionId: String
    ) {
        checkout.onComplete { [weak self] result in
            self?.sendCompleteResult(componentId: "SESSION_ADYEN_COMPONENT", sessionId: sessionId, result: result)
        }.onError { [weak self] error in
            self?.sendErrorResult(componentId: "SESSION_ADYEN_COMPONENT", error: error)
        }
    }

    // MARK: - Advanced checkout configuration

    private func createAdvancedCheckoutConfiguration(
        configurationDTO: CheckoutConfigurationDTO
    ) throws -> CheckoutConfiguration {
        try createCheckoutConfiguration(configurationDTO: configurationDTO)
    }

    private func setupAdvancedCallbacks(_ checkout: AdvancedCheckout) {
        checkout.onSubmit { [weak self] paymentData -> SubmitResult in
            guard let self else { return .completion(resultCode: "Error") }
            return await self.handleSubmit(paymentData: paymentData)
        }.onAdditionalDetails { [weak self] additionalDetailsData -> AdditionalDetailsResult in
            guard let self else { return .completion(resultCode: "Error") }
            return await self.handleAdditionalDetails(additionalDetailsData: additionalDetailsData)
        }.onComplete { [weak self] result in
            self?.sendCompleteResult(componentId: "ADVANCED_ADYEN_COMPONENT", sessionId: "", result: result)
        }.onError { [weak self] error in
            self?.sendErrorResult(componentId: "ADVANCED_ADYEN_COMPONENT", error: error)
        }
    }

    // MARK: - Shared configuration builder

    private func createCheckoutConfiguration(
        configurationDTO: CheckoutConfigurationDTO
    ) throws -> CheckoutConfiguration {
        let cardConfig = configurationDTO.cardConfigurationDTO?.mapToCardConfiguration(shopperLocale: configurationDTO.shopperLocale) ?? CardConfiguration()
        return try CheckoutConfiguration(
            environment: configurationDTO.environment.mapToEnvironment(),
            amount: configurationDTO.amount!.mapToAmount(),
            clientKey: configurationDTO.clientKey,
            analyticsConfiguration: .init()
        ) {
            cardConfig
        }
    }

    // MARK: - Advanced flow handlers

    private func handleSubmit(paymentData: PaymentComponentData) async -> SubmitResult {
        do {
            let dataJson = try paymentData.toPlatformSubmitDataJson()
            let checkoutResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CheckoutResultDTO, Error>) in
                sendSubmitToFlutter(dataJson: dataJson) { result in
                    switch result {
                    case let .success(dto):
                        continuation.resume(returning: dto)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
            }
            return mapCheckoutResultToSubmitResult(checkoutResult)
        } catch {
            sendErrorResultToFlutter(componentId: "ADVANCED_ADYEN_COMPONENT", reason: error.localizedDescription)
            return .completion(resultCode: "Error")
        }
    }

    private func handleAdditionalDetails(additionalDetailsData: ActionComponentData) async -> AdditionalDetailsResult {
        do {
            let dataJson = try additionalDetailsData.toPlatformAdditionalDetailsJson()
            let checkoutResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CheckoutResultDTO, Error>) in
                sendAdditionalDetailsToFlutter(dataJson: dataJson) { result in
                    switch result {
                    case let .success(dto):
                        continuation.resume(returning: dto)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
            }
            return mapCheckoutResultToAdditionalDetailsResult(checkoutResult)
        } catch {
            sendErrorResultToFlutter(componentId: "ADVANCED_ADYEN_COMPONENT", reason: error.localizedDescription)
            return .completion(resultCode: "Error")
        }
    }

    private func mapCheckoutResultToSubmitResult(_ checkoutResult: CheckoutResultDTO) -> SubmitResult {
        switch checkoutResult {
        case let result as FinishedResultDTO:
            return .completion(resultCode: result.resultCode)
        case let result as ActionResultDTO:
            if let action = try? JSONDecoder().decode(Action.self, from: Data(result.actionResponse.utf8)) {
                return .action(action)
            }
            sendErrorResultToFlutter(componentId: "ADVANCED_ADYEN_COMPONENT", reason: "Failed to decode action.")
            return .completion(resultCode: "Error")
        case let result as ErrorResultDTO:
            sendErrorResultToFlutter(componentId: "ADVANCED_ADYEN_COMPONENT", reason: result.errorMessage)
            return .completion(resultCode: "Error")
        default:
            sendErrorResultToFlutter(componentId: "ADVANCED_ADYEN_COMPONENT", reason: "Unsupported checkout result.")
            return .completion(resultCode: "Error")
        }
    }

    private func mapCheckoutResultToAdditionalDetailsResult(_ checkoutResult: CheckoutResultDTO) -> AdditionalDetailsResult {
        switch checkoutResult {
        case let result as FinishedResultDTO:
            return .completion(resultCode: result.resultCode)
        case let result as ErrorResultDTO:
            sendErrorResultToFlutter(componentId: "ADVANCED_ADYEN_COMPONENT", reason: result.errorMessage)
            return .completion(resultCode: "Error")
        default:
            sendErrorResultToFlutter(componentId: "ADVANCED_ADYEN_COMPONENT", reason: "Unsupported checkout result.")
            return .completion(resultCode: "Error")
        }
    }

    // MARK: - Result helpers

    private func sendCompleteResult(componentId: String, sessionId: String, result: CheckoutResult) {
        let paymentResult = PaymentResultModelDTO(
            sessionId: sessionId,
            sessionResult: result.sessionResult,
            resultCode: result.resultCode.rawValue
        )
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: componentId,
            paymentResult: PaymentResultDTO(
                type: PaymentResultEnum.finished,
                result: paymentResult
            )
        )
        componentPlatformEventHandler.send(event: componentCommunicationModel)
    }

    private func sendErrorResult(componentId: String, error: CheckoutError) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: componentId,
            paymentResult: PaymentResultDTO(
                type: .from(error: error),
                reason: error.localizedDescription
            )
        )
        componentPlatformEventHandler.send(event: componentCommunicationModel)
    }

    private func sendErrorResultToFlutter(componentId: String, reason: String) {
        componentPlatformEventHandler.send(
            event: ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: componentId,
                paymentResult: PaymentResultDTO(
                    type: PaymentResultEnum.error,
                    reason: reason
                )
            )
        )
    }

    private func sendSubmitToFlutter(
        dataJson: String,
        completion: @escaping (Result<CheckoutResultDTO, AdyenPigeonError>) -> Void
    ) {
        let platformCommunication = PlatformCommunicationDTO(
            type: ComponentCommunicationType.onSubmit,
            componentId: "ADVANCED_ADYEN_COMPONENT",
            dataJson: dataJson
        )
        adyenFlutterInterface.onSubmit(platformCommunicationDTO: platformCommunication, completion: completion)
    }

    private func sendAdditionalDetailsToFlutter(
        dataJson: String,
        completion: @escaping (Result<CheckoutResultDTO, AdyenPigeonError>) -> Void
    ) {
        let platformCommunication = PlatformCommunicationDTO(
            type: ComponentCommunicationType.additionalDetails,
            componentId: "ADVANCED_ADYEN_COMPONENT",
            dataJson: dataJson
        )
        adyenFlutterInterface.onAdditionalDetails(platformCommunicationDTO: platformCommunication, completion: completion)
    }

    private func getViewController() -> UIViewController? {
        var rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
        while let presentedViewController = rootViewController?.presentedViewController {
            let type = String(describing: type(of: presentedViewController))
            if type == "DropInNavigationController" {
                return nil
            } else {
                rootViewController = presentedViewController
            }
        }

        return rootViewController
    }

    private func determineSessionConfiguration(configuration: DropInConfigurationDTO) throws -> CheckoutConfiguration {
        return try configuration.createCheckoutConfiguration()
    }
}

private extension PaymentComponentData {
    func toPlatformSubmitDataJson() throws -> String {
        let paymentComponentData = PaymentComponentDataResponse(
            amount: amount,
            paymentMethod: paymentMethod.encodable,
            storePaymentMethod: storePaymentMethod,
            order: order,
            amountToPay: order?.remainingAmount,
            installments: installments,
            shopperName: shopperName,
            emailAddress: emailAddress,
            telephoneNumber: telephoneNumber,
            browserInfo: browserInfo,
            billingAddress: billingAddress,
            deliveryAddress: deliveryAddress,
            socialSecurityNumber: socialSecurityNumber,
            delegatedAuthenticationData: delegatedAuthenticationData
        )
        let json = try JSONEncoder().encode(paymentComponentData)
        guard let jsonString = String(data: json, encoding: .utf8) else {
            throw PlatformError(errorDescription: "Unable to encode submit data")
        }
        return jsonString
    }
}

private extension ActionComponentData {
    func toPlatformAdditionalDetailsJson() throws -> String {
        let actionComponentData = ActionComponentDataModel(details: details.encodable, paymentData: paymentData)
        let json = try JSONEncoder().encode(actionComponentData)
        guard let jsonString = String(data: json, encoding: .utf8) else {
            throw PlatformError(errorDescription: "Unable to encode additional details")
        }
        return jsonString
    }
}

