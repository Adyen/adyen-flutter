@_spi(AdyenInternal) import AdyenCheckout
@_spi(AdyenInternal) import Adyen
#if canImport(AdyenSession)
    import AdyenSession
#endif

class SessionHolder {
    var session: Session?
    var sessionDelegate: SessionDelegate?
    var adyenCheckout : Checkout?

    func setup(
        session: Session,
        sessionDelegate: SessionDelegate
    ) {
        self.session = session
        self.sessionDelegate = sessionDelegate
    }

    func reset() {
        session = nil
        sessionDelegate = nil
        adyenCheckout = nil
    }
}
