import Adyen
import UIKit

/// Presents action-related component view controllers (e.g. redirect, await, 3DS challenge)
/// modally on top of a given view controller, and keeps track of the presented view
/// controller so it can be dismissed once the action completes.
///
/// The generic `AdyenComponent`/`CheckoutPlatformApi` path has no Drop-in-style container to
/// automatically dismiss action UI once a result comes in, so without this the "awaiting
/// confirmation"/redirect/3DS view stays on screen even after the payment has finished.
@MainActor
final class ComponentPresentationDelegate: NSObject, PresentationDelegate {
    private weak var presentingViewController: UIViewController?
    private weak var presentedComponentViewController: UIViewController?

    init(presentingViewController: UIViewController?) {
        self.presentingViewController = presentingViewController
    }

    func present(component: PresentableComponent) {
        presentedComponentViewController = component.viewController
        presentingViewController?.present(component.viewController, animated: true, completion: nil)
    }

    /// Dismisses the currently presented component view controller, if any.
    func dismiss(completion: (() -> Void)? = nil) {
        guard let presentedComponentViewController, presentedComponentViewController.presentingViewController != nil else {
            completion?()
            return
        }
        self.presentedComponentViewController = nil
        presentedComponentViewController.dismiss(animated: true, completion: completion)
    }
}
