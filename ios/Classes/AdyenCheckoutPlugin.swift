import Adyen
import Flutter
import UIKit

public class AdyenCheckoutPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger: FlutterBinaryMessenger = registrar.messenger()
        let dropInFlutterApi = DropInFlutterInterface(binaryMessenger: messenger)
        let componentFlutterApi = ComponentFlutterInterface(binaryMessenger: messenger)
        let dropInSessionManager = DropInSessionManager(dropInFlutterApi: dropInFlutterApi)
        let dropInAdvancedManager = DropInAdvancedManager(dropInFlutterApi: dropInFlutterApi)
        let applePayComponentManager = ApplePayComponentManager(componentFlutterApi: componentFlutterApi)
        let componentPlatformApi = ComponentPlatformApi(applePayComponentManager: applePayComponentManager)
        ComponentPlatformInterfaceSetup.setUp(binaryMessenger: messenger, api: componentPlatformApi)

        let dropInPlatformApi = DropInPlatformApi(
            dropInFlutterApi: dropInFlutterApi,
            dropInSessionManager: dropInSessionManager,
            dropInAdvancedManager: dropInAdvancedManager
        )
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
            viewTypeId: CardComponentFactory.cardComponentSessionId
        )
        registrar.register(cardComponentSessionFactory, withId: CardComponentFactory.cardComponentSessionId)
        
        let checkoutPlatformApi = CheckoutPlatformApi(
            dropInFlutterApi: dropInFlutterApi,
            componentFlutterApi: componentFlutterApi,
            dropInSessionManager: dropInSessionManager,
            cardComponentSessionFactory: cardComponentSessionFactory,
            applePayComponentManager: applePayComponentManager
        )
        CheckoutPlatformInterfaceSetup.setUp(binaryMessenger: messenger, api: checkoutPlatformApi)
    }
}
