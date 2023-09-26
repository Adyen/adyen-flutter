import Adyen
import AdyenNetworking

class DropInSessionsDelegate : AdyenSessionDelegate {
  
    private let viewController : UIViewController?
    private let checkoutFlutterApi: CheckoutFlutterApi
    
    init(viewController: UIViewController, checkoutFlutterApi: CheckoutFlutterApi) {
        self.viewController = viewController
        self.checkoutFlutterApi = checkoutFlutterApi
    }
    
    func didComplete(with result: Adyen.AdyenSessionResult, component: Adyen.Component, session: Adyen.AdyenSession) {
        viewController?.dismiss(animated: false, completion: {
            let paymentResult = PaymentResultModelDTO(sessionId: session.sessionContext.identifier, sessionData: session.sessionContext.data, resultCode: result.resultCode.rawValue)
            self.checkoutFlutterApi.onDropInSessionResult(sessionPaymentResult: PaymentResultDTO(type: PaymentResultEnum.finished, result: paymentResult), completion: {})
        })
    }
    
    func didFail(with error: Error, from component: Component, session: AdyenSession) {
        viewController?.dismiss(animated: true, completion: {
            switch (error) {
            case ComponentError.cancelled:
                self.checkoutFlutterApi.onDropInSessionResult(sessionPaymentResult: PaymentResultDTO(type: PaymentResultEnum.cancelledByUser, reason: error.localizedDescription)) {}
            default:
                self.checkoutFlutterApi.onDropInSessionResult(sessionPaymentResult: PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription)) {}
            }
        })
    }
    
    func didOpenExternalApplication(component: ActionComponent, session: AdyenSession) {
        print("external")
    }
}
