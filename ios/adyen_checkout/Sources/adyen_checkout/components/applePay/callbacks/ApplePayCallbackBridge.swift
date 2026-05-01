@_spi(AdyenInternal) import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import PassKit

protocol ApplePayCallbackBridge {
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
