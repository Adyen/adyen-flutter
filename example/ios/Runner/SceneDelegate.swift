import Adyen
import Flutter
import UIKit

#if canImport(AdyenCheckout)
    import AdyenCheckout
#endif

final class SceneDelegate: FlutterSceneDelegate {
    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url, Checkout.handleReturn(url: url) {
            return
        }
        super.scene(scene, openURLContexts: URLContexts)
    }
}
