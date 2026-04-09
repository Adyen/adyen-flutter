import Flutter

class BlikComponentFactory: ComponentFactory {
    static let blikComponentAdvancedId = "blikComponentAdvanced"
    static let blikComponentSessionId = "blikComponentSession"
    let viewTypeId: String
    let checkoutHolder: CheckoutHolder?

    init(
        messenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi,
        viewTypeId: String,
        checkoutHolder: CheckoutHolder? = nil
    ) {
        self.viewTypeId = viewTypeId
        self.checkoutHolder = checkoutHolder
        super.init(
            messenger: messenger,
            componentFlutterApi: componentFlutterApi,
            componentPlatformApi: componentPlatformApi
        )
    }

    override func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        if viewTypeId == BlikComponentFactory.blikComponentSessionId, let checkoutHolder {
            return BlikSessionComponent(
                frame: frame,
                viewIdentifier: viewId,
                arguments: args as? NSDictionary ?? [:],
                binaryMessenger: messenger,
                componentFlutterApi: componentFlutterApi,
                componentPlatformApi: componentPlatformApi,
                checkoutHolder: checkoutHolder
            )
        } else {
            return BlikAdvancedComponent(
                frame: frame,
                viewIdentifier: viewId,
                arguments: args as? NSDictionary ?? [:],
                binaryMessenger: messenger,
                componentFlutterApi: componentFlutterApi,
                componentPlatformApi: componentPlatformApi
            )
        }
    }
}
