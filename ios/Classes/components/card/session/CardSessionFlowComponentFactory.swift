import Flutter

class CardSessionFlowComponentFactory: ComponentFactory {
    let sessionHolder: SessionHolder

    init(messenger: FlutterBinaryMessenger, componentFlutterApi: ComponentFlutterInterface, sessionHolder: SessionHolder) {
        self.sessionHolder = sessionHolder

        super.init(messenger: messenger, componentFlutterApi: componentFlutterApi)
    }

    override func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return CardSessionFlowComponent(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args as? NSDictionary ?? [:],
            binaryMessenger: messenger,
            componentFlutterApi: componentFlutterApi,
            sessionHolder: sessionHolder
        )
    }
}
