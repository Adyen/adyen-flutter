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

class CheckoutPlatformApi: CheckoutPlatformInterface {
    private let checkoutFlutter: CheckoutFlutterInterface
    private let componentFlutterApi: ComponentFlutterInterface
    private let adyenFlutterInterface: AdyenFlutterInterface
    private let componentPlatformEventHandler: ComponentPlatformEventHandler
    private let sessionHolder: SessionHolder
    private let adyenCse: AdyenCSE = .init()
    
    private var checkoutConfig : CheckoutConfiguration? = nil

    init(
        checkoutFlutter: CheckoutFlutterInterface,
        componentFlutterApi: ComponentFlutterInterface,
        adyenFlutterInterface: AdyenFlutterInterface,
        componentPlatformEventHandler: ComponentPlatformEventHandler,
        sessionHolder: SessionHolder
    ) {
        self.checkoutFlutter = checkoutFlutter
        self.componentFlutterApi = componentFlutterApi
        self.adyenFlutterInterface = adyenFlutterInterface
        self.componentPlatformEventHandler = componentPlatformEventHandler
        self.sessionHolder = sessionHolder
    }
    
    func setup(
        sessionResponseDTO: SessionResponseDTO,
        checkoutConfigurationDTO: CheckoutConfigurationDTO,
        completion: @escaping (Result<SessionDTO, any Error>) -> Void) {
            Task {
                do {
                    //TODO: Config needs to be just session relevant, component specific one needs to be bound when creating component?
                    let sessionResponse = sessionResponseDTO.mapToSessionResponse()
                    let checkoutConfiguration = try await createSessionCheckoutConfiguration(configurationDTO: checkoutConfigurationDTO)
                    let checkoutSession = try await Checkout.setup(
                        with: sessionResponse,
                        configuration: checkoutConfiguration
                    )
                    
                    try onSetupSuccess(
                        id: sessionResponseDTO.id, //Flutter specific, maybe we can use id from the checkout session like on Android
                        checkoutSession: checkoutSession,
                        completion: completion
                    )
                } catch {
                    completion(Result.failure(error))
                }
            }
    }
    
    func setupSession(sessionResponseDTO: SessionResponseDTO, checkoutConfigurationDTO: CheckoutConfigurationDTO, completion: @escaping (Result<SessionDTO, any Error>) -> Void) {
        Task {
            do {
                let sessionResponse = sessionResponseDTO.mapToSessionResponse()
                let checkoutConfiguration = try await createSessionCheckoutConfiguration(configurationDTO: checkoutConfigurationDTO)
                self.checkoutConfig = checkoutConfiguration
                let checkoutSession = try await Checkout.setup(
                    with: sessionResponse,
                    configuration: checkoutConfiguration
                )

                try onSetupSuccess(
                    id: sessionResponseDTO.id,
                    checkoutSession: checkoutSession,
                    completion: completion
                )
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
                let checkoutConfiguration = try await createAdvancedCheckoutConfiguration(configurationDTO: checkoutConfigurationDTO)
                self.checkoutConfig = checkoutConfiguration
                let adyenCheckout = try await Checkout.setup(
                    with: paymentMethods,
                    configuration: checkoutConfiguration
                )

                sessionHolder.adyenCheckout = adyenCheckout
                completion(Result.success(()))
            } catch {
                completion(Result.failure(error))
            }
        }
    }

    func createSession(
        sessionId: String,
        sessionData: String,
        configuration: Any?,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) {
        Task {
            do {
                switch configuration {
                case let checkoutConfiguration as CardComponentConfigurationDTO:
                    do {
//                        let sessionConfiguration = try await createConfiguration(configuration: checkoutConfiguration)
//                        let checkoutSession = try await Checkout.setup(
//                            with: SessionResponse(id: sessionId, sessionData: sessionData),
//                            configuration: sessionConfiguration
//                        )
//                        
//                        try onSessionCreationSuccess(
//                            id: sessionId, //Flutter specific, maybe we can use id from the checkout session like on Android
//                            checkoutSession: checkoutSession,
//                            completion: completion
//                        )
                    } catch {
                        // TODO: Add error handling
                        completion(Result.failure(error))
                    }
                case .none, .some:
                    completion(Result.failure(PlatformError(errorDescription: "Configuration is not valid")))
                }
            } catch {
                completion(Result.failure(error))
            }
        }
    }
    
    func clearSession() {
        sessionHolder.reset()
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

    private func createSessionForDropIn(
        configuration: CheckoutConfiguration,
        adyenContext: AdyenContext,
        sessionId: String,
        sessionData: String,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) async throws {
        let sessionDelegate = DropInSessionsDelegate(viewController: getViewController(), checkoutFlutter: checkoutFlutter)
    }
    
    private func test() -> CardComponentConfiguration? {
        return nil
    }

    private func createSessionCheckoutConfiguration(
        configurationDTO: CheckoutConfigurationDTO,
    ) async throws -> CheckoutConfiguration {
        let checkoutConfig = try CheckoutConfiguration(
            environment: configurationDTO.environment.mapToEnvironment(),
            amount: configurationDTO.amount!.mapToAmount(),
            clientKey: configurationDTO.clientKey,
            analyticsConfiguration: .init()
        ) {
            configurationDTO.cardConfigurationDTO!.mapToCardComponentConfiguration(shopperLocale: configurationDTO.shopperLocale)            
        }.onComplete { [weak self] result in
            print("ON COMPLETE SWIFT INVOKED")
            let paymentResult = PaymentResultModelDTO(
                sessionId: "", // REMOVE FROM DTO
                sessionResult: result.sessionResult,
                resultCode: result.resultCode.rawValue
            )
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: "SESSION_ADYEN_COMPONENT",
                paymentResult: PaymentResultDTO(
                    type: PaymentResultEnum.finished,
                    result: paymentResult
                )
            )
            self?.componentPlatformEventHandler.send(event: componentCommunicationModel)
            
        }.onError { [weak self] error in
            print("ON ERROR SWIFT INVOKED")
            let componentCommunicationModel = ComponentCommunicationModel(
                type: ComponentCommunicationType.result,
                componentId: "SESSION_ADYEN_COMPONENT",
                paymentResult: PaymentResultDTO(
                    type: .from(error: error),
                    reason: error.localizedDescription
                )
            )
            self?.componentPlatformEventHandler.send(event: componentCommunicationModel)
        }
        
        return checkoutConfig
    }

