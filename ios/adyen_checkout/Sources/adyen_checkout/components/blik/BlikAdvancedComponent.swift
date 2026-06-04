@_spi(AdyenInternal) import Adyen
@_spi(AdyenInternal) import AdyenCheckout
import Flutter
import Foundation

// TODO: v6 migration - ActionComponentDelegate, PaymentComponentDelegate, CheckoutActionComponent are now package-access.
class BlikAdvancedComponent: BaseBlikComponent, AdvancedComponentProtocol {
    override init(
        frame: CGRect,
        viewIdentifier: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi
    ) {
        super.init(
            frame: frame,
            viewIdentifier: viewIdentifier,
            arguments: arguments,
            binaryMessenger: binaryMessenger,
            componentFlutterApi: componentFlutterApi,
            componentPlatformApi: componentPlatformApi
        )
        // TODO: v6 migration - Set up BLIK component through Checkout.setup() like CardAdvancedComponent
        sendErrorToFlutterLayer(errorMessage: "BLIK advanced component not yet migrated to v6.")
    }

    func stopLoadingOnError() {}

    override func onDispose() {
        super.onDispose()
    }
}
