
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
    private let checkoutFlutterApi: CheckoutFlutterApi
    private var session: AdyenSession?
    private var dropInComponent: DropInComponent?
    private var viewController : UIViewController?
    private let jsonDecoder = JSONDecoder()

    init(checkoutFlutterApi: CheckoutFlutterApi) {
        self.checkoutFlutterApi = checkoutFlutterApi
    }

    func getPlatformVersion(completion: @escaping (Result<String, Error>) -> Void) {
        let systemVersion = UIDevice.current.systemVersion
        completion(Result.success(systemVersion))
    }
    
    func startDropInSessionPayment(dropInConfiguration: DropInConfiguration, session: Session) {
        do {
            viewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
            let adyenContext = try createAdyenContext(dropInConfiguration: dropInConfiguration)
            let configuration = AdyenSession.Configuration(sessionIdentifier: session.id,
                                                           initialSessionData: session.sessionData,
                                                           context: adyenContext)
            DispatchQueue.main.async {
                AdyenSession.initialize(with: configuration, delegate: self, presentationDelegate: self) { [weak self] result in
                    switch result {
                    case let .success(session):
                        self?.session = session
                        let dropInConfiguration = self?.createDropInConfiguration()
                        let dropInComponent = DropInComponent(paymentMethods: session.sessionContext.paymentMethods,
                                                              context: adyenContext,
                                                              configuration: dropInConfiguration!)
                        dropInComponent.delegate = session
                        dropInComponent.partialPaymentDelegate = session
                        self?.dropInComponent = dropInComponent
                        self?.viewController?.present(dropInComponent.viewController, animated: true)
                    case let .failure(error):
                        print("Native sdk error: \(error.localizedDescription)")
                        self?.checkoutFlutterApi.onDropInSessionResult(sessionPaymentResult: PaymentResult(type: PaymentResultEnum.error, reason: error.localizedDescription)) {}
                    }
                }
            }
        } catch let error {
            print("Native sdk error: \(error.localizedDescription)")
            checkoutFlutterApi.onDropInSessionResult(sessionPaymentResult: PaymentResult(type: PaymentResultEnum.error, reason: error.localizedDescription)) {}
        }
    }


    func startDropInAdvancedFlowPayment(dropInConfiguration: DropInConfiguration, paymentMethodsResponse: String) {
        do {
            viewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
            let adyenContext = try createAdyenContext(dropInConfiguration: dropInConfiguration)
            let paymentMethods = try jsonDecoder.decode(PaymentMethods.self, from:Data(paymentMethodsResponse.utf8))
            let configuration = createDropInConfiguration()
            let dropInComponent = DropInComponent(paymentMethods: paymentMethods,context: adyenContext,configuration: configuration)
            dropInComponent.delegate = self
            dropInComponent.storedPaymentMethodsDelegate = self
            self.dropInComponent = dropInComponent
            viewController?.present(dropInComponent.viewController, animated: true)
        } catch let error {
            checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, dropInResult: DropInResult(type: DropInResultEnum.error, reason: error.localizedDescription)), completion: {})
        }
    }

    func getReturnUrl(completion: @escaping (Result<String, Error>) -> Void) {
        completion(Result.success(""))
    }

    func onPaymentsResult(paymentsResult: DropInResult) throws {
        print(paymentsResult)
        handleResponse(result: paymentsResult)
    }

    func onPaymentsDetailsResult(paymentsDetailsResult: DropInResult) throws {
        print(paymentsDetailsResult)
        handleResponse(result: paymentsDetailsResult)
    }
    
    private func createAdyenContext(dropInConfiguration: DropInConfiguration) throws  -> AdyenContext  {
        let apiContext = try APIContext(environment: mapToEnvironment(environment: dropInConfiguration.environment), clientKey: dropInConfiguration.clientKey)
        let value: Int = Int(dropInConfiguration.amount.value)
        guard let currencyCode : String = dropInConfiguration.amount.currency else {
            throw BalanceChecker.Error.unexpectedCurrencyCode
        }
        let amount = Adyen.Amount(value: value, currencyCode: currencyCode)
        let adyenContext = AdyenContext(apiContext: apiContext, payment: Payment(amount: amount, countryCode: dropInConfiguration.countryCode))
        return adyenContext
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
        let dropInConfiguration = DropInComponent.Configuration()
        return dropInConfiguration
    }
    
    private func handleResponse(result: [String : Any?]) {
        do {
            if let action = result["action"] {
                let jsonData = try JSONSerialization.data(withJSONObject: action, options: [])
                let decoder = JSONDecoder()
                let result = try decoder.decode(Action.self, from: jsonData)
                self.dropInComponent?.handle(result)
            } else if result.keys.contains("resultCode") {

                let resultCode = ResultCode(rawValue: result["resultCode"] as! String)

                let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
                self.dropInComponent?.finalizeIfNeeded(with: success) { [weak self] in
                    print("dismiss")

                    self?.dropInComponent?.viewController.dismiss(animated: false)
                    self?.dropInComponent?.viewController.dismiss(animated: false)
                }
            }
        } catch let error {
            print(error)
        }

    }


    private func finalize(_ success: Bool, _ message: String) {
        dropInComponent?.finalizeIfNeeded(with: success) { [weak self] in
            guard let self = self else { return }
            self.viewController?.dismiss(animated: true)
        }
    }
}

