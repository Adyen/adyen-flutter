public protocol DropInInteractorDelegate: AnyObject {
    func dismiss(completion: @escaping () -> Void)
    func finalizeAndDismiss(success: Bool, completion: @escaping (() -> Void))
}
