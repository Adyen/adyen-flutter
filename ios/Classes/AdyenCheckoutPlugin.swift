import Adyen
import Flutter
import UIKit

public class AdyenCheckoutPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger: FlutterBinaryMessenger = registrar.messenger()
        let componentFlutterApi = ComponentFlutterInterface(binaryMessenger: messenger)

        // Session
        let sessionHolder = SessionHolder()

        // DropIn
        let checkoutFlutterApi = CheckoutFlutterApi(binaryMessenger: messenger)
        let checkoutPlatformApi = CheckoutPlatformApi(checkoutFlutterApi: checkoutFlutterApi, componentFlutterApi: componentFlutterApi, sessionHolder: sessionHolder)
        CheckoutPlatformInterfaceSetup.setUp(binaryMessenger: messenger, api: checkoutPlatformApi)

        // Components
        let cardComponentAdvancedFlowFactory = CardAdvancedFlowComponentFactory(messenger: messenger, componentFlutterApi: componentFlutterApi)
        registrar.register(cardComponentAdvancedFlowFactory, withId: "cardComponentAdvancedFlow")
        let cardComponentSessionFlowFactory = CardSessionFlowComponentFactory(messenger: messenger, componentFlutterApi: componentFlutterApi, sessionHolder: sessionHolder)
        registrar.register(cardComponentSessionFlowFactory, withId: "cardComponentSessionFlow")
    }
}
