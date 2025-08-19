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
//        dropInStyle.formComponent.mainButtonItem.button.backgroundColor = .yellow
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
}
