@_spi(AdyenInternal) import Adyen

protocol SessionSetupProtocol {
    var sessionWrapper: SessionWrapper? { get set }

    func setupSession(
        adyenContext: AdyenContext,
        sessionId: String,
        sessionData: String,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    )
}

extension SessionSetupProtocol {
    func getViewController() -> UIViewController? {
        var rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
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
}
