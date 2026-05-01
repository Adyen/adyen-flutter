@_spi(AdyenInternal) import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import PassKit

protocol ApplePayCallbackBridge {
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
