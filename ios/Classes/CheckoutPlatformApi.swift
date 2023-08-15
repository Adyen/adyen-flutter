//
//  CheckoutApi.swift
//  adyen_checkout
//
//  Created by Robert Schulze Dieckhoff on 07/08/2023.
//

import Foundation
@_spi(AdyenInternal)
import Adyen
import AdyenNetworking


//Todo Add config:
// 1) Add Info.plist for adding photo library usage description
// 2) Add url scheme
// 3) Add AppDelegate redirect

class CheckoutPlatformApi : CheckoutPlatformInterface {
    
    private let checkoutResultFlutterInterface: CheckoutResultFlutterInterface
    private var session: AdyenSession?
    private var dropInComponent: DropInComponent?
    private var viewController : UIViewController?
    
    init(checkoutResultFlutterInterface: CheckoutResultFlutterInterface) {
        self.checkoutResultFlutterInterface = checkoutResultFlutterInterface
    }
    
    private static var delegatedAuthenticationConfigurations: ThreeDS2Component.Configuration.DelegatedAuthentication {
        .init(localizedRegistrationReason: "Authenticate your card!",
              localizedAuthenticationReason: "Register this device!",
              appleTeamIdentifier: "AppleTeamIdentifier")
    }
    
    func getPlatformVersion(completion: @escaping (Result<String, Error>) -> Void) {
        let systemVersion = UIDevice.current.systemVersion
        completion(Result.success(systemVersion))
    }
    
    func startPayment(sessionModel: SessionModel, dropInConfiguration: DropInConfigurationModel, completion: @escaping (Result<Void, Error>) -> Void) {
        viewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        let adyenContext = createAdyenContext(dropInConfiguration: dropInConfiguration)
        let configuration = AdyenSession.Configuration(sessionIdentifier: sessionModel.id,
                                                       initialSessionData: sessionModel.sessionData,
                                                       context: adyenContext)
        DispatchQueue.main.async {
            AdyenSession.initialize(with: configuration, delegate: self, presentationDelegate: self) { [weak self] result in
                switch result {
                case let .success(session):
                    self?.session = session
                    let paymentMethods = session.sessionContext.paymentMethods
                    let dropInConfiguration = self?.createDropInConfiguration(paymentMethods: paymentMethods)
                    let dropInComponent = DropInComponent(paymentMethods: session.sessionContext.paymentMethods,
                                                          context: adyenContext,
                                                          configuration: dropInConfiguration!,
                                                          title: "TEST")
                    dropInComponent.delegate = session
                    dropInComponent.partialPaymentDelegate = session
                    self?.dropInComponent = dropInComponent
                    self?.viewController?.present(dropInComponent.viewController, animated: true)
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func getReturnUrl() -> String {
        return "";
    }
    
    private func createAdyenContext(dropInConfiguration: DropInConfigurationModel) -> AdyenContext {
        let apiContext = try! APIContext(environment: mapToEnvironment(environment: dropInConfiguration.environment), clientKey: dropInConfiguration.clientKey)
        let value: Int = Int(dropInConfiguration.amount.value)
        let currencyCode : String = dropInConfiguration.amount.currency ?? ""
        let amount = Adyen.Amount(value: value, currencyCode: currencyCode)
        let adyenContext = AdyenContext(apiContext: apiContext, payment: nil)
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
    
    private func getCountryCode(locale: Locale?) -> String {
        return "NL"
    }
    
    private func createDropInConfiguration(paymentMethods: PaymentMethods) -> DropInComponent.Configuration {
        let dropInConfiguration = DropInComponent.Configuration()
        dropInConfiguration.actionComponent.threeDS.delegateAuthentication = CheckoutPlatformApi.delegatedAuthenticationConfigurations
        return dropInConfiguration
    }
    
}

extension CheckoutPlatformApi: AdyenSessionDelegate {
    func didComplete(with resultCode: SessionPaymentResultCode, component: Component, session: AdyenSession) {
        self.viewController?.dismiss(animated: false)
        checkoutResultFlutterInterface.onSessionDropInResult(sessionDropInResult: SessionDropInResultModel(
            sessionDropInResult: SessionDropInResultEnum.finished,
            result: SessionPaymentResultModel(sessionId: session.sessionContext.identifier,
                                              sessionData: session.sessionContext.data,
                                              resultCode: resultCode.rawValue)
        )) {}
    }
    
    func didFail(with error: Error, from component: Component, session: AdyenSession) {
        self.viewController?.dismiss(animated: true)
        checkoutResultFlutterInterface.onSessionDropInResult(sessionDropInResult: SessionDropInResultModel(sessionDropInResult: SessionDropInResultEnum.cancelledByUser)) {}
    }
    
    func didOpenExternalApplication(component: ActionComponent, session: AdyenSession) {
        print("external")
    }
}

extension CheckoutPlatformApi: PresentationDelegate {
    func present(component: PresentableComponent) {
        print("presentable component")
    }
}
