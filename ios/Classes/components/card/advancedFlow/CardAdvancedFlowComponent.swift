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
    private var cardComponent: CardComponent?

    private var rootViewController: UIViewController?
    private var componentDelegate: CardAdvancedFlowDelegate?
    private var actionComponent: AdyenActionComponent?

    init(
        frame _: CGRect,
        viewIdentifier _: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterApi
    ) {
        self.componentFlutterApi = componentFlutterApi
        componentPlatformApi = ComponentPlatformApi()
        actionComponentDelegate = CardAdvancedFlowActionComponentDelegate(componentFlutterApi: componentFlutterApi)
        presentationDelegate = CardAvancedFlowPresentationDelegate()
        componentWrapperView = .init()
        ComponentPlatformInterfaceSetup.setUp(binaryMessenger: binaryMessenger, api: componentPlatformApi)
        super.init()

        componentWrapperView.resizeViewportCallback = {
            var viewHeight = Double(round(100 * (self.cardComponent?.viewController.preferredContentSize.height ?? 0) ) / 100)
            viewHeight += 32 // Bottom View
            self.componentFlutterApi.onComponentCommunication(componentCommunicationModel: ComponentCommunicationModel(type: ComponentCommunicationType.resize, data: viewHeight), completion: { _ in })
        }
        
        componentPlatformApi.onActionCallback = { [weak self] jsonActionResponse in
            self?.onAction(actionResponse: jsonActionResponse)
        }

        createCardComponentView(arguments: arguments)
    }

    func view() -> UIView {
        return componentWrapperView
    }

    private func createCardComponentView(arguments: NSDictionary) {
        do {
            guard let paymentMethodsResponse = arguments.value(forKey: "paymentMethods") as? String else { throw PlatformError(errorDescription: "Payment methods not provided") }
            guard let cardComponentConfiguration = arguments.value(forKey: "cardComponentConfiguration") as? CardComponentConfigurationDTO else { throw PlatformError(errorDescription: "Card configuration not provided")  }
            let paymentMethods = try JSONDecoder().decode(PaymentMethods.self, from: Data(paymentMethodsResponse.utf8))
            let component = try cardComponent(from: paymentMethods, cardComponentConfiguration: cardComponentConfiguration)
            componentDelegate = CardAdvancedFlowDelegate(componentFlutterApi: componentFlutterApi)
            component.delegate = componentDelegate
            
            actionComponent = createActionComponent(arguments: arguments)

            cardComponent = component
            let componentViewController = component.viewController

            rootViewController = getViewController()
            rootViewController?.addChild(componentViewController)

            componentViewController.view.frame = CGRect(x: 0.0, y: 0.0, width: 0, height: 0)
            (componentViewController.view.subviews[0].subviews[0] as? UIScrollView)?.bounces = false
            (componentViewController.view.subviews[0].subviews[0] as? UIScrollView)?.isScrollEnabled = false
            (componentViewController.view.subviews[0].subviews[0] as? UIScrollView)?.alwaysBounceVertical = false

            // let formViewController = componentViewController.children[0]

            let cardView = componentViewController.view!
            componentWrapperView.addSubview(cardView)

            // _view.translatesAutoresizingMaskIntoConstraints = false
            // cardView.adyen.anchor(inside: _view)

            cardView.translatesAutoresizingMaskIntoConstraints = false
            let horizontalConstraint1 = cardView.leadingAnchor.constraint(equalTo: componentWrapperView.leadingAnchor)
            let horizontalConstraint2 = cardView.trailingAnchor.constraint(equalTo: componentWrapperView.trailingAnchor)
            let horizontalConstraint3 = cardView.topAnchor.constraint(equalTo: componentWrapperView.topAnchor)
            let horizontalConstraint4 = cardView.bottomAnchor.constraint(equalTo: componentWrapperView.bottomAnchor)
            NSLayoutConstraint.activate([horizontalConstraint1, horizontalConstraint2, horizontalConstraint3, horizontalConstraint4])

        } catch {}
    }

    private func cardComponent(from paymentMethods: PaymentMethods, cardComponentConfiguration: CardComponentConfigurationDTO) throws -> CardComponent {
        let context = try APIContext(environment: Adyen.Environment.test, clientKey: cardComponentConfiguration.clientKey)
        let adyenContext = AdyenContext(apiContext: context,
                                        payment: Payment(amount: Amount(value: 2100, currencyCode: "EUR"), countryCode: "NL"),
                                        analyticsConfiguration: AnalyticsConfiguration())

        guard let paymentMethod = paymentMethods.paymentMethod(ofType: CardPaymentMethod.self) else {
            throw PlatformError(errorDescription: "error")
        }

        var style = FormComponentStyle()
        style.backgroundColor = UIColor.clear
        let component = CardComponent(paymentMethod: paymentMethod,
                                      context: adyenContext,
                                      configuration: cardComponentConfiguration.cardConfiguration.toCardComponentConfiguration())
        component.cardComponentDelegate = self
        return component
    }

    private func viewController(for component: PresentableComponent) -> UIViewController {
        guard component.requiresModalPresentation else {
            return component.viewController
        }

        let navigation = UINavigationController(rootViewController: component.viewController)
        component.viewController.navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .cancel,
                                                                          target: self,
                                                                          action: #selector(cancelPressed))
        return navigation
    }

    @objc private func cancelPressed() {
        cardComponent?.cancelIfNeeded()
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
  */


extension FormViewController {
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        print("Did layout")
    }
}

extension CardConfigurationDTO {
    func toCardComponentConfiguration() -> CardComponent.Configuration {
        let koreanAuthenticationMode = kcpFieldVisibility.toCardFieldVisibility()
        let socialSecurityNumberMode = socialSecurityNumberFieldVisibility.toCardFieldVisibility()
        let storedCardConfiguration = createStoredCardConfiguration(showCvcForStoredCard: showCvcForStoredCard)
        let allowedCardTypes = determineAllowedCardTypes(cardTypes: supportedCardTypes)
        let billingAddressConfiguration = determineBillingAddressConfiguration(addressMode: addressMode)
        let cardConfiguration = CardComponent.Configuration(
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
