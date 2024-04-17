@_spi(AdyenInternal) import Adyen

class SessionWrapper {
    var session: AdyenSession?
    var sessionPresentationDelegate: PresentationDelegate?
    var sessionDelegate: AdyenSessionDelegate?
    
    func setup(
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
            guard let self else { return }
            switch result {
            case let .success(session):
                self.session = session
                self.sessionPresentationDelegate = sessionPresentationDelegate
                self.sessionDelegate = sessionDelegate
                do {
                    let paymentMethods = try JSONEncoder().encode(session.sessionContext.paymentMethods)
                    completion(Result.success(SessionDTO(
                        id: sessionId,
                        sessionData: sessionData,
                        paymentMethodsJson: String(data: paymentMethods, encoding: .utf8) ?? ""
                    )))
                } catch {
                    self.reset()
                    completion(Result.failure(error))
                }
            case let .failure(error):
                self.reset()
                completion(Result.failure(error))
            }
        }
    }
    
    func reset() {
        session = nil
        sessionPresentationDelegate = nil
        sessionDelegate = nil
    }
}
