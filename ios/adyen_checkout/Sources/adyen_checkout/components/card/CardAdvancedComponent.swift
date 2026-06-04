@_spi(AdyenInternal) import Adyen
@_spi(AdyenInternal) import AdyenCheckout

import Flutter
import Foundation

#if canImport(AdyenCard)
    import AdyenCard
#endif

class CardAdvancedComponent: BaseCardComponent, AdvancedComponentProtocol {
    override init(
        frame: CGRect,
        viewIdentifier: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi
    ) {
        super.init(
            frame: frame,
            viewIdentifier: viewIdentifier,
            arguments: arguments,
            binaryMessenger: binaryMessenger,
            componentFlutterApi: componentFlutterApi,
            componentPlatformApi: componentPlatformApi
        )
        setupCardComponentView()
    }

    private func setupCardComponentView() {
        Task {
            do {
                guard let cardComponentConfiguration else {
                    throw PlatformError(errorDescription: "Card configuration not found")
                }

                let cardConfig = cardComponentConfiguration.cardConfiguration.mapToCardConfiguration(
                    shopperLocale: cardComponentConfiguration.shopperLocale
                )
                let configuration = try CheckoutConfiguration(
                    environment: cardComponentConfiguration.environment.mapToEnvironment(),
                    amount: cardComponentConfiguration.amount!.mapToAmount(),
                    clientKey: cardComponentConfiguration.clientKey,
                    analyticsConfiguration: .init()
                ) {
                    cardConfig
                }

                guard let paymentMethodString = paymentMethod else {
                    throw PlatformError(errorDescription: "Payment method not found")
                }
                let wrappedJSON = "{\"paymentMethods\":[\(paymentMethodString)]}"
                guard let jsonData = wrappedJSON.data(using: .utf8) else {
                    throw PlatformError(errorDescription: "Failed to encode payment methods")
                }
                let paymentMethods = try JSONDecoder().decode(PaymentMethods.self, from: jsonData)
                let adyenCheckout = try await Checkout.setup(with: paymentMethods, configuration: configuration)

                // TODO: v6 migration - Wire onSubmit/onAdditionalDetails/onComplete/onError callbacks on adyenCheckout (AdvancedCheckout)

                let cardPaymentMethod = try JSONDecoder().decode(CardPaymentMethod.self, from: Data(paymentMethodString.utf8))
                let cardComponent = try buildCardComponent(adyenCheckout: adyenCheckout, cardPaymentMethod: cardPaymentMethod)
                showCardComponent(cardComponent: cardComponent)
            } catch {
                sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
            }
        }
    }

    func stopLoadingOnError() {}

    override func onDispose() {
        super.onDispose()
    }
}

// MARK: - Original V1 implementation (pre-v6 reference)
//
// @_spi(AdyenInternal) import Adyen
// @_spi(AdyenInternal) import AdyenCheckout
//
// #if canImport(AdyenActions)
//     import AdyenActions
// #endif
// #if canImport(AdyenCard)
//     import AdyenCard
// #endif
//
// class CardAdvancedComponent: BaseCardComponent, AdvancedComponentProtocol {
//     private var actionComponentDelegate: ActionComponentDelegate?
//     private var presentationDelegate: PresentationDelegate?
//     private var componentDelegate: PaymentComponentDelegate?
//     private(set) var actionComponent: CheckoutActionComponent?
//
//     override init(
//         frame: CGRect,
//         viewIdentifier: Int64,
//         arguments: NSDictionary,
//         binaryMessenger: FlutterBinaryMessenger,
//         componentFlutterApi: ComponentFlutterInterface,
//         componentPlatformApi: ComponentPlatformApi
//     ) {
//         super.init(
//             frame: frame,
//             viewIdentifier: viewIdentifier,
//             arguments: arguments,
//             binaryMessenger: binaryMessenger,
//             componentFlutterApi: componentFlutterApi,
//             componentPlatformApi: componentPlatformApi
//         )
//
//         actionComponentDelegate = ComponentActionHandler(
//             componentFlutterApi: componentFlutterApi,
//             componentId: componentId,
//             finalizeCallback: finalizeAndDismiss(success:completion:)
//         )
//         setupCardComponentView()
//     }
//
//     private func setupCardComponentView() {
//         Task {
//             do {
//                 let configuration = try CheckoutConfiguration(
//                     environment: cardComponentConfiguration!.environment.mapToEnvironment(),
//                     amount: cardComponentConfiguration!.amount!.mapToAmount(),
//                     clientKey: cardComponentConfiguration!.clientKey,
//                     analyticsConfiguration: .init()
//                 ) {
//                 }.onSubmit { data, handler in
//
//                 }.onAdditionalDetails { data, handler in
//
//                 }.onError { error in
//
//                 }.onComplete { result in
//
//                 }
//
//                 let wrappedJSON = "{\"paymentMethods\":[\(paymentMethod)]}"
//                 guard let jsonData = wrappedJSON.data(using: .utf8) else {
//                     throw PlatformError(errorDescription: "Failed to encode payment methods")
//                 }
//                 let paymentMethods = try JSONDecoder().decode(PaymentMethods.self, from: jsonData)
//                 let adyenCheckout = try await Checkout.setup(with: paymentMethods, configuration: configuration)
//                 guard let paymentMethodString = paymentMethod else { throw PlatformError(errorDescription: "Payment method not found") }
//                 let cardPaymentMethod = try JSONDecoder().decode(CardPaymentMethod.self, from: Data(paymentMethodString.utf8))
//                 let cardComponent = try buildCardComponent(adyenCheckout: adyenCheckout, cardPaymentMethod: cardPaymentMethod)
//                 showCardComponent(cardComponent: cardComponent)
//             } catch {
//                 sendErrorToFlutterLayer(errorMessage: error.localizedDescription)
//             }
//         }
//     }
//
//     private func buildActionComponent(adyenContext: AdyenContext) -> CheckoutActionComponent {
//         var configuration = CheckoutActionComponent.Configuration()
//         if let threeDS2Config = cardComponentConfiguration?.threeDS2ConfigurationDTO {
//             configuration.threeDS = threeDS2Config.mapToThreeDS2Configuration()
//         }
//         let actionComponent = CheckoutActionComponent(context: adyenContext, configuration: configuration)
//         actionComponent.delegate = actionComponentDelegate
//         actionComponent.presentationDelegate = getViewController()
//         return actionComponent
//     }
//
//     func stopLoadingOnError() {
//         return
//     }
//
//     override func onDispose() {
//         actionComponentDelegate = nil
//         presentationDelegate = nil
//         componentDelegate = nil
//         actionComponent = nil
//         super.onDispose()
//     }
// }
