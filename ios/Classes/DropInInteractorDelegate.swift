public protocol DropInInteractorDelegate : AnyObject {
    
    func finalizeAndDismiss(success: Bool, completion: @escaping (() -> Void))
}
