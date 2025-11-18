import Foundation
import UIKit

#if canImport(AdyenSession)
    import AdyenSession
#endif
#if canImport(AdyenCard)
    import AdyenCard
#endif
@_spi(AdyenInternal) import Adyen

// TODO: Add config:
// 1) Add Info.plist for adding photo library usage description
// 2) Add url scheme
// 3) Add AppDelegate redirect

class CheckoutPlatformApi: CheckoutPlatformInterface {
    private let checkoutFlutter: CheckoutFlutterInterface
    private let componentFlutterApi: ComponentFlutterInterface
    private let sessionHolder: SessionHolder
    private let adyenCse: AdyenCSE = .init()

    init(
        checkoutFlutter: CheckoutFlutterInterface,
        componentFlutterApi: ComponentFlutterInterface,
        sessionHolder: SessionHolder
    ) {
        self.checkoutFlutter = checkoutFlutter
        self.componentFlutterApi = componentFlutterApi
        self.sessionHolder = sessionHolder
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
                case let dropInConfigurationDTO as DropInConfigurationDTO:
                    Task {
                        let sessionDelegate = DropInSessionsDelegate(viewController: getViewController(), checkoutFlutter: checkoutFlutter)
                        await setSession(
                            sessionId: sessionId,
                            sessionData: sessionData,
                            sessionDelegate: sessionDelegate,
                            configuration: dropInConfigurationDTO,
                            completion: completion
                        )
                    }
                    //                try createSessionForDropIn(
                    //                    adyenContext: dropInConfigurationDTO.createAdyenContext(),
                    //                    sessionId: sessionId,
                    //                    sessionData: sessionData,
                    //                    completion: completion
                    //                )
                case let cardComponentConfigurationDTO as CardComponentConfigurationDTO:
                    try await createSessionForComponent(
                        configuration: cardComponentConfigurationDTO.createCheckoutConfiguration(),
                        sessionId: sessionId,
                        sessionData: sessionData,
                        completion: completion
                    )
//                case let instantComponentConfigurationDTO as InstantPaymentConfigurationDTO:
                    //                try createSessionForComponent(
                    //                    configuration: instantComponentConfigurationDTO.createCheckoutConfiguration(),
                    //                    adyenContext: instantComponentConfigurationDTO.createAdyenContext(),
                    //                    sessionId: sessionId,
                    //                    sessionData: sessionData,
                    //                    completion: completion
                    //                )
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
        threeDS2SdkVersion
    }

    private func createSessionForDropIn(
        configuration: CheckoutConfiguration,
        adyenContext: AdyenContext,
        sessionId: String,
        sessionData: String,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) async throws {
        let sessionDelegate = DropInSessionsDelegate(viewController: getViewController(), checkoutFlutter: checkoutFlutter)
        try await requestAndSetSession(
            checkoutConfiguration: configuration,
            sessionId: sessionId,
            sessionData: sessionData,
            completion: completion
        )
    }

    private func createSessionForComponent(
        configuration: CheckoutConfiguration,
        sessionId: String,
        sessionData: String,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) async throws {
        let sessionDelegate = ComponentSessionFlowHandler(componentFlutterApi: componentFlutterApi)
        try await requestAndSetSession(
            checkoutConfiguration: configuration,
            sessionId: sessionId,
            sessionData: sessionData,
            completion: completion
        )
    }
    
    private func setSession(
        sessionId: String,
        sessionData: String,
        sessionDelegate: AdyenSessionDelegate,
        configuration: DropInConfigurationDTO,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) async {
        do {
            let configuration = try configuration.createCheckoutConfiguration()
            let adyenCheckout = try await AdyenCheckout.setup(with: sessionId, sessionData: sessionData, configuration: configuration)
            sessionHolder.adyenCheckout = adyenCheckout
            sessionHolder.sessionDelegate = sessionDelegate
            let encodedPaymentMethods = try JSONEncoder().encode(adyenCheckout.paymentMethods)
            guard let encodedPaymentMethodsString = String(data: encodedPaymentMethods, encoding: .utf8) else {
                completion(Result.failure(PlatformError(errorDescription: "Encoding payment methods failed")))
                return
            }
            
            completion(Result.success(SessionDTO(
                id: sessionId,
                sessionData: sessionData,
                paymentMethodsJson: encodedPaymentMethodsString
            )))
        } catch {
            completion(Result.failure(error))
        }
    }

    private func requestAndSetSession(
        checkoutConfiguration: CheckoutConfiguration,
        sessionId: String,
        sessionData: String,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) async throws {
//        guard let presentationDelegate = getViewController() else {
//            throw PlatformError(errorDescription: "Host view controller not available.")
//        }
        
        let adyenCheckout = try await AdyenCheckout.setup(
            with: sessionId,
            sessionData: sessionData,
            configuration: checkoutConfiguration,
        )

        sessionHolder.sessionId = sessionId
        sessionHolder.sessionData = sessionData
        
        let encodedPaymentMethods = try JSONEncoder().encode(adyenCheckout.paymentMethods)
        guard let encodedPaymentMethodsString = String(data: encodedPaymentMethods, encoding: .utf8) else {
            completion(Result.failure(PlatformError(errorDescription: "Encoding payment methods failed")))
            return
        }
        completion(Result.success(SessionDTO(
            id: sessionId,
            sessionData: sessionData,
            paymentMethodsJson: encodedPaymentMethodsString
        )))
        
//
//        AdyenSession.setup(
//            with: sessionConfiguration,
//            delegate: sessionDelegate,
//            presentationDelegate: presentationDelegate
//        ) { [weak self] result in
//            do {
//                switch result {
//                case let .success(session):
//                    self?.sessionHolder.setup(
//                        session: session,
//                        sessionDelegate: sessionDelegate
//                    )
//                    let encodedPaymentMethods = try JSONEncoder().encode(session.sessionContext.paymentMethods)
//                    guard let encodedPaymentMethodsString = String(data: encodedPaymentMethods, encoding: .utf8) else {
//                        completion(Result.failure(PlatformError(errorDescription: "Encoding payment methods failed")))
//                        return
//                    }
//                    completion(Result.success(SessionDTO(
//                        id: sessionId,
//                        sessionData: sessionData,
//                        paymentMethodsJson: encodedPaymentMethodsString
//                    )))
//                case let .failure(error):
//                    completion(Result.failure(error))
//                }
//            } catch {
//                completion(Result.failure(error))
//            }
//        }
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
}
