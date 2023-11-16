@_spi(AdyenInternal)
import Adyen
import AdyenNetworking
import Flutter

class BaseCardComponent: NSObject, FlutterPlatformView, UIScrollViewDelegate {
    let componentFlutterApi: ComponentFlutterApi
    let componentPlatformApi: ComponentPlatformApi
    let componentWrapperView: ComponentWrapperView
    let configurationMapper = ConfigurationMapper()

    var cardComponent: CardComponent?
    var cardDelegate: PaymentComponentDelegate?
    var contentOffset : CGPoint?

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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.contentOffset = .zero
    }

    func getViewController() -> UIViewController? {
        var rootViewController = UIApplication.shared.adyen.mainKeyWindow?.rootViewController
        while let presentedViewController = rootViewController?.presentedViewController {
            rootViewController = presentedViewController
        }

        return rootViewController
    }

    func attachCardView(cardComponentView: UIView) {
        componentWrapperView.addSubview(cardComponentView)
        disableNativeScrollingAndBouncing(cardComponentView: cardComponentView)
        adjustCardComponentLayout(cardComponentView: cardComponentView)
        sendHeightUpdate()
    }

    func sendErrorToFlutterLayer(errorMessage: String) {
        let componentCommunicationModel = ComponentCommunicationModel(type: ComponentCommunicationType.error,
                                                                      data: errorMessage)
        componentFlutterApi.onComponentCommunication(componentCommunicationModel: componentCommunicationModel, completion: { _ in })
    }

    private func disableNativeScrollingAndBouncing(cardComponentView: UIView) {
        let formView = cardComponentView.subviews[0].subviews[0] as? UIScrollView
        formView?.delegate = self
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
            self.sendHeightUpdate()
        }
        
        componentPlatformApi.onUpdateViewHeightCallback = {
            self.sendHeightUpdate()
        }
    }
    
    private func sendHeightUpdate() {
        guard let viewHeight = self.cardComponent?.viewController.preferredContentSize.height else { return }
        let roundedViewHeight = Double(round(100 * viewHeight / 100))
        self.componentFlutterApi.onComponentCommunication(componentCommunicationModel: ComponentCommunicationModel(type: ComponentCommunicationType.resize, data: roundedViewHeight), completion: { _ in })
    }
}
