public protocol DropInInteractorDelegate: AnyObject {
    /// Dismisses Drop-in after an AdyenSession has completed or failed.
    func dismiss(completion: @escaping () -> Void)

    /// Finalizes an advanced-flow Drop-in and then dismisses it.
    func finalizeAndDismiss(success: Bool, completion: @escaping (() -> Void))
}
