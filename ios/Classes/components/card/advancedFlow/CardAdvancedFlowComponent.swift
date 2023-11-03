import Flutter

@_spi(AdyenInternal)
import Adyen
import AdyenNetworking

class FLNativeView: NSObject, FlutterPlatformView {
    
    private var componentWrapperView: ComponentWrapperView = ComponentWrapperView(resizeViewport: {})
    private var cardComponent : CardComponent?
    private var rootViewController : UIViewController?
    private let componentFlutterApi: ComponentFlutterApi
    private let componentPlatformApi: ComponentPlatformApi
    private var componentDelegate: CardAdvancedFlowDelegate?
    
    
    private var adyenActionComponent: AdyenActionComponent?
  
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments: NSDictionary,
        binaryMessenger: FlutterBinaryMessenger,
        componentFlutterApi: ComponentFlutterApi
    ) {
        self.componentFlutterApi = componentFlutterApi
        self.componentPlatformApi = ComponentPlatformApi(onActionCallback: {_ in })
        
        
        super.init()
        
        self.adyenActionComponent = createActionComponent(arguments: arguments)

        ComponentPlatformInterfaceSetup.setUp(binaryMessenger: binaryMessenger, api: componentPlatformApi)
        self.componentPlatformApi.onActionCallback = { [weak self] jsonActionResponse in
            self?.onAction(actionResponse: jsonActionResponse)
        }
        
        createNativeView(args: arguments)
    }
    
    func createActionComponent(arguments: NSDictionary) -> AdyenActionComponent? {
        do {
            let cardComponentConfiguration = arguments.value(forKey: "cardComponentConfiguration") as! CardComponentConfigurationDTO
            let apiContext = try APIContext(environment: Adyen.Environment.test, clientKey: cardComponentConfiguration.clientKey)
            let adyenContext = AdyenContext(apiContext: apiContext,
                                            payment: Payment(amount: Amount(value: 2100, currencyCode: "EUR"), countryCode: "NL"))
            
            return AdyenActionComponent(context: adyenContext)
        } catch {
            return nil
        }
    }
    
    func onAction(actionResponse: [String? : Any?]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: actionResponse, options: [])
            let action = try JSONDecoder().decode(Action.self, from: jsonData)
            adyenActionComponent?.handle(action)
            print("ACTION")
        }catch {
            print("ERRROR ACTION")
        }
        
     
    }

    func view() -> UIView {
        return componentWrapperView
    }

    func createNativeView(args: NSDictionary){
        
        componentWrapperView.resizeViewportCallback = {
            var height = self.cardComponent?.viewController.preferredContentSize.height ?? 0
            height += 16 //Bottom View
            self.componentFlutterApi.onComponentCommunication(componentCommunicationModel: ComponentCommunicationModel(type: ComponentCommunicationType.resize, data: height), completion: {_ in })
        }
        
     
        
       
        
        do {
            
            let paymentMethodsResponse = args.value(forKey: "paymentMethods") as! String
            let cardComponentConfiguration = args.value(forKey: "cardComponentConfiguration") as! CardComponentConfigurationDTO
            
            let paymentMethods = try JSONDecoder().decode(PaymentMethods.self, from: Data(paymentMethodsResponse.utf8))
            let component = try cardComponent(from: paymentMethods, cardComponentConfiguration: cardComponentConfiguration)
            componentDelegate = CardAdvancedFlowDelegate(componentFlutterApi: componentFlutterApi)
            component.delegate = componentDelegate
            self.cardComponent = component
            let componentViewController = component.viewController
            
            
            rootViewController = getViewController()
            rootViewController?.addChild(componentViewController)
            
            

                        
            componentViewController.view.frame = CGRect(x:0.0, y:0.0, width: 0, height:0)
            (componentViewController.view.subviews[0].subviews[0] as? UIScrollView)?.bounces = false
            (componentViewController.view.subviews[0].subviews[0] as? UIScrollView)?.isScrollEnabled = false
            (componentViewController.view.subviews[0].subviews[0] as? UIScrollView)?.alwaysBounceVertical = false
            
            
            //let formViewController = componentViewController.children[0]
            
            let cardView = componentViewController.view!
            componentWrapperView.addSubview(cardView)
            
            //_view.translatesAutoresizingMaskIntoConstraints = false
            //cardView.adyen.anchor(inside: _view)
            
            
            cardView.translatesAutoresizingMaskIntoConstraints = false
            let horizontalConstraint1 = cardView.leadingAnchor.constraint(equalTo: componentWrapperView.leadingAnchor)
            let horizontalConstraint2 = cardView.trailingAnchor.constraint(equalTo: componentWrapperView.trailingAnchor)
            let horizontalConstraint3 = cardView.topAnchor.constraint(equalTo: componentWrapperView.topAnchor)
            let horizontalConstraint4 = cardView.bottomAnchor.constraint(equalTo: componentWrapperView.bottomAnchor)
            NSLayoutConstraint.activate([horizontalConstraint1, horizontalConstraint2, horizontalConstraint3, horizontalConstraint4])
            
            
           
            print("Form height: \(componentViewController.preferredContentSize.height)")

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                print("Form height: \(componentViewController.preferredContentSize.height)")
                print("Container view height: \(self.componentWrapperView.frame.height)")
            }
            
            //NotificationCenter.default.addObserver(self, selector: #selector(checkSize(notification:)), name: .updateSize, object: nil)

            
        } catch {
        }

    
    }
    
    @objc func checkSize(notification: NSNotification) {
         print("checkSize")
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
                                      configuration: cardComponentConfiguration.cardConfiguration.toCardComponentConfiguration()
                                )
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

extension FLNativeView: CardComponentDelegate {

    func didSubmit(lastFour: String, finalBIN: String, component: CardComponent) {
        print("Card used: **** **** **** \(lastFour)")
        print("Final BIN: \(finalBIN)")
    }

    internal func didChangeBIN(_ value: String, component: CardComponent) {
        print("Current BIN: \(value)")
    }

    internal func didChangeCardBrand(_ value: [CardBrand]?, component: CardComponent) {
        print("Current card type: \((value ?? []).reduce("") { "\($0), \($1)" })")
    }
}

extension FLNativeView: AdyenSessionDelegate {
    
    func didComplete(with result: AdyenSessionResult, component: Component, session: AdyenSession) {
    }

    func didFail(with error: Error, from component: Component, session: AdyenSession) {
    }

    func didOpenExternalApplication(component: ActionComponent, session: AdyenSession) {}

}

extension FLNativeView: PresentationDelegate {
    internal func present(component: PresentableComponent) {
        let componentViewController = viewController(for: component)

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

extension Notification.Name {
     static let updateSize = Notification.Name("size")
}


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


