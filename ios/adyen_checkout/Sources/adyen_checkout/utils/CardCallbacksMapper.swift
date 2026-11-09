import AdyenCard
import Foundation

extension CardCallbacksDTO {
    func makeCallbacks(events: ComponentPlatformEventHandler, checkoutId: String) -> AdyenCard.CardCallbacks? {
        guard hasOnBinChange || hasOnBinLookup else { return nil }
        var callbacks = AdyenCard.CardCallbacks()
        if hasOnBinChange {
            callbacks = callbacks.onBinChange { bin in
                events.send(event: CheckoutEventDTO(type: .binValue, checkoutId: checkoutId, binValue: bin))
            }
        }
        if hasOnBinLookup {
            callbacks = callbacks.onBinLookup { data in
                events.send(event: CheckoutEventDTO(
                    type: .binLookup,
                    checkoutId: checkoutId,
                    binLookupData: [data.toDTO()]
                ))
            }
        }
        return callbacks
    }
}

extension AdyenCard.BinLookupData {
    func toDTO() -> BinLookupDataDTO {
        BinLookupDataDTO(
            issuingCountryCode: issuingCountryCode,
            brands: brands.map { $0.toDTO() }
        )
    }
}

private extension AdyenCard.BinLookupBrand {
    func toDTO() -> BinLookupBrandDTO {
        BinLookupBrandDTO(
            brand: brand,
            supported: supported,
            paymentMethodVariant: paymentMethodVariant
        )
    }
}
