@_spi(AdyenInternal) import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import PassKit

final class ApplePayComponentDelegateHandler: ApplePayComponentDelegate {
    private let applePayCallbackBridge: ApplePayCallbackBridge
    private let componentId: String

    init(
        applePayCallbackBridge: ApplePayCallbackBridge,
        componentId: String
    ) {
        self.applePayCallbackBridge = applePayCallbackBridge
        self.componentId = componentId
    }

    func didUpdate(
        contact: PKContact,
        for payment: ApplePayPayment,
        completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        applePayCallbackBridge.onShippingContactChange(
            componentId: componentId,
            contact: contact,
            payment: payment,
            completion: completion
        )
    }

    func didUpdate(
        shippingMethod: PKShippingMethod,
        for payment: ApplePayPayment,
        completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
    ) {
        applePayCallbackBridge.onShippingMethodChange(
            componentId: componentId,
            shippingMethod: shippingMethod,
            payment: payment,
            completion: completion
        )
    }

    @available(iOS 15.0, *)
    func didUpdate(
        couponCode: String,
        for payment: ApplePayPayment,
        completion: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void
    ) {
        applePayCallbackBridge.onCouponCodeChange(
            componentId: componentId,
            couponCode: couponCode,
            payment: payment,
            completion: completion
        )
    }
}
