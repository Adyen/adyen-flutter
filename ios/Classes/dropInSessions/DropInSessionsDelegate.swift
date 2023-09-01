import Adyen
import AdyenNetworking

class DropInSessionsDelegate : AdyenSessionDelegate {
    private let viewController : UIViewController?
    private let checkoutFlutterApi: CheckoutFlutterApi
    
    init(viewController: UIViewController, checkoutFlutterApi: CheckoutFlutterApi) {
        self.viewController = viewController
        self.checkoutFlutterApi = checkoutFlutterApi
    }
    
    func didComplete(with resultCode: SessionPaymentResultCode, component: Component, session: AdyenSession) {
        viewController?.dismiss(animated: false, completion: {
            let paymentResult = PaymentResult(sessionId: session.sessionContext.identifier, sessionData: session.sessionContext.data, resultCode: resultCode.rawValue)
            self.checkoutFlutterApi.onDropInSessionResult(sessionDropInResult: DropInResult(type: DropInResultEnum.finished,result: paymentResult), completion: {})
        })
    }
    
    func didFail(with error: Error, from component: Component, session: AdyenSession) {
        viewController?.dismiss(animated: true, completion: {
            switch (error) {
            case ComponentError.cancelled:
                self.checkoutFlutterApi.onDropInSessionResult(sessionDropInResult: DropInResult(type: DropInResultEnum.cancelledByUser, reason: error.localizedDescription)) {}
            default:
                self.checkoutFlutterApi.onDropInSessionResult(sessionDropInResult: DropInResult(type: DropInResultEnum.error, reason: error.localizedDescription)) {}
            }
        })
    }
    
    func didOpenExternalApplication(component: ActionComponent, session: AdyenSession) {
        print("external")
    }
}
