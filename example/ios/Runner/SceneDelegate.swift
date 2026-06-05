import Adyen
import Flutter
import UIKit

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
