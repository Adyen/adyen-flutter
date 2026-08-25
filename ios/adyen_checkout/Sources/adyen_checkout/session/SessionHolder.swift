@_spi(AdyenInternal) import Adyen
#if canImport(AdyenSession)
    import AdyenSession
#endif

class SessionHolder {
    var session: AdyenSession?
    var sessionDelegate: AdyenSessionDelegate?
    private(set) var isSessionInUse = false

    func setup(
        session: AdyenSession,
        sessionDelegate: AdyenSessionDelegate
    ) {
        guard !isSessionInUse else {
            adyenPrint("Session is currently being used.")
            return
        }
        self.session = session
        self.sessionDelegate = sessionDelegate
    }

    func reset() {
        guard !isSessionInUse else {
            adyenPrint("Session reset ignored because the session is still in use.")
            return
        }
        (sessionDelegate as? ComponentSessionFlowHandler)?.reset()
        session = nil
        sessionDelegate = nil
    }

    func markSessionAsInUse() {
        isSessionInUse = true
    }

    func releaseSession() {
        isSessionInUse = false
    }
}