    private func createAdvancedCheckoutConfiguration(
        configurationDTO: CheckoutConfigurationDTO,
    ) async throws -> CheckoutConfiguration {
        let checkoutConfig = try await createSessionCheckoutConfiguration(configurationDTO: configurationDTO)
        checkoutConfig.onSubmit { [weak self] paymentData, handler in
            print("ON SUBMIT SWIFT INVOKED")
            guard let self else { return }
            do {
                let dataJson = try paymentData.toPlatformSubmitDataJson()
                sendSubmitToFlutter(dataJson: dataJson) { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case let .success(checkoutResult):
                        self.handleCheckoutResult(checkoutResult, handler: handler)
                    case let .failure(error):
                        self.sendErrorResultToFlutter(componentId: "ADVANCED_ADYEN_COMPONENT", reason: error.localizedDescription)
                        handler?(CheckoutPaymentsResponse(resultCode: .error))
                    }
                }
            } catch {
                sendErrorResultToFlutter(componentId: "ADVANCED_ADYEN_COMPONENT", reason: error.localizedDescription)
                handler?(CheckoutPaymentsResponse(resultCode: .error))
            }
        }.onAdditionalDetails { [weak self] additionalDetailsData, handler in
            print("ON ADDITIONAL DETAILS SWIFT INVOKED")
            guard let self else { return }
            do {
                let dataJson = try additionalDetailsData.toPlatformAdditionalDetailsJson()
                sendAdditionalDetailsToFlutter(dataJson: dataJson) { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case let .success(checkoutResult):
                        self.handleCheckoutResult(checkoutResult, handler: handler)
                    case let .failure(error):
                        self.sendErrorResultToFlutter(componentId: "ADVANCED_ADYEN_COMPONENT", reason: error.localizedDescription)
                        handler?(CheckoutPaymentsResponse(resultCode: .error))
                    }
                }
            } catch {
                sendErrorResultToFlutter(componentId: "ADVANCED_ADYEN_COMPONENT", reason: error.localizedDescription)
                handler?(CheckoutPaymentsResponse(resultCode: .error))
            }
        }

        return checkoutConfig
    }
    
    private func onSetupSuccess(
        id: String,
        checkoutSession: Checkout,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) throws {
        sessionHolder.adyenCheckout = checkoutSession
        let encodedPaymentMethods = try JSONEncoder().encode(checkoutSession.paymentMethods)
        guard let encodedPaymentMethodsString = String(data: encodedPaymentMethods, encoding: .utf8) else {
            completion(Result.failure(PlatformError(errorDescription: "Encoding payment methods failed")))
            return
        }

        completion(Result.success(SessionDTO(
            id: id,
            paymentMethodsJson: encodedPaymentMethodsString
        )))
    }

    private func buildActionComponentConfiguration(from threeDS2ConfigurationDTO: ThreeDS2ConfigurationDTO?) -> CheckoutActionComponent.Configuration? {
            threeDS2ConfigurationDTO.map {
                var actionComponentConfiguration = CheckoutActionComponent.Configuration()
                actionComponentConfiguration.threeDS = $0.mapToThreeDS2Configuration()
                return actionComponentConfiguration
            }
        }

    private func handleCheckoutResult(
        _ checkoutResult: CheckoutResultDTO,
        handler: PaymentsResponseHandler?
    ) {
        guard let handler else { return }
        switch checkoutResult {
        case let result as FinishedResultDTO:
            handler(CheckoutPaymentsResponse(resultCode: .init(rawValue: result.resultCode)))
        case let result as ErrorResultDTO:
            sendErrorResultToFlutter(componentId: "ADVANCED_ADYEN_COMPONENT", reason: result.errorMessage)
            handler(CheckoutPaymentsResponse(resultCode: .error))
        case let result as ActionResultDTO:
            do {
                let action = try JSONDecoder().decode(Action.self, from: Data(result.actionResponse.utf8))
                handler(CheckoutPaymentsResponse(resultCode: .redirectShopper, action: action))
            } catch {
                sendErrorResultToFlutter(componentId: "ADVANCED_ADYEN_COMPONENT", reason: error.localizedDescription)
                handler(CheckoutPaymentsResponse(resultCode: .error))
            }
        default:
            sendErrorResultToFlutter(componentId: "ADVANCED_ADYEN_COMPONENT", reason: "Unsupported checkout result.")
            handler(CheckoutPaymentsResponse(resultCode: .error))
        }
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
        var rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        while let presentedViewController = rootViewController?.presentedViewController {
            let type = String(describing: type(of: presentedViewController))
            // TODO: - We need to discuss how the SDK should react if a DropInNavigationController is already displayed
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

