@_spi(AdyenInternal) import Adyen

protocol SessionComponentProtocol: AnyObject {
    var componentId: String { get }
    var sessionHolder: SessionHolder { get }

    func finalizeAndDismissSessionComponent(success: Bool, completion: @escaping (() -> Void))
}

extension SessionComponentProtocol {
    func setupSessionFlowDelegate() {
        if let componentSessionFlowDelegate = (sessionHolder.sessionDelegate as? ComponentSessionFlowHandler) {
            componentSessionFlowDelegate.finalizeCallback = finalizeAndDismissSessionComponent
            componentSessionFlowDelegate.componentId = componentId
        } else {
            AdyenAssertion.assertionFailure(message: "Wrong session flow delegate usage")
        }
    }
}
