@_spi(AdyenInternal)
import Adyen

class DropInSessionsStoredPaymentMethodsDelegate : StoredPaymentMethodsDelegate {
    private let checkoutFlutterApi: CheckoutFlutterApi
    private let viewController : UIViewController
    private var completionHandler: ((Bool) -> Void)?
    
    init(viewController: UIViewController, checkoutFlutterApi: CheckoutFlutterApi) {
        self.checkoutFlutterApi = checkoutFlutterApi
        self.viewController = viewController
    }
    
    internal func disable(storedPaymentMethod: StoredPaymentMethod, completion: @escaping (Bool) -> Void) {
        completionHandler = completion
        let platformCommunicationModel = PlatformCommunicationModel(type: PlatformCommunicationType.deleteStoredPaymentMethod, data: storedPaymentMethod.identifier)
        checkoutFlutterApi.onDropInSessionPlatformCommunication(platformCommunicationModel: platformCommunicationModel, completion: {})
    }
    
    func handleDisableResult(isSuccessfullyRemoved: Bool) {
        if (isSuccessfullyRemoved == false) {
            let errorAlert = TemporaryAlertHelper.buildPaymentMethodDeletionErrorAlert()
            viewController.adyen.topPresenter.present(errorAlert, animated: true)
        }
        
        completionHandler?(isSuccessfullyRemoved)
    }
}
