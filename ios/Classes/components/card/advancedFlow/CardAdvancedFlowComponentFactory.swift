import Flutter

class CardAdvancedFlowComponentFactory: ComponentFactory {
    override func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return CardAdvancedFlowComponent(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args as? NSDictionary ?? [:],
            binaryMessenger: super.messenger,
            componentFlutterApi: super.componentFlutterApi
        )
    }
}
