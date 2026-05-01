@_spi(AdyenInternal) import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import PassKit

protocol ApplePayCallbackBridge {
    func onAuthorize(
        componentId: String,
        payment: PKPayment,
        completion: @escaping (PKPaymentAuthorizationResult) -> Void
    )

    @available(iOS 15.0, *)
    func onCouponCodeChange(
        componentId: String,
        couponCode: String,
        payment: ApplePayPayment,
        completion: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void
    )

    func onShippingContactChange(
        componentId: String,
        contact: PKContact,
        payment: ApplePayPayment,
        completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    )

    func onShippingMethodChange(
        componentId: String,
        shippingMethod: PKShippingMethod,
        payment: ApplePayPayment,
        completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
    )
}

final class PigeonApplePayCallbackBridge: ApplePayCallbackBridge {
    private let componentFlutterApi: ComponentFlutterInterface

    init(componentFlutterApi: ComponentFlutterInterface) {
        self.componentFlutterApi = componentFlutterApi
    }

    func onAuthorize(
        componentId: String,
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

    @available(iOS 15.0, *)
    func onCouponCodeChange(
        componentId: String,
        couponCode: String,
        payment: ApplePayPayment,
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

    func onShippingContactChange(
        componentId: String,
        contact: PKContact,
        payment: ApplePayPayment,
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

    func onShippingMethodChange(
        componentId: String,
        shippingMethod: PKShippingMethod,
        payment: ApplePayPayment,
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
}
