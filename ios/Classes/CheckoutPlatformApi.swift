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
    private let checkoutFlutterApi: CheckoutFlutterApi
    private var session: AdyenSession?
    private var dropInComponent: DropInComponent?
    private var viewController : UIViewController?
    
    init(checkoutFlutterApi: CheckoutFlutterApi) {
        self.checkoutFlutterApi = checkoutFlutterApi
    }

    func getPlatformVersion(completion: @escaping (Result<String, Error>) -> Void) {
        let systemVersion = UIDevice.current.systemVersion
        completion(Result.success(systemVersion))
    }
    
    func startPayment(dropInConfiguration: DropInConfigurationModel, sessionModel: SessionModel) {
        do {
            viewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
            let adyenContext = try createAdyenContext(dropInConfiguration: dropInConfiguration)
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
                                                              configuration: dropInConfiguration!)
                        dropInComponent.delegate = session
                        dropInComponent.partialPaymentDelegate = session
                        self?.dropInComponent = dropInComponent
                        self?.viewController?.present(dropInComponent.viewController, animated: true)
                    case let .failure(error):
                        print("Native sdk error: \(error.localizedDescription)")
                        self?.checkoutFlutterApi.onDropInSessionResult(sessionDropInResult: DropInResultModel(sessionDropInResult: DropInResultEnum.error, reason: error.localizedDescription)) {}
                    }
                }
            }
        } catch let error {
            print("Native sdk error: \(error.localizedDescription)")
            checkoutFlutterApi.onDropInSessionResult(sessionDropInResult: DropInResultModel(sessionDropInResult: DropInResultEnum.error, reason: error.localizedDescription)) {}
        }
    }


    func startPaymentDropInAdvancedFlow(dropInConfiguration: DropInConfigurationModel, paymentMethodsResponse: String) {

    }

    func getReturnUrl(completion: @escaping (Result<String, Error>) -> Void) {
        completion(Result.success(""))
    }

    func onPaymentsResult(paymentsResult: [String : Any?]) throws {

    }

    func onPaymentsDetailsResult(paymentsDetailsResult: [String : Any?]) throws {

    }
    
    private func createAdyenContext(dropInConfiguration: DropInConfigurationModel) throws  -> AdyenContext  {
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

    private func createDropInConfiguration(paymentMethods: PaymentMethods) -> DropInComponent.Configuration {
        let dropInConfiguration = DropInComponent.Configuration()
        return dropInConfiguration
    }
    
}

extension CheckoutPlatformApi: AdyenSessionDelegate {
    func didComplete(with resultCode: SessionPaymentResultCode, component: Component, session: AdyenSession) {
        self.viewController?.dismiss(animated: false, completion: {
            self.checkoutFlutterApi.onDropInSessionResult(sessionDropInResult: DropInResultModel(
                sessionDropInResult: DropInResultEnum.finished,
                result: SessionPaymentResultModel(sessionId: session.sessionContext.identifier, sessionData: session.sessionContext.data, resultCode: resultCode.rawValue)), completion: {})
        })
    }
    
    func didFail(with error: Error, from component: Component, session: AdyenSession) {
        self.viewController?.dismiss(animated: true)
        print("Native sdk error: \(error.localizedDescription)")
        checkoutFlutterApi.onDropInSessionResult(sessionDropInResult: DropInResultModel(sessionDropInResult: DropInResultEnum.error, reason: error.localizedDescription)) {}
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
