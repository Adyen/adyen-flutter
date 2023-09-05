import Foundation
@_spi(AdyenInternal)
import Adyen
@_spi(AdyenInternal)
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
    private var dropInSessionsDelegate : AdyenSessionDelegate?
    private var dropInSessionsPresentationDelegate : PresentationDelegate?
    private var dropInAdvancedFlowDelegate : DropInComponentDelegate?
    private var storedPaymentMethodsDelegate : StoredPaymentMethodsDelegate?
    private let actionKey = "action"
    private let resultCodeKey = "resultCode"
    
    init(checkoutFlutterApi: CheckoutFlutterApi) {
        self.checkoutFlutterApi = checkoutFlutterApi
    }

    func getPlatformVersion(completion: @escaping (Result<String, Error>) -> Void) {
        let systemVersion = UIDevice.current.systemVersion
        completion(Result.success(systemVersion))
    }
    
    func startDropInSessionPayment(dropInConfiguration: DropInConfiguration, session: Session) {
        do {
            guard let viewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController else {
                return
            }

            self.viewController = viewController
            dropInSessionsDelegate = DropInSessionsDelegate(viewController: viewController, checkoutFlutterApi: checkoutFlutterApi)
            dropInSessionsPresentationDelegate = DropInSessionsPresentationDelegate()
            let adyenContext = try createAdyenContext(dropInConfiguration: dropInConfiguration)
            let configuration = AdyenSession.Configuration(sessionIdentifier: session.id, initialSessionData: session.sessionData, context: adyenContext)
            AdyenSession.initialize(with: configuration, delegate: self.dropInSessionsDelegate!, presentationDelegate: self.dropInSessionsPresentationDelegate!) { [weak self] result in
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
                    self?.checkoutFlutterApi.onDropInSessionResult(sessionDropInResult: DropInResult(type: DropInResultEnum.error, errorReason: error.localizedDescription)) {}
                }
            }
        } catch let error {
            checkoutFlutterApi.onDropInSessionResult(sessionDropInResult: DropInResult(type: DropInResultEnum.error, errorReason: error.localizedDescription)) {}
        }
    }


    func startDropInAdvancedFlowPayment(dropInConfiguration: DropInConfiguration, paymentMethodsResponse: String) {
        do {
            guard let viewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController else {
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
            let platformCommunicationModel = PlatformCommunicationModel(type: PlatformCommunicationType.result, dropInResult: DropInResult(type: DropInResultEnum.error, errorReason: error.localizedDescription))
            checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: platformCommunicationModel, completion: {})
        }
    }

    func getReturnUrl(completion: @escaping (Result<String, Error>) -> Void) {
        completion(Result.failure(PlatformError(errorDescription: "Please use your app url type instead of this method.")))
    }

    func onPaymentsResult(paymentsResult: DropInResult) {
        handleResponse(result: paymentsResult)
    }

    func onPaymentsDetailsResult(paymentsDetailsResult: DropInResult) {
        handleResponse(result: paymentsDetailsResult)
    }
        
    private func createAdyenContext(dropInConfiguration: DropInConfiguration) throws  -> AdyenContext  {
        let apiContext = try APIContext(environment: mapToEnvironment(environment: dropInConfiguration.environment), clientKey: dropInConfiguration.clientKey)
        let value: Int = Int(dropInConfiguration.amount.value)
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
    
    private func handleResponse(result: [String : Any?]) {
        do {
            if (result.keys.contains(actionKey)) {
                let action = result[actionKey]
                let jsonData = try JSONSerialization.data(withJSONObject: action as! [String: Any], options: [])
                let result = try JSONDecoder().decode(Action.self, from: jsonData)
                self.dropInComponent?.handle(result)
            } else if (result.keys.contains(resultCodeKey)) {
                let resultCode = ResultCode(rawValue: result[resultCodeKey] as! String)
                let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
                self.dropInComponent?.finalizeIfNeeded(with: success) { [weak self] in
                    self?.dropInComponent?.viewController.presentingViewController?.dismiss(animated: false, completion: {
                        let dropInResult = DropInResult(type: DropInResultEnum.finished, result: PaymentResult(resultCode: resultCode?.rawValue))
                        self?.checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, dropInResult: dropInResult), completion: {})
                    })
                }
            } else {
                let dropInResult = DropInResult(type: DropInResultEnum.error, errorReason: "\(String(describing: result["message"]!!))")
                self.checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, dropInResult: dropInResult), completion: {})
                self.finalize(false, "\(result)")
            }
        } catch let error {
            let dropInResult = DropInResult(type: DropInResultEnum.error, errorReason: error.localizedDescription)
            self.checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, dropInResult: dropInResult), completion: {})
            self.finalize(false, "\(result)")
        }
    }

    private func finalize(_ success: Bool, _ message: String) {
        dropInComponent?.finalizeIfNeeded(with: success) { [weak self] in
            guard let self = self else { return }
            self.viewController?.dismiss(animated: true)
        }
    }
}
