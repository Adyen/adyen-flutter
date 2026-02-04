@_spi(AdyenInternal) import Adyen
@_spi(AdyenInternal) import AdyenCheckout
import Flutter

#if canImport(AdyenCard)
    import AdyenCard
#endif
#if canImport(AdyenNetworking)
    import AdyenNetworking
#endif

class BaseCardComponent: NSObject, FlutterPlatformView, UIScrollViewDelegate {
    let cardComponentConfigurationKey = "cardComponentConfiguration"
    let isStoredPaymentMethodKey = "isStoredPaymentMethod"
    let paymentMethodKey = "paymentMethod"
    let componentIdKey = "componentId"
    let cardComponentConfiguration: CardComponentConfigurationDTO?
    let isStoredPaymentMethod: Bool
    let paymentMethod: String?
    let componentId: String
    let componentFlutterApi: ComponentFlutterInterface
    let componentPlatformApi: ComponentPlatformApi
    let componentWrapperView: ComponentWrapperView

    var cardComponent: CheckoutPaymentComponent?
    var checkout: Checkout? = nil
    var contentOffset: CGPoint?

    init(
        frame _: CGRect,
        viewIdentifier _: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterInterface,
        componentPlatformApi: ComponentPlatformApi
    ) {
        self.componentFlutterApi = componentFlutterApi
        self.componentPlatformApi = componentPlatformApi
        cardComponentConfiguration = arguments.value(forKey: cardComponentConfigurationKey) as? CardComponentConfigurationDTO
        paymentMethod = arguments.value(forKey: paymentMethodKey) as? String
        isStoredPaymentMethod = arguments.value(forKey: isStoredPaymentMethodKey) as? Bool ?? false
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
    
    func buildCardComponent(adyenCheckout : Checkout, cardPaymentMethod: PaymentMethod) throws -> CheckoutPaymentComponent {
        guard let component = adyenCheckout.createPaymentComponent(for: cardPaymentMethod.type) else {throw PlatformError() }
        return component
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
            getViewController()?.presentViewController(storedCardViewController!, animated: true)
        } else {
            guard let cardView = cardComponent.viewController!.view else { return }
            attachCardView(cardView: cardView)
        }
    }

    func attachCardView(cardView: UIView) {
        componentWrapperView.addArrangedSubview(cardView)
        disableNativeScrollingAndBouncing(cardView: cardView)
        sendHeightUpdate()
    }

    func attachActivityIndicator() {
        let activityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicatorView.color = .gray
        activityIndicatorView.startAnimating()
        componentWrapperView.addArrangedSubview(activityIndicatorView)
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
//        cardComponent?.finalizeIfNeeded(with: success) { [weak self] in
//            self?.getViewController()?.dismiss(animated: true, completion: {
//                completion()
//            })
//        }
    }

    private func disableNativeScrollingAndBouncing(cardView: UIView) {
        let formView = cardView.subviews[0].subviews[0] as? UIScrollView
        formView?.delegate = self
        formView?.bounces = false
        formView?.isScrollEnabled = false
        formView?.alwaysBounceVertical = false
        formView?.contentInsetAdjustmentBehavior = .never
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
        guard let viewHeight = cardComponent?.viewController?.preferredContentSize.height else { return }
        let additionalViewportSpace = determineAdditionalViewportSpace()
        let roundedViewHeight = Int(viewHeight + additionalViewportSpace)
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
    
    private func determineAdditionalViewportSpace() -> CGFloat {
        if isStoredPaymentMethod {
            return 256.0
        } else {
            return 0
        }
    }
}

extension BaseCardComponent {
    func didSubmit(lastFour: String, finalBIN: String, component: CardComponent) {}
    
    func didChangeBIN(_ value: String, component: CardComponent) {
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.binValue,
            componentId: componentId,
            data: value
        )
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }
    
    func didChangeCardBrand(_ value: [CardBrand]?, component: CardComponent) {
        guard let binLookupData = value else {
            return
        }
        
        let binLookupDataDtoList: [BinLookupDataDTO] = binLookupData.map { cardBrand in
            BinLookupDataDTO(brand: cardBrand.type.rawValue)
        }
        
        let componentCommunicationModel = ComponentCommunicationModel(
            type: ComponentCommunicationType.binLookup,
            componentId: componentId,
            data: binLookupDataDtoList
        )
        componentFlutterApi.onComponentCommunication(
            componentCommunicationModel: componentCommunicationModel,
            completion: { _ in }
        )
    }
}
