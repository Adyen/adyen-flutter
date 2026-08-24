@_spi(AdyenInternal) import Adyen
#if canImport(AdyenSession)
    import AdyenSession
#endif

class SessionHolder {
    var session: AdyenSession?
    var sessionDelegate: AdyenSessionDelegate?

    /// Set while a presentation owns the session, so a stray `clearSession()` from the merchant cannot
    /// tear down a session that is still driving an on-screen Drop-in.
    private(set) var isSessionInUse = false

    func setup(
        session: AdyenSession,
        sessionDelegate: AdyenSessionDelegate
    ) throws {
        try ensureSessionIsNotInUse()
        self.session = session
        self.sessionDelegate = sessionDelegate
    }

    /// Discards the session, unless a presentation still holds it. Callers tearing down that presentation
    /// must call `releaseSession()` first, otherwise the session is kept and the reset is ignored.
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

    private func ensureSessionIsNotInUse() throws {
        guard !isSessionInUse else {
            throw PlatformError(errorDescription: "Session is currently being used.")
        }
    }
}
