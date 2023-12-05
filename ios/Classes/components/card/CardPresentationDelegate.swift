import Adyen

class CardPresentationDelegate: PresentationDelegate {
    let topViewController: UIViewController?
    var cardComponent: PresentableComponent?
    
    init(topViewController: UIViewController?) {
        self.topViewController = topViewController
    }
    
    func present(component: PresentableComponent) {
        let componentViewController = viewController(for: component)
        cardComponent = component
        topViewController?.present(componentViewController, animated: true, completion: nil)
    }
    
    private func viewController(for component: PresentableComponent) -> UIViewController {
        guard component.requiresModalPresentation else {
            return component.viewController
        }

        let navigation = UINavigationController(rootViewController: component.viewController)
        component.viewController.navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .cancel,
                                                                          target: self,
                                                                          action: #selector(cancelPressed))
        return navigation
    }

    @objc private func cancelPressed() {
        cardComponent?.cancelIfNeeded()
    }
}
