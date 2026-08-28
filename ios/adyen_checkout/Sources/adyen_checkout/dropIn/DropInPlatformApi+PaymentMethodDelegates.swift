@_spi(AdyenInternal) import Adyen
#if canImport(AdyenDropIn)
    import AdyenDropIn
#endif
#if canImport(AdyenCard)
    import AdyenCard
#endif

extension DropInPlatformApi: StoredPaymentMethodsDelegate {
    func disable(storedPaymentMethod: StoredPaymentMethod, completion: @escaping (Bool) -> Void) {
        deleteStoredPaymentMethodCompletionHandler = completion
        let checkoutEvent = CheckoutEvent(
            type: CheckoutEventType.deleteStoredPaymentMethod,
            data: storedPaymentMethod.identifier
        )
        checkoutFlutter.send(
            event: checkoutEvent,
            completion: { _ in }
        )
    }
}

extension DropInPlatformApi: CardComponentDelegate {
    func didSubmit(lastFour: String, finalBIN: String, component: CardComponent) {}

    func didChangeBIN(_ value: String, component: CardComponent) {
        let checkoutEvent = CheckoutEvent(type: CheckoutEventType.binValue, data: value)
        checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
    }

    func didChangeCardBrand(_ value: [CardBrand]?, component: CardComponent) {
        guard let binLookupData = value else {
            return
        }

        let binLookupDataDtoList: [BinLookupDataDTO] = binLookupData.map { cardBrand in
            BinLookupDataDTO(brand: cardBrand.type.rawValue)
        }

        let checkoutEvent = CheckoutEvent(type: CheckoutEventType.binLookup, data: binLookupDataDtoList)
        checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
    }
}
