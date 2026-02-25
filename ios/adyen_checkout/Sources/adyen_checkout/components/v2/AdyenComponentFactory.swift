import Flutter

final class AdyenComponentFactory: NSObject, FlutterPlatformViewFactory {
    static let adyenAdvancedComponentId = "AdyenAdvancedComponent"
    static let adyenSessionComponentId = "AdyenSessionComponent"

    private let adyenFlutterInterface: AdyenFlutterInterface
    private let componentPlatformEventHandler: ComponentPlatformEventHandler
    private let sessionHolder: SessionHolder
    private let viewTypeId: String

    init(
        adyenFlutterInterface: AdyenFlutterInterface,
        componentPlatformEventHandler: ComponentPlatformEventHandler,
        sessionHolder: SessionHolder,
        viewTypeId: String
    ) {
        self.adyenFlutterInterface = adyenFlutterInterface
        self.componentPlatformEventHandler = componentPlatformEventHandler
        self.sessionHolder = sessionHolder
        self.viewTypeId = viewTypeId
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        AdyenComponent(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args as? NSDictionary ?? [:],
            adyenFlutterInterface: adyenFlutterInterface,
            componentPlatformEventHandler: componentPlatformEventHandler,
            sessionHolder: sessionHolder,
            viewTypeId: viewTypeId
        )
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        adyenFlutterInterface.codec
    }
}
