import Flutter
import UIKit

public class AdyenCheckoutPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let api: CheckoutPlatformApi = CheckoutPlatformApiImpl()
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        CheckoutPlatformApiSetup.setUp(binaryMessenger: messenger, api: api)
    }
    
}
