import Adyen
import Flutter
import UIKit

#if canImport(AdyenActions)
    import AdyenActions
#endif

final class SceneDelegate: FlutterSceneDelegate {
    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // TODO: v6 migration - RedirectComponent.applicationDidOpen is now package-access on
        // 6.0.0-alpha.1 with no documented public replacement yet.
        super.scene(scene, openURLContexts: URLContexts)
    }
}
