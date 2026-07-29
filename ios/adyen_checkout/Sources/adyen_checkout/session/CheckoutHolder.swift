@_spi(AdyenInternal) import AdyenCheckout
@_spi(AdyenInternal) import Adyen

class CheckoutHolder {
    var adyenCheckout: PaymentCheckout?

    /// The componentId of the currently active Apple Pay component. Apple Pay's dynamic
    /// callbacks (onAuthorize, onSelectShippingContact, onSelectShippingMethod, onChangeCouponCode)
    /// are chained onto `ApplePayConfiguration` once, at `Checkout.setup()` time, before any
    /// specific componentId is known. This property lets those closures resolve the componentId
    /// lazily, when they actually fire during the Apple Pay sheet flow.
    var activeApplePayComponentId: String?

    func reset() {
        adyenCheckout = nil
        activeApplePayComponentId = nil
    }
}
