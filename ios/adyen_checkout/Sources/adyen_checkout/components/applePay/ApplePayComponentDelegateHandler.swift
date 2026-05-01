@_spi(AdyenInternal) import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import PassKit

final class ApplePayComponentDelegateHandler: ApplePayComponentDelegate {
    private let componentFlutterApi: ComponentFlutterInterface
    private let componentId: String

    init(
        componentFlutterApi: ComponentFlutterInterface,
        componentId: String
    ) {
        self.componentFlutterApi = componentFlutterApi
        self.componentId = componentId
    }

    func didUpdate(
        contact: PKContact,
        for payment: ApplePayPayment,
        completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        completion(PKPaymentRequestShippingContactUpdate(paymentSummaryItems: payment.summaryItems))
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
        completion(PKPaymentRequestCouponCodeUpdate(paymentSummaryItems: payment.summaryItems))
    }
}
