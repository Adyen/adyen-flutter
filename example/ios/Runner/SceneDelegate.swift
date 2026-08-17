import Adyen
import Flutter
import UIKit

#if canImport(AdyenCheckout)
    import AdyenCheckout
#endif

final class SceneDelegate: FlutterSceneDelegate {
    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        var unhandledURLContexts = Set<UIOpenURLContext>()
        for context in URLContexts where !Checkout.handleReturn(url: context.url) {
            unhandledURLContexts.insert(context)
        }
        guard !unhandledURLContexts.isEmpty else { return }
        super.scene(scene, openURLContexts: unhandledURLContexts)
    }
}
