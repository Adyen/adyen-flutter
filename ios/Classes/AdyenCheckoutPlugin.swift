import Flutter
import UIKit

public class AdyenCheckoutPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let api: CheckoutPlatformApi = CheckoutPlatformApi()
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        CheckoutPlatformApiInterfaceSetup.setUp(binaryMessenger: messenger, api: api)
    }
    
}
