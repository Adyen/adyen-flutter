@_spi(AdyenInternal)
import Adyen
import AdyenNetworking
import Flutter

class CardAdvancedFlowComponent: NSObject, FlutterPlatformView {
    private let componentFlutterApi: ComponentFlutterApi
    private let componentPlatformApi: ComponentPlatformApi
    private let componentWrapperView: ComponentWrapperView
    private let actionComponentDelegate: ActionComponentDelegate
    private let presentationDelegate: PresentationDelegate
    private let configurationMapper: ConfigurationMapper
    private let initialFrame: CGRect
    private var cardComponent: CardComponent?
    private var cardDelegate: CardAdvancedFlowDelegate?
    private var actionComponent: AdyenActionComponent?
    private var rootViewController: UIViewController?

    init(
        frame: CGRect,
        viewIdentifier _: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterApi
    ) {
        self.componentFlutterApi = componentFlutterApi
        componentPlatformApi = ComponentPlatformApi()
        actionComponentDelegate = CardAdvancedFlowActionComponentDelegate(componentFlutterApi: componentFlutterApi)
        presentationDelegate = CardAdvancedFlowPresentationDelegate()
        componentWrapperView = .init()
        configurationMapper = ConfigurationMapper()
        initialFrame = frame
        super.init()

        ComponentPlatformInterfaceSetup.setUp(binaryMessenger: binaryMessenger, api: componentPlatformApi)
        setupCallbacks()
        setupCardView(arguments: arguments)
    }

    func view() -> UIView {
        return componentWrapperView
    }
    
    private func setupCardView(arguments: NSDictionary) {
        do {
            let cardView = try createCardComponentView(arguments: arguments)
            componentWrapperView.addSubview(cardView)
            adjustCardComponentLayout(cardView: cardView)
        } catch {
            // TODO: Dispaly error
        }
    }

    private func setupCallbacks() {
        componentWrapperView.resizeViewportCallback = {
            var viewHeight = Double(round(100 * (self.cardComponent?.viewController.preferredContentSize.height ?? 0)) / 100)
            viewHeight += 32 // TODO: adjust view by preventing clamping scroll to prevent bottom view overscroll
            self.componentFlutterApi.onComponentCommunication(componentCommunicationModel: ComponentCommunicationModel(type: ComponentCommunicationType.resize, data: viewHeight), completion: { _ in })
        }

        componentPlatformApi.onActionCallback = { [weak self] jsonActionResponse in
            self?.onAction(actionResponse: jsonActionResponse)
        }
    }

    private func createCardComponentView(arguments: NSDictionary) throws -> UIView {
        guard let paymentMethodsResponse = arguments.value(forKey: "paymentMethods") as? String else { throw PlatformError(errorDescription: "Payment methods not provided") }
        guard let cardComponentConfiguration = arguments.value(forKey: "cardComponentConfiguration") as? CardComponentConfigurationDTO else { throw PlatformError(errorDescription: "Card configuration not provided") }
        let paymentMethods = try JSONDecoder().decode(PaymentMethods.self, from: Data(paymentMethodsResponse.utf8))
        cardComponent = try buildCardComponent(paymentMethods: paymentMethods, cardComponentConfiguration: cardComponentConfiguration)
        cardDelegate = CardAdvancedFlowDelegate(componentFlutterApi: componentFlutterApi)
        cardComponent?.delegate = cardDelegate
        guard let componentViewController = cardComponent?.viewController else { throw PlatformError(errorDescription: "Failed to initialize card component") }
        guard let cardView = componentViewController.view else { throw PlatformError(errorDescription: "Failed to get card component view") }
        componentViewController.view.frame = initialFrame
        rootViewController = getViewController()
        rootViewController?.addChild(componentViewController)
        disableNativeScrollingAndBouncing(componentViewController: componentViewController)
        return cardView
    }

    private func disableNativeScrollingAndBouncing(componentViewController: UIViewController) {
        let formView = componentViewController.view.subviews[0].subviews[0] as? UIScrollView
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

    private func buildCardComponent(paymentMethods: PaymentMethods, cardComponentConfiguration: CardComponentConfigurationDTO) throws -> CardComponent {
        guard let paymentMethod = paymentMethods.paymentMethod(ofType: CardPaymentMethod.self) else {
            throw PlatformError(errorDescription: "Card payment method not provided")
        }

        let adyenContext = try cardComponentConfiguration.createAdyenContext()
        let cardConfiguration = cardComponentConfiguration.cardConfiguration.mapToCardComponentConfiguration()
        let cardComponent = CardComponent(paymentMethod: paymentMethod, context: adyenContext, configuration: cardConfiguration)
        actionComponent = try buildActionComponent(adyenContext: adyenContext)
        return cardComponent
    }

    private func buildActionComponent(adyenContext: AdyenContext) throws -> AdyenActionComponent {
        let adyenActionComponent = AdyenActionComponent(context: adyenContext)
        adyenActionComponent.delegate = actionComponentDelegate
        adyenActionComponent.presentationDelegate = presentationDelegate
        return adyenActionComponent
    }

    private func onAction(actionResponse: [String?: Any?]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: actionResponse, options: [])
            let action = try JSONDecoder().decode(Action.self, from: jsonData)
            actionComponent?.handle(action)
        } catch {
            print("Error in handling action")
        }
    }

    private func getViewController() -> UIViewController? {
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
}
