#if canImport(AdyenDropIn)
    import AdyenDropIn
#endif

extension DropInPlatformApi: DropInWindowManagerDelegate {
    /// The Drop-in window disappeared without a dismissal request, so Flutter still awaits a result.
    func dropInWindowDidDismissUnexpectedly() {
        clearPresentationReferences()
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

extension DropInPlatformApi: DropInInteractorDelegate {
    func finalizeAndDismiss(success: Bool, completion: @escaping (() -> Void)) {
        guard let dropInComponent else { return }
        let dropInViewController = dropInComponent.viewController
        dropInComponent.finalizeIfNeeded(with: success) { [weak self] in
            self?.dropInWindowManager.dismiss(
                dropInViewController: dropInViewController,
                animated: true,
                completion: completion
            )
        }
    }
}
