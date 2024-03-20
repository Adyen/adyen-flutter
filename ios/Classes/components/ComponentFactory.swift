import Flutter

class ComponentFactory: NSObject, FlutterPlatformViewFactory {
    let messenger: FlutterBinaryMessenger
    let componentFlutterApi: ComponentFlutterInterface
    let componentPlatformApi: ComponentPlatformApi

    init(
        messenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi
    ) {
        self.messenger = messenger
        self.componentFlutterApi = componentFlutterApi
        self.componentPlatformApi = componentPlatformApi
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
        componentFlutterApi.codec
    }
}
