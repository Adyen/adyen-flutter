import AdyenCheckout
import Flutter
import Foundation

@MainActor
final class CheckoutPaymentViewFactory: NSObject, FlutterPlatformViewFactory {
    static let viewType = "AdyenCheckoutPaymentComponent"

    private let holder: CheckoutHolder
    private let events: ComponentPlatformEventHandler
    private let registry: CheckoutComponentRegistry

    init(holder: CheckoutHolder, events: ComponentPlatformEventHandler, registry: CheckoutComponentRegistry) {
        self.holder = holder
        self.events = events
        self.registry = registry
    }

    func create(
        withFrame _: CGRect,
        viewIdentifier _: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        guard let params = args as? CheckoutPaymentViewParamsDTO else {
            return FailedPlatformView()
        }
        return CheckoutPaymentView(params: params, holder: holder, events: events, registry: registry)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        PlatformApiPigeonCodec.shared
    }
}

@MainActor
private final class FailedPlatformView: NSObject, FlutterPlatformView {
    private let emptyView = UIView()

    func view() -> UIView {
        emptyView
    }
}
