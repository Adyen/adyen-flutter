import Adyen
import Flutter
import UIKit

/// UIScene lifecycle delegate for the example app; forwards 3DS2 / redirect URLs
/// to Adyen's RedirectComponent.
final class SceneDelegate: FlutterSceneDelegate {
    override func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        // `URLContexts` is a `Set`; `.first` is non-deterministic when multiple
        // contexts are delivered.
        for context in URLContexts {
            if RedirectComponent.applicationDidOpen(from: context.url) {
                break
            }
        }
        super.scene(scene, openURLContexts: URLContexts)
    }
}
