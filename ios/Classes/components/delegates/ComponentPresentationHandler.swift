import Adyen

extension UIViewController: PresentationDelegate {
    public func present(component: PresentableComponent) {
        present(component.viewController, animated: true, completion: nil)
    }

    /*
     This is needed for when we implement voucher support
    
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
         presentableComponent?.cancelIfNeeded()
     }
     */
}
