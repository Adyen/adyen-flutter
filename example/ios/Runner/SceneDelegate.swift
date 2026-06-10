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
        let unhandledContexts = URLContexts.filter { context in
            !RedirectComponent.applicationDidOpen(from: context.url)
        }
        super.scene(scene, openURLContexts: Set(unhandledContexts))
    }
}
