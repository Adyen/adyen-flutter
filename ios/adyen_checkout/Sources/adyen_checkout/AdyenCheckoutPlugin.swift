import Flutter
import UIKit

@MainActor
public final class AdyenCheckoutPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let holder = CheckoutHolder()
        let messenger = registrar.messenger()
        let callbacksApi = CheckoutCallbacksFlutterApi(binaryMessenger: messenger)
        let actionOnlyApi = ActionOnlyFlutterApi(binaryMessenger: messenger)
        let events = ComponentPlatformEventHandler()
        let checkoutApi = CheckoutPlatformApi(
            callbacksApi: callbacksApi,
            actionOnlyApi: actionOnlyApi,
            holder: holder,
            events: events
        )
        let componentApi = ComponentPlatformApi()

        CheckoutHostApiSetup.setUp(binaryMessenger: messenger, api: checkoutApi)
        ComponentHostApiSetup.setUp(binaryMessenger: messenger, api: componentApi)
        EventsStreamHandler.register(with: messenger, streamHandler: events)
        registrar.register(
            CheckoutPaymentViewFactory(holder: holder, events: events),
            withId: CheckoutPaymentViewFactory.viewType
        )
    }
}
