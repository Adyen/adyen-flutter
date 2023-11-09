import Adyen

class CardAdvancedFlowPresentationDelegate: PresentationDelegate {
    func present(component _: Adyen.PresentableComponent) {
        print("did present")
        // TODO: Could we discuss when this callback is being triggered and needs to be handled?
    }
}
