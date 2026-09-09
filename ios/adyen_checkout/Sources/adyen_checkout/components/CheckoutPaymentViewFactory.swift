import AdyenCheckout
import Flutter
import Foundation

@MainActor
final class CheckoutPaymentViewFactory: NSObject, FlutterPlatformViewFactory {
    static let viewType = "AdyenCheckoutPaymentComponent"

    private let holder: CheckoutHolder
    private let events: ComponentPlatformEventHandler

    init(holder: CheckoutHolder, events: ComponentPlatformEventHandler) {
        self.holder = holder
        self.events = events
    }

    func create(
        withFrame _: CGRect,
        viewIdentifier _: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let arguments = args as? NSDictionary ?? [:]
        return CheckoutPaymentView(
            checkoutId: arguments["checkoutId"] as? String ?? "",
            componentId: arguments["componentId"] as? String ?? "",
            paymentMethodJson: arguments["paymentMethod"] as? String ?? "",
            isStoredPaymentMethod: arguments["isStoredPaymentMethod"] as? Bool ?? false,
            applePayButtonTheme: arguments["applePayButtonTheme"] as? String,
            applePayButtonType: arguments["applePayButtonType"] as? String,
            applePayButtonCornerRadius: arguments["applePayButtonCornerRadius"] as? Double,
            applePayButtonWidth: arguments["applePayButtonWidth"] as? Double,
            applePayButtonHeight: arguments["applePayButtonHeight"] as? Double,
            holder: holder,
            events: events
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        PlatformApiPigeonCodec.shared
    }
}
