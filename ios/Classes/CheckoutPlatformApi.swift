import Foundation
@_spi(AdyenInternal)
import Adyen
import AdyenNetworking
import PassKit

//TODO: Add config:
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
    
    func startDropInSessionPayment(dropInConfigurationDTO: DropInConfigurationDTO, session: Session) {
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
            AdyenSession.initialize(with: sessionConfiguration,
                                    delegate: dropInSessionDelegate!,
                                    presentationDelegate: dropInSessionPresentationDelegate!) { [weak self] result in
                switch result {
                case let .success(session):
                    do {
                        self?.session = session
                        let dropInConfiguration = try self?.createDropInConfiguration(dropInConfigurationDTO: dropInConfigurationDTO)
                        let dropInComponent = DropInComponent(paymentMethods: session.sessionContext.paymentMethods,
                                                              context: adyenContext,
                                                              configuration: dropInConfiguration!)
                        dropInComponent.delegate = session
                        dropInComponent.partialPaymentDelegate = session
                        self?.dropInComponent = dropInComponent
                        self?.viewController?.present(dropInComponent.viewController, animated: true)
                    } catch let error {
                        self?.checkoutFlutterApi.onDropInSessionResult(sessionPaymentResult: PaymentResult(type: PaymentResultEnum.error, reason: error.localizedDescription)) {}
                    }
                case let .failure(error):
                    self?.checkoutFlutterApi.onDropInSessionResult(sessionPaymentResult: PaymentResult(type: PaymentResultEnum.error, reason: error.localizedDescription)) {}
                }
            }
        } catch let error {
            checkoutFlutterApi.onDropInSessionResult(sessionPaymentResult: PaymentResult(type: PaymentResultEnum.error, reason: error.localizedDescription)) {}
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
            let configuration = try createDropInConfiguration(dropInConfigurationDTO: dropInConfigurationDTO)
            let dropInComponent = DropInComponent(paymentMethods: paymentMethodsWithoutGiftCards,
                                                  context: adyenContext,
                                                  configuration: configuration)
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
    
    private func createDropInConfiguration(dropInConfigurationDTO: DropInConfigurationDTO) throws -> DropInComponent.Configuration {
        let dropInConfiguration = DropInComponent.Configuration(allowsSkippingPaymentList: dropInConfigurationDTO.skipListWhenSinglePaymentMethod ?? false,
                                                                allowPreselectedPaymentView: dropInConfigurationDTO.showPreselectedStoredPaymentMethod ?? false)
        
        if let cardsConfigurationDTO = dropInConfigurationDTO.cardsConfigurationDTO {
            let koreanAuthenticationMode = determineFieldVisibility(visible: cardsConfigurationDTO.showKcpField)
            let socialSecurityNumberMode = determineFieldVisibility(visible: cardsConfigurationDTO.showSocialSecurityNumberField)
            let storedCardConfiguration = createStoredCardConfiguration(showCvcForStoredCard: cardsConfigurationDTO.showCvcForStoredCard)
            let allowedCardTypes = determineAllowedCardTypes(cardTypes: cardsConfigurationDTO.supportedCardTypes)
            let billingAddressConfiguration = determineBillingAddressConfiguration(addressMode: cardsConfigurationDTO.addressMode)
            let cardConfiguration = DropInComponent.Card.init(
                showsHolderNameField: cardsConfigurationDTO.holderNameRequired,
                showsStorePaymentMethodField: cardsConfigurationDTO.showStorePaymentField,
                showsSecurityCodeField: cardsConfigurationDTO.showCvc == true,
                koreanAuthenticationMode: koreanAuthenticationMode,
                socialSecurityNumberMode: socialSecurityNumberMode,
                storedCardConfiguration: storedCardConfiguration,
                allowedCardTypes: allowedCardTypes,
                billingAddress: billingAddressConfiguration
            )
            
            dropInConfiguration.card = cardConfiguration
        }
        
        if let appleConfigurationDTO = dropInConfigurationDTO.applePayConfigurationDTO {
            let appleConfiguration = try buildApplePayConfiguration(dropInConfigurationDTO: dropInConfigurationDTO)
            dropInConfiguration.applePay = appleConfiguration
        }
        
        if let cashAppPayConfigurationDTO = dropInConfigurationDTO.cashAppPayConfigurationDTO {
            dropInConfiguration.cashAppPay = DropInComponent.CashAppPay(redirectURL: URL(string: cashAppPayConfigurationDTO.returnUrl)!)
        }
        
        return dropInConfiguration
    }
    
    private func determineFieldVisibility(visible: Bool?) -> CardComponent.FieldVisibility {
        if (visible == true) {
            return .show
        } else {
            return .hide
        }
    }
    
    private func createStoredCardConfiguration(showCvcForStoredCard: Bool?) -> StoredCardConfiguration {
        var storedCardConfiguration = StoredCardConfiguration()
        storedCardConfiguration.showsSecurityCodeField = showCvcForStoredCard ?? false
        return storedCardConfiguration;
    }
    
    private func determineAllowedCardTypes(cardTypes: [String?]?) -> [CardType]? {
        guard let mappedCardTypes = cardTypes else {
            return nil
        }
        
        if mappedCardTypes.isEmpty {
            return nil
        }
        
        return mappedCardTypes.compactMap{$0}.map { CardType(rawValue: $0.lowercased()) }
    }
    
    private func determineBillingAddressConfiguration(addressMode: AddressMode?) -> BillingAddressConfiguration {
        var billingAddressConfiguration = BillingAddressConfiguration.init()
        switch addressMode {
            case .full:
                billingAddressConfiguration.mode = CardComponent.AddressFormType.full
            case .postalCode:
                billingAddressConfiguration.mode = CardComponent.AddressFormType.postalCode
            case .none?:
                billingAddressConfiguration.mode = CardComponent.AddressFormType.none
            default:
                billingAddressConfiguration.mode = CardComponent.AddressFormType.none
        }
        
        return billingAddressConfiguration
    }
    
    private func buildApplePayConfiguration(dropInConfigurationDTO: DropInConfigurationDTO) throws -> Adyen.ApplePayComponent.Configuration {
        let value = Int(dropInConfigurationDTO.amount.value)
        guard let currencyCode : String = dropInConfigurationDTO.amount.currency else {
            throw BalanceChecker.Error.unexpectedCurrencyCode
        }
        
        let amount = AmountFormatter.decimalAmount(value,
                                                   currencyCode: currencyCode,
                                                   localeIdentifier: nil)
        
        let applePayPayment = try ApplePayPayment.init(countryCode: dropInConfigurationDTO.countryCode,
                                                       currencyCode: currencyCode,
                                                       summaryItems: [PKPaymentSummaryItem(label: dropInConfigurationDTO.applePayConfigurationDTO!.merchantName, amount: amount)])
        
        return ApplePayComponent.Configuration.init(payment: applePayPayment,
                                                    merchantIdentifier: dropInConfigurationDTO.applePayConfigurationDTO!.merchantId)
    }
    
    
    private func handleDropInResult(dropInResult: DropInResult) {
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
            let paymentResult = PaymentResult(type: PaymentResultEnum.error, reason: error.localizedDescription)
            self.checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: paymentResult), completion: {})
            self.finalize(false, "\(error.localizedDescription)")
        }
    }
    
    private func onDropInResultFinished(dropInResult: DropInResult) {
        let resultCode = ResultCode(rawValue: dropInResult.result ?? "")
        let success = resultCode == .authorised || resultCode == .received || resultCode == .pending
        self.dropInComponent?.finalizeIfNeeded(with: success) { [weak self] in
            self?.dropInComponent?.viewController.presentingViewController?.dismiss(animated: false, completion: {
                let paymentResult = PaymentResult(type: PaymentResultEnum.finished, result: PaymentResultModel(resultCode: resultCode?.rawValue))
                self?.checkoutFlutterApi.onDropInAdvancedFlowPlatformCommunication(platformCommunicationModel: PlatformCommunicationModel(type: PlatformCommunicationType.result, paymentResult: paymentResult), completion: {})
            })
        }
    }
    
    private func onDropInResultAction(dropInResult: DropInResult) throws {
        let jsonData = try JSONSerialization.data(withJSONObject: dropInResult.actionResponse as Any, options: [])
        let result = try JSONDecoder().decode(Action.self, from: jsonData)
        self.dropInComponent?.handle(result)
    }
    
    private func onDropInResultError(dropInResult: DropInResult) {
        let paymentResult = PaymentResult(type: PaymentResultEnum.error, reason: dropInResult.error?.errorMessage)
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
