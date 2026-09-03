extension DropInPlatformApi: DropInWindowManagerDelegate {
    /// The Drop-in window disappeared without a dismissal request, so Flutter still awaits a result.
    func dropInWindowDidDismissUnexpectedly() {
        let checkoutEvent = CheckoutEvent(
            type: CheckoutEventType.result,
            data: PaymentResultDTO(
                type: PaymentResultEnum.error,
                reason: "Drop-in was dismissed unexpectedly."
            )
        )
        checkoutFlutter.send(event: checkoutEvent, completion: { _ in })
    }
}
