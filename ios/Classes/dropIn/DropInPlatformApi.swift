@_spi(AdyenInternal) import Adyen
import AdyenNetworking

class DropInPlatformApi: DropInPlatformInterface {
    private let dropInFlutterApi: DropInFlutterInterface
    private let dropInSessionManager: DropInSessionManager
    private let dropInAdvancedManager: DropInAdvancedManager

    init(
        dropInFlutterApi: DropInFlutterInterface,
        dropInSessionManager: DropInSessionManager,
        dropInAdvancedManager: DropInAdvancedManager
    ) {
        self.dropInFlutterApi = dropInFlutterApi
        self.dropInSessionManager = dropInSessionManager
        self.dropInAdvancedManager = dropInAdvancedManager
    }

    func showDropInSession(dropInConfigurationDTO: DropInConfigurationDTO, sessionDTO: SessionDTO) {
        dropInSessionManager.showDropIn(configuration: dropInConfigurationDTO, sessionDTO: sessionDTO)
    }

    func showDropInAdvanced(dropInConfigurationDTO: DropInConfigurationDTO, paymentMethodsResponse: String) {
        dropInAdvancedManager.showDropIn(configuration: dropInConfigurationDTO, paymentMethodsResponse: paymentMethodsResponse)
    }

    func onPaymentsResult(paymentsResult: PaymentEventDTO) {
        dropInAdvancedManager.handlePaymentEvent(paymentEventDTO: paymentsResult)
    }

    func onPaymentsDetailsResult(paymentsDetailsResult: PaymentEventDTO) {
        dropInAdvancedManager.handlePaymentEvent(paymentEventDTO: paymentsDetailsResult)
    }

    func onDeleteStoredPaymentMethodResult(deleteStoredPaymentMethodResultDTO: DeletedStoredPaymentMethodResultDTO) {
        dropInSessionManager.onDeleteStoredPaymentMethodResult(deleteStoredPaymentMethodResultDTO: deleteStoredPaymentMethodResultDTO)
        dropInAdvancedManager.onDeleteStoredPaymentMethodResult(deleteStoredPaymentMethodResultDTO: deleteStoredPaymentMethodResultDTO)
    }

    func cleanUpDropInAdvanced() {
        dropInAdvancedManager.cleanUp()
    }
    
    func cleanUpDropInSession() {
        dropInSessionManager.cleanUp()
    }
}
