import UIKit
@_spi(AdyenInternal) import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import PassKit

class BaseApplePayComponent {
    let componentFlutterApi: ComponentFlutterInterface
    let componentId: String
    var applePayComponent: ApplePayComponent?
    var currencyCode: String?

    init(
        componentFlutterApi: ComponentFlutterInterface,
        componentId: String
    ) {
        self.componentFlutterApi = componentFlutterApi
        self.componentId = componentId
    }

    func present() {
        preconditionFailure("This method must be implemented")
    }
    
    func onDispose() {
        preconditionFailure("This method must be implemented")
    }
        
    func finalizeAndDismissComponent(success: Bool, completion: @escaping (() -> Void)) {
        applePayComponent?.finalizeIfNeeded(with: success) { [weak self] in
            if let viewController = self?.getViewController() {
                viewController.dismiss(animated: true) {
                    completion()
                }
            } else {
                completion()
            }
        }
    }
    
    func getViewController() -> UIViewController? {
        let rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        return rootViewController?.adyen.topPresenter
    }

    func assignDelegates(to component: ApplePayComponent, configuration: ApplePayConfigurationDTO?) {
        if configuration?.requiresApplePayUpdateDelegate == true {
            component.applePayDelegate = self
        }
        if configuration?.requiresAuthorizationDelegate == true {
            component.authorizationDelegate = self
        }
    }

}

extension BaseApplePayComponent: ApplePayComponentDelegate {
    func didUpdate(
        contact: PKContact,
        for payment: ApplePayPayment,
        completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        let fallback = PKPaymentRequestShippingContactUpdate(paymentSummaryItems: payment.summaryItems)
        componentFlutterApi.onApplePayShippingContactChange(
            componentId: componentId,
            contact: contact.toDTO(),
            currentSummaryItems: payment.summaryItems.map { $0.toDTO(currencyCode: payment.currencyCode) },
            completion: { result in
                switch result {
                case let .success(update):
                    do {
                        try completion(update.toPKPaymentRequestShippingContactUpdate())
                    } catch {
                        completion(fallback)
                    }
                case .failure:
                    completion(fallback)
                }
            }
        )
    }

    func didUpdate(
        shippingMethod: PKShippingMethod,
        for payment: ApplePayPayment,
        completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
    ) {
        let fallback = PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: payment.summaryItems)
        componentFlutterApi.onApplePayShippingMethodChange(
            componentId: componentId,
            shippingMethod: shippingMethod.toDTO(currencyCode: payment.currencyCode),
            currentSummaryItems: payment.summaryItems.map { $0.toDTO(currencyCode: payment.currencyCode) },
            completion: { result in
                switch result {
                case let .success(update):
                    do {
                        try completion(update.toPKPaymentRequestShippingMethodUpdate())
                    } catch {
                        completion(fallback)
                    }
                case .failure:
                    completion(fallback)
                }
            }
        )
    }

    @available(iOS 15.0, *)
    func didUpdate(
        couponCode: String,
        for payment: ApplePayPayment,
        completion: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void
    ) {
        let fallback = PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: payment.summaryItems)
        componentFlutterApi.onApplePayCouponCodeChange(
            componentId: componentId,
            couponCode: couponCode,
            currentSummaryItems: payment.summaryItems.map { $0.toDTO(currencyCode: payment.currencyCode) },
            completion: { result in
                switch result {
                case let .success(update):
                    do {
                        try completion(update.toPKPaymentRequestCouponCodeUpdate())
                    } catch {
                        completion(fallback)
                    }
                case .failure:
                    completion(fallback)
                }
            }
        )
    }
}

extension BaseApplePayComponent: ApplePayAuthorizationDelegate {
    func didAuthorize(
        payment: PKPayment,
        completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        guard let currencyCode, currencyCode.isEmpty == false else {
            completion(PKPaymentAuthorizationResult(status: .failure, errors: [ApplePayComponent.Error.invalidCurrencyCode]))
            return
        }

        componentFlutterApi.onApplePayAuthorize(
            componentId: componentId,
            payment: payment.toAuthorizedPaymentDTO(currencyCode: currencyCode),
            completion: { result in
                switch result {
                case let .success(update):
                    completion(update.toPKPaymentAuthorizationResult())
                case let .failure(adyenPigeonError):
                    completion(PKPaymentAuthorizationResult(
                            status: .failure,
                            errors: [NSError(domain: "AdyenPigeonError", code: 0, userInfo: [NSLocalizedDescriptionKey: adyenPigeonError.message ?? adyenPigeonError.code])])
                    )
                }
            }
        )
    }
}
