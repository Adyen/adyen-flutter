import Foundation
@_spi(AdyenInternal) import Adyen
import AdyenNetworking

// TODO: Add config:
// 1) Add Info.plist for adding photo library usage description
// 2) Add url scheme
// 3) Add AppDelegate redirect

class CheckoutPlatformApi: CheckoutPlatformInterface {
    var dropInComponent: DropInComponent?
    private let jsonDecoder = JSONDecoder()
    private let configurationMapper = ConfigurationMapper()
    private let checkoutFlutterApi: CheckoutFlutterApi
    private let componentFlutterApi: ComponentFlutterInterface
    private var viewController: UIViewController?
    private var session: AdyenSession?
    private let sessionHolder: SessionHolder
    private var dropInSessionDelegate: AdyenSessionDelegate?
    private var dropInAdvancedFlowDelegate: DropInAdvancedFlowDelegate?
    private var dropInSessionStoredPaymentMethodsDelegate: DropInSessionsStoredPaymentMethodsDelegate?
    private var dropInAdvancedFlowStoredPaymentMethodsDelegate: DropInAdvancedFlowStoredPaymentMethodsDelegate?

    init(checkoutFlutterApi: CheckoutFlutterApi, componentFlutterApi: ComponentFlutterInterface, sessionHolder: SessionHolder) {
        self.checkoutFlutterApi = checkoutFlutterApi
        self.componentFlutterApi = componentFlutterApi
        self.sessionHolder = sessionHolder
    }

    func getPlatformVersion(completion: @escaping (Result<String, Error>) -> Void) {
        let systemVersion = UIDevice.current.systemVersion
        completion(Result.success(systemVersion))
    }

    func createSession(sessionId: String, sessionData: String, configuration: Any?, completion: @escaping (Result<SessionDTO, Error>) -> Void) {
        do {
            switch configuration {
            case is CardComponentConfigurationDTO:
                let adyenContext = try (configuration as! CardComponentConfigurationDTO).createAdyenContext()
                let sessionConfiguration = AdyenSession.Configuration(sessionIdentifier: sessionId,
                                                                      initialSessionData: sessionData,
                                                                      context: adyenContext,
                                                                      actionComponent: .init())
                sessionHolder.sessionPresentationDelegate = CardPresentationDelegate(topViewController: getViewController())
                sessionHolder.sessionDelegate = CardSessionFlowDelegate(componentFlutterApi: componentFlutterApi)
                AdyenSession.initialize(with: sessionConfiguration,
                                        delegate: sessionHolder.sessionDelegate!,
                                        presentationDelegate: sessionHolder.sessionPresentationDelegate!) { [weak self] result in
                    switch result {
                    case let .success(session):
                        self?.sessionHolder.session = session
                        // TODO: serialize paymentMethods
                        completion(Result.success(SessionDTO(id: sessionId,
                                                             sessionData: sessionData,
                                                             paymentMethodsJson: "")))
                    case let .failure(error):
                        completion(Result.failure(error))
                    }
                }
            case .none, .some:
                completion(Result.failure(PlatformError(errorDescription: "Configuration is not valid")))
            }
        } catch {
            completion(Result.failure(error))
        }
    }

    func startDropInSessionPayment(dropInConfigurationDTO: DropInConfigurationDTO, session: SessionDTO) {
        do {
            guard let viewController = getViewController() else {
                return
            }

            self.viewController = viewController
            dropInSessionDelegate = DropInSessionsDelegate(viewController: viewController, checkoutFlutterApi: checkoutFlutterApi)
            sessionHolder.sessionPresentationDelegate = DropInSessionsPresentationDelegate()
            let adyenContext = try dropInConfigurationDTO.createAdyenContext()
            let sessionConfiguration = AdyenSession.Configuration(sessionIdentifier: session.id,
                                                                  initialSessionData: session.sessionData,
                                                                  context: adyenContext)
            dropInSessionStoredPaymentMethodsDelegate = DropInSessionsStoredPaymentMethodsDelegate(viewController: viewController,
                                                                                                   checkoutFlutterApi: checkoutFlutterApi)

            AdyenSession.initialize(with: sessionConfiguration,
                                    delegate: dropInSessionDelegate!,
                                    presentationDelegate: sessionHolder.sessionPresentationDelegate!)
            { [weak self] result in
                switch result {
                case let .success(session):
                    do {
                        self?.session = session
                        let dropInConfiguration = try self?.configurationMapper.createDropInConfiguration(dropInConfigurationDTO: dropInConfigurationDTO)
                        let dropInComponent = DropInComponent(paymentMethods: session.sessionContext.paymentMethods,
                                                              context: adyenContext,
                                                              configuration: dropInConfiguration!)
                        dropInComponent.delegate = session
                        dropInComponent.partialPaymentDelegate = session
                        if dropInConfigurationDTO.isRemoveStoredPaymentMethodEnabled {
                            dropInComponent.storedPaymentMethodsDelegate = self?.dropInSessionStoredPaymentMethodsDelegate
                        }
                        self?.dropInComponent = dropInComponent
                        self?.viewController?.present(dropInComponent.viewController, animated: true)
                    } catch {
                        self?.sendSessionError(error: error)
                    }
                case let .failure(error):
                    self?.sendSessionError(error: error)
                }
            }
        } catch {
            sendSessionError(error: error)
        }
    }

