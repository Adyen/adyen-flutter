import Flutter

class ComponentFactory: NSObject, FlutterPlatformViewFactory {
    let messenger: FlutterBinaryMessenger
    let componentFlutterApi: ComponentFlutterInterface

    init(
        messenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface
    ) {
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
