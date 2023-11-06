import Flutter

class CardComponentViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    private let componentFlutterApi: ComponentFlutterApi

    init(messenger: FlutterBinaryMessenger, componentFlutterApi: ComponentFlutterApi) {
        self.messenger = messenger
        self.componentFlutterApi = componentFlutterApi

        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return CardAdvancedFlowComponent(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args as? NSDictionary ?? [:],
            binaryMessenger: messenger,
            componentFlutterApi: componentFlutterApi
        )
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return componentFlutterApi.codec
    }
}
