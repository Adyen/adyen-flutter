import Flutter
import UIKit

public class AdyenCheckoutPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger: FlutterBinaryMessenger = registrar.messenger()
        
        //DropIn
        let checkoutFlutterApi = CheckoutFlutterApi(binaryMessenger: messenger)
        let checkoutPlatformApi = CheckoutPlatformApi(checkoutFlutterApi: checkoutFlutterApi)
        CheckoutPlatformInterfaceSetup.setUp(binaryMessenger: messenger, api: checkoutPlatformApi)
        
        //Component
        let componentFlutterApi = ComponentFlutterApi(binaryMessenger: messenger)
        let cardComponentAdvancedFlowFactory = CardComponentViewFactory(messenger: messenger, componentFlutterApi: componentFlutterApi)
        registrar.register(cardComponentAdvancedFlowFactory, withId: "cardComponentAdvancedFlow")
        let cardComponentSessionFlowFactory = CardComponentViewFactory(messenger: messenger, componentFlutterApi: componentFlutterApi)
        registrar.register(cardComponentAdvancedFlowFactory, withId: "cardComponentSessionFlow")
    }
}
