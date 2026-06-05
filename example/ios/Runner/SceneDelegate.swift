import Adyen
import Flutter
import UIKit

/// Subclasses Flutter's UISceneDelegate so the example app adopts the UIScene
/// lifecycle that Apple now requires for iOS 26+ targeting apps. The override
/// forwards 3DS2 / redirect URLs to Adyen's RedirectComponent in addition to
/// letting Flutter's superclass do its normal plugin event forwarding.
final class SceneDelegate: FlutterSceneDelegate {
    override func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        // `URLContexts` is a `Set`, so `.first` is non-deterministic when multiple
        // contexts are delivered. Iterate to find the first URL that the Adyen
        // redirect component handles (it returns `true` on match).
        for context in URLContexts {
            if RedirectComponent.applicationDidOpen(from: context.url) {
                break
            }
        }
        super.scene(scene, openURLContexts: URLContexts)
    }
}
