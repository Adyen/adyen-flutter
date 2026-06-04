@_spi(AdyenInternal) import Adyen
@_spi(AdyenInternal) import AdyenCheckout
import Flutter

class BaseCardComponent: BasePlatformViewComponent {
    let cardComponentConfigurationKey = "cardComponentConfiguration"
    let isStoredPaymentMethodKey = "isStoredPaymentMethod"
    let cardComponentConfiguration: CardComponentConfigurationDTO?
    let isStoredPaymentMethod: Bool
    let storedCardComponentAdditionalHeight = 256.0
    let paymentMethod: String?
    var cardComponent: CheckoutPaymentComponent?
    var contentOffset: CGPoint?

    init(
        frame _: CGRect,
        viewIdentifier: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi
    ) {
        cardComponentConfiguration = arguments.value(forKey: cardComponentConfigurationKey) as? CardComponentConfigurationDTO
        paymentMethod = arguments.value(forKey: Constants.paymentMethodKey) as? String
        isStoredPaymentMethod = arguments.value(forKey: isStoredPaymentMethodKey) as? Bool ?? false
        let componentId = arguments.value(forKey: Constants.componentIdKey) as? String ?? ""
        super.init(
            viewId: viewIdentifier,
            componentId: componentId,
            componentFlutterApi: componentFlutterApi,
            componentPlatformApi: componentPlatformApi
        )
    }
    
    func buildCardComponent(adyenCheckout: PaymentCheckout, cardPaymentMethod: PaymentMethod) throws -> CheckoutPaymentComponent {
        try adyenCheckout.createPaymentComponent(for: cardPaymentMethod.type)
    }

//    func buildCardComponent(
//        paymentMethodString: String?,
//        isStoredPaymentMethod: Bool,
//        cardComponentConfiguration: CardComponentConfigurationDTO?,
//        componentDelegate: PaymentComponentDelegate?,
//        cardDelegate: CardComponentDelegate?
//    ) throws -> CardComponent {
//        guard let paymentMethodString = paymentMethod else { throw PlatformError(errorDescription: "Payment method not found") }
//        guard let cardComponentConfiguration else { throw PlatformError(errorDescription: "Card configuration not found") }
//        let adyenContext = try cardComponentConfiguration.createAdyenContext()
//        let cardConfiguration = cardComponentConfiguration.cardConfiguration.mapToCardComponentConfiguration(
//            shopperLocale: cardComponentConfiguration.shopperLocale)
//        let paymentMethod: AnyCardPaymentMethod = isStoredPaymentMethod
//            ? try JSONDecoder().decode(StoredCardPaymentMethod.self, from: Data(paymentMethodString.utf8))
//            : try JSONDecoder().decode(CardPaymentMethod.self, from: Data(paymentMethodString.utf8))
//        let cardComponent = CardComponent(
//            paymentMethod: paymentMethod,
//            context: adyenContext,
//            configuration: cardConfiguration
//        )
//        cardComponent.delegate = componentDelegate
//        cardComponent.cardComponentDelegate = cardDelegate
//        return cardComponent
//    }

    func showCardComponent(cardComponent: CheckoutPaymentComponent) {
        self.cardComponent = cardComponent
        if isStoredPaymentMethod {
            let storedCardViewController = cardComponent.viewController
            attachActivityIndicator()
            getViewController()?.present(storedCardViewController!, animated: true)
        } else {
            guard let cardView = cardComponent.viewController!.view else { return }
            attachCardView(cardView: cardView)
        }
    }

    func attachCardView(cardView: UIView) {
        componentWrapperView.addArrangedSubview(cardView)
        disableNativeScrollingAndBouncing(componentView: cardView)
        notifyHeightChanged()
    }

    func attachActivityIndicator() {
        let activityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicatorView.color = .gray
        activityIndicatorView.startAnimating()
        componentWrapperView.addArrangedSubview(activityIndicatorView)
    }

    func finalizeAndDismiss(
        success: Bool,
        completion: @escaping (() -> Void)
    ) {
//        cardComponent?.finalizeIfNeeded(with: success) { [weak self] in
//            self?.getViewController()?.dismiss(animated: true, completion: {
//                completion()
//            })
//        }
    }

    override func onDispose() {
        cardComponent = nil
    }

    override func componentViewPreferredContentHeight() -> CGFloat? {
        cardComponent?.viewController?.preferredContentSize.height
    }

    override func additionalViewportSpace() -> CGFloat {
        isStoredPaymentMethod ? storedCardComponentAdditionalHeight : 0
    }
}

// TODO: v6 migration - CardComponent and CardComponentDelegate are now package-access.
// Bin lookup / bin value callbacks need to be wired through CheckoutPaymentComponent or CardConfiguration callbacks.
