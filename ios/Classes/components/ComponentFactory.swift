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
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        fatalError("Subclasses need to implement the `create()` method.")
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return componentFlutterApi.codec
    }
}
