import Flutter
import UIKit

public class AdyenCheckoutPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger: FlutterBinaryMessenger = registrar.messenger()

        // DropIn
        let checkoutFlutterApi = CheckoutFlutterApi(binaryMessenger: messenger)
        let checkoutPlatformApi = CheckoutPlatformApi(checkoutFlutterApi: checkoutFlutterApi)
        CheckoutPlatformInterfaceSetup.setUp(binaryMessenger: messenger, api: checkoutPlatformApi)

        // Component
        let componentFlutterApi = ComponentFlutterInterface(binaryMessenger: messenger)
        let cardComponentAdvancedFlowFactory = CardAdvancedFlowComponentFactory(messenger: messenger, componentFlutterApi: componentFlutterApi)
        registrar.register(cardComponentAdvancedFlowFactory, withId: "cardComponentAdvancedFlow")
        let cardComponentSessionFlowFactory = CardSessionFlowComponentFactory(messenger: messenger, componentFlutterApi: componentFlutterApi)
        registrar.register(cardComponentSessionFlowFactory, withId: "cardComponentSessionFlow")
    }
}
