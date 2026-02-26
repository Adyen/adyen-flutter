import Flutter

class CardComponentFactory: ComponentFactory {
    static let cardComponentAdvancedId = "cardComponentAdvanced"
    static let cardComponentSessionId = "cardComponentSession"
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
        if viewTypeId == CardComponentFactory.cardComponentSessionId, checkoutHolder != nil {
            return CardSessionComponent(
                frame: frame,
                viewIdentifier: viewId,
                arguments: args as? NSDictionary ?? [:],
                binaryMessenger: messenger,
                componentFlutterApi: componentFlutterApi,
                componentPlatformApi: componentPlatformApi,
                checkoutHolder: checkoutHolder!
            )
        } else {
            return CardAdvancedComponent(
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
