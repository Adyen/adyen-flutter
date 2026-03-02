@_spi(AdyenInternal) import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import Flutter

class BaseBlikComponent: NSObject, FlutterPlatformView, UIScrollViewDelegate {
    let blikComponentConfigurationKey = "blikComponentConfiguration"
    let paymentMethodKey = "paymentMethod"
    let componentIdKey = "componentId"
    let blikComponentConfiguration: BlikComponentConfigurationDTO?
    let paymentMethod: String?
    let componentId: String
    let componentFlutterApi: ComponentFlutterInterface
    let componentPlatformApi: ComponentPlatformApi
    let componentWrapperView: ComponentWrapperView
    var blikComponent: BLIKComponent?
    
    init(
        frame _: CGRect,
        viewIdentifier _: Int64,
        arguments: NSDictionary,
        binaryMessenger _: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi
    ) {
        self.componentFlutterApi = componentFlutterApi
        self.componentPlatformApi = componentPlatformApi
        blikComponentConfiguration = arguments.value(forKey: blikComponentConfigurationKey) as? BlikComponentConfigurationDTO
        paymentMethod = arguments.value(forKey: paymentMethodKey) as? String
        componentId = arguments.value(forKey: componentIdKey) as? String ?? ""
        componentWrapperView = .init()
        super.init()

        setupResizeViewportCallback()
    }

    func view() -> UIView {
        componentWrapperView
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

    func buildBlikComponent(
        paymentMethodString: String?,
        blikComponentConfiguration: BlikComponentConfigurationDTO?,
        componentDelegate: PaymentComponentDelegate?
    ) throws -> BLIKComponent {
        guard let paymentMethodString else { throw PlatformError(errorDescription: "Payment method not found") }
        guard let blikComponentConfiguration else { throw PlatformError(errorDescription: "Blik configuration not found") }
        let adyenContext = try blikComponentConfiguration.createAdyenContext()
        let paymentMethod = try JSONDecoder().decode(BLIKPaymentMethod.self, from: Data(paymentMethodString.utf8))
        let blikComponentStyle = AdyenAppearance.blikComponentStyle
        let blikComponent = BLIKComponent(
            paymentMethod: paymentMethod,
            context: adyenContext,
            configuration: .init(style: blikComponentStyle)
        )
        blikComponent.delegate = componentDelegate
        return blikComponent
    }

    func showBlikComponent(blikComponent: BLIKComponent) {
        self.blikComponent = blikComponent
        guard let blikView = blikComponent.viewController.view else { return }
        componentWrapperView.addArrangedSubview(blikView)
        disableNativeScrollingAndBouncing(componentView: blikView)
        sendHeightUpdate()
    }

    func sendErrorToFlutterLayer(errorMessage: String) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.result,
            componentId: componentId,
            paymentResult: PaymentResultDTO(
                type: PaymentResultEnum.error,
                reason: errorMessage
            )
        )
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }

    func finalizeAndDismiss(
        success: Bool,
        completion: @escaping (() -> Void)
    ) {
        blikComponent?.finalizeIfNeeded(with: success) { [weak self] in
            self?.getViewController()?.dismiss(animated: true, completion: {
                completion()
            })
        }
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
        guard let viewHeight = blikComponent?.viewController.preferredContentSize.height else { return }
        let roundedViewHeight = Int(viewHeight)
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.resize,
            componentId: componentId,
            data: roundedViewHeight
        )
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }
    
    private func disableNativeScrollingAndBouncing(componentView: UIView) {
        let formView = componentView.subviews[0].subviews[0] as? UIScrollView
        formView?.delegate = self
        formView?.bounces = false
        formView?.isScrollEnabled = false
        formView?.alwaysBounceVertical = false
        formView?.contentInsetAdjustmentBehavior = .never
    }
}
