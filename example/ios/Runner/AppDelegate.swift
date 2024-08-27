import Adyen
import adyen_checkout
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        setDropInStyle()
        setCardComponentStyle()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        RedirectComponent.applicationDidOpen(from: url)
        return true
    }
    
    private func setDropInStyle() {
        var dropInStyle = Adyen.DropInComponent.Style()
        dropInStyle.formComponent.mainButtonItem.button.backgroundColor = .black
        dropInStyle.formComponent.mainButtonItem.button.title.color = .white
        AdyenAppearance.dropInStyle = dropInStyle
    }
    
    private func setCardComponentStyle() {
        var cardComponentStyle = Adyen.FormComponentStyle()
        cardComponentStyle.mainButtonItem.button.backgroundColor = .black
        cardComponentStyle.mainButtonItem.button.title.color = .white
        AdyenAppearance.cardComponentStyle = cardComponentStyle
    }
}
