import Foundation
@_spi(AdyenInternal) import Adyen
import AdyenNetworking

// TODO: Add config:
// 1) Add Info.plist for adding photo library usage description
// 2) Add url scheme
// 3) Add AppDelegate redirect

class CheckoutPlatformApi: CheckoutPlatformInterface {
    private let configurationMapper = ConfigurationMapper()
    private let dropInFlutterApi: DropInFlutterInterface
    private let componentFlutterApi: ComponentFlutterInterface
    private let sessionHolder: SessionHolder
    private let adyenCse: AdyenCSE = .init()

    init(
        dropInFlutterApi: DropInFlutterInterface,
        componentFlutterApi: ComponentFlutterInterface,
        sessionHolder: SessionHolder
    ) {
        self.dropInFlutterApi = dropInFlutterApi
        self.componentFlutterApi = componentFlutterApi
        self.sessionHolder = sessionHolder
    }

    func createSession(
        sessionId: String,
        sessionData: String,
        configuration: Any?,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) {
        do {
            // TODO: Let's plan a generic configuration mapping for creating a session.
            switch configuration {
            case let dropInConfigurationDTO as DropInConfigurationDTO:
                try createSessionForDropIn(
                    configuration: dropInConfigurationDTO,
                    sessionId: sessionId,
                    sessionData: sessionData,
                    completion: completion
                )
            case let cardComponentConfigurationDTO as CardComponentConfigurationDTO:
                try createSessionForCardComponent(
                    configuration: cardComponentConfigurationDTO,
                    sessionId: sessionId,
                    sessionData: sessionData,
                    completion: completion
                )
            case let instantComponentConfigurationDTO as InstantPaymentConfigurationDTO:
                try createSessionForInstantPaymentConfiguration(
                    configuration: instantComponentConfigurationDTO,
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
    
    func encryptCard(unencryptedCardDTO: UnencryptedCardDTO, publicKey: String, completion: @escaping (Result<EncryptedCardDTO, any Error>) -> Void) {
        let encryptedCardResult = adyenCse.encryptCard(unencryptedCardDTO: unencryptedCardDTO, publicKey: publicKey)
        completion(encryptedCardResult)
    }
    
    func encryptBin(bin: String, publicKey: String, completion: @escaping (Result<String, any Error>) -> Void) {
        let encryptedBinResult = adyenCse.encryptBin(bin: bin, publicKey: publicKey)
        completion(encryptedBinResult)
    }

    private func createSessionForDropIn(
        configuration: DropInConfigurationDTO,
        sessionId: String,
        sessionData: String,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) throws {
        let adyenContext = try configuration.createAdyenContext()
        let sessionDelegate = DropInSessionsDelegate(viewController: getViewController(), dropInFlutterApi: dropInFlutterApi)
        let sessionPresentationDelegate = DropInSessionsPresentationDelegate()
        requestAndSetSession(
            adyenContext: adyenContext,
            sessionId: sessionId,
            sessionData: sessionData,
            sessionDelegate: sessionDelegate,
            sessionPresentationDelegate: sessionPresentationDelegate,
            completion: completion
        )
    }

    private func createSessionForCardComponent(
        configuration: CardComponentConfigurationDTO,
        sessionId: String,
        sessionData: String,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) throws {
        let adyenContext = try configuration.createAdyenContext()
        let sessionDelegate = ComponentSessionFlowDelegate(componentFlutterApi: componentFlutterApi)
        let sessionPresentationDelegate = ComponentPresentationDelegate(topViewController: getViewController())
        requestAndSetSession(
            adyenContext: adyenContext,
            sessionId: sessionId,
            sessionData: sessionData,
            sessionDelegate: sessionDelegate,
            sessionPresentationDelegate: sessionPresentationDelegate,
            completion: completion
        )
    }
    
    private func createSessionForInstantPaymentConfiguration(
        configuration: InstantPaymentConfigurationDTO,
        sessionId: String,
        sessionData: String,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) throws {
        let adyenContext = try configuration.createAdyenContext()
        let sessionDelegate = ComponentSessionFlowDelegate(componentFlutterApi: componentFlutterApi)
        let applePayPresentationDelegate = ComponentPresentationDelegate(topViewController: getViewController())
        requestAndSetSession(
            adyenContext: adyenContext,
            sessionId: sessionId,
            sessionData: sessionData,
            sessionDelegate: sessionDelegate,
            sessionPresentationDelegate: applePayPresentationDelegate,
            completion: completion
        )
    }

    private func requestAndSetSession(
        adyenContext: AdyenContext,
        sessionId: String,
        sessionData: String,
        sessionDelegate: AdyenSessionDelegate,
        sessionPresentationDelegate: PresentationDelegate,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) {
        let sessionConfiguration = AdyenSession.Configuration(
            sessionIdentifier: sessionId,
            initialSessionData: sessionData,
            context: adyenContext,
            actionComponent: .init()
        )
        AdyenSession.initialize(
            with: sessionConfiguration,
            delegate: sessionDelegate,
            presentationDelegate: sessionPresentationDelegate
        ) { [weak self] result in
            switch result {
            case let .success(session):
                // TODO: For later  - We need to return the actual session and removing the session holder when the session is codable.
                self?.sessionHolder.setup(
                    session: session,
                    sessionPresentationDelegate: sessionPresentationDelegate,
                    sessionDelegate: sessionDelegate
                )
                // TODO: serialize paymentMethods
                completion(Result.success(SessionDTO(
                    id: sessionId,
                    sessionData: sessionData,
                    paymentMethodsJson: ""
                )))
            case let .failure(error):
                completion(Result.failure(error))
            }
        }
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
