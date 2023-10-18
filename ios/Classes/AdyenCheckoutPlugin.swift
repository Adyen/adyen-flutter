import Flutter
import UIKit

public class AdyenCheckoutPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger: FlutterBinaryMessenger = registrar.messenger()
        let checkoutFlutterApi = CheckoutFlutterApi(binaryMessenger: messenger)
        let checkoutPlatformApi = CheckoutPlatformApi(checkoutFlutterApi: checkoutFlutterApi)
        CheckoutPlatformInterfaceSetup.setUp(binaryMessenger: messenger, api: checkoutPlatformApi)
        
        let factory = CardComponentViewFactory(messenger: registrar.messenger(), checkoutFlutterApi: checkoutFlutterApi)
        registrar.register(factory, withId: "<platform-view-type>")
    }
}
