import Adyen
import Flutter
import UIKit

public class AdyenCheckoutPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let sessionHolder = SessionHolder()
        let messenger: FlutterBinaryMessenger = registrar.messenger()
        let dropInFlutterApi = DropInFlutterInterface(binaryMessenger: messenger)
        let componentFlutterApi = ComponentFlutterInterface(binaryMessenger: messenger)
        let checkoutPlatformApi = CheckoutPlatformApi(
            dropInFlutterApi: dropInFlutterApi,
            componentFlutterApi: componentFlutterApi,
            sessionHolder: sessionHolder
        )
        CheckoutPlatformInterfaceSetup.setUp(binaryMessenger: messenger, api: checkoutPlatformApi)

        // DropIn
        let dropInPlatformApi = DropInPlatformApi(dropInFlutterApi: dropInFlutterApi, sessionHolder: sessionHolder)
        DropInPlatformInterfaceSetup.setUp(binaryMessenger: messenger, api: dropInPlatformApi)

        // Components
        let cardComponentAdvancedFactory = CardComponentFactory(
            messenger: messenger,
            componentFlutterApi: componentFlutterApi,
            viewTypeId: CardComponentFactory.cardComponentAdvancedId
        )
        registrar.register(cardComponentAdvancedFactory, withId: CardComponentFactory.cardComponentAdvancedId)
        let cardComponentSessionFactory = CardComponentFactory(
            messenger: messenger,
            componentFlutterApi: componentFlutterApi,
            viewTypeId: CardComponentFactory.cardComponentSessionId,
            sessionHolder: sessionHolder
        )
        registrar.register(cardComponentSessionFactory, withId: CardComponentFactory.cardComponentSessionId)
    }
}
