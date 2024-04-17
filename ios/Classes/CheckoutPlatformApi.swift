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
    private let sessionHolder: SessionHolder
    private let dropInSessionManager: DropInSessionManager

    init(
        dropInFlutterApi: DropInFlutterInterface,
        componentFlutterApi: ComponentFlutterInterface,
        sessionHolder: SessionHolder,
        dropInSessions: DropInSessionManager
    ) {
        self.dropInFlutterApi = dropInFlutterApi
        self.componentFlutterApi = componentFlutterApi
        self.sessionHolder = sessionHolder
        self.dropInSessionManager = dropInSessions
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
                dropInSessionManager.createSession(
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
                createSessionForComponent(
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
                createSessionForComponent(
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

    private func createSessionForComponent(
        adyenContext: AdyenContext,
        sessionId: String,
        sessionData: String,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) {
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
                
                do {
                    let paymentMethods = try JSONEncoder().encode(session.sessionContext.paymentMethods)
                    completion(Result.success(SessionDTO(
                        id: sessionId,
                        sessionData: sessionData,
                        paymentMethodsJson: String(data: paymentMethods, encoding: .utf8) ?? ""
                    )))
                } catch {
                    completion(Result.failure(error))
                }
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
