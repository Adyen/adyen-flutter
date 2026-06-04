@_spi(AdyenInternal) import AdyenCheckout
@_spi(AdyenInternal) import Adyen

class CheckoutHolder {
    var adyenCheckout: PaymentCheckout?

    func reset() {
        adyenCheckout = nil
    }
}
