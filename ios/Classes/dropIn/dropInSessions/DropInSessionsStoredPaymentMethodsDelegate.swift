@_spi(AdyenInternal)
import Adyen

class DropInSessionsStoredPaymentMethodsDelegate: StoredPaymentMethodsDelegate {
    private let dropInFlutterApi: DropInFlutterInterface
    private let viewController: UIViewController
    private var completionHandler: ((Bool) -> Void)?

    init(viewController: UIViewController, dropInFlutterApi: DropInFlutterInterface) {
        self.dropInFlutterApi = dropInFlutterApi
        self.viewController = viewController
    }

    func disable(storedPaymentMethod: StoredPaymentMethod, completion: @escaping (Bool) -> Void) {
        completionHandler = completion
        let platformCommunicationModel = PlatformCommunicationModel(
            type: PlatformCommunicationType.deleteStoredPaymentMethod,
            data: storedPaymentMethod.identifier
        )
        dropInFlutterApi.onDropInSessionPlatformCommunication(
            platformCommunicationModel: platformCommunicationModel,
            completion: { _ in }
        )
    }

    func handleDisableResult(isSuccessfullyRemoved: Bool) {
        if isSuccessfullyRemoved == false {
            let errorAlert = TemporaryAlertHelper.buildPaymentMethodDeletionErrorAlert()
            viewController.adyen.topPresenter.present(errorAlert, animated: true)
        }

        completionHandler?(isSuccessfullyRemoved)
    }
}
