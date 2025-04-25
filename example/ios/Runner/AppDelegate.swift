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
        dropInStyle.navigation.backgroundColor = color(hex: 0x287F99)
        dropInStyle.formComponent.backgroundColor = color(hex: 0x287F99)
        dropInStyle.formComponent.textField.tintColor = color(hex: 0x06F01D)
        dropInStyle.formComponent.mainButtonItem.button.backgroundColor = color(hex: 0xFFB860)
        dropInStyle.formComponent.mainButtonItem.button.title.color = .white
        AdyenAppearance.dropInStyle = dropInStyle
    }

    private func setCardComponentStyle() {
        var cardComponentStyle = Adyen.FormComponentStyle()
        cardComponentStyle.mainButtonItem.button.backgroundColor = .black
        cardComponentStyle.mainButtonItem.button.title.color = .white
        AdyenAppearance.cardComponentStyle = cardComponentStyle
    }
    
    internal func color(hex: UInt) -> UIColor {
        assert(
            hex >= 0x000000 && hex <= 0xFFFFFF,
            "Invalid Hexadecimal color, Hexadecimal number should be between 0x0 and 0xFFFFFF"
        )
        return UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}
