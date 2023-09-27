import Foundation
@_spi(AdyenInternal)
import Adyen
import AdyenNetworking

//TODO: Add config:
// 1) Add Info.plist for adding photo library usage description
// 2) Add url scheme
// 3) Add AppDelegate redirect

class CheckoutPlatformApi : CheckoutPlatformInterface {
    var dropInComponent: DropInComponent?
    private let jsonDecoder = JSONDecoder()
    private let configurationMapper = ConfigurationMapper()
    private let checkoutFlutterApi: CheckoutFlutterApi
    private var viewController : UIViewController?
    private var session: AdyenSession?
    private var dropInSessionDelegate : AdyenSessionDelegate?
    private var dropInSessionPresentationDelegate : PresentationDelegate?
    private var dropInAdvancedFlowDelegate : DropInComponentDelegate?
    private var dropInSessionStoredPaymentMethodsDelegate: DropInSessionsStoredPaymentMethodsDelegate?
    private var dropInAdvancedFlowStoredPaymentMethodsDelegate : DropInAdvancedFlowStoredPaymentMethodsDelegate?
    
    init(checkoutFlutterApi: CheckoutFlutterApi) {
        self.checkoutFlutterApi = checkoutFlutterApi
    }
    
    func getPlatformVersion(completion: @escaping (Result<String, Error>) -> Void) {
        let systemVersion = UIDevice.current.systemVersion
        completion(Result.success(systemVersion))
    }
    