    func startDropInAdvancedFlowPayment(dropInConfigurationDTO: DropInConfigurationDTO, paymentMethodsResponse: String) {
        do {
            guard let viewController = getViewController() else {
                return
            }
            self.viewController = viewController
            let adyenContext = try dropInConfigurationDTO.createAdyenContext()
            let paymentMethods = try jsonDecoder.decode(PaymentMethods.self, from: Data(paymentMethodsResponse.utf8))
            let paymentMethodsWithoutGiftCards = removeGiftCardPaymentMethods(paymentMethods: paymentMethods)
            let configuration = try configurationMapper.createDropInConfiguration(dropInConfigurationDTO: dropInConfigurationDTO)
            let dropInComponent = DropInComponent(paymentMethods: paymentMethodsWithoutGiftCards,
                                                  context: adyenContext,
                                                  configuration: configuration)
            dropInAdvancedFlowDelegate = DropInAdvancedFlowDelegate(checkoutFlutterApi: checkoutFlutterApi)
            dropInAdvancedFlowDelegate?.dropInInteractorDelegate = self
            dropInComponent.delegate = dropInAdvancedFlowDelegate

            if dropInConfigurationDTO.isRemoveStoredPaymentMethodEnabled == true {
                dropInAdvancedFlowStoredPaymentMethodsDelegate = DropInAdvancedFlowStoredPaymentMethodsDelegate(viewController: viewController,
                                                                                                                checkoutFlutterApi: checkoutFlutterApi)
                dropInComponent.storedPaymentMethodsDelegate = dropInAdvancedFlowStoredPaymentMethodsDelegate
            }
            self.dropInComponent = dropInComponent
            self.viewController?.present(dropInComponent.viewController, animated: true)
        } catch {
            let platformCommunicationModel = PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription))
            checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: platformCommunicationModel, completion: { _ in })
        }
    }

    func getReturnUrl(completion: @escaping (Result<String, Error>) -> Void) {
        completion(Result.failure(PlatformError(errorDescription: "Please use your app url type instead of this method.")))
    }

    func onPaymentsResult(paymentsResult: PaymentFlowOutcomeDTO) {
        handlePaymentFlowOutcome(paymentFlowOutcomeDTO: paymentsResult)
    }

    func onPaymentsDetailsResult(paymentsDetailsResult: PaymentFlowOutcomeDTO) {
        handlePaymentFlowOutcome(paymentFlowOutcomeDTO: paymentsDetailsResult)
    }

    func onDeleteStoredPaymentMethodResult(deleteStoredPaymentMethodResultDTO: DeletedStoredPaymentMethodResultDTO) {
        dropInSessionStoredPaymentMethodsDelegate?.handleDisableResult(isSuccessfullyRemoved: deleteStoredPaymentMethodResultDTO.isSuccessfullyRemoved)
        dropInAdvancedFlowStoredPaymentMethodsDelegate?.handleDisableResult(isSuccessfullyRemoved: deleteStoredPaymentMethodResultDTO.isSuccessfullyRemoved)
    }

    func enableLogging(loggingEnabled: Bool) {
        AdyenLogging.isEnabled = loggingEnabled
    }

    func cleanUpDropIn() {
        sessionHolder.sessionPresentationDelegate = nil
        dropInSessionDelegate = nil
        dropInSessionStoredPaymentMethodsDelegate = nil
        dropInAdvancedFlowDelegate?.dropInInteractorDelegate = nil
        dropInAdvancedFlowDelegate = nil
        dropInAdvancedFlowStoredPaymentMethodsDelegate = nil
        viewController = nil
    }

    private func getViewController() -> UIViewController? {
        var rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        while let presentedViewController = rootViewController?.presentedViewController {
            let type = String(describing: type(of: presentedViewController))
            // TODO: - We need to discuss how the SDK should react if a DropInNavigationController is already displayed
            if type == "DropInNavigationController" {
                return nil
            } else {
                rootViewController = presentedViewController
            }
        }

        return rootViewController
    }

    private func handlePaymentFlowOutcome(paymentFlowOutcomeDTO: PaymentFlowOutcomeDTO) {
        switch paymentFlowOutcomeDTO.paymentFlowResultType {
        case .finished:
            onDropInResultFinished(paymentFlowOutcome: paymentFlowOutcomeDTO)
        case .action:
            onDropInResultAction(paymentFlowOutcome: paymentFlowOutcomeDTO)
        case .error:
            onDropInResultError(paymentFlowOutcome: paymentFlowOutcomeDTO)
        }
    }

    private func onDropInResultFinished(paymentFlowOutcome: PaymentFlowOutcomeDTO) {
        let resultCode = ResultCode(rawValue: paymentFlowOutcome.result ?? "")
        let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
        finalizeAndDismiss(success: success, completion: { [weak self] in
            let paymentResult = PaymentResultDTO(type: PaymentResultEnum.finished, result: PaymentResultModelDTO(resultCode: resultCode?.rawValue))
            self?.checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: paymentResult), completion: { _ in })
        })
    }

    private func onDropInResultAction(paymentFlowOutcome: PaymentFlowOutcomeDTO) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: paymentFlowOutcome.actionResponse as Any, options: [])
            let result = try JSONDecoder().decode(Action.self, from: jsonData)
            dropInComponent?.handle(result)
        } catch {
            let paymentResult = PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription)
            checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: paymentResult), completion: { _ in })
            finalizeAndDismiss(success: false) {}
        }
    }

    private func onDropInResultError(paymentFlowOutcome: PaymentFlowOutcomeDTO) {
        dropInComponent?.stopLoading()

        if paymentFlowOutcome.error?.dismissDropIn == true {
            let paymentResult = PaymentResultDTO(type: PaymentResultEnum.error, reason: paymentFlowOutcome.error?.errorMessage)
            checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: paymentResult), completion: { _ in })
            finalizeAndDismiss(success: false) {}
        } else {
            dropInComponent?.finalizeIfNeeded(with: false, completion: {})
            let localizationParameters = (dropInComponent as? Localizable)?.localizationParameters
            let title = localizedString(.errorTitle, localizationParameters)
            let alertController = UIAlertController(title: title,
                                                    message: paymentFlowOutcome.error?.errorMessage,
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: localizedString(.dismissButton, localizationParameters), style: .cancel))
            viewController?.adyen.topPresenter.present(alertController, animated: true)
        }
    }

    private func removeGiftCardPaymentMethods(paymentMethods: PaymentMethods) -> PaymentMethods {
        let storedPaymentMethods = paymentMethods.stored.filter { !($0.type == PaymentMethodType.giftcard) }
        let paymentMethods = paymentMethods.regular.filter { !($0.type == PaymentMethodType.giftcard) }
        return PaymentMethods(regular: paymentMethods, stored: storedPaymentMethods)
    }

    private func sendSessionError(error: Error) {
        let platformCommunicationModel = PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription))
        checkoutFlutterApi.onDropInSessionPlatformCommunication(platformCommunicationModel: platformCommunicationModel, completion: { _ in })
    }
}

extension CheckoutPlatformApi: DropInInteractorDelegate {
    func finalizeAndDismiss(success: Bool, completion: @escaping (() -> Void)) {
        dropInComponent?.finalizeIfNeeded(with: success) { [weak self] in
            self?.viewController?.dismiss(animated: true, completion: {
                completion()
            })
        }
    }
}
