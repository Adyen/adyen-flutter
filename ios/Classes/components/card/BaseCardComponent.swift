@_spi(AdyenInternal)
import Adyen
import AdyenNetworking
import Flutter

class BaseCardComponent: NSObject, FlutterPlatformView {
    let componentFlutterApi: ComponentFlutterApi
    let componentPlatformApi: ComponentPlatformApi
    let componentWrapperView: ComponentWrapperView
    let configurationMapper = ConfigurationMapper()

    var cardComponent: CardComponent?
    var cardDelegate: PaymentComponentDelegate?
    var actionComponent: AdyenActionComponent?

    init(
        frame _: CGRect,
        viewIdentifier _: Int64,
        arguments _: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterApi
    ) {
        self.componentFlutterApi = componentFlutterApi
        componentPlatformApi = ComponentPlatformApi()
        componentWrapperView = .init()
        ComponentPlatformInterfaceSetup.setUp(binaryMessenger: binaryMessenger, api: componentPlatformApi)
        super.init()

        setupResizeViewportCallback()
    }

    func view() -> UIView {
        return componentWrapperView
    }

    func getViewController() -> UIViewController? {
        var rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        while let presentedViewController = rootViewController?.presentedViewController {
            let type = String(describing: type(of: presentedViewController))
            // TODO: - We need to discuss how the SDK should react if a DropInNavigationController is already displayed
            if type == "DropInNavigationController" {
                return nil
            } else {
                rootViewController = presentedViewController
            }
        }

        return rootViewController
    }

    func attachCardView(cardComponentView: UIView) {
        componentWrapperView.addSubview(cardComponentView)
        disableNativeScrollingAndBouncing(cardComponentView: cardComponentView)
        adjustCardComponentLayout(cardComponentView: cardComponentView)
    }

    private func disableNativeScrollingAndBouncing(cardComponentView: UIView) {
        let formView = cardComponentView.subviews[0].subviews[0] as? UIScrollView
        formView?.bounces = false
        formView?.isScrollEnabled = false
        formView?.alwaysBounceVertical = false
        formView?.contentInsetAdjustmentBehavior = .never
    }

    private func adjustCardComponentLayout(cardComponentView: UIView) {
        cardComponentView.translatesAutoresizingMaskIntoConstraints = false
        let leadingConstraint = cardComponentView.leadingAnchor.constraint(equalTo: componentWrapperView.leadingAnchor)
        let trailingConstraint = cardComponentView.trailingAnchor.constraint(equalTo: componentWrapperView.trailingAnchor)
        let topConstraint = cardComponentView.topAnchor.constraint(equalTo: componentWrapperView.topAnchor)
        let bottomConstraint = cardComponentView.bottomAnchor.constraint(equalTo: componentWrapperView.bottomAnchor)
        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])
    }

    private func setupResizeViewportCallback() {
        componentWrapperView.resizeViewportCallback = {
            var viewHeight = self.cardComponent?.viewController.preferredContentSize.height ?? 0
            viewHeight += 32 // TODO: adjust view by preventing clamping scroll to prevent bottom view overscroll
            let roundedViewHeight = Double(round(100 * viewHeight / 100))
            self.componentFlutterApi.onComponentCommunication(componentCommunicationModel: ComponentCommunicationModel(type: ComponentCommunicationType.resize, data: roundedViewHeight), completion: { _ in })
        }
    }
}
