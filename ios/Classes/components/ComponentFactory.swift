import Flutter

class ComponentFactory: NSObject, FlutterPlatformViewFactory {
    let messenger: FlutterBinaryMessenger
    let componentFlutterApi: ComponentFlutterApi

    init(messenger: FlutterBinaryMessenger, componentFlutterApi: ComponentFlutterApi) {
        self.messenger = messenger
        self.componentFlutterApi = componentFlutterApi

        super.init()
    }

    func create(
        withFrame _: CGRect,
        viewIdentifier _: Int64,
        arguments _: Any?
    ) -> FlutterPlatformView {
        fatalError("Subclasses need to implement the `create()` method.")
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return componentFlutterApi.codec
    }
}
