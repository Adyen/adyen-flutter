import Adyen
import adyen_checkout
import Flutter
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        RedirectComponent.applicationDidOpen(from: url)
        return true
    }
}

class AdyenAppearance: AdyenAppearanceProvider {
    static func createDropInStyle() -> Adyen.DropInComponent.Style? {
        var style = Adyen.DropInComponent.Style()
        style.formComponent.mainButtonItem.button.backgroundColor = .black
        style.formComponent.mainButtonItem.button.title.color = .white
        return style
    }

    static func createCardComponentStyle() -> Adyen.FormComponentStyle? {
        var style = FormComponentStyle()
        style.mainButtonItem.button.backgroundColor = .black
        style.mainButtonItem.button.title.color = .white
        return style
    }
}
