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
}

extension BaseApplePayComponent: ApplePayComponentDelegate {
    func didUpdate(
        contact: PKContact,
        for payment: ApplePayPayment,
        completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        componentFlutterApi.onApplePayShippingContactChange(
            componentId: componentId,
            contact: contact.toDTO(),
            currentSummaryItems: payment.summaryItems.map { $0.toDTO(currencyCode: payment.currencyCode) },
            completion: { result in
                switch result {
                case let .success(update):
                    completion(update.toPKPaymentRequestShippingContactUpdate())
                case .failure:
                    completion(PKPaymentRequestShippingContactUpdate(paymentSummaryItems: payment.summaryItems))
                }
            }
        )
    }

    func didUpdate(
        shippingMethod: PKShippingMethod,
        for payment: ApplePayPayment,
        completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
    ) {
        componentFlutterApi.onApplePayShippingMethodChange(
            componentId: componentId,
            shippingMethod: shippingMethod.toDTO(currencyCode: payment.currencyCode),
            currentSummaryItems: payment.summaryItems.map { $0.toDTO(currencyCode: payment.currencyCode) },
            completion: { result in
                switch result {
                case let .success(update):
                    completion(update.toPKPaymentRequestShippingMethodUpdate())
                case .failure:
                    completion(PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: payment.summaryItems))
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
        componentFlutterApi.onApplePayCouponCodeChange(
            componentId: componentId,
            couponCode: couponCode,
            currentSummaryItems: payment.summaryItems.map { $0.toDTO(currencyCode: payment.currencyCode) },
            completion: { result in
                switch result {
                case let .success(update):
                    completion(update.toPKPaymentRequestCouponCodeUpdate())
                case .failure:
                    completion(PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: payment.summaryItems))
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
        componentFlutterApi.onApplePayAuthorize(
            componentId: componentId,
            payment: payment.toAuthorizedPaymentDTO(),
            completion: { result in
                switch result {
                case let .success(update):
                    completion(update.toPKPaymentAuthorizationResult())
                case .failure:
                    completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                }
            }
        )
    }
}
