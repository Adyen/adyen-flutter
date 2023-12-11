import Foundation
@_spi(AdyenInternal) import Adyen
import AdyenNetworking

// TODO: Add config:
// 1) Add Info.plist for adding photo library usage description
// 2) Add url scheme
// 3) Add AppDelegate redirect

class CheckoutPlatformApi: CheckoutPlatformInterface {
    private let configurationMapper = ConfigurationMapper()
    private let componentFlutterApi: ComponentFlutterInterface
    private let sessionHolder: SessionHolder

    init(
        componentFlutterApi: ComponentFlutterInterface,
        sessionHolder: SessionHolder
    ) {
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
            switch configuration {
            case is CardComponentConfigurationDTO:
                let adyenContext = try (configuration as! CardComponentConfigurationDTO).createAdyenContext()
                let sessionConfiguration = AdyenSession.Configuration(sessionIdentifier: sessionId,
                                                                      initialSessionData: sessionData,
                                                                      context: adyenContext,
                                                                      actionComponent: .init())
                let sessionDelegate = CardSessionFlowDelegate(componentFlutterApi: componentFlutterApi)
                let sessionPresentationDelegate = CardPresentationDelegate(topViewController: getViewController())
                AdyenSession.initialize(with: sessionConfiguration,
                                        delegate: sessionDelegate,
                                        presentationDelegate: sessionPresentationDelegate)
                { [weak self] result in
                    switch result {
                    case let .success(session):
                        self?.sessionHolder.setup(session: session, sessionPresentationDelegate: sessionPresentationDelegate, sessionDelegate: sessionDelegate)
                        // TODO: serialize paymentMethods
                        completion(Result.success(SessionDTO(id: sessionId,
                                                             sessionData: sessionData,
                                                             paymentMethodsJson: "")))
                    case let .failure(error):
                        completion(Result.failure(error))
                    }
                }
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
