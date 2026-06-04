@_spi(AdyenInternal) import Adyen
@_spi(AdyenInternal) import AdyenCheckout
import Flutter

// TODO: v6 migration - BLIKComponent, PaymentComponentDelegate are now package-access.
class BaseBlikComponent: BasePlatformViewComponent {
    let blikComponentConfigurationKey = "blikComponentConfiguration"
    let blikComponentConfiguration: BlikComponentConfigurationDTO?
    let paymentMethod: String?
    var blikComponent: CheckoutPaymentComponent?

    init(
        frame _: CGRect,
        viewIdentifier: Int64,
        arguments: NSDictionary,
        binaryMessenger _: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi
    ) {
        blikComponentConfiguration = arguments.value(forKey: blikComponentConfigurationKey) as? BlikComponentConfigurationDTO
        paymentMethod = arguments.value(forKey: Constants.paymentMethodKey) as? String
        let componentId = arguments.value(forKey: Constants.componentIdKey) as? String ?? ""
        super.init(
            viewId: viewIdentifier,
            componentId: componentId,
            componentFlutterApi: componentFlutterApi,
            componentPlatformApi: componentPlatformApi
        )
    }

    func buildBlikComponent(adyenCheckout: PaymentCheckout, blikPaymentMethod: PaymentMethod) throws -> CheckoutPaymentComponent {
        try adyenCheckout.createPaymentComponent(for: blikPaymentMethod.type)
    }

    func showBlikComponent(blikComponent: CheckoutPaymentComponent) {
        self.blikComponent = blikComponent
        guard let blikView = blikComponent.viewController?.view else { return }
        componentWrapperView.addArrangedSubview(blikView)
        disableNativeScrollingAndBouncing(componentView: blikView)
        notifyHeightChanged()
    }

    func finalizeAndDismiss(
        success: Bool,
        completion: @escaping (() -> Void)
    ) {
        // TODO: v6 migration - finalize through checkout callbacks
        completion()
    }

    override func onDispose() {
        blikComponent = nil
    }

    override func componentViewPreferredContentHeight() -> CGFloat? {
        blikComponent?.viewController?.preferredContentSize.height
    }
}
