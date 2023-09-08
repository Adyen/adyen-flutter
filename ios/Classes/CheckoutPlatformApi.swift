import Foundation
@_spi(AdyenInternal)
import Adyen
import AdyenNetworking

//Todo Add config:
// 1) Add Info.plist for adding photo library usage description
// 2) Add url scheme
// 3) Add AppDelegate redirect

class CheckoutPlatformApi : CheckoutPlatformInterface {
    var dropInComponent: DropInComponent?
    private let jsonDecoder = JSONDecoder()
    private let checkoutFlutterApi: CheckoutFlutterApi
    private var viewController : UIViewController?
    private var session: AdyenSession?
    private var dropInSessionDelegate : AdyenSessionDelegate?
    private var dropInSessionPresentationDelegate : PresentationDelegate?
    private var dropInAdvancedFlowDelegate : DropInComponentDelegate?
    private var storedPaymentMethodsDelegate : StoredPaymentMethodsDelegate?
    
    init(checkoutFlutterApi: CheckoutFlutterApi) {
        self.checkoutFlutterApi = checkoutFlutterApi
    }
    
    func getPlatformVersion(completion: @escaping (Result<String, Error>) -> Void) {
        let systemVersion = UIDevice.current.systemVersion
        completion(Result.success(systemVersion))
    }
    
    func startDropInSessionPayment(dropInConfiguration: DropInConfiguration, session: Session) {
        do {
            guard let viewController = getTopMostViewController() else {
                return
            }
            
            self.viewController = viewController
            dropInSessionDelegate = DropInSessionsDelegate(viewController: viewController, checkoutFlutterApi: checkoutFlutterApi)
            dropInSessionPresentationDelegate = DropInSessionsPresentationDelegate()
            let adyenContext = try createAdyenContext(dropInConfiguration: dropInConfiguration)
            let sessionConfiguration = AdyenSession.Configuration(sessionIdentifier: session.id, initialSessionData: session.sessionData, context: adyenContext)
            AdyenSession.initialize(with: sessionConfiguration, delegate: dropInSessionDelegate!, presentationDelegate: dropInSessionPresentationDelegate!) { [weak self] result in
                switch result {
                case let .success(session):
                    self?.session = session
                    let dropInConfiguration = self?.createDropInConfiguration()
                    let dropInComponent = DropInComponent(paymentMethods: session.sessionContext.paymentMethods, context: adyenContext, configuration: dropInConfiguration!)
                    dropInComponent.delegate = session
                    dropInComponent.partialPaymentDelegate = session
                    self?.dropInComponent = dropInComponent
                    self?.viewController?.present(dropInComponent.viewController, animated: true)
                case let .failure(error):
                    self?.checkoutFlutterApi.onDropInSessionResult(sessionPaymentResult: PaymentResult(type: PaymentResultEnum.error, reason: error.localizedDescription)) {}
                }
            }
        } catch let error {
            checkoutFlutterApi.onDropInSessionResult(sessionPaymentResult: PaymentResult(type: PaymentResultEnum.error, reason: error.localizedDescription)) {}
        }
    }
    
    func startDropInAdvancedFlowPayment(dropInConfiguration: DropInConfiguration, paymentMethodsResponse: String) {
        do {
            guard let viewController = getTopMostViewController() else {
                return
            }
            
            self.viewController = viewController
            let adyenContext = try createAdyenContext(dropInConfiguration: dropInConfiguration)
            let paymentMethods = try jsonDecoder.decode(PaymentMethods.self, from:Data(paymentMethodsResponse.utf8))
            let configuration = createDropInConfiguration()
            let dropInComponent = DropInComponent(paymentMethods: paymentMethods,context: adyenContext,configuration: configuration)
            dropInAdvancedFlowDelegate = DropInAdvancedFlowDelegate(checkoutFlutterApi: checkoutFlutterApi, component: dropInComponent)
            storedPaymentMethodsDelegate = DropInAdvancedFlowStoredPaymentMethodsDelegate()
            dropInComponent.delegate = dropInAdvancedFlowDelegate
            dropInComponent.storedPaymentMethodsDelegate = storedPaymentMethodsDelegate
            self.dropInComponent = dropInComponent
            self.viewController?.present(dropInComponent.viewController, animated: true)
        } catch let error {
            let platformCommunicationModel = PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: PaymentResult(type: PaymentResultEnum.error, reason: error.localizedDescription))
            checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: platformCommunicationModel, completion: {})
        }
    }
    
    func getReturnUrl(completion: @escaping (Result<String, Error>) -> Void) {
        completion(Result.failure(PlatformError(errorDescription: "Please use your app url type instead of this method.")))
    }
    
    func onPaymentsResult(paymentsResult: DropInResult) {
        handleDropInResult(dropInResult: paymentsResult)
    }
    
    func onPaymentsDetailsResult(paymentsDetailsResult: DropInResult) {
        handleDropInResult(dropInResult: paymentsDetailsResult)
    }
    
    private func getTopMostViewController() -> UIViewController? {
        var topMostViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        while let presentedViewController = topMostViewController?.presentedViewController {
            let type = String(describing: type(of: presentedViewController))
            // We need to discuss how the SDK should react if a DropInNavigationController is already displayed
            if (type == "DropInNavigationController") {
                return nil;
            } else {
                topMostViewController = presentedViewController
            }
        }
        
        return topMostViewController
    }
    
    private func createAdyenContext(dropInConfiguration: DropInConfiguration) throws  -> AdyenContext  {
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
            return Adyen.Environment.liveEurope
        case .unitedStates:
            return Adyen.Environment.liveUnitedStates
        case .australia:
            return Adyen.Environment.liveAustralia
        case .india:
            return Adyen.Environment.liveIndia
        case .apse:
            return Adyen.Environment.liveApse
        }
    }
    
    private func createDropInConfiguration() -> DropInComponent.Configuration {
        return DropInComponent.Configuration()
    }
    
    private func handleDropInResult(dropInResult: DropInResult) {
        do {
            switch dropInResult.dropInResultType {
            case .finished:
                let resultCode = ResultCode(rawValue: dropInResult.result ?? "")
                let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
                self.dropInComponent?.finalizeIfNeeded(with: success) { [weak self] in
                    self?.dropInComponent?.viewController.presentingViewController?.dismiss(animated: false, completion: {
                        let paymentResult = PaymentResult(type: PaymentResultEnum.finished, result: PaymentResultModel(resultCode: resultCode?.rawValue))
                        self?.checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: paymentResult), completion: {})
                    })
                }
            case .action:
                let jsonData = try JSONSerialization.data(withJSONObject: dropInResult.actionResponse as Any, options: [])
                let result = try JSONDecoder().decode(Action.self, from: jsonData)
                self.dropInComponent?.handle(result)
            case .error:
                let paymentResult = PaymentResult(type: PaymentResultEnum.error, reason: dropInResult.error?.errorMessage)
                self.checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: paymentResult), completion: {})
                self.finalize(false, dropInResult.error?.errorMessage ?? "")
            }
        } catch let error {
            let paymentResult = PaymentResult(type: PaymentResultEnum.error, reason: error.localizedDescription)
            self.checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: paymentResult), completion: {})
            self.finalize(false, "\(error.localizedDescription)")
        }
    }
    
    private func finalize(_ success: Bool, _ message: String) {
        dropInComponent?.finalizeIfNeeded(with: success) { [weak self] in
            guard let self = self else { return }
            self.viewController?.dismiss(animated: true)
        }
    }
}
