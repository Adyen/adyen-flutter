import Flutter

class CardSessionFlowComponentFactory: ComponentFactory {
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
            componentFlutterApi: componentFlutterApi
        )
    }
}
