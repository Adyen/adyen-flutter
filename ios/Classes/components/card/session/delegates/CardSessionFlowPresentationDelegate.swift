import Adyen

class CardSessionFlowPresentationDelegate: PresentationDelegate {
    func present(component _: Adyen.PresentableComponent) {
        print("present")
    }
}
