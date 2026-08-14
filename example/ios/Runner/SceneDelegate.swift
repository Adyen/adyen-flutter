import Adyen
import Flutter
import UIKit

#if canImport(AdyenActions)
    import AdyenActions
#endif

final class SceneDelegate: FlutterSceneDelegate {
    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        var unhandledURLContexts = Set<UIOpenURLContext>()
        for context in URLContexts where !RedirectComponent.applicationDidOpen(from: context.url) {
            unhandledURLContexts.insert(context)
        }
        guard !unhandledURLContexts.isEmpty else { return }
        super.scene(scene, openURLContexts: unhandledURLContexts)
    }
}
