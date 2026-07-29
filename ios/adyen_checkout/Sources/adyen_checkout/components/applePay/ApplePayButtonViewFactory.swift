import Flutter

@MainActor
final class ApplePayButtonViewFactory: NSObject, FlutterPlatformViewFactory {
    static let viewTypeId = "ApplePayButtonView"

    private let componentPlatformEventHandler: ComponentPlatformEventHandler

    init(componentPlatformEventHandler: ComponentPlatformEventHandler) {
        self.componentPlatformEventHandler = componentPlatformEventHandler
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier _: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        ApplePayButtonView(
            frame: frame,
            arguments: args as? [String: Any] ?? [:],
            componentPlatformEventHandler: componentPlatformEventHandler
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}
