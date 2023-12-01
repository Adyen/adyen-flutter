import Adyen

class SessionHolder {
    var session: AdyenSession?
    var sessionPresentationDelegate: PresentationDelegate?
    var sessionDelegate: AdyenSessionDelegate?
}
