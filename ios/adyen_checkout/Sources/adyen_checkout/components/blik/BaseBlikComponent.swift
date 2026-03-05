@_spi(AdyenInternal) import Adyen
#if canImport(AdyenComponents)
    import AdyenComponents
#endif
import Flutter

class BaseBlikComponent: BasePlatformViewComponent {
    let blikComponentConfigurationKey = "blikComponentConfiguration"
    let paymentMethodKey = "paymentMethod"
    let componentIdKey = "componentId"
    let blikComponentConfiguration: BlikComponentConfigurationDTO?
    let paymentMethod: String?
    var blikComponent: BLIKComponent?
    
    init(
        frame _: CGRect,
        viewIdentifier _: Int64,
        arguments: NSDictionary,
        binaryMessenger _: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi
    ) {
        blikComponentConfiguration = arguments.value(forKey: blikComponentConfigurationKey) as? BlikComponentConfigurationDTO
        paymentMethod = arguments.value(forKey: paymentMethodKey) as? String
        let componentId = arguments.value(forKey: componentIdKey) as? String ?? ""
        super.init(
            componentId: componentId,
            componentFlutterApi: componentFlutterApi,
            componentPlatformApi: componentPlatformApi
        )
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
        let blikComponent = BLIKComponent(
            paymentMethod: paymentMethod,
            context: adyenContext,
            configuration: blikComponentConfiguration.mapToBlikComponentConfiguration()
        )
        blikComponent.delegate = componentDelegate
        return blikComponent
    }

    func showBlikComponent(blikComponent: BLIKComponent) {
        self.blikComponent = blikComponent
        guard let blikView = blikComponent.viewController.view else { return }
        componentWrapperView.addArrangedSubview(blikView)
        disableNativeScrollingAndBouncing(componentView: blikView)
        notifyHeightChanged()
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

    override func componentViewPreferredContentHeight() -> CGFloat? {
        blikComponent?.viewController.preferredContentSize.height
    }
}
