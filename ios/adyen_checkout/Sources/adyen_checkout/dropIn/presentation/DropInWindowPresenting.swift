import UIKit

/// The UIKit boundary of `DropInWindowManager`, so window creation, dismissal timing and scene
/// disconnection can be substituted in tests.
protocol DropInWindowPresenting {
    func makeWindow(for windowScene: UIWindowScene) -> UIWindow

    func dismiss(_ viewController: UIViewController, animated: Bool, completion: @escaping () -> Void)

    func observeSceneDisconnect(of windowScene: UIWindowScene, handler: @escaping () -> Void)

    func stopObservingSceneDisconnect()
}
