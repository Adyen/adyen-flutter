import Adyen
import Flutter
import UIKit

#if canImport(AdyenActions)
    import AdyenActions
#endif

final class SceneDelegate: FlutterSceneDelegate {
    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        URLContexts.forEach { RedirectComponent.applicationDidOpen(from: $0.url) }
        super.scene(scene, openURLContexts: URLContexts)
    }
}
