import Adyen
import Flutter
import UIKit

public class AdyenCheckoutPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let sessionHolder = SessionHolder()
        let messenger: FlutterBinaryMessenger = registrar.messenger()
        let componentFlutterApi = ComponentFlutterInterface(binaryMessenger: messenger)
        let checkoutPlatformApi = CheckoutPlatformApi(componentFlutterApi: componentFlutterApi, sessionHolder: sessionHolder)
        CheckoutPlatformInterfaceSetup.setUp(binaryMessenger: messenger, api: checkoutPlatformApi)

        // DropIn
        let dropInFlutterApi = DropInFlutterInterface(binaryMessenger: messenger)
        let dropInPlatformApi = DropInPlatformApi(dropInFlutterApi: dropInFlutterApi, sessionHolder: sessionHolder)
        DropInPlatformInterfaceSetup.setUp(binaryMessenger: messenger, api: dropInPlatformApi)

        // Components
        let cardComponentAdvancedFlowFactory = CardAdvancedFlowComponentFactory(messenger: messenger, componentFlutterApi: componentFlutterApi)
        registrar.register(cardComponentAdvancedFlowFactory, withId: "cardComponentAdvancedFlow")
        let cardComponentSessionFlowFactory = CardSessionFlowComponentFactory(messenger: messenger, componentFlutterApi: componentFlutterApi, sessionHolder: sessionHolder)
        registrar.register(cardComponentSessionFlowFactory, withId: "cardComponentSessionFlow")
    }
}
