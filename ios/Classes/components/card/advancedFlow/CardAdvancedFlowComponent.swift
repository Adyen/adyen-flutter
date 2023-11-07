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
        initialFrame = frame
        super.init()

        ComponentPlatformInterfaceSetup.setUp(binaryMessenger: binaryMessenger, api: componentPlatformApi)
        setupCallbacks()
        do {
            let cardView = try createCardComponentView(arguments: arguments)
            componentWrapperView.addSubview(cardView)
            adjustCardComponentLayout(cardView: cardView)
        } catch {
            // TODO: Dispaly error
        }
    }

    func view() -> UIView {
        return componentWrapperView
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
        cardComponent = try buildCardComponent(from: paymentMethods, cardComponentConfiguration: cardComponentConfiguration)
        cardDelegate = CardAdvancedFlowDelegate(componentFlutterApi: componentFlutterApi)
        cardComponent?.delegate = cardDelegate
        actionComponent = createActionComponent(arguments: arguments)
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

    private func buildCardComponent(from paymentMethods: PaymentMethods, cardComponentConfiguration: CardComponentConfigurationDTO) throws -> CardComponent {
        let context = try APIContext(environment: Adyen.Environment.test, clientKey: cardComponentConfiguration.clientKey)
        let adyenContext = AdyenContext(apiContext: context,
                                        payment: Payment(amount: Amount(value: 2100, currencyCode: "EUR"), countryCode: "NL"),
                                        analyticsConfiguration: AnalyticsConfiguration())

        guard let paymentMethod = paymentMethods.paymentMethod(ofType: CardPaymentMethod.self) else {
            throw PlatformError(errorDescription: "error")
        }

        let component = CardComponent(paymentMethod: paymentMethod,
                                      context: adyenContext,
                                      configuration: cardComponentConfiguration.cardConfiguration.toCardComponentConfiguration())
        component.cardComponentDelegate = self
        return component
    }

    private func createActionComponent(arguments: NSDictionary) -> AdyenActionComponent? {
        do {
            let cardComponentConfiguration = arguments.value(forKey: "cardComponentConfiguration") as! CardComponentConfigurationDTO
            let apiContext = try APIContext(environment: Adyen.Environment.test, clientKey: cardComponentConfiguration.clientKey)
            let adyenContext = AdyenContext(apiContext: apiContext,
                                            payment: Payment(amount: Amount(value: 2100, currencyCode: "EUR"), countryCode: "NL"))

            let component = AdyenActionComponent(context: adyenContext)
            component.delegate = actionComponentDelegate
            component.presentationDelegate = presentationDelegate

            return component
        } catch {
            return nil
        }
    }

    func onAction(actionResponse: [String?: Any?]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: actionResponse, options: [])
            let action = try JSONDecoder().decode(Action.self, from: jsonData)
            actionComponent?.handle(action)
        } catch {
            print("ERRROR ACTION")
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

extension CardAdvancedFlowComponent: CardComponentDelegate {
    func didSubmit(lastFour: String, finalBIN: String, component _: CardComponent) {
        print("Card used: **** **** **** \(lastFour)")
        print("Final BIN: \(finalBIN)")
    }

    func didChangeBIN(_ value: String, component _: CardComponent) {
        print("Current BIN: \(value)")
    }

    func didChangeCardBrand(_ value: [CardBrand]?, component _: CardComponent) {
        print("Current card type: \((value ?? []).reduce("") { "\($0), \($1)" })")
    }
}

/*
  extension FormView {

      public override func layoutSubviews() {
          super.layoutSubviews()

          //print("Form layout subviews")
          //NotificationCenter.default.post(name: .updateSize, object: nil)
      }
  }

 extension FormViewController {
     override open func viewDidLayoutSubviews() {
         super.viewDidLayoutSubviews()

         print("Did layout")
     }
 }

  */

extension CardConfigurationDTO {
    func toCardComponentConfiguration() -> CardComponent.Configuration {
        var formComponentStyle = FormComponentStyle()
        formComponentStyle.backgroundColor = UIColor.clear
        let koreanAuthenticationMode = kcpFieldVisibility.toCardFieldVisibility()
        let socialSecurityNumberMode = socialSecurityNumberFieldVisibility.toCardFieldVisibility()
        let storedCardConfiguration = createStoredCardConfiguration(showCvcForStoredCard: showCvcForStoredCard)
        let allowedCardTypes = determineAllowedCardTypes(cardTypes: supportedCardTypes)
        let billingAddressConfiguration = determineBillingAddressConfiguration(addressMode: addressMode)
        let cardConfiguration = CardComponent.Configuration(
            style: formComponentStyle,
            showsHolderNameField: holderNameRequired,
            showsStorePaymentMethodField: showStorePaymentField,
            showsSecurityCodeField: showCvc,
            koreanAuthenticationMode: koreanAuthenticationMode,
            socialSecurityNumberMode: socialSecurityNumberMode,
            storedCardConfiguration: storedCardConfiguration,
            allowedCardTypes: allowedCardTypes,
            billingAddress: billingAddressConfiguration
        )

        return cardConfiguration
    }

    private func createStoredCardConfiguration(showCvcForStoredCard: Bool) -> StoredCardConfiguration {
        var storedCardConfiguration = StoredCardConfiguration()
        storedCardConfiguration.showsSecurityCodeField = showCvcForStoredCard
        return storedCardConfiguration
    }

    private func determineAllowedCardTypes(cardTypes: [String?]?) -> [CardType]? {
        guard let mappedCardTypes = cardTypes, !mappedCardTypes.isEmpty else {
            return nil
        }

        return mappedCardTypes.compactMap { $0 }.map { CardType(rawValue: $0.lowercased()) }
    }

    private func determineBillingAddressConfiguration(addressMode: AddressMode?) -> BillingAddressConfiguration {
        var billingAddressConfiguration = BillingAddressConfiguration()
        switch addressMode {
        case .full:
            billingAddressConfiguration.mode = CardComponent.AddressFormType.full
        case .postalCode:
            billingAddressConfiguration.mode = CardComponent.AddressFormType.postalCode
        case .none?:
            billingAddressConfiguration.mode = CardComponent.AddressFormType.none
        default:
            billingAddressConfiguration.mode = CardComponent.AddressFormType.none
        }

        return billingAddressConfiguration
    }
}
