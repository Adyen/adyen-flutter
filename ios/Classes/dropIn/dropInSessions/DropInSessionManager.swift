@_spi(AdyenInternal) import Adyen

class DropInSessionManager: BaseDropInManager, SessionSetupProtocol {
    private let dropInFlutterApi: DropInFlutterInterface
    private var sessionStoredPaymentMethodsDelegate: DropInSessionStoredPaymentMethodsDelegate?
    var sessionWrapper: SessionWrapper?

    init(
        dropInFlutterApi: DropInFlutterInterface
    ) {
        self.dropInFlutterApi = dropInFlutterApi
    }
    
    func setupSession(
        adyenContext: AdyenContext,
        sessionId: String,
        sessionData: String,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) {
        let sessionDelegate = DropInSessionDelegate(dropInFlutterApi: dropInFlutterApi, finalizeAndDismiss: finalizeAndDismiss(success:completion:))
        let sessionPresentationDelegate = DropInSessionPresentationDelegate()
        sessionWrapper = SessionWrapper()
        sessionWrapper?.setup(
            adyenContext: adyenContext,
            sessionId: sessionId,
            sessionData: sessionData,
            sessionDelegate: sessionDelegate,
            sessionPresentationDelegate: sessionPresentationDelegate,
            completion: completion
        )
    }
    
    func showDropIn(configuration: DropInConfigurationDTO, sessionDTO: SessionDTO) {
        do {
            guard let viewController = getViewController() else {
                return
            }
           
            let adyenContext = try configuration.createAdyenContext()
            let paymentMethods = try JSONDecoder().decode(PaymentMethods.self, from: Data(sessionDTO.paymentMethodsJson.utf8))
            let paymentMethodsWithoutGiftCards = removeGiftCardPaymentMethods(paymentMethods: paymentMethods)
            let dropInConfiguration = try configuration.mapToDropInConfiguration()
            let dropInComponent = DropInComponent(
                paymentMethods: paymentMethodsWithoutGiftCards,
                context: adyenContext,
                configuration: dropInConfiguration
            )
            dropInComponent.delegate = sessionWrapper?.session
            dropInComponent.partialPaymentDelegate = sessionWrapper?.session
            if configuration.isRemoveStoredPaymentMethodEnabled {
                sessionStoredPaymentMethodsDelegate = DropInSessionStoredPaymentMethodsDelegate(
                    viewController: viewController,
                    dropInFlutterApi: dropInFlutterApi
                )
                dropInComponent.storedPaymentMethodsDelegate = sessionStoredPaymentMethodsDelegate
            }
            self.viewController = viewController
            self.dropInComponent = dropInComponent
            viewController.present(dropInComponent.viewController, animated: true)
        } catch {
            cleanUp()
            sendSessionError(error: error)
        }
    }
    
    func onDeleteStoredPaymentMethodResult(deleteStoredPaymentMethodResultDTO: DeletedStoredPaymentMethodResultDTO) {
        sessionStoredPaymentMethodsDelegate?.handleDisableResult(
            isSuccessfullyRemoved: deleteStoredPaymentMethodResultDTO.isSuccessfullyRemoved)
    }
    
    func cleanUp() {
        sessionWrapper?.reset()
        sessionStoredPaymentMethodsDelegate = nil
        dropInComponent = nil
        viewController = nil
    }
    
    private func sendSessionError(error: Error) {
        let platformCommunicationModel = PlatformCommunicationModel(
            type: PlatformCommunicationType.result,
            paymentResult: PaymentResultDTO(
                type: PaymentResultEnum.error,
                reason: error.localizedDescription
            )
        )
        dropInFlutterApi.onDropInSessionPlatformCommunication(
            platformCommunicationModel: platformCommunicationModel,
            completion: { _ in }
        )
    }
}
