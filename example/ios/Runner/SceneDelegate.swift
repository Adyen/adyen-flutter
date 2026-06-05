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
        if let url = URLContexts.first?.url {
            RedirectComponent.applicationDidOpen(from: url)
        }
        super.scene(scene, openURLContexts: URLContexts)
    }
}