    func startDropInSessionPayment(dropInConfigurationDTO: DropInConfigurationDTO, session: SessionDTO) {
        do {
            guard let viewController = getViewController() else {
                return
            }
            
            self.viewController = viewController
            dropInSessionDelegate = DropInSessionsDelegate(viewController: viewController, checkoutFlutterApi: checkoutFlutterApi)
            dropInSessionPresentationDelegate = DropInSessionsPresentationDelegate()
            let adyenContext = try createAdyenContext(dropInConfiguration: dropInConfigurationDTO)
            let sessionConfiguration = AdyenSession.Configuration(sessionIdentifier: session.id,
                                                                  initialSessionData: session.sessionData,
                                                                  context: adyenContext)
            self.dropInSessionStoredPaymentMethodsDelegate = DropInSessionsStoredPaymentMethodsDelegate(checkoutFlutterApi: self.checkoutFlutterApi)

            AdyenSession.initialize(with: sessionConfiguration,
                                    delegate: dropInSessionDelegate!,
                                    presentationDelegate: dropInSessionPresentationDelegate!) { [weak self] result in
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
                        if (dropInConfigurationDTO.isRemoveStoredPaymentMethodEnabled == true) {
                            dropInComponent.storedPaymentMethodsDelegate = self?.dropInSessionStoredPaymentMethodsDelegate
                        }
                        self?.dropInComponent = dropInComponent
                        self?.viewController?.present(dropInComponent.viewController, animated: true)
                    } catch let error {
                        let platformCommunicationModel = PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription))
                        self?.checkoutFlutterApi.onDropInSessionPlatformCommunication(platformCommunicationModel: platformCommunicationModel, completion: {})
                    }
                case let .failure(error):
                    let platformCommunicationModel = PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription))
                    self?.checkoutFlutterApi.onDropInSessionPlatformCommunication(platformCommunicationModel: platformCommunicationModel, completion: {})
                }
            }
        } catch let error {
            let platformCommunicationModel = PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription))
            checkoutFlutterApi.onDropInSessionPlatformCommunication(platformCommunicationModel: platformCommunicationModel, completion: {})
        }
    }
    
    func startDropInAdvancedFlowPayment(dropInConfigurationDTO: DropInConfigurationDTO, paymentMethodsResponse: String) {
        do {
            guard let viewController = getViewController() else {
                return
            }
            self.viewController = viewController
            let adyenContext = try createAdyenContext(dropInConfiguration: dropInConfigurationDTO)
            let paymentMethods = try jsonDecoder.decode(PaymentMethods.self, from:Data(paymentMethodsResponse.utf8))
            let paymentMethodsWithoutGiftCards = removeGiftCardPaymentMethods(paymentMethods: paymentMethods)
            let configuration = try configurationMapper.createDropInConfiguration(dropInConfigurationDTO: dropInConfigurationDTO)
            let dropInComponent = DropInComponent(paymentMethods: paymentMethodsWithoutGiftCards,
                                                  context: adyenContext,
                                                  configuration: configuration)
            dropInAdvancedFlowDelegate = DropInAdvancedFlowDelegate(checkoutFlutterApi: checkoutFlutterApi, component: dropInComponent)
            dropInAdvancedFlowStoredPaymentMethodsDelegate = DropInAdvancedFlowStoredPaymentMethodsDelegate(checkoutFlutterApi: checkoutFlutterApi)
            dropInComponent.delegate = dropInAdvancedFlowDelegate
            if (dropInConfigurationDTO.isRemoveStoredPaymentMethodEnabled == true) {
                dropInComponent.storedPaymentMethodsDelegate = dropInAdvancedFlowStoredPaymentMethodsDelegate
            }
            self.dropInComponent = dropInComponent
            self.viewController?.present(dropInComponent.viewController, animated: true)
        } catch let error {
            let platformCommunicationModel = PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription))
            checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: platformCommunicationModel, completion: {})
        }
    }
    
    func getReturnUrl(completion: @escaping (Result<String, Error>) -> Void) {
        completion(Result.failure(PlatformError(errorDescription: "Please use your app url type instead of this method.")))
    }
    
    func onPaymentsResult(paymentsResult: DropInResultDTO) {
        handleDropInResult(dropInResult: paymentsResult)
    }
    
    func onPaymentsDetailsResult(paymentsDetailsResult: DropInResultDTO) {
        handleDropInResult(dropInResult: paymentsDetailsResult)
    }
    
    func onDeleteStoredPaymentMethodResult(deleteStoredPaymentMethodResultDTO: DeletedStoredPaymentMethodResultDTO) {
        dropInSessionStoredPaymentMethodsDelegate?.handleDisableResult(isSuccessfullyRemoved: deleteStoredPaymentMethodResultDTO.isSuccessfullyRemoved)
        dropInAdvancedFlowStoredPaymentMethodsDelegate?.handleDisableResult(isSuccessfullyRemoved: deleteStoredPaymentMethodResultDTO.isSuccessfullyRemoved)
    }
    
    private func getViewController() -> UIViewController? {
        var rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        while let presentedViewController = rootViewController?.presentedViewController {
            let type = String(describing: type(of: presentedViewController))
            // TODO: - We need to discuss how the SDK should react if a DropInNavigationController is already displayed
            if (type == "DropInNavigationController") {
                return nil;
            } else {
                rootViewController = presentedViewController
            }
        }
        
        return rootViewController
    }
    
    private func createAdyenContext(dropInConfiguration: DropInConfigurationDTO) throws  -> AdyenContext  {
        let environment = mapToEnvironment(environment: dropInConfiguration.environment)
        let apiContext = try APIContext(environment: environment, clientKey: dropInConfiguration.clientKey)
        let value = Int(dropInConfiguration.amount.value)
        guard let currencyCode : String = dropInConfiguration.amount.currency else {
            throw BalanceChecker.Error.unexpectedCurrencyCode
        }
        let amount = Adyen.Amount(value: value, currencyCode: currencyCode)
        return AdyenContext(apiContext: apiContext, payment: Payment(amount: amount, countryCode: dropInConfiguration.countryCode))
    }
    
    private func mapToEnvironment(environment: Environment) -> Adyen.Environment {
        switch environment {
        case .test:
            return Adyen.Environment.test
        case .europe:
            return .liveEurope
        case .unitedStates:
            return .liveUnitedStates
        case .australia:
            return .liveAustralia
        case .india:
            return .liveIndia
        case .apse:
            return .liveApse
        }
    }
    
    
    private func handleDropInResult(dropInResult: DropInResultDTO) {
        do {
            switch dropInResult.dropInResultType {
            case .finished:
                onDropInResultFinished(dropInResult: dropInResult)
            case .action:
                try onDropInResultAction(dropInResult: dropInResult)
            case .error:
                onDropInResultError(dropInResult: dropInResult)
            }
        } catch let error {
            let paymentResult = PaymentResultDTO(type: PaymentResultEnum.error, reason: error.localizedDescription)
            self.checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: paymentResult), completion: {})
            self.finalize(false, "\(error.localizedDescription)")
        }
    }
    
    private func onDropInResultFinished(dropInResult: DropInResultDTO) {
        let resultCode = ResultCode(rawValue: dropInResult.result ?? "")
        let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
        self.dropInComponent?.finalizeIfNeeded(with: success) { [weak self] in
            self?.dropInComponent?.viewController.presentingViewController?.dismiss(animated: false, completion: {
                let paymentResult = PaymentResultDTO(type: PaymentResultEnum.finished, result: PaymentResultModelDTO(resultCode: resultCode?.rawValue))
                self?.checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: paymentResult), completion: {})
            })
        }
    }
    
    private func onDropInResultAction(dropInResult: DropInResultDTO) throws {
        let jsonData = try JSONSerialization.data(withJSONObject: dropInResult.actionResponse as Any, options: [])
        let result = try JSONDecoder().decode(Action.self, from: jsonData)
        self.dropInComponent?.handle(result)
    }
    
    private func onDropInResultError(dropInResult: DropInResultDTO) {
        let paymentResult = PaymentResultDTO(type: PaymentResultEnum.error, reason: dropInResult.error?.errorMessage)
        self.checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: paymentResult), completion: {})
        self.finalize(false, dropInResult.error?.errorMessage ?? "")
    }
    
    private func finalize(_ success: Bool, _ message: String) {
        dropInComponent?.finalizeIfNeeded(with: success) { [weak self] in
            guard let self = self else { return }
            self.viewController?.dismiss(animated: true)
        }
    }
    
    private func removeGiftCardPaymentMethods(paymentMethods: PaymentMethods) -> PaymentMethods {
        let storedPaymentMethods = paymentMethods.stored.filter { !($0.type == PaymentMethodType.giftcard)}
        let paymentMethods = paymentMethods.regular.filter { !($0.type == PaymentMethodType.giftcard)}
        return PaymentMethods(regular: paymentMethods, stored: storedPaymentMethods)
    }
}
