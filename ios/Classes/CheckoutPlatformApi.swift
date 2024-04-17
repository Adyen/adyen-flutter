import Foundation
@_spi(AdyenInternal) import Adyen
import AdyenNetworking

// TODO: Add config:
// 1) Add Info.plist for adding photo library usage description
// 2) Add url scheme
// 3) Add AppDelegate redirect

class CheckoutPlatformApi: CheckoutPlatformInterface {
    private let dropInFlutterApi: DropInFlutterInterface
    private let componentFlutterApi: ComponentFlutterInterface
    private let dropInSessionManager: DropInSessionManager
    private let cardComponentSessionFactory: CardComponentFactory
    private let applePayComponentManager: ApplePayComponentManager
    
    init(
        dropInFlutterApi: DropInFlutterInterface,
        componentFlutterApi: ComponentFlutterInterface,
        dropInSessionManager: DropInSessionManager,
        cardComponentSessionFactory: CardComponentFactory,
        applePayComponentManager: ApplePayComponentManager
    ) {
        self.dropInFlutterApi = dropInFlutterApi
        self.componentFlutterApi = componentFlutterApi
        self.dropInSessionManager = dropInSessionManager
        self.cardComponentSessionFactory = cardComponentSessionFactory
        self.applePayComponentManager = applePayComponentManager
    }

    func createSession(
        sessionId: String,
        sessionData: String,
        configuration: Any?,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) {
        do {
            switch configuration {
            case let dropInConfigurationDTO as DropInConfigurationDTO:
                let adyenContext = try buildAdyenContext(
                    environment: dropInConfigurationDTO.environment,
                    clientKey: dropInConfigurationDTO.clientKey,
                    amount: dropInConfigurationDTO.amount,
                    analyticsOptionsDTO: dropInConfigurationDTO.analyticsOptionsDTO,
                    countryCode: dropInConfigurationDTO.countryCode
                )
                dropInSessionManager.setupSession(
                    adyenContext: adyenContext,
                    sessionId: sessionId,
                    sessionData: sessionData,
                    completion: completion
                )
            case let configuration as CardComponentConfigurationDTO:
                let adyenContext = try buildAdyenContext(
                    environment: configuration.environment,
                    clientKey: configuration.clientKey,
                    amount: configuration.amount,
                    analyticsOptionsDTO: configuration.analyticsOptionsDTO,
                    countryCode: configuration.countryCode
                )
                cardComponentSessionFactory.setupSession(
                    adyenContext: adyenContext,
                    sessionId: sessionId,
                    sessionData: sessionData,
                    completion: completion
                )
            case let configuration as InstantPaymentConfigurationDTO:
                let adyenContext = try buildAdyenContext(
                    environment: configuration.environment,
                    clientKey: configuration.clientKey,
                    amount: configuration.amount,
                    analyticsOptionsDTO: configuration.analyticsOptionsDTO,
                    countryCode: configuration.countryCode
                )
                applePayComponentManager.setupSession(
                    adyenContext: adyenContext,
                    sessionId: sessionId,
                    sessionData: sessionData,
                    completion: completion
                )
            case .none, .some:
                completion(Result.failure(PlatformError(errorDescription: "Configuration is not valid")))
            }
        } catch {
            completion(Result.failure(error))
        }
    }

    func getReturnUrl(completion: @escaping (Result<String, Error>) -> Void) {
        completion(Result.failure(PlatformError(errorDescription: "Please use your app url type instead of this method.")))
    }

    func enableConsoleLogging(loggingEnabled: Bool) {
        AdyenLogging.isEnabled = loggingEnabled
    }
}
