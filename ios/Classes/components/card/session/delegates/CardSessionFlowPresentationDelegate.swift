import Adyen

class CardSessionFlowPresentationDelegate: PresentationDelegate {
    func present(component _: Adyen.PresentableComponent) {
        print("present")
        // TODO: Could we discuss when this callback is being triggered and needs to be handled?
    }
}
