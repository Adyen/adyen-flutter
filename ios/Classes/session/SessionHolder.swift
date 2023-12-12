import Adyen

class SessionHolder {
    var session: AdyenSession?
    var sessionPresentationDelegate: PresentationDelegate?
    var sessionDelegate: AdyenSessionDelegate?

    func setup(
        session: AdyenSession,
        sessionPresentationDelegate: PresentationDelegate,
        sessionDelegate: AdyenSessionDelegate
    ) {
        self.session = session
        self.sessionPresentationDelegate = sessionPresentationDelegate
        self.sessionDelegate = sessionDelegate
    }

    func reset() {
        session = nil
        sessionPresentationDelegate = nil
        sessionDelegate = nil
    }
}
