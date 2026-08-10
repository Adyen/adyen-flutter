@_spi(AdyenInternal) import Adyen
#if canImport(AdyenDropIn)
    import AdyenDropIn
#endif
import UIKit

/// View controller is required to prevent propagating the tap event to the FlutterViewController - https://github.com/flutter/flutter/issues/35784#issuecomment-516243057
class DropInViewController: UIViewController, DropInRootViewController {
    let dropInComponent: DropInComponent
    weak var hostViewController: UIViewController?
    private var isDropInPresentationPending = true

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        hostViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        hostViewController?.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }

    override var prefersStatusBarHidden: Bool {
        hostViewController?.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        hostViewController?.prefersHomeIndicatorAutoHidden ?? super.prefersHomeIndicatorAutoHidden
    }
    
    init(dropInComponent: DropInComponent) {
        self.dropInComponent = dropInComponent
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard isDropInPresentationPending else { return }
        isDropInPresentationPending = false
        let componentViewController = dropInComponent.viewController
        present(componentViewController, animated: true) {
            UIAccessibility.post(notification: .screenChanged, argument: componentViewController.view)
        }
    }

    func dismissDropIn(animated: Bool, completion: (() -> Void)? = nil) {
        isDropInPresentationPending = false
        dismiss(animated: animated, completion: completion)
    }
}
