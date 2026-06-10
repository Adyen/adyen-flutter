import Adyen
import Flutter
import UIKit

#if canImport(AdyenActions)
    import AdyenActions
#endif

final class SceneDelegate: FlutterSceneDelegate {
    override func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        for context in URLContexts {
            if RedirectComponent.applicationDidOpen(from: context.url) {
                break
            }
        }
        super.scene(scene, openURLContexts: URLContexts)
    }
}
