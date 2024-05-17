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
        
        let componentPlatformApi = ComponentPlatformApi(componentFlutterApi: componentFlutterApi, sessionHolder: sessionHolder)
        ComponentPlatformInterfaceSetup.setUp(binaryMessenger: messenger, api: componentPlatformApi)
        CheckoutPlatformInterfaceSetup.setUp(binaryMessenger: messenger, api: checkoutPlatformApi)

        let dropInPlatformApi = DropInPlatformApi(dropInFlutterApi: dropInFlutterApi, sessionHolder: sessionHolder)
        DropInPlatformInterfaceSetup.setUp(binaryMessenger: messenger, api: dropInPlatformApi)

        let cardComponentAdvancedFactory = CardComponentFactory(
            messenger: messenger,
            componentFlutterApi: componentFlutterApi,
            componentPlatformApi: componentPlatformApi,
            viewTypeId: CardComponentFactory.cardComponentAdvancedId
        )
        registrar.register(cardComponentAdvancedFactory, withId: CardComponentFactory.cardComponentAdvancedId)
        let cardComponentSessionFactory = CardComponentFactory(
            messenger: messenger,
            componentFlutterApi: componentFlutterApi,
            componentPlatformApi: componentPlatformApi,
            viewTypeId: CardComponentFactory.cardComponentSessionId,
            sessionHolder: sessionHolder
        )
        registrar.register(cardComponentSessionFactory, withId: CardComponentFactory.cardComponentSessionId)
    }
}
