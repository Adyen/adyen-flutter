import Flutter
import UIKit

#if canImport(AdyenCheckout)
    import AdyenCheckout
#endif

final class SceneDelegate: FlutterSceneDelegate {
    override func scene(_ scene: UIScene, openURLContexts contexts: Set<UIOpenURLContext>) {
        var unhandled = Set<UIOpenURLContext>()
        for context in contexts where !Checkout.handleReturn(url: context.url) {
            unhandled.insert(context)
        }
        guard !unhandled.isEmpty else { return }
        super.scene(scene, openURLContexts: unhandled)
    }
}
