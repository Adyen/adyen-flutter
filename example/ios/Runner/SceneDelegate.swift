import Adyen
import Flutter
import UIKit

#if canImport(AdyenActions)
    import AdyenActions
#endif

final class SceneDelegate: FlutterSceneDelegate {
    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        let unhandledURLContexts = URLContexts.filter {
            !RedirectComponent.applicationDidOpen(from: $0.url)
        }
        guard !unhandledURLContexts.isEmpty else { return }
        super.scene(scene, openURLContexts: unhandledURLContexts)
    }
}
