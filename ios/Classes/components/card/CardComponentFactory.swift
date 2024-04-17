import Flutter
@_spi(AdyenInternal) import Adyen

class CardComponentFactory: ComponentFactory, SessionSetupProtocol {
    static let cardComponentAdvancedId = "cardComponentAdvanced"
    static let cardComponentSessionId = "cardComponentSession"
    private let viewTypeId: String
    var sessionWrapper: SessionWrapper?

    init(
        messenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi,
        viewTypeId: String
    ) {
        self.viewTypeId = viewTypeId
        super.init(
            messenger: messenger,
            componentFlutterApi: componentFlutterApi,
            componentPlatformApi: componentPlatformApi
        )
    }

    override func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        if viewTypeId == CardComponentFactory.cardComponentSessionId, sessionWrapper != nil {
            return CardSessionComponent(
                frame: frame,
                viewIdentifier: viewId,
                arguments: args as? NSDictionary ?? [:],
                binaryMessenger: messenger,
                componentFlutterApi: componentFlutterApi,
                componentPlatformApi: componentPlatformApi,
                sessionWrapper: sessionWrapper!
            )
        } else {
            return CardAdvancedComponent(
                frame: frame,
                viewIdentifier: viewId,
                arguments: args as? NSDictionary ?? [:],
                binaryMessenger: messenger,
                componentFlutterApi: componentFlutterApi,
                componentPlatformApi: componentPlatformApi
            )
        }
    }
    
    func setupSession(
        adyenContext: AdyenContext,
        sessionId: String,
        sessionData: String,
        completion: @escaping (Result<SessionDTO, Error>) -> Void
    ) {
        let sessionDelegate = ComponentSessionFlowDelegate(componentFlutterApi: componentFlutterApi)
        let sessionPresentationDelegate = ComponentPresentationDelegate(topViewController: getViewController())
        sessionWrapper = SessionWrapper()
        sessionWrapper?.setup(
            adyenContext: adyenContext,
            sessionId: sessionId,
            sessionData: sessionData,
            sessionDelegate: sessionDelegate,
            sessionPresentationDelegate: sessionPresentationDelegate,
            completion: completion
        )
    }
}
