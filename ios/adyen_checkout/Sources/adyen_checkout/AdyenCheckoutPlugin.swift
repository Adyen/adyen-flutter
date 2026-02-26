import Flutter
import UIKit

public class AdyenCheckoutPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let checkoutHolder = CheckoutHolder()
        let messenger: FlutterBinaryMessenger = registrar.messenger()
        let checkoutFlutter = CheckoutFlutterInterface(binaryMessenger: messenger)
        let componentFlutterApi = ComponentFlutterInterface(binaryMessenger: messenger)
        //V2
        let adyenFlutterInterface = AdyenFlutterInterface(binaryMessenger: messenger)
        let componentPlatformEventHandler = ComponentPlatformEventHandler()
        let checkoutPlatformApi = CheckoutPlatformApi(
            checkoutFlutter: checkoutFlutter,
            componentFlutterApi: componentFlutterApi,
            adyenFlutterInterface: adyenFlutterInterface,
            componentPlatformEventHandler: componentPlatformEventHandler,
            checkoutHolder: checkoutHolder
        )
        
        let componentPlatformApi = ComponentPlatformApi(componentFlutterApi: componentFlutterApi, checkoutHolder: checkoutHolder)
        ComponentPlatformInterfaceSetup.setUp(binaryMessenger: messenger, api: componentPlatformApi)
        CheckoutPlatformInterfaceSetup.setUp(binaryMessenger: messenger, api: checkoutPlatformApi)

        let dropInPlatformApi = DropInPlatformApi(checkoutFlutter: checkoutFlutter, checkoutHolder: checkoutHolder)
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
            checkoutHolder: checkoutHolder
        )
        registrar.register(cardComponentSessionFactory, withId: CardComponentFactory.cardComponentSessionId)

        
        //V2
        OnPlatformEventStreamHandler.register(with: messenger, streamHandler: componentPlatformEventHandler)
        let adyenComponentSessionFactory = AdyenComponentFactory(
            adyenFlutterInterface: adyenFlutterInterface,
            componentPlatformEventHandler: componentPlatformEventHandler,
            checkoutHolder: checkoutHolder,
            viewTypeId: AdyenComponentFactory.adyenSessionComponentId
        )
        registrar.register(
            adyenComponentSessionFactory,
            withId: AdyenComponentFactory.adyenSessionComponentId
        )
        
        let adyenComponentAdvancedFactory = AdyenComponentFactory(
            adyenFlutterInterface: adyenFlutterInterface,
            componentPlatformEventHandler: componentPlatformEventHandler,
            checkoutHolder: checkoutHolder,
            viewTypeId: AdyenComponentFactory.adyenAdvancedComponentId
        )
        registrar.register(
            adyenComponentAdvancedFactory,
            withId: AdyenComponentFactory.adyenAdvancedComponentId
        )
    }
}