extension CheckoutPlatformApi: AdyenSessionDelegate {
    func didComplete(with resultCode: SessionPaymentResultCode, component: Component, session: AdyenSession) {
        self.viewController?.dismiss(animated: false, completion: {
            self.checkoutFlutterApi.onDropInSessionResult(sessionPaymentResult: PaymentResult(
                type: PaymentResultEnum.finished,
                result: SessionPaymentResultModel(sessionId: session.sessionContext.identifier, sessionData: session.sessionContext.data, resultCode: resultCode.rawValue)), completion: {})
        })
    }
    
    func didFail(with error: Error, from component: Component, session: AdyenSession) {
        self.viewController?.dismiss(animated: true)
        print("Native sdk error: \(error.localizedDescription)")
        checkoutFlutterApi.onDropInSessionResult(sessionPaymentResult: PaymentResult(type: PaymentResultEnum.cancelledByUser, reason: error.localizedDescription)) {}
    }
    
    func didOpenExternalApplication(component: ActionComponent, session: AdyenSession) {
        print("external")
    }
}

extension CheckoutPlatformApi: PresentationDelegate {
    func present(component: PresentableComponent) {
        print("presentable component")
        //This is required later when integrating components
    }
}


//AdvancedFlow
extension CheckoutPlatformApi: DropInComponentDelegate {

    func didSubmit(_ data: PaymentComponentData, from component: PaymentComponent, in dropInComponent: AnyDropInComponent) {
        do {
            let componentData = PaymentComponentDataResponse(amount: data.amount, paymentMethod: data.paymentMethod.encodable, storePaymentMethod: data.storePaymentMethod, order: data.order, amountToPay: data.order?.remainingAmount, installments: data.installments, shopperName: data.shopperName, emailAddress: data.emailAddress, telephoneNumber: data.telephoneNumber, browserInfo: data.browserInfo, checkoutAttemptId: data.checkoutAttemptId, billingAddress: data.billingAddress, deliveryAddress: data.deliveryAddress, socialSecurityNumber: data.socialSecurityNumber, delegatedAuthenticationData: data.delegatedAuthenticationData)

            let json = try JSONEncoder().encode(componentData)
            let jsonString = String(data: json, encoding: .utf8)
            //TODO discuss to use an actual class instead of json
            checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel:PlatformCommunicationModel(type: PlatformCommunicationType.paymentComponent, data:jsonString ), completion: {})
        } catch let error {
            print(error.localizedDescription)
        }
    }

    func didFail(with error: Error, from component: PaymentComponent, in dropInComponent: AnyDropInComponent) {
        print(error)
        self.dropInComponent?.viewController.dismiss(animated: true)
    }

    func didProvide(_ data: ActionComponentData, from component: ActionComponent, in dropInComponent: AnyDropInComponent) {
        print("did provide")
        do {
            let actionComponentData = ActionComponentDataModel(details: data.details.encodable, paymentData: data.paymentData)
            let json = try JSONEncoder().encode(actionComponentData)
            let jsonString = String(data: json, encoding: .utf8)
            checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel:PlatformCommunicationModel(type: PlatformCommunicationType.additionalDetails, data:jsonString ), completion: {})
        } catch let error {
            print(error.localizedDescription)
        }
    }

    func didComplete(from component: ActionComponent, in dropInComponent: AnyDropInComponent) {
        print("did complete")
    }

    func didFail(with error: Error, from component: ActionComponent, in dropInComponent: AnyDropInComponent) {
        print(error)
        self.dropInComponent?.viewController.dismiss(animated: true)
    }

    internal func didCancel(component: PaymentComponent, from dropInComponent: AnyDropInComponent) {
        // Handle the event when the user closes a PresentableComponent.
        print("User did close: \(component.paymentMethod.name)")
        self.dropInComponent?.viewController.dismiss(animated: true)
    }

    internal func didFail(with error: Error, from dropInComponent: AnyDropInComponent) {
        print(error)
        self.dropInComponent?.viewController.dismiss(animated: true)
    }

    private func handleAction(action: Action) {
        print("has action")
        self.dropInComponent?.handle(action)
    }

}

extension CheckoutPlatformApi: StoredPaymentMethodsDelegate {
    internal func disable(storedPaymentMethod: StoredPaymentMethod, completion: @escaping (Bool) -> Void) {
        print("stored disabled")
    }
}
