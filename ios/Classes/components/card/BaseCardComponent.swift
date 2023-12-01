@_spi(AdyenInternal)
import Adyen
import AdyenNetworking
import Flutter

class BaseCardComponent: NSObject, FlutterPlatformView, UIScrollViewDelegate {
    let cardComponentConfigurationKey = "cardComponentConfiguration"
    let isStoredPaymentMethodKey = "isStoredPaymentMethod"
    let paymentMethodKey = "paymentMethod"
    let cardComponentConfiguration: CardComponentConfigurationDTO?
    let isStoredPaymentMethod: Bool
    let paymentMethod: String?
    let componentFlutterApi: ComponentFlutterInterface
    let componentPlatformApi: ComponentPlatformApi
    let componentWrapperView: ComponentWrapperView
    let configurationMapper = ConfigurationMapper()

    var cardComponent: CardComponent?
    var cardDelegate: PaymentComponentDelegate?
    var presentationDelegate: PresentationDelegate?
    var contentOffset: CGPoint?

    init(
        frame _: CGRect,
        viewIdentifier _: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface
    ) {
        self.componentFlutterApi = componentFlutterApi
        cardComponentConfiguration = arguments.value(forKey: cardComponentConfigurationKey) as? CardComponentConfigurationDTO
        paymentMethod = arguments.value(forKey: paymentMethodKey) as? String
        isStoredPaymentMethod = arguments.value(forKey: isStoredPaymentMethodKey) as? Bool ?? false
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

    func showCardComponent() {
        if isStoredPaymentMethod {
            guard let storedCardViewController = cardComponent?.viewController else { return }
            attachActivityIndicator()
            getViewController()?.presentViewController(storedCardViewController, animated: true)
        } else {
            guard let cardView = cardComponent?.viewController.view else { return }
            attachCardView(cardView: cardView)
        }
    }

    func attachCardView(cardView: UIView) {
        componentWrapperView.addSubview(cardView)
        disableNativeScrollingAndBouncing(cardView: cardView)
        adjustCardComponentLayout(cardView: cardView)
        sendHeightUpdate()
    }

    func attachActivityIndicator() {
        let activityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicatorView.color = .gray
        activityIndicatorView.startAnimating()
        componentWrapperView.addSubview(activityIndicatorView)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        let leadingConstraint = activityIndicatorView.leadingAnchor.constraint(equalTo: componentWrapperView.leadingAnchor)
        let trailingConstraint = activityIndicatorView.trailingAnchor.constraint(equalTo: componentWrapperView.trailingAnchor)
        let topConstraint = activityIndicatorView.topAnchor.constraint(equalTo: componentWrapperView.topAnchor)
        let bottomConstraint = activityIndicatorView.bottomAnchor.constraint(equalTo: componentWrapperView.bottomAnchor)
        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])
    }

    func sendErrorToFlutterLayer(errorMessage: String) {
        let componentCommunicationModel = ComponentCommunicationModel(type: ComponentCommunicationType.error,
                                                                      data: errorMessage)
        componentFlutterApi.onComponentCommunication(componentCommunicationModel: componentCommunicationModel, completion: { _ in })
    }

    func finalizeAndDismiss(success: Bool, completion: @escaping (() -> Void)) {
        cardComponent?.finalizeIfNeeded(with: success) { [weak self] in
            // Is this viewcontroller access correct?
            self?.getViewController()?.dismiss(animated: true, completion: {
                completion()
            })
        }
    }

    private func disableNativeScrollingAndBouncing(cardView: UIView) {
        let formView = cardView.subviews[0].subviews[0] as? UIScrollView
        formView?.delegate = self
        formView?.bounces = false
        formView?.isScrollEnabled = false
        formView?.alwaysBounceVertical = false
        formView?.contentInsetAdjustmentBehavior = .never
    }

    private func adjustCardComponentLayout(cardView: UIView) {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        let leadingConstraint = cardView.leadingAnchor.constraint(equalTo: componentWrapperView.leadingAnchor)
        let trailingConstraint = cardView.trailingAnchor.constraint(equalTo: componentWrapperView.trailingAnchor)
        let topConstraint = cardView.topAnchor.constraint(equalTo: componentWrapperView.topAnchor)
        let bottomConstraint = cardView.bottomAnchor.constraint(equalTo: componentWrapperView.bottomAnchor)
        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])
    }

    private func setupResizeViewportCallback() {
        componentWrapperView.resizeViewportCallback = { [weak self] in
            self?.sendHeightUpdate()
        }

        componentPlatformApi.onUpdateViewHeightCallback = { [weak self] in
            self?.sendHeightUpdate()
        }
    }

    private func sendHeightUpdate() {
        guard let viewHeight = cardComponent?.viewController.preferredContentSize.height else { return }
        let roundedViewHeight = Double(round(100 * viewHeight / 100))
        componentFlutterApi.onComponentCommunication(componentCommunicationModel: ComponentCommunicationModel(type: ComponentCommunicationType.resize, data: roundedViewHeight), completion: { _ in })
    }
}
