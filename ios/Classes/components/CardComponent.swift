import Flutter

@_spi(AdyenInternal) import Adyen
import AdyenNetworking

class CardComponentViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private let componentFlutterApi: ComponentFlutterApi

    init(messenger: FlutterBinaryMessenger, componentFlutterApi: ComponentFlutterApi) {
        self.messenger = messenger
        self.componentFlutterApi = componentFlutterApi
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return FLNativeView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger,
            componentFlutterApi: componentFlutterApi
        )
    }

    /// Implementing this method is only necessary when the `arguments` in `createWithFrame` is not `nil`.
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
         // return FlutterStandardMessageCodec.sharedInstance()
        return componentFlutterApi.codec
    }
}

class FLNativeView: NSObject, FlutterPlatformView, PaymentComponentDelegate {
    func didSubmit(_ data: Adyen.PaymentComponentData, from component: Adyen.PaymentComponent) {
        print("DID SUBMIT")
        do {
            let paymentComponentData = PaymentComponentDataResponse(amount: data.amount, paymentMethod: data.paymentMethod.encodable, storePaymentMethod: data.storePaymentMethod, order: data.order, amountToPay: data.order?.remainingAmount, installments: data.installments, shopperName: data.shopperName, emailAddress: data.emailAddress, telephoneNumber: data.telephoneNumber, browserInfo: data.browserInfo, checkoutAttemptId: data.checkoutAttemptId, billingAddress: data.billingAddress, deliveryAddress: data.deliveryAddress, socialSecurityNumber: data.socialSecurityNumber, delegatedAuthenticationData: data.delegatedAuthenticationData)
            let paymentComponentJson = try JSONEncoder().encode(paymentComponentData)
            let paymentComponentString = String(data: paymentComponentJson, encoding: .utf8)
            componentFlutterApi.onComponentCommunication(componentCommunicationModel: ComponentCommunicationModel(type: ComponentCommunicationType.paymentComponent, data: paymentComponentString), completion: { _ in })
        } catch {
        }
    }
    
    func didFail(with error: Error, from component: Adyen.PaymentComponent) {
        print("DID FAILL")

    }
    
    private var _view: TestView
    private var cardComponent : CardComponent?
    private var rootViewController : UIViewController?
    private let componentFlutterApi: ComponentFlutterApi
    
    private var testView: TestView?
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?,
        componentFlutterApi: ComponentFlutterApi
    ) {
        self.componentFlutterApi = componentFlutterApi
        _view = TestView(handler: {
        })
        //_view = TestView()
        super.init()
        
        // iOS views can be created here
        createNativeView(view: _view, args: args as! NSDictionary)
    }

    func view() -> UIView {
        return _view
    }

    func createNativeView(view _view: TestView, args: NSDictionary){
        
        _view.handler = {
            var height = self.cardComponent?.viewController.preferredContentSize.height ?? 0
            height += 16 //Bottom View
            self.componentFlutterApi.onComponentCommunication(componentCommunicationModel: ComponentCommunicationModel(type: ComponentCommunicationType.resize, data: height), completion: {_ in })
        }
        
        do {
            
            let paymentMethodsResponse = args.value(forKey: "paymentMethods") as! String
            let cardComponentConfiguration = args.value(forKey: "cardComponentConfiguration") as! CardComponentConfigurationDTO
            
            let paymentMethods = try JSONDecoder().decode(PaymentMethods.self, from: Data(paymentMethodsResponse.utf8))
            let component = try cardComponent(from: paymentMethods, cardComponentConfiguration: cardComponentConfiguration)
            component.delegate = self
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
            _view.addSubview(cardView)
            
            //_view.translatesAutoresizingMaskIntoConstraints = false
            //cardView.adyen.anchor(inside: _view)
            
            
            cardView.translatesAutoresizingMaskIntoConstraints = false
            let horizontalConstraint1 = cardView.leadingAnchor.constraint(equalTo: _view.leadingAnchor)
            let horizontalConstraint2 = cardView.trailingAnchor.constraint(equalTo: _view.trailingAnchor)
            let horizontalConstraint3 = cardView.topAnchor.constraint(equalTo: _view.topAnchor)
            let horizontalConstraint4 = cardView.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
            NSLayoutConstraint.activate([horizontalConstraint1, horizontalConstraint2, horizontalConstraint3, horizontalConstraint4])
            
            
           
            print("Form height: \(componentViewController.preferredContentSize.height)")

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                print("Form height: \(componentViewController.preferredContentSize.height)")
                print("Container view height: \(_view.frame.height)")
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

