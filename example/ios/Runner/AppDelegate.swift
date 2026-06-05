import Adyen
import Flutter
import UIKit

#if canImport(adyen_checkout)
    import adyen_checkout
#endif

#if canImport(AdyenActions)
    import AdyenActions
#endif

#if canImport(AdyenDropIn)
    import AdyenDropIn
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Style setup is process-level, not UI-level — keep here.
        setDropInStyle()
        setCardComponentStyle()
        setBlikComponentStyle()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    /// Move plugin registration to the scene's implicit engine. This is the iOS 26+ /
    /// UIScene-aware pattern: plugins are now registered against the Flutter engine
    /// attached to the scene, not the app.
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }

    /// Kept as an iOS 12 / non-scene fallback. On iOS 13+ with a scene manifest
    /// installed, iOS routes URL opens to SceneDelegate.scene(_:openURLContexts:)
    /// and this method is dead. Harmless to leave for backwards compat.
    override func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        RedirectComponent.applicationDidOpen(from: url)
        return true
    }

    private func setDropInStyle() {
        var dropInStyle = DropInComponent.Style()
        dropInStyle.formComponent.mainButtonItem.button.backgroundColor = UIColor(named: "PrimaryBackground") ?? .black
        dropInStyle.formComponent.mainButtonItem.button.title.color = UIColor(named: "PrimaryTitle") ?? .white
        dropInStyle.formComponent.textField.tintColor = UIColor(named: "PrimaryBackground") ?? .black
        AdyenAppearance.dropInStyle = dropInStyle
    }

    private func setCardComponentStyle() {
        var cardComponentStyle = Adyen.FormComponentStyle()
        cardComponentStyle.mainButtonItem.button.backgroundColor = UIColor(named: "PrimaryBackground") ?? .black
        cardComponentStyle.mainButtonItem.button.title.color = UIColor(named: "PrimaryTitle") ?? .white
        cardComponentStyle.textField.tintColor = UIColor(named: "PrimaryBackground") ?? .black
        cardComponentStyle.backgroundColor = UIColor(named: "AppBackground") ?? .white
        AdyenAppearance.cardComponentStyle = cardComponentStyle
    }

    private func setBlikComponentStyle() {
        var blikComponentStyle = Adyen.FormComponentStyle()
        blikComponentStyle.mainButtonItem.button.backgroundColor = UIColor(named: "PrimaryBackground") ?? .black
        blikComponentStyle.mainButtonItem.button.title.color = UIColor(named: "PrimaryTitle") ?? .white
        blikComponentStyle.textField.tintColor = UIColor(named: "PrimaryBackground") ?? .black
        blikComponentStyle.backgroundColor = UIColor(named: "AppBackground") ?? .white
        AdyenAppearance.blikComponentStyle = blikComponentStyle
    }
}
