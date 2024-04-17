@_spi(AdyenInternal) import Adyen

class DropInSessionManager: BaseDropInManager {
    private let dropInFlutterApi: DropInFlutterInterface
    private var sessionDelegate: AdyenSessionDelegate?
    private var sessionPresentationDelegate: PresentationDelegate?
    private var sessionStoredPaymentMethodsDelegate: DropInSessionStoredPaymentMethodsDelegate?
    private var session: AdyenSession?
    
    init(
        dropInFlutterApi: DropInFlutterInterface
    ) {
        self.dropInFlutterApi = dropInFlutterApi
    }
    
    func createSession(
        adyenContext: AdyenContext,
        sessionId: String,
        sessionData: String,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) {
        let sessionDelegate = DropInSessionDelegate(dropInFlutterApi: dropInFlutterApi, finalizeAndDismiss: finalizeAndDismiss(success:completion:))
        let sessionPresentationDelegate = DropInSessionPresentationDelegate()
        let sessionConfiguration = AdyenSession.Configuration(
            sessionIdentifier: sessionId,
            initialSessionData: sessionData,
            context: adyenContext,
            actionComponent: .init()
        )
        self.sessionDelegate = sessionDelegate
        self.sessionPresentationDelegate = sessionPresentationDelegate
        AdyenSession.initialize(
            with: sessionConfiguration,
            delegate: sessionDelegate,
            presentationDelegate: sessionPresentationDelegate
        ) { [weak self] result in
            switch result {
            case let .success(session):
                do {
                    self?.session = session
                    let paymentMethods = try JSONEncoder().encode(session.sessionContext.paymentMethods)
                    let encodedPaymentMethods = String(data: paymentMethods, encoding: .utf8) ?? ""
                    completion(Result.success(SessionDTO(
                        id: sessionId,
                        sessionData: sessionData,
                        paymentMethodsJson: encodedPaymentMethods
                    )))
                } catch {
                    self?.cleanUp()
                    completion(Result.failure(error))
                }
            case let .failure(error):
                self?.cleanUp()
                completion(Result.failure(error))
            }
        }
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
            dropInComponent.delegate = session
            dropInComponent.partialPaymentDelegate = session
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
        sessionDelegate = nil
        sessionPresentationDelegate = nil
        sessionStoredPaymentMethodsDelegate = nil
        session = nil
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
