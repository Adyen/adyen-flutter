import Adyen

class SessionHolder {
    var session: AdyenSession?
    var sessionDelegate: AdyenSessionDelegate?

    func setup(
        session: AdyenSession,
        sessionDelegate: AdyenSessionDelegate
    ) {
        self.session = session
        self.sessionDelegate = sessionDelegate
    }

    func reset() {
        session = nil
        sessionDelegate = nil
    }
}
