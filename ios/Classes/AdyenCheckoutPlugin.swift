import Flutter
import UIKit
@_spi(AdyenInternal)
import Adyen

public class AdyenCheckoutPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        let checkoutFlutterApi = CheckoutFlutterApi(binaryMessenger: messenger)
        let api: CheckoutPlatformApi = CheckoutPlatformApi(checkoutFlutterApi: checkoutFlutterApi)
        CheckoutPlatformInterfaceSetup.setUp(binaryMessenger: messenger, api: api)
    }
    
}
