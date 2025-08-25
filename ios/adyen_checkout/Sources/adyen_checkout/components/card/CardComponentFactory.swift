import Flutter

class CardComponentFactory: ComponentFactory {
    static let cardComponentAdvancedId = "cardComponentAdvanced"
    static let cardComponentSessionId = "cardComponentSession"
    let viewTypeId: String
    let sessionHolder: SessionHolder?

    init(
        messenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi,
        viewTypeId: String,
        sessionHolder: SessionHolder? = nil
    ) {
        self.viewTypeId = viewTypeId
        self.sessionHolder = sessionHolder
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
        if viewTypeId == CardComponentFactory.cardComponentSessionId, sessionHolder != nil {
            return CardSessionComponent(
                frame: frame,
                viewIdentifier: viewId,
                arguments: args as? NSDictionary ?? [:],
                binaryMessenger: messenger,
                componentFlutterApi: componentFlutterApi,
                componentPlatformApi: componentPlatformApi,
                sessionHolder: sessionHolder!
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
