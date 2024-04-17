import Adyen

class DropInSessionPresentationDelegate: PresentationDelegate {
    func present(component _: PresentableComponent) {
        print("presentable component")
        // This is required later when integrating components
    }
}
